const { expect } = require("chai");

describe("Epoch.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners()
    this.devAddr = this.signers[0]
    this.daoMultisig = this.signers[1]
    this.contributorPurse = this.signers[2]
    this.userOne = this.signers[3]
    this.userTwo = this.signers[4]
    this.userThree = this.signers[5]

    this.Epoch = await ethers.getContractFactory("Epoch");
  })

  beforeEach(async function () {
    this.epoch = await this.Epoch.deploy();
    await this.epoch.deployed();
  })  

  it("should set correct state variables", async function () {
    expect(await this.epoch.owner()).to.equal(this.devAddr.address);
    expect(await this.epoch.currentEpoch()).to.equal(0);
  })

  it("should set correct ownership permissions", async function () {
    // random user cannot call the contract
    const userOneCalls = this.epoch.connect(this.userOne);
    await expect(userOneCalls.incrementEpoch()).to.be.revertedWith("Application is not approved to call this contract");
    await expect(userOneCalls.resetEpoch()).to.be.revertedWith("Application is not approved to call this contract");
  })

  it("should properly increment the epoch", async function() {
    // approve and set up the app contract (as the multisig)
    await this.epoch.approveApplication(this.daoMultisig.address);
    const approvedAppCalls = this.epoch.connect(this.daoMultisig);

    await approvedAppCalls.incrementEpoch();
    expect(await this.epoch.currentEpoch()).to.equal(1);

    await approvedAppCalls.resetEpoch();
    expect(await this.epoch.currentEpoch()).to.equal(0);
  })


})