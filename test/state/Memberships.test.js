const { expect } = require("chai");

describe("StateContract.sol", function () {

  before(async function () {
    this.signers = await ethers.getSigners()
    this.devAddr = this.signers[0]
    this.daoMultiSig = this.signers[1]
    this.contributorPurse = this.signers[2]
    this.firstUser = this.signers[3]
    this.secondUser = this.signers[4]
    this.thirdUser = this.signers[5]

    this.Memberships = await ethers.getContractFactory("Memberships")
    this.Epoch = await ethers.getContractFactory("Epoch")
    this.DefaultToken = await ethers.getContractFactory("DefaultToken")
    this.USDCoin = await ethers.getContractFactory("ERC20")
    this.ClaimableRewards = await ethers.getContractFactory("ClaimableRewards")

    this.MemberRegistry = await ethers.getContractFactory("MemberRegistry")
    this.TreasuryVault = await ethers.getContractFactory("TreasuryVault")
    this.BalanceSheetMining = await ethers.getContractFactory("BalanceSheetMining")

    this.Operator = await ethers.getContractFactory("Operator")

  })

  beforeEach(async function () {
    this.memberships = await this.Memberships.deploy([this.daoMultiSig.address, this.firstUser.address, this.secondUser.address, this.thirdUser.address]);
    this.epoch = await this.Epoch.deploy();
    this.dnt = await this.DefaultToken.deploy();
    this.usdc = await this.USDCoin.deploy("USD Coin", "USDC");

    await this.memberships.deployed();
    await this.epoch.deployed();
    await this.dnt.deployed();
    await this.usdc.deployed();


    this.dntVault = await this.TreasuryVault.deploy(this.dnt.address, 85, true, this.memberships.address);
    this.usdcVault = await this.TreasuryVault.deploy(this.usdc.address, 10, false, this.memberships.address);
    await this.dntVault.deployed();
    await this.usdcVault.deployed();
    
    this.dntVaultShares = await this.dntVault.Shares();
    this.usdcVaultShares = await this.usdcVault.Shares();

    this.rewards = await this.ClaimableRewards.deploy(this.dntVaultShares, this.usdcVaultShares);

    await this.epoch.deployed()
    await this.dnt.deployed()
    await this.usdc.deployed()

    this.rewarder = await this.BalanceSheetMining.deploy(this.usdcVaultShares, this.dntVaultShares, this.rewards.address, this.memberships.address)
    await this.rewarder.deployed();
  })
    
  it("should set correct state variables", async function () {
  })

})