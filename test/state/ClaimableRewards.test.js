const { expect } = require("chai");

describe("ClaimableRewards.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners()
    this.devAddr = this.signers[0]
    this.daoMultisig = this.signers[1]
    this.operator = this.signers[2]
    this.userOne = this.signers[3]
    this.userTwo = this.signers[4]
    this.userThree = this.signers[5]

    this.ClaimableRewards = await ethers.getContractFactory("ClaimableRewards");
    this.VaultShares = await ethers.getContractFactory("VaultShares");
  })

  beforeEach(async function () {
    // pretend devAddr is the vault for these shares.
    this.usdcShares = await this.VaultShares.deploy("USDC Vault Shares", "USDC-VS", 6);
    this.dntShares = await this.VaultShares.deploy("DNT Vault Shares", "DNT-VS", 18);
    await this.usdcShares.deployed();
    await this.dntShares.deployed();

    this.rewards = await this.ClaimableRewards.deploy(this.usdcShares.address, this.dntShares.address);
    await this.rewards.deployed();
  })  

  it("should set correct state variables", async function () {
    expect(await this.rewards.owner()).to.equal(this.devAddr.address);
    expect(await this.rewards.rewardToken()).to.equal(this.dntShares.address);
    expect(await this.rewards.depositorShares()).to.equal(this.usdcShares.address);

    expect(await this.rewards.accRewardsPerShare()).to.equal(0);
    expect(await this.rewards.reservedRewards()).to.equal(0);
  })

//   it("should set correct ownership permissions", async function () {
//     // random user cannot call the contract
//     const userOneCalls = this.epoch.connect(this.userOne);
//     await expect(userOneCalls.incrementEpoch()).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
//     await expect(userOneCalls.resetEpoch()).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
//   })

//   it("should properly increment the epoch", async function() {
//     // approve and set up the app contract (as the multisig)
//     await this.epoch.approveApplication(this.daoMultisig.address);
//     const approvedAppCalls = this.epoch.connect(this.daoMultisig);

//     await approvedAppCalls.incrementEpoch();
//     expect(await this.epoch.currentEpoch()).to.equal(1);

//     await approvedAppCalls.resetEpoch();
//     expect(await this.epoch.currentEpoch()).to.equal(0);
//   })
})