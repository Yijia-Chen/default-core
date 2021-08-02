const { expect } = require("chai");

describe("BalanceSheetMiningV1.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.devAddr = this.signers[0]
        this.daoWallet = this.signers[1]
        this.app = this.signers[2]
        this.userOne = this.signers[3]
        this.userTwo = this.signers[4]

        this.BalanceSheetMining = await ethers.getContractFactory("BalanceSheetMiningV1");
        this.ClaimableRewards = await ethers.getContractFactory("ClaimableRewards");
        this.VaultShares = await ethers.getContractFactory("VaultShares");
    })

    beforeEach(async function () {
        this.defShares = await this.VaultShares.deploy("DEF Treasury Vault", "DEF-VS", 18);
        this.usdcShares = await this.VaultShares.deploy("USDC Treasury Vault", "USDC-VS", 6);
        await this.defShares.deployed();
        await this.usdcShares.deployed();
        
        this.mining = await this.BalanceSheetMining.deploy(this.usdcShares.address, this.defShares.address);
        await this.mining.deployed();

        this.rewards = await ethers.getContractAt("ClaimableRewards", await this.mining.Rewards());

        // mint shares
        await this.usdcShares.approveApplication(this.devAddr.address);
        await this.usdcShares.issueShares(this.userOne.address, 333333);
        await this.usdcShares.issueShares(this.userTwo.address, 666666);

        await this.defShares.approveApplication(this.devAddr.address);
        await this.defShares.issueShares(this.mining.address, 1000000);

        const devCalls = this.mining.connect(this.devAddr);
        await devCalls.approveApplication(this.devAddr.address);
        await devCalls.issueRewards(1000000);
    })

    it("should set correct state variables", async function () {
        expect(await this.mining.UsdcVaultShares()).to.equal(this.usdcShares.address);
        expect(await this.mining.DefVaultShares()).to.equal(this.defShares.address);
        expect(await this.mining.Rewards()).to.equal(this.rewards.address);
    })

    it("should have the correct access permissions", async function () {
        const userCalls = this.mining.connect(this.userOne);
        await expect(userCalls.register(this.userOne.address)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
        await expect(userCalls.claimRewardsFor(this.userOne.address)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
        await expect(userCalls.issueRewards(0)).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
    })

    it("issues rewards successfully", async function () {
        const accRewardsPerShare = 1000000 * 1e12 / 999999
        expect(await this.rewards.accRewardsPerShare()).to.equal(accRewardsPerShare);
        expect(await this.mining.pendingRewards(this.userOne.address)).to.equal(333333);
        expect(await this.mining.pendingRewards(this.userTwo.address)).to.equal(666666);
    })

    it("registers users successfully", async function () {
        await this.mining.approveApplication(this.devAddr.address);
        await this.mining.register(this.userOne.address);
        expect(await this.mining.pendingRewards(this.userOne.address)).to.equal(0);
        expect(await this.mining.pendingRewards(this.userTwo.address)).to.equal(666666);
    })

    it("claims rewards successfully", async function () {
        await this.mining.approveApplication(this.devAddr.address);
        await this.defShares.approveApplication(this.mining.address);

        await this.mining.claimRewardsFor(this.userOne.address);
        expect(await this.defShares.balanceOf(this.mining.address)).to.equal(666667);
        expect(await this.defShares.balanceOf(this.userOne.address)).to.equal(333333)
        expect(await this.mining.pendingRewards(this.userOne.address)).to.equal(0);
        expect(await this.mining.pendingRewards(this.userTwo.address)).to.equal(666666);
        
        await this.mining.claimRewardsFor(this.userTwo.address);
        expect(await this.defShares.balanceOf(this.mining.address)).to.equal(1);
        expect(await this.defShares.balanceOf(this.userTwo.address)).to.equal(666666)
        expect(await this.mining.pendingRewards(this.userTwo.address)).to.equal(0);
    })
})