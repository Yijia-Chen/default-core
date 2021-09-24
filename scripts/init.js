const { ethers } = require("hardhat");

async function main() {
  const defaultOsName = ethers.utils.formatBytes32String("Default Dao")

  const DefaultOsFactory = await ethers.getContractFactory("DefaultOSFactory");

  const DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
  const DefaultEpochInstaller = await ethers.getContractFactory("def_EpochInstaller");
  const DefaultTreasuryInstaller = await ethers.getContractFactory("def_TreasuryInstaller");
  const DefaultMiningInstaller = await ethers.getContractFactory("def_MiningInstaller");
  const DefaultMembersInstaller = await ethers.getContractFactory("def_MembersInstaller");
  const DefaultPeerRewardsInstaller = await ethers.getContractFactory("def_PeerRewardsInstaller");

  const defaultOsFactory = await DefaultOsFactory.deploy()
  await defaultOsFactory.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultOSFactory: ", defaultOsFactory.address);

  // get default os contract created from factory
  await defaultOsFactory.setOS(defaultOsName)
  const defaultOsAddress = await defaultOsFactory.osMap(defaultOsName)
  const defaultOs = await ethers.getContractAt("DefaultOS", defaultOsAddress);

  console.log("[CONTRACT DEPLOYED] DefaultOs: ", defaultOs.address);
  
  const defaultTokenInstaller = await DefaultTokenInstaller.deploy();
  await defaultTokenInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultTokenInstaller: ", defaultTokenInstaller.address);

  const defaultEpochInstaller = await DefaultEpochInstaller.deploy();
  await defaultEpochInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultEpochInstaller: ", defaultEpochInstaller.address);

  const defaultTreasuryInstaller = await DefaultTreasuryInstaller.deploy();
  await defaultTreasuryInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultTreasuryInstaller: ", defaultTreasuryInstaller.address);

  const defaultMiningInstaller = await DefaultMiningInstaller.deploy();
  await defaultMiningInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultMiningInstaller: ", defaultMiningInstaller.address);

  const defaultMembersInstaller = await DefaultMembersInstaller.deploy();
  await defaultMembersInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultMembersInstaller: ", defaultMembersInstaller.address);
  
  const defaultPeerRewardsInstaller = await DefaultPeerRewardsInstaller.deploy();
  await defaultPeerRewardsInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultPeerRewardsInstaller: ", defaultPeerRewardsInstaller.address);

  await defaultOs.installModule(defaultTokenInstaller.address);
  await defaultOs.installModule(defaultEpochInstaller.address);
  await defaultOs.installModule(defaultTreasuryInstaller.address);
  await defaultOs.installModule(defaultMiningInstaller.address);
  await defaultOs.installModule(defaultMembersInstaller.address);
  await defaultOs.installModule(defaultPeerRewardsInstaller.address);
  return {
    defaultOs,
    defaultOsFactory,
    defaultTokenInstaller,
    defaultEpochInstaller,
    defaultTreasuryInstaller,
    defaultMiningInstaller,
    defaultMembersInstaller,
    defaultPeerRewardsInstaller,
  }
}

module.exports = main;