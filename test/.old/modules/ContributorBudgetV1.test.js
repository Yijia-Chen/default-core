const { expect } = require("chai");

describe("ContributorBudget.sol", function () {
    before(async function () {
        this.signers   = await ethers.getSigners();
        this.dev       = this.signers[0];
        this.dao       = this.signers[1];
        this.operator  = this.signers[2];
        this.userOne   = this.signers[3];
        this.userTwo   = this.signers[4];
        this.userThree = this.signers[5];
        this.userFour  = this.signers[6];

        this.Memberships = await ethers.getContractFactory("Memberships");
        this.VaultShares = await ethers.getContractFactory("VaultShares");
        this.ContributorBudget = await ethers.getContractFactory("ContributorBudgetV1");
    })

    beforeEach(async function () {
        this.defShares = await this.VaultShares.deploy("DEF Treasury Vault", "DEF-VS", 18);
        this.members = await this.Memberships.deploy([this.userOne.address, this.userTwo.address, this.userThree.address]);
        await this.defShares.deployed();
        await this.members.deployed();

        this.budget = await this.ContributorBudget.deploy(this.defShares.address, this.members.address);
        await this.budget.approveApplication(this.dev.address)
        
        await this.defShares.approveApplication(this.dev.address);
        await this.defShares.issueShares(this.budget.address, 1000000);
        await this.defShares.approveApplication(this.budget.address);
    })

    it("should set correct state variables", async function () {
        expect(await this.budget.DefVaultShares()).to.equal(this.defShares.address);
        expect(await this.budget.Members()).to.equal(this.members.address);
    })

    it("should have the correct access permissions", async function () {
        const userCalls = this.budget.connect(this.userOne);
        await expect(userCalls.bulkTransfer([this.userOne.address], [10000])).to.be.revertedWith("Permissioned onlyApprovedApps(): Application is not approved to call this contract");
    })

    context("bulktransfer()", async function () {
        it("ensures params are equal in length", async function () {
            await expect(this.budget.bulkTransfer([this.userOne.address], [1, 2])).to.be.revertedWith("Operator.sol bulkTransfer(): input array for contributors and reward amounts must be equal");
        })
    
        it("ensures only registered members receive transfers", async function () {
            // await this.budget.approveApplication(this.dev.address)
            await expect(this.budget.connect(this.dev).bulkTransfer([this.userOne.address, this.userFour.address], [1, 1])).to.be.revertedWith("Operator.sol bulkTransfer(): contributor is not a member");
        })
    
        it("does not successfully transfer more tokens than the available budget", async function () {
            await expect(this.budget.connect(this.dev).bulkTransfer(
              [this.userOne.address, this.userTwo.address, this.userThree.address], 
              [555555, 555553, 335555] // more than 1,000,000 tokens
            )).to.be.revertedWith("ERC20: transfer amount exceeds balance");
            
            expect(await this.defShares.balanceOf(this.budget.address)).to.equal(1000000);
        })

        it("successfully transfers tokens if less than available budget", async function () {
            await this.budget.connect(this.dev).bulkTransfer(
              [this.userOne.address, this.userTwo.address, this.userThree.address], 
              [333332, 333333, 333334] // less than 1,000,000 tokens
            );
            
            expect(await this.defShares.balanceOf(this.budget.address)).to.equal(1);
            expect(await this.defShares.balanceOf(this.userOne.address)).to.equal(333332);
            expect(await this.defShares.balanceOf(this.userTwo.address)).to.equal(333333);
            expect(await this.defShares.balanceOf(this.userThree.address)).to.equal(333334);
        })
    })
})