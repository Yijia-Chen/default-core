const { expect } = require("chai");
const { BigNumber } = require("ethers");

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
    this.VaultShares = await ethers.getContractFactory("VaultShares", this.operator);
  })

  beforeEach(async function () {
    // pretend devAddr is the vault for these shares.
    this.usdcShares = await this.VaultShares.deploy("USDC Vault Shares", "USDC-VS", 6);
    this.defShares = await this.VaultShares.deploy("DNT Vault Shares", "DNT-VS", 18);
    await this.defShares.deployed();
    await this.usdcShares.deployed();

    this.rewards = await this.ClaimableRewards.deploy(this.usdcShares.address, this.defShares.address);
    await this.rewards.deployed();
  })  

  it("should set correct state variables", async function () {
    expect(await this.rewards.owner()).to.equal(this.devAddr.address);
    expect(await this.rewards.rewardToken()).to.equal(this.defShares.address);
    expect(await this.rewards.depositorShares()).to.equal(this.usdcShares.address);

    expect(await this.rewards.accRewardsPerShare()).to.equal(0);
    expect(await this.rewards.ineligibleRewards(this.devAddr.address)).to.equal(0);
    expect(await this.rewards.ineligibleRewards('0x0000000000000000000000000000000000000000')).to.equal(0);
  })

  it("should set correct ownership permissions", async function () {
    // random user cannot call the contract
    const userOneCalls = this.rewards.connect(this.userOne);
    await expect(userOneCalls.resetClaimableRewards(this.devAddr.address)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.distributeRewards(1000)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");

    await this.rewards.approveApplication(this.operator.address);
    await this.usdcShares.approveApplication(this.operator.address);
    await this.usdcShares.connect(this.operator).issueShares(this.userOne.address, 1000);
      
    const operatorCalls = this.rewards.connect(this.operator);
    await expect(operatorCalls.resetClaimableRewards(this.devAddr.address)).not.to.be.reverted;
    await expect(operatorCalls.distributeRewards(1000)).not.to.be.reverted;
  })
  
  context("when distributing rewards", async function() {

    it("should only distribute rewards if there's assets in the Treasury Vault", async function() {
      await this.rewards.approveApplication(this.operator.address);
      await expect(this.rewards.connect(this.operator).distributeRewards(5)).to.be.revertedWith("ClaimableRewards distributeRewards(): USDC Treasury Vault cannot be empty");
    })
    
    it("should properly increment the accRewardsPerShare and update ineglible rewards mapping", async function() {
      await this.usdcShares.approveApplication(this.operator.address);
      await this.usdcShares.connect(this.operator).issueShares(this.userOne.address, 1000);
      await this.usdcShares.connect(this.operator).issueShares(this.devAddr.address, 1000);

      await this.rewards.approveApplication(this.operator.address);
      const operatorCalls = this.rewards.connect(this.operator);
      await operatorCalls.distributeRewards(5);
      const decimalMultiplier = await this.rewards.decimalMultiplier(); // -> currently 1e12
  
      expect(await this.rewards.accRewardsPerShare()).to.equal(5 * decimalMultiplier / 2000);
      expect(await this.rewards.ineligibleRewards(this.userOne.address)).to.equal(0);
      expect(await this.rewards.ineligibleRewards(this.devAddr.address)).to.equal(0);

      await operatorCalls.resetClaimableRewards(this.userOne.address);
      expect(await this.rewards.ineligibleRewards(this.userOne.address)).to.equal(1000 * 5 * decimalMultiplier / 2000);
      expect(await this.rewards.ineligibleRewards(this.devAddr.address)).to.equal(0);

      await operatorCalls.resetClaimableRewards(this.devAddr.address);
      expect(await this.rewards.ineligibleRewards(this.devAddr.address)).to.equal(1000 * 5 * decimalMultiplier / 2000);


    })
  })
})