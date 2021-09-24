const { ethers } = require("hardhat");
const faker = require('faker');
const deploy = require('./init');

const membersModInfo = {
  keyCode: ethers.utils.toUtf8Bytes("MBR"),
  name: "def_Members",
};
const tokenModInfo = {
  keyCode: ethers.utils.toUtf8Bytes("TKN"),
  name: "def_Token",
}

async function seedData() {
  const { 
    defaultOs, 
    defaultOsFactory,
    defaultTokenInstaller,
    defaultEpochInstaller,
    defaultTreasuryInstaller,
    defaultMiningInstaller,
    defaultMembersInstaller,
    defaultPeerRewardsInstaller,
  } = await deploy();
  const accounts = await ethers.getSigners();

  const testOsName = ethers.utils.formatBytes32String('testOs');
  const otherOsName = ethers.utils.formatBytes32String('otherOs');

  // create two new test OSs
  await defaultOsFactory.setOS(testOsName);
  await defaultOsFactory.setOS(otherOsName);
  
  const testOsAddress = await defaultOsFactory.osMap(testOsName);
  const otherOsAddress = await defaultOsFactory.osMap(otherOsName);

  const testOs = await ethers.getContractAt("DefaultOS", testOsAddress);
  const otherOs = await ethers.getContractAt("DefaultOS", otherOsAddress);
  console.log('[CONTRACT DEPLOYED] testOs: ', testOs.address);
  console.log('[CONTRACT DEPLOYED] otherOs: ', otherOs.address);

  // split the available accounts into each os
  const half = Math.ceil(accounts.length / 2); 
  const testOsMembers = accounts.slice(0, half);
  const otherOsMembers = accounts.slice(-half);

  // install all modules for each os
  await testOs.installModule(defaultTokenInstaller.address);
  await testOs.installModule(defaultEpochInstaller.address);
  await testOs.installModule(defaultTreasuryInstaller.address);
  await testOs.installModule(defaultMiningInstaller.address);
  await testOs.installModule(defaultMembersInstaller.address);
  await testOs.installModule(defaultPeerRewardsInstaller.address);

  await otherOs.installModule(defaultTokenInstaller.address);
  await otherOs.installModule(defaultEpochInstaller.address);
  await otherOs.installModule(defaultTreasuryInstaller.address);
  await otherOs.installModule(defaultMiningInstaller.address);
  await otherOs.installModule(defaultMembersInstaller.address);
  await otherOs.installModule(defaultPeerRewardsInstaller.address);

  // Members module contract
  const testOsMemMod = await getModuleContract(testOs, membersModInfo);
  const otherOsMemMod = await getModuleContract(otherOs, membersModInfo);

  // Token module contract
  const testOsTokenMod = await getModuleContract(testOs, tokenModInfo);
  const otherOsTokenMod = await getModuleContract(otherOs, tokenModInfo);

  // create memberships
  await bulkRegisterMembers(testOs, testOsMemMod, testOsMembers);
  await bulkRegisterMembers(otherOs, otherOsMemMod, otherOsMembers);

  // mint tokens
  await bulkMintTokens(testOs, testOsTokenMod, testOsMemMod, testOsMembers);
  await bulkMintTokens(otherOs, otherOsTokenMod, otherOsMemMod, otherOsMembers);

  // stake tokens
  await bulkStakeForMembers(testOs, testOsMemMod, testOsTokenMod,testOsMembers);
  await bulkStakeForMembers(otherOs, otherOsMemMod, otherOsTokenMod,otherOsMembers);

  // endorse members
  await bulkEndorseMembers(testOs, testOsMemMod, testOsTokenMod, testOsMembers);
  await bulkEndorseMembers(otherOs, otherOsMemMod, otherOsTokenMod, otherOsMembers);

}

async function bulkRegisterMembers(os, membersModule, members) {
  const osName = ethers.utils.parseBytes32String(await os.organizationName());
  members.forEach(async member => {
    const signer = await ethers.getSigner(member.address);
    const alias = ethers.utils.formatBytes32String(faker.internet.userName());
  
    // set alias
    await membersModule.connect(signer).setAlias(alias);
  
    // confirm alias
    const memAdd = await membersModule.getMemberForAlias(alias);
    console.log(
      `[OS ${osName}][Member Registered] alias: ${ethers.utils.parseBytes32String(alias)}, address:${memAdd}`
    );
  });
}

async function bulkMintTokens(os, tokenModule, membersModule, members) {
  const osName = ethers.utils.parseBytes32String(await os.organizationName());
  await members.forEach(async member => {
    await tokenModule.mint(member.address, ethers.BigNumber.from("1000"));
    // verify 
    const balance = await tokenModule.balanceOf(member.address);
    await tokenModule.connect(member).approve(membersModule.address, balance);
    console.log(
      `[OS ${osName}][Tokens Minted] address: ${member.address}, balance: ${balance}`
    );
  });
  
}

async function bulkStakeForMembers(os, membersModule, tokenModule, members) {
  // stake half of each members tokens after theyve been minted and approved
  const osName = ethers.utils.parseBytes32String(await os.organizationName());
  await members.forEach(async member => {
    tokenModule.once(tokenModule.filters.Approval(member.address, membersModule.address), async () => {
      
      const acctBalance = await tokenModule.balanceOf(member.address);
      const halfOfAcctBalance = acctBalance.div(2);
      const lockDuration = ethers.BigNumber.from(faker.datatype.number({ min: 50, max: 180 }));
  
      await membersModule.connect(member).mintEndorsements(lockDuration, halfOfAcctBalance);
      const totalEndorsements = await membersModule.totalEndorsementsAvailableToGive(member.address);
      console.log(
        `[OS ${osName}][Tokens Staked] address: ${member.address}, totalEndorsements: ${totalEndorsements}`
      );
    });
  });
}

async function bulkEndorseMembers(os, membersModule, tokenModule, members) {
  const osName = ethers.utils.parseBytes32String(await os.organizationName());
  await members.forEach( async (member, index) => {

    membersModule.once(membersModule.filters.TokensStaked(null, member.address), async () => {
      
      // pick a random member to endorse to
      let randomIndex = null;
      while(randomIndex === null || randomIndex === index) {
        randomIndex = faker.datatype.number({min: 0, max: members.length - 1});
      }
      const totalEndorsements = await membersModule.totalEndorsementsAvailableToGive(member.address);
      const memberToEndorse = members[randomIndex];
      //console.log(`member: ${member.address} will give ${totalEndorsements.toString()} to member: ${memberToEndorse.address}`);
      await membersModule.connect(member).endorseMember(memberToEndorse.address, totalEndorsements);

      // verify
      membersModule.once(membersModule.filters.EndorsementGiven(null, member.address, memberToEndorse.address), 
      async (_os, _fromMember, _toMember, _endorsementsGiven, _epoch) => {
        console.log(`[OS ${osName}][Endorsements Received] ${_toMember} received ${_endorsementsGiven.toString()} from ${_fromMember}`);

        // randomly create a few withdrawals
        if (faker.datatype.boolean()) {
          const signer = await ethers.getSigner(_fromMember);
          const amtToWithdrawl = ethers.BigNumber.from(faker.datatype.number({min: 1, max: 100})); // there should never be less than 100 endorsements given
          await membersModule.connect(signer).withdrawEndorsementFrom(_toMember, amtToWithdrawl);

          // verify 
          membersModule.once(membersModule.filters.EndorsementWithdrawn(null, _fromMember, _toMember), 
          async (os_, fromMember_, toMember_, endorsementsWithdrawn_, epoch_) => {
            console.log(`[OS ${osName}][Endorsement Withdrawn] ${fromMember_} withdrew ${endorsementsWithdrawn_.toString()} from their endorsement to ${toMember_}`);

          })
        }
      });
    });

  });
}

async function getModuleContract(os, moduleInfo) {
  const modAddress = await os.getModule(moduleInfo.keyCode);
  const mod = await ethers.getContractAt(moduleInfo.name, modAddress);
  return mod;
}

seedData();