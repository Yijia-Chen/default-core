// npx hardhat run scripts/deploy.js --network <network-name>

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");

async function main() {

  const DaoTracker = await ethers.getContractFactory("DaoTracker");

  const DefaultOS = await ethers.getContractFactory("DefaultOS");

  const DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
  const DefaultMembersInstaller = await ethers.getContractFactory("def_MembersInstaller");
  const DefaultPeerRewardsInstaller = await ethers.getContractFactory("def_PeerRewardsInstaller");

  const daoTracker = await DaoTracker.deploy()
  await daoTracker.deployed();
  console.log("[CONTRACT DEPLOYED] DaoTracker: ", daoTracker.address);

  const defaultOS = await DefaultOS.deploy("Default DAO", "default", daoTracker.address)
  await defaultOS.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultOS: ", defaultOS.address);
  
  const defaultTokenInstaller = await DefaultTokenInstaller.deploy();
  await defaultTokenInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultTokenInstaller: ", defaultTokenInstaller.address);

  const defaultMembersInstaller = await DefaultMembersInstaller.deploy();
  await defaultMembersInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultMembersInstaller: ", defaultMembersInstaller.address);
  
  const defaultPeerRewardsInstaller = await DefaultPeerRewardsInstaller.deploy();
  await defaultPeerRewardsInstaller.deployed();
  console.log("[CONTRACT DEPLOYED] DefaultMembersInstaller: ", defaultPeerRewardsInstaller.address);

  await defaultOS.installModule(defaultTokenInstaller.address);
  await defaultOS.installModule(defaultMembersInstaller.address);
  await defaultOS.installModule(defaultPeerRewardsInstaller.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
