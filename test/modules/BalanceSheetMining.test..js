// const { expect } = require("chai");
// const { ethers } = require("ethers");

// const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

// describe("TreasuryVault.sol", function () {

//   before(async function () {
//     this.signers = await ethers.getSigners();
//     this.devAddr = this.signers[0]
//     this.daoMultisig = this.signers[1]
//     this.userOne = this.signers[2]
//     this.userTwo = this.signers[3]
//     this.userThree = this.signers[4]

//     this.Memberships = await ethers.getContractFactory("Memberships");
//     this.TreasuryVault = await ethers.getContractFactory("TreasuryVault");
//     this.Token = await ethers.getContractFactory("DefaultToken");
//     this.BalanceSheetMining = await ethers.getContractFactory("BalanceSheetMining");
//   })

//   beforeEach(async function () {
//     this.memberships = await this.Memberships.deploy([this.userOne.address, this.userTwo.address, this.userThree.address]);
//     await this.memberships.deployed();

//     this.dnt = await this.Token.deploy();
//     this.usdc = await this.Token.deploy();
//     await this.dnt.deployed();
//     await this.usdc.deployed();

//     this.dntVault = await this.TreasuryVault.deploy(this.token.address, this.mining.address, 85, false, this.memberships.address);
//     this.usdcVault = await this.TreasuryVault.deploy(this.token.address, this.mining.address, 85, false, this.memberships.address);
//     await this.dntVault.deployed();
//     await this.usdcVault.deployed();

//     const usdcVaultShares = await this.usdcVault.Shares();
//     const dntVaultShares = await this.dntVault.Shares();

//     this.mining = await this.BalanceSheetMining.deploy([]);
//     await this.mining.deployed();

//     // mint tokens
//     const ownerCalls = this.token.connect(this.devAddr);
//     await ownerCalls.approveApplication(this.devAddr.address);
//     await ownerCalls.changeOperator(this.devAddr.address);
//   })  

//   it("should set correct state variables", async function () {
//     // expect(await this.epoch.owner()).to.equal(this.devAddr.address);
//     // expect(await this.epoch.currentEpoch()).to.equal(0);

//     expect (await this.vault.Assets()).to.equal(this.token.address);
//     expect (await this.vault.Shares()).to.be.properAddress;
//     expect (await this.vault.Rewarder()).to.equal(ZERO_ADDRESS);
//   })

//   it("should set correct access permissions", async function () {
//     // random user cannot call the contract
//     // const userOneCalls = this.epoch.connect(this.userOne);
//     // await expect(userOneCalls.incrementEpoch()).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
//     // await expect(userOneCalls.resetEpoch()).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
//   })

//   it("should properly increment the epoch", async function() {
//     // approve and set up the app contract (as the multisig)
//   //   await this.epoch.approveApplication(this.daoMultisig.address);
//   //   const approvedAppCalls = this.epoch.connect(this.daoMultisig);

//   //   await approvedAppCalls.incrementEpoch();
//   //   expect(await this.epoch.currentEpoch()).to.equal(1);

//   //   await approvedAppCalls.resetEpoch();
//   //   expect(await this.epoch.currentEpoch()).to.equal(0);
//   // })
//   })
// })