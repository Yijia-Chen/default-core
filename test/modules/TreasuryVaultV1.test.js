const { expect } = require("chai");

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("TreasuryVault.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners();
    this.devAddr = this.signers[0]
    this.daoWallet = this.signers[1]
    this.app = this.signers[2]
    this.userOne = this.signers[3]
    this.userTwo = this.signers[4]

    this.TreasuryVault = await ethers.getContractFactory("TreasuryVaultV1");
    this.Token = await ethers.getContractFactory("DefaultToken");
    this.VaultShares = await ethers.getContractFactory("VaultShares");
  })

  beforeEach(async function () {
    this.token = await this.Token.deploy();
    await this.token.deployed();

    this.vault = await this.TreasuryVault.deploy(this.token.address, 10);
    await this.vault.deployed();
    
    this.shares = await ethers.getContractAt("VaultShares", await this.vault.Shares());

    // mint tokens
    const ownerCalls = this.token.connect(this.devAddr);
    await ownerCalls.approveApplication(this.devAddr.address);
    await ownerCalls.mint(1700000);
    await ownerCalls.transfer(this.userOne.address, 1000000);
  })  

  it("should set correct state variables", async function () {
    expect (await this.vault.Assets()).to.equal(this.token.address);
    expect (await this.vault.Shares()).to.be.properAddress;
    expect (await this.vault.withdrawFeePctg()).to.equal(10);
  })

  it("should set correct access permissions", async function () {
    // random user cannot call the contract
    const userOneCalls = this.vault.connect(this.userOne);
    await expect(userOneCalls.deposit(this.userOne.address, 0)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.withdraw(this.userOne.address, 0)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.borrow(0)).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(userOneCalls.repay(0)).to.be.revertedWith("Ownable: caller is not the owner");
    await expect(userOneCalls.setFee(50)).to.be.revertedWith("Ownable: caller is not the owner");
  })

  context("deposit() + borrow", async function() {
    beforeEach(async function() {
      // approve the app contract to interact with it
      const devCalls = this.vault.connect(this.devAddr);
      await devCalls.approveApplication(this.app.address);
      await devCalls.transferOwnership(this.daoWallet.address);

      // user approves vault to transfer their tokens for a deposit
      await this.token.connect(this.userOne).approve(this.vault.address, 1000000)

      // user deposits 1000000 tokens into the vault through the app
      await this.vault.connect(this.app).deposit(this.userOne.address, 1000000);
    })

    it("gives back 1:1 shares when vault is empty", async function() {
      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(1000000);
      expect (await this.token.balanceOf(this.userOne.address)).to.equal(0);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(1000000);
    })
  
    it("gives back correct shares when vault is in debt", async function() {
      const daoCalls = this.vault.connect(this.daoWallet);
      await daoCalls.borrow(333333);
      expect (await this.token.balanceOf(this.daoWallet.address)).to.equal(333333);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(666667);
      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(1000000);

      const tokenOwnerCalls = this.token.connect(this.devAddr);
      await tokenOwnerCalls.transfer(this.userOne.address, 700000);
      await this.token.connect(this.userOne).approve(this.vault.address, 700000)
      await this.vault.connect(this.app).deposit(this.userOne.address, 700000);

      expect (await this.token.balanceOf(this.userOne.address)).to.equal(0);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(1366667);

      const sharesToReceive = 1000000 + Math.trunc(700000 * 1000000 / 666667);
      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(sharesToReceive);
    })
  })

  context("withdraw() + repay", async function() {
    beforeEach(async function() {
      const devCalls = this.vault.connect(this.devAddr);
      await devCalls.approveApplication(this.app.address);
      await devCalls.transferOwnership(this.daoWallet.address);

      // user approves vault to transfer their tokens for a deposit
      await this.token.connect(this.userOne).approve(this.vault.address, 1000000)

      // user deposits 1000000 tokens into the vault through the app
      await this.vault.connect(this.app).deposit(this.userOne.address, 1000000);
    })

    it("returns the proper amount of assets after applying the fee", async function() {
      await this.vault.connect(this.app).withdraw(this.userOne.address, 650000);

      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(350000);
      expect (await this.token.balanceOf(this.userOne.address)).to.equal(650000 * .9);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(350000 + (.1 * 650000));
      expect (await this.shares.balanceOf(this.daoWallet.address)).to.equal(650000 * .1);
    })

    it("gives back correct shares when vault is in debt", async function() {
      const daoCalls = this.vault.connect(this.daoWallet);
      await daoCalls.borrow(333333);

      await this.vault.connect(this.app).withdraw(this.userOne.address, 650000);

      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(350000);
      const tokensWithdrawn = Math.trunc(650000 * .9 * 666667 / 1000000);
      expect (await this.token.balanceOf(this.userOne.address)).to.equal(tokensWithdrawn);
      expect (await this.token.balanceOf(this.daoWallet.address)).to.equal(333333);
      expect (await this.shares.balanceOf(this.daoWallet.address)).to.equal(650000 * .1);
    })

    it("gives back correct shares when vault is in debt", async function() {
      const daoCalls = this.vault.connect(this.daoWallet);
      await daoCalls.borrow(333333);

      await this.vault.connect(this.app).withdraw(this.userOne.address, 650000);

      expect (await this.shares.balanceOf(this.userOne.address)).to.equal(350000);
      const tokensWithdrawn = Math.trunc(650000 * .9 * 666667 / 1000000);
      expect (await this.token.balanceOf(this.userOne.address)).to.equal(tokensWithdrawn); // 390000
      expect (await this.token.balanceOf(this.daoWallet.address)).to.equal(333333);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(276667); // 1000000 - 333333 - tokensWithdrawn;
      expect (await this.shares.balanceOf(this.daoWallet.address)).to.equal(650000 * .1);
    })

    it("successfully repays debt", async function() {
      const daoCalls = this.vault.connect(this.daoWallet);
      await daoCalls.borrow(333333);
      await this.vault.connect(this.app).withdraw(this.userOne.address, 650000);
      await this.token.connect(this.daoWallet).approve(this.vault.address, 333333);
      await daoCalls.repay(333333);
      expect (await this.token.balanceOf(this.daoWallet.address)).to.equal(0);
      expect (await this.token.balanceOf(this.vault.address)).to.equal(276667 + 333333); // 1000000 - tokensWithdrawn;
      expect (await this.shares.balanceOf(this.daoWallet.address)).to.equal(650000 * .1);
    })
  })

  it("correctly changes the fee", async function() {
    const devCalls = this.vault.connect(this.devAddr);
    await devCalls.transferOwnership(this.daoWallet.address);
    const daoCalls = this.vault.connect(this.daoWallet);
    await daoCalls.approveApplication(this.app.address);
    await daoCalls.setFee(80);

    // user approves vault to transfer their tokens for a deposit
    await this.token.connect(this.userOne).approve(this.vault.address, 1000000)

    // user deposits 1000000 tokens into the vault through the app
    await this.vault.connect(this.app).deposit(this.userOne.address, 1000000);

    await this.vault.connect(this.app).withdraw(this.userOne.address, 1000000);
    expect(await this.token.balanceOf(this.vault.address)).to.equal(800000);
    expect(await this.token.balanceOf(this.userOne.address)).to.equal(200000);
    expect(await this.shares.balanceOf(this.daoWallet.address)).to.equal(800000);
  })
  
})