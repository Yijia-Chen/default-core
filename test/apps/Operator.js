const { expect } = require("chai");
const { BigNumber } = require("ethers");

function getBigNumber(amount, decimals = 18) {
    return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals))
}

describe("Operator.sol", function () {
    before(async function () {
        this.signers   = await ethers.getSigners();
        this.dev       = this.signers[0];
        this.dao       = this.signers[1];
        this.operator  = this.signers[2];
        this.userOne   = this.signers[3];
        this.userTwo   = this.signers[4];
        this.userThree = this.signers[5];
        this.userFour  = this.signers[6];

        this.Operator           = await ethers.getContractFactory("Operator");

        this.Memberships        = await ethers.getContractFactory("Memberships");
        this.DefToken           = await ethers.getContractFactory("DefaultToken");
        this.UsdCoin            = await ethers.getContractFactory("DefaultToken");
        this.TreasuryVault      = await ethers.getContractFactory("TreasuryVaultV1");
        this.BalanceSheetMining = await ethers.getContractFactory("BalanceSheetMiningV1");
        this.ContributorBudget  = await ethers.getContractFactory("ContributorBudgetV1");

        this.ClaimableRewards   = await ethers.getContractFactory("ClaimableRewards");
        this.VaultShares        = await ethers.getContractFactory("VaultShares");
    })

    beforeEach(async function () {
        this.memberships = await this.Memberships.deploy([this.userOne.address, this.userTwo.address, this.userThree.address]);
        this.defToken = await this.DefToken.deploy();
        this.usdCoin = await this.UsdCoin.deploy();
        await this.defToken.deployed();
        await this.usdCoin.deployed();

        this.defVault = await this.TreasuryVault.deploy(this.defToken.address, 85);
        this.usdcVault = await this.TreasuryVault.deploy(this.usdCoin.address, 10);
        await this.defVault.deployed();
        await this.usdcVault.deployed();

        this.defShares = await ethers.getContractAt("VaultShares", await this.defVault.Shares());
        this.usdcShares = await ethers.getContractAt("VaultShares", await this.usdcVault.Shares());
        
        this.mining = await this.BalanceSheetMining.deploy(this.usdcShares.address, this.defShares.address);
        await this.mining.deployed();

        this.mining = await this.BalanceSheetMining.deploy(this.usdcShares.address, this.defShares.address)
        this.rewards = await ethers.getContractAt("ClaimableRewards", await this.mining.Rewards());

        this.budget = await this.ContributorBudget.deploy(this.defShares.address, this.memberships.address);
        await this.budget.deployed();

        this.operator = await this.Operator.deploy(
            this.memberships.address,
            this.defToken.address,
            this.usdcVault.address,
            this.defVault.address,
            this.mining.address,
            this.budget.address
        )

        await this.defToken.approveApplication(this.operator.address);
        await this.mining.approveApplication(this.operator.address);
        await this.defVault.approveApplication(this.operator.address);
        await this.usdcVault.approveApplication(this.operator.address);
        await this.defShares.approveApplication(this.operator.address);
        await this.defShares.approveApplication(this.mining.address);



        // mint USDC so rewards can be distributed
        await this.usdCoin.approveApplication(this.dev.address);

        await this.usdCoin.mint(1000000);
        await this.usdCoin.transfer(this.userOne.address, 222222);
        await this.usdCoin.transfer(this.userTwo.address, 333333);
        await this.usdCoin.transfer(this.userThree.address, 444444);
        await this.usdCoin.transfer(this.userFour.address, 1);
    })

    it("should set correct state variables", async function () {
        expect(await this.operator.Members()).to.equal(this.memberships.address);
        expect(await this.operator.DefToken()).to.equal(this.defToken.address);
        expect(await this.operator.DefVault()).to.equal(this.defVault.address);
        expect(await this.operator.UsdcVault()).to.equal(this.usdcVault.address);
        expect(await this.operator.Mining()).to.equal(this.mining.address);
        expect(await this.operator.Budget()).to.equal(this.budget.address);

        expect(await this.operator.currentEpoch()).to.equal(0);
        expect(await this.operator.EPOCH_REWARDS()/1e18).to.equal(1000000);
    })

    it("should have the correct access permissions", async function () {
        const nonMemberCalls = this.operator.connect(this.userFour);
        await expect(nonMemberCalls.depositUsdc(0)).to.be.revertedWith("Operator.sol onlyMember(): only members of the DAO can call this contract");
        await expect(nonMemberCalls.withdrawUsdc(0)).to.be.revertedWith("Operator.sol onlyMember(): only members of the DAO can call this contract");
        await expect(nonMemberCalls.claimRewards()).to.be.revertedWith("Operator.sol onlyMember(): only members of the DAO can call this contract");

        const memberCalls = this.operator.connect(this.userOne);
        await expect(memberCalls.incrementEpoch()).to.be.revertedWith("Ownable: caller is not the owner");
    })

    context("when interacting with the contract", async function () {
        beforeEach(async function() {
            await this.usdCoin.connect(this.userOne).approve(this.usdcVault.address, 222222);
            await this.usdCoin.connect(this.userTwo).approve(this.usdcVault.address, 333333);
            await this.usdCoin.connect(this.userThree).approve(this.usdcVault.address, 444444);
    
            await this.operator.connect(this.userOne).depositUsdc(222222);
            await this.operator.connect(this.userTwo).depositUsdc(333333);
            await this.operator.connect(this.userThree).depositUsdc(444444);
        })
        it("users can deposit usdc successfully", async function () {
            expect(await this.usdcShares.balanceOf(this.userOne.address)).to.equal(222222);
            expect(await this.usdcShares.balanceOf(this.userTwo.address)).to.equal(333333);
            expect(await this.usdcShares.balanceOf(this.userThree.address)).to.equal(444444);
        })

        context("when incrementing the epoch", async function () { 
            beforeEach(async function () {
                await this.operator.transferOwnership(this.dao.address);
                const daoCalls = this.operator.connect(this.dao);
        
                await daoCalls.incrementEpoch();
            })

            it ("transfers rewards to all relevant contracts", async function () {
                expect (await this.defToken.totalSupply()/1e18).to.equal(1000000);
                expect (await this.defToken.balanceOf(this.defVault.address)/1e18).to.equal(1000000);
                expect (await this.defShares.balanceOf(this.budget.address)/1e18).to.equal(500000);
                expect (await this.defShares.balanceOf(this.mining.address)/1e18).to.equal(500000);
            })

            it("allow members to claim successfully and accurately", async function () {
                await this.operator.connect(this.userOne).claimRewards();
                expect (await this.defShares.balanceOf(this.userOne.address)).to.equal(getBigNumber(500000).mul(222222).div(999999));

                // claim again to make sure nothing changes
                await this.operator.connect(this.userOne).claimRewards();
                expect (await this.defShares.balanceOf(this.userOne.address)).to.equal(getBigNumber(500000).mul(222222).div(999999));
            })

            it("auto claims when members withdraw", async function () {
                await this.operator.connect(this.userOne).withdrawUsdc(222222);
                expect (await this.usdcShares.balanceOf(this.userOne.address)).to.equal(0);
                expect (await this.usdCoin.balanceOf(this.userOne.address)).to.equal(Math.trunc(222222 * .9));
                expect (await this.defShares.balanceOf(this.userOne.address)).to.equal(getBigNumber(500000).mul(222222).div(999999));
            })
        })
    })


})