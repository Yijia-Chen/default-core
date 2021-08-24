const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("Members Module", function () {

    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.user = this.signers[1];
        this.otherUser = this.signers[2];
    
        this.DefaultOS = await ethers.getContractFactory("DefaultOS");
        this.DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
        this.DefaultMembersInstaller = await ethers.getContractFactory("def_MembersInstaller");

        this.membersModule = await this.DefaultMembersInstaller.deploy();
        await this.membersModule.deployed();

        this.tokenModule = await this.DefaultTokenInstaller.deploy();
        await this.tokenModule.deployed();
    })

    beforeEach(async function() {
        this.defaultOS = await this.DefaultOS.deploy("Default DAO");
        this.default = await this.defaultOS.deployed();

        await this.default.installModule(this.tokenModule.address);
        this.token = await ethers.getContractAt("def_Token", await this.default.getModule("0x544b4e")); // "TKN"

        await this.default.installModule(this.membersModule.address);
        this.members = await ethers.getContractAt("def_Members", await this.default.getModule("0x4d4252")); // "MBR"

        await this.token.mint(this.user.address, 5000);
        await this.token.connect(this.user).approve(this.members.address, 5000);
    })

    it("alias()", async function() {
        // ALIAS
        expect(false).to.equal(true);
    })

    describe("mintEndorsements()", async function () {

        it("1x multiplier for 50 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.mintEndorsements(50, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 50, 0);

            const userStakes = await this.members.getStakesForMember(this.user.address);
            expect(userStakes.numStakes).to.equal(1);
            expect(userStakes.totalTokensStaked).to.equal(1000);
            
            // test endorsements
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(1000);

            // test token transfer successful
            expect(await this.token.balanceOf(this.user.address)).to.equal(4000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(1000);
        }) 

        it("3x multiplier for 100 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.mintEndorsements(100, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 100, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(3000);
        }) 
        
        it("6x multiplier for 150 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.mintEndorsements(150, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 150, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(6000);
        }) 
        
        it("10x multiplier for 200 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.mintEndorsements(200, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 200, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(10000);
        }) 
    })

    describe("endorseMember()", async function () {
        beforeEach(async function () {
            const userCalls = this.members.connect(this.user);
            // user gets 10000 endorsements
            await userCalls.mintEndorsements(200, 1000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.be.equal(10000);
        })

        it("successfully endorses multiple registered members and changes the right state", async function () {

            const userCalls = this.members.connect(this.user);

            // Test events
            await expect(userCalls.endorseMember(this.otherUser.address, 3000))
                .to.emit(this.members, "EndorsementGiven")
                .withArgs(this.user.address, this.otherUser.address, 3000, 0);

            await expect(userCalls.endorseMember(this.dev.address, 5000))
                .to.emit(this.members, "EndorsementGiven")
                .withArgs(this.user.address, this.dev.address, 5000, 0);

            expect(await this.members.totalEndorsementsGiven(this.user.address)).to.equal(8000);
            expect(await this.members.totalEndorsementsReceived(this.otherUser.address)).to.equal(3000);
            expect(await this.members.totalEndorsementsReceived(this.dev.address)).to.equal(5000);

            expect(await this.members.endorsementsGiven(this.user.address, this.otherUser.address)).to.equal(3000); 
            expect(await this.members.endorsementsReceived(this.otherUser.address, this.user.address)).to.equal(3000); 

            expect(await this.members.endorsementsGiven(this.user.address, this.dev.address)).to.equal(5000); 
            expect(await this.members.endorsementsReceived(this.dev.address, this.user.address)).to.equal(5000); 
        })

        it("successfully endorses registered members from multiple members", async function () {
            await this.token.mint(this.dev.address, 5000);
            await this.token.approve(this.members.address, 5000);

            await this.members.mintEndorsements(50, 1200);

            // Test events
            await this.members.connect(this.user).endorseMember(this.otherUser.address, 3000)
            await this.members.connect(this.dev).endorseMember(this.otherUser.address, 1100)

            expect(await this.members.totalEndorsementsReceived(this.otherUser.address)).to.equal(4100);

            expect(await this.members.endorsementsGiven(this.user.address, this.otherUser.address)).to.equal(3000); 
            expect(await this.members.endorsementsReceived(this.otherUser.address, this.user.address)).to.equal(3000); 

            expect(await this.members.endorsementsGiven(this.dev.address, this.otherUser.address)).to.equal(1100); 
            expect(await this.members.endorsementsReceived(this.otherUser.address, this.dev.address)).to.equal(1100); 
        })
    })

    describe("withdrawEndorsementFrom()", async function () {
        beforeEach(async function () {
            // user gets 10000 endorsements
            const userCalls = this.members.connect(this.user);
            await userCalls.mintEndorsements(200, 1000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.be.equal(10000);

            await userCalls.endorseMember(this.otherUser.address, 3000);
            await userCalls.endorseMember(this.dev.address, 5000);
        })

        it("reverts if the user does not have enough endorsements to withdraw", async function () {
            await expect(this.members.connect(this.user).endorseMember(this.otherUser.address, 10001)).to.be.revertedWith("Member does not have available endorsements to give");
        })

        it("successfully withdraws endorsements members and changes the right state", async function () {
            await expect(this.members.connect(this.user).withdrawEndorsementFrom(this.otherUser.address, 2500))
                .to.emit(this.members, "EndorsementWithdrawn")
                .withArgs(this.user.address, this.otherUser.address, 2500, 0);
                
            expect(await this.members.totalEndorsementsGiven(this.user.address)).to.equal(5500);
            expect(await this.members.totalEndorsementsReceived(this.otherUser.address)).to.equal(500);
            expect(await this.members.endorsementsGiven(this.user.address, this.otherUser.address)).to.equal(500); 
            expect(await this.members.endorsementsReceived(this.otherUser.address, this.user.address)).to.equal(500); 

            await expect(this.members.connect(this.user).withdrawEndorsementFrom(this.dev.address, 4000))
                .to.emit(this.members, "EndorsementWithdrawn")
                .withArgs(this.user.address, this.dev.address, 4000, 0);

            expect(await this.members.totalEndorsementsGiven(this.user.address)).to.equal(1500);
            expect(await this.members.totalEndorsementsReceived(this.dev.address)).to.equal(1000);
            expect(await this.members.endorsementsGiven(this.user.address, this.dev.address)).to.equal(1000); 
            expect(await this.members.endorsementsReceived(this.dev.address, this.user.address)).to.equal(1000); 
        })
    })

    describe("reclaimTokens()", async function () {

        beforeEach(async function () {
            const userCalls = this.members.connect(this.user);
            
            await userCalls.mintEndorsements(50, 1000);
            await this.default.incrementEpoch();

            await userCalls.mintEndorsements(100, 1000);
            await this.default.incrementEpoch();

            await userCalls.mintEndorsements(150, 1000);
            await this.default.incrementEpoch();                

            await userCalls.mintEndorsements(200, 1000);

            for (let i = 1; i <= 46; i++) {
                await this.default.incrementEpoch();
            }            
        })

        it("sanity check", async function() {
            expect(await this.token.balanceOf(this.user.address)).to.equal(1000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(4000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(20000);
            expect(await this.default.currentEpoch()).to.equal(49);
        })
        
        it("Reverts nothing when no stakes have vested/expired", async function() {
            expect(await this.default.currentEpoch()).to.equal(49);
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.reclaimTokens()).to.be.revertedWith("No expired stakes available for withdraw")
        })

        it("Unstakes correctly if vested/expired", async function() {
            // epoch 50 -> first stake expires
            await this.default.incrementEpoch();
            expect(await this.default.currentEpoch()).to.equal(50);

            let userStakes = await this.members.getStakesForMember(this.user.address);
            const userCalls = this.members.connect(this.user);
            expect(userStakes.numStakes).to.equal(4);
            
            await expect(userCalls.reclaimTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 50, 50);

            userStakes = await this.members.getStakesForMember(this.user.address);

            expect(userStakes.numStakes).to.equal(3);
            expect(userStakes.totalTokensStaked).to.equal(3000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(19000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(2000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(3000);

            // epoch 101 -> second stake expires
            for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }            

            expect(await this.default.currentEpoch()).to.equal(101);
            await expect(userCalls.reclaimTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 100, 101);
            
            userStakes = await this.members.getStakesForMember(this.user.address);

            expect(userStakes.numStakes).to.equal(2);
            expect(userStakes.totalTokensStaked).to.equal(2000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(16000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(3000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(2000);

            // epoch 152 -> third stake expires
             for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }

            expect(await this.default.currentEpoch()).to.equal(152);
            await expect(userCalls.reclaimTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 150, 152);
            
            userStakes = await this.members.getStakesForMember(this.user.address);

            expect(userStakes.numStakes).to.equal(1);
            expect(userStakes.totalTokensStaked).to.equal(1000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(10000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(4000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(1000);

            // epoch 203 -> last stake expires
            for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }            

            expect(await this.default.currentEpoch()).to.equal(203);
            await expect(userCalls.reclaimTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 200, 203);

            userStakes = await this.members.getStakesForMember(this.user.address);

            expect(userStakes.numStakes).to.equal(0);
            expect(userStakes.totalTokensStaked).to.equal(0);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(0);
            expect(await this.token.balanceOf(this.user.address)).to.equal(5000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(0);
        })
        
        it("reverts if user doesn't have enough endorsements after unstaking", async function () {
            const userCalls = this.members.connect(this.user);
            
            await this.default.incrementEpoch();
            expect(await this.default.currentEpoch()).to.equal(50);

            await userCalls.endorseMember(this.otherUser.address, 20000)
            await expect(userCalls.reclaimTokens()).to.be.revertedWith("Not enough endorsements remaining after unstaking");
        })
    })
})