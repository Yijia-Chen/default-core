const { expect } = require("chai");

describe("VaultShares.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners()
    this.devAddr = this.signers[0]
    this.daoMultisig = this.signers[1]
    this.userOne = this.signers[2]
    this.operator = this.signers[3]
    this.vault = this.signers[4]
    this.newOperator = this.signers[5];

    this.VaultShares = await ethers.getContractFactory("VaultShares");
  })

  beforeEach(async function () {
    this.fakeShares = await this.VaultShares.deploy("Mock Default Vault Shares", "MOCK-VS", 6);
    await this.fakeShares.deployed();
  })  

  it("should set correct state variables", async function () {
    expect(await this.fakeShares.owner()).to.equal(this.devAddr.address);
    expect(await this.fakeShares.decimals()).to.equal(6);
  })

  it("should set correct ownership permissions", async function () {
    // random user cannot call the contract
    const userOneCalls = this.fakeShares.connect(this.userOne);
    await expect(userOneCalls.transfer(this.devAddr.address, 0)).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.transferFrom(this.daoMultisig.address, this.devAddr.address, 0)).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.issueShares(this.devAddr.address, 0)).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
    await expect(userOneCalls.burnShares(this.daoMultisig.address, 0)).to.be.revertedWith("StateContract onlyApprovedApps(): Application is not approved to call this contract");
  })

  it("should set correct ownership permissions", async function () {
    await this.fakeShares.approveApplication(this.operator.address);
    await this.fakeShares.approveApplication(this.vault.address);

    // only the operator can transfer tokens
    const vaultCalls = this.fakeShares.connect(this.vault);
    await expect(vaultCalls.transfer(this.devAddr.address, 0)).to.be.revertedWith("VaultShares transfer(): only the operator contract is able to transfer shares");
    await expect(vaultCalls.transferFrom(this.daoMultisig.address, this.devAddr.address, 0)).to.be.revertedWith("VaultShares transferFrom(): only the operator contract is able to transfer shares");

    // only the vault can issue/burn shares
    const operatorCalls = this.fakeShares.connect(this.operator);
    await expect(operatorCalls.issueShares(this.devAddr.address, 0)).to.be.revertedWith("VaultShares issueShares(): only vault contract can issue shares");
    await expect(operatorCalls.burnShares(this.devAddr.address, 0)).to.be.revertedWith("VaultShares burnShares(): only vault contract can burn shares");

    // only the owner can successfully change the operator contract
    await this.fakeShares.transferOwnership(this.daoMultisig.address);
    const multisigCalls = this.fakeShares.connect(this.daoMultisig);
    await multisigCalls.setOperatorContract(this.newOperator.address);
    await multisigCalls.approveApplication(this.newOperator.address);

    await expect(operatorCalls.transfer(this.devAddr.address, 0)).to.be.revertedWith("VaultShares transfer(): only the operator contract is able to transfer shares");
    await expect(operatorCalls.transferFrom(this.daoMultisig.address, this.devAddr.address, 0)).to.be.revertedWith("VaultShares transferFrom(): only the operator contract is able to transfer shares");

    const newOperatorCalls = this.fakeShares.connect(this.newOperator);
    await expect(newOperatorCalls.transfer(this.devAddr.address, 0)).not.to.be.reverted;
    await expect(newOperatorCalls.transferFrom(this.daoMultisig.address, this.devAddr.address, 0)).not.to.be.reverted;
  })
  
  it("approved vaults should properly issue and burn shares", async function() {
    this.VaultShares = await ethers.getContractFactory("VaultShares", this.vault);
    this.fakeShares = await this.VaultShares.deploy("Mock Default Vault Shares 2", "MOCK-VS-2", 18);
    await this.fakeShares.deployed();

    // approve and set up the app contract (as the multisig)
    await this.fakeShares.approveApplication(this.operator.address);
    await this.fakeShares.approveApplication(this.vault.address);

    const vaultCalls = this.fakeShares.connect(this.vault);
    await vaultCalls.issueShares(this.userOne.address, 1000);
    expect(await this.fakeShares.balanceOf(this.userOne.address)).to.equal(1000);
    await vaultCalls.burnShares(this.userOne.address, 600);
    expect(await this.fakeShares.balanceOf(this.userOne.address)).to.equal(400);
  })

  // @dev Good first issue for contributors: clean up tests/make them more efficient
  it("assigned operator should be able to transfer shares", async function() {
    this.VaultShares = await ethers.getContractFactory("VaultShares", this.vault);
    this.fakeShares = await this.VaultShares.deploy("Mock Default Vault Shares 2", "MOCK-VS-2", 18);
    await this.fakeShares.deployed();

    // approve and set up the app contract (as the multisig)
    await this.fakeShares.approveApplication(this.operator.address);
    await this.fakeShares.approveApplication(this.vault.address);
    await this.fakeShares.setOperatorContract(this.operator.address);

    const vaultCalls = this.fakeShares.connect(this.vault);
    await vaultCalls.issueShares(this.operator.address, 1000);
    expect(await this.fakeShares.balanceOf(this.operator.address)).to.equal(1000);
  
    const operatorCalls = this.fakeShares.connect(this.operator);
    await operatorCalls.transfer(this.userOne.address, 500);
    expect(await this.fakeShares.balanceOf(this.userOne.address)).to.equal(500);
    
    const userCalls = this.fakeShares.connect(this.userOne);
    await userCalls.approve(this.operator.address, 300);
    await operatorCalls.transferFrom(this.userOne.address, this.devAddr.address, 300);
    expect(await this.fakeShares.balanceOf(this.userOne.address)).to.equal(200);
    expect(await this.fakeShares.balanceOf(this.devAddr.address)).to.equal(300);
    expect(await this.fakeShares.balanceOf(this.operator.address)).to.equal(500);
  })
})