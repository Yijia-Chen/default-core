const { expect } = require("chai");

describe("StateContract.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners()
    this.devAddr = this.signers[0]
    this.daoMultisig = this.signers[1]
    this.contributorPurse = this.signers[2]
    this.userOne = this.signers[3]
    this.userTwo = this.signers[4]
    this.userThree = this.signers[5]

    this.Memberships = await ethers.getContractFactory("Memberships")
    // this.Epoch = await ethers.getContractFactory("Epoch")
    // this.DefaultToken = await ethers.getContractFactory("DefaultToken")
    // this.USDCoin = await ethers.getContractFactory("ERC20")
    // this.ClaimableRewards = await ethers.getContractFactory("ClaimableRewards")

    // this.MemberRegistry = await ethers.getContractFactory("MemberRegistry")
    // this.TreasuryVault = await ethers.getContractFactory("TreasuryVault")
    // this.BalanceSheetMining = await ethers.getContractFactory("BalanceSheetMining")

    // this.Operator = await ethers.getContractFactory("Operator")

  })

  beforeEach(async function () {
    this.memberships = await this.Memberships.deploy([this.daoMultisig.address, this.userOne.address, this.userTwo.address, this.userThree.address]);
    // this.epoch = await this.Epoch.deploy();
    // this.dnt = await this.DefaultToken.deploy();
    // this.usdc = await this.USDCoin.deploy("USD Coin", "USDC");

    await this.memberships.deployed();
    // await this.epoch.deployed();
    // await this.dnt.deployed();
    // await this.usdc.deployed();


    // this.dntVault = await this.TreasuryVault.deploy(this.dnt.address, 85, true, this.memberships.address);
    // this.usdcVault = await this.TreasuryVault.deploy(this.usdc.address, 10, false, this.memberships.address);
    // await this.dntVault.deployed();
    // await this.usdcVault.deployed();
    
    // this.dntVaultShares = await this.dntVault.Shares();
    // this.usdcVaultShares = await this.usdcVault.Shares();

    // this.rewards = await this.ClaimableRewards.deploy(this.dntVaultShares, this.usdcVaultShares);

    // await this.epoch.deployed()
    // await this.dnt.deployed()
    // await this.usdc.deployed()

    // this.rewarder = await this.BalanceSheetMining.deploy(this.usdcVaultShares, this.dntVaultShares, this.rewards.address, this.memberships.address)
    // await this.rewarder.deployed();
  })  

  it("should set correct state variables", async function () {
    expect(await this.memberships.owner()).to.equal(this.devAddr.address);
    
    const members = await this.memberships.getMembers();
    expect(members.length).to.equal(4);

    expect(await this.memberships.isMember(this.daoMultisig.address)).to.equal(true);    
    expect(await this.memberships.isMember(this.userOne.address)).to.equal(true);
    expect(await this.memberships.isMember(this.userTwo.address)).to.equal(true);
    expect(await this.memberships.isMember(this.userThree.address)).to.equal(true);
  })

  it("should set correct ownership permissions", async function () {
    // random user cannot call the contract
    const userOneCalls = this.memberships.connect(this.userOne);
    await expect(userOneCalls.grantMembership(this.userOne.address)).to.be.revertedWith("Application is not approved to call this contract");
    await expect(userOneCalls.revokeMembership(this.userOne.address)).to.be.revertedWith("Application is not approved to call this contract");
    await expect(userOneCalls.bulkGrantMemberships([])).to.be.revertedWith("Application is not approved to call this contract");
    await expect(userOneCalls.bulkRevokeMemberships([])).to.be.revertedWith("Application is not approved to call this contract");
  })

  it("should properly approve applications", async function() {
    // approve and set up the app contract (as the multisig)
    await this.memberships.approveApplication(this.daoMultisig.address);
    const approvedAppCalls = this.memberships.connect(this.daoMultisig);

    await approvedAppCalls.revokeMembership(this.userOne.address);
    expect(await this.memberships.isMember(this.userOne.address)).to.equal(false);

    await approvedAppCalls.grantMembership(this.userOne.address);
    expect(await this.memberships.isMember(this.userOne.address)).to.equal(true);

    await approvedAppCalls.bulkRevokeMemberships([this.userOne.address, this.userTwo.address]);
    expect(await this.memberships.isMember(this.userOne.address)).to.equal(false);
    expect(await this.memberships.isMember(this.userTwo.address)).to.equal(false);

    await approvedAppCalls.bulkGrantMemberships([this.userOne.address, this.userTwo.address]);
    expect(await this.memberships.isMember(this.userOne.address)).to.equal(true);
    expect(await this.memberships.isMember(this.userTwo.address)).to.equal(true);
  })


})