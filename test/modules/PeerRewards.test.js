const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("Peer Rewards Module", function () {

    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.userA = this.signers[1];
        this.userB = this.signers[2];
        this.userC = this.signers[3];
        this.userD = this.signers[4];
        this.userE = this.signers[5];
    
        this.DefaultOS = await ethers.getContractFactory("DefaultOS");
        this.DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
        this.DefaultMembersInstaller = await ethers.getContractFactory("def_MembersInstaller");
        this.DefaultPeerRewardsInstaller = await ethers.getContractFactory("def_PeerRewardsInstaller");
    })

    beforeEach(async function() {
        this.defaultOS = await this.DefaultOS.deploy("Default DAO");
        this.default = await this.defaultOS.deployed();

        this.membersModule = await this.DefaultmembersInstaller.deploy();
        await this.membersModule.deployed();

        this.tokenModule = await this.DefaultTokenInstaller.deploy();
        await this.tokenModule.deployed();

        this.peerRewardsModule = await this.DefaultTokenInstaller.deploy();
        await this.peerRewardsModule.deployed();

        await this.default.installModule(this.tokenModule.address);
        this.token = await ethers.getContractAt("def_Token", await this.default.getModule("0x544b4e")); // "TKN"

        await this.default.installModule(this.membersModule.address);
        this.members = await ethers.getContractAt("def_Members", await this.default.getModule("0x4d4252")); // "MBR"

        await this.default.installModule(this.tokenModule.address);
        this.token = await ethers.getContractAt("def_PeerRewards", await this.default.getModule("0x504159")); // "PAY"


        await this.token.mint(this.userA.address, 100000);
        await this.token.connect(this.userA).approve(this.members.address, 100000);
        await this.members.mintEndorsements()

        await this.token.mint(this.userB.address, 100000);
        await this.token.connect(this.userB).approve(this.members.address, 100000);
        await this.token.mint(this.userC.address, 100000);
        await this.token.connect(this.userC).approve(this.members.address, 100000);
        await this.token.mint(this.userD.address, 100000);
        await this.token.connect(this.userD).approve(this.members.address, 100000);
        await this.token.mint(this.userE.address, 100000);
        await this.token.connect(this.userE).approve(this.members.address, 100000);
    })

    it("registers a user", async function () {
        this.memberStakes = await ethers.getContractAt("MemberStakes", await this.members.getMemberStakes(this.user.address)); // "MBR"
        expect(this.memberStakes.address).not.to.equal(ZERO_ADDRESS);
        await expect(this.members.connect(this.user).register()).to.be.revertedWith("Member already exists");
    })

    it("requires membership to stake, more than 0 tokens to be staked, and minimum stake duration to be 50 epochs", async function () {
        expect(await this.token.balanceOf(this.user.address)).to.equal(5000); // sanity check

        await expect(this.members.stakeTokens(0,0)).to.be.revertedWith("Membership required to call this function");

        const userCalls = this.members.connect(this.user);
        await expect(userCalls.stakeTokens(50,0)).to.be.revertedWith("Member must stake more than 0 tokens");
        await expect(userCalls.stakeTokens(49,1000)).to.be.revertedWith("Minimum stake duration is 50 epochs");
    })

    // @DEV
    // TEST GAS LIMITS FOR HIGH AMOUNTS TO STAKE —— PRE-PROD
    // PLEASE NOTICE THIS AND TEST BEFORE RELEASE—— CRITICAL FUNCTIONALITY
    describe("stakeTokens()", async function () {

        before(async function() {
            // mint user tokens
            await this.token.mint(this.user.address, 5000);
            await this.token.connect(this.user).approve(this.members.address, 5000);
        })

        it("stakes successfully with the right multiplier", async function () {
            expect(await this.token.balanceOf(this.user.address)).to.equal(5000); // sanity check
        })

        it("1x multiplier for 50 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.stakeTokens(50, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 50, 0);

            this.userStakes = await ethers.getContractAt("MemberStakes", await this.members.getMemberStakes(this.user.address));
            expect(await this.userStakes.numStakes()).to.equal(1);
            expect(await this.userStakes.totalStakedTokens()).to.equal(1000);
            
            // test endorsements
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(1000);

            // test token transfer successful
            expect(await this.token.balanceOf(this.user.address)).to.equal(4000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(1000);
        }) 

        it("3x multiplier for 100 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.stakeTokens(100, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 100, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(3000);
        }) 
        
        it("6x multiplier for 150 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.stakeTokens(150, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 150, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(6000);
        }) 
        
        it("10x multiplier for 200 epochs", async function () {
            const userCalls = this.members.connect(this.user);
            await expect(userCalls.stakeTokens(200, 1000))
                .to.emit(this.members, "TokensStaked")
                .withArgs(this.user.address, 1000, 200, 0);

            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(10000);
        }) 
    })

    describe("endorseMember()", async function () {
        beforeEach(async function () {
            const userCalls = this.members.connect(this.user);
            this.members.connect(this.otherUser).register();
            // user gets 10000 endorsements
            await userCalls.stakeTokens(200, 1000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.be.equal(10000);
        })

        it("reverts if target user is not a registered member of the DAO", async function () {
            await expect(this.members.connect(this.user).endorseMember(this.dev.address, 0)).to.be.revertedWith("Target member is not registered");
        })

        it("reverts if the user does not have enough endorsements to give", async function () {
            await expect(this.members.connect(this.user).endorseMember(this.otherUser.address, 10001)).to.be.revertedWith("Member does not have available endorsements to give");
        })

        it("successfully endorses multiple registered members and changes the right state", async function () {
            await this.members.connect(this.dev).register();

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
            await this.members.connect(this.dev).register();
            await this.token.mint(this.dev.address, 5000);
            await this.token.approve(this.members.address, 5000);

            await this.members.stakeTokens(50, 1200);

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
            const userCalls = this.members.connect(this.user);
            await this.members.connect(this.dev).register();
            await this.members.connect(this.otherUser).register();

            // user gets 10000 endorsements
            await userCalls.stakeTokens(200, 1000);
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

    describe("unstakeTokens()", async function () {

        beforeEach(async function () {
            this.memberStakes = await ethers.getContractAt("MemberStakes", await this.members.getMemberStakes(this.user.address)); // "MBR"
            
            const userCalls = this.members.connect(this.user);
            
            await userCalls.stakeTokens(50, 1000);
            await this.default.incrementEpoch();

            await userCalls.stakeTokens(100, 1000);
            await this.default.incrementEpoch();

            await userCalls.stakeTokens(150, 1000);
            await this.default.incrementEpoch();                

            await userCalls.stakeTokens(200, 1000);

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
            await expect(userCalls.unstakeTokens()).to.be.revertedWith("No expired stakes available for withdraw")
        })

        it("Unstakes correctly if vested/expired", async function() {
            // epoch 50 -> first stake expires
            await this.default.incrementEpoch();
            expect(await this.default.currentEpoch()).to.equal(50);

            this.userStakes = await ethers.getContractAt("MemberStakes", await this.members.getMemberStakes(this.user.address));
            const userCalls = this.members.connect(this.user);
            expect(await this.userStakes.numStakes()).to.equal(4);
            
            await expect(userCalls.unstakeTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 50, 50);

            expect(await this.userStakes.numStakes()).to.equal(3);
            expect(await this.userStakes.totalStakedTokens()).to.equal(3000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(19000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(2000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(3000);

            // epoch 101 -> second stake expires
            for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }            

            expect(await this.default.currentEpoch()).to.equal(101);
            await expect(userCalls.unstakeTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 100, 101);

            expect(await this.userStakes.numStakes()).to.equal(2);
            expect(await this.userStakes.totalStakedTokens()).to.equal(2000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(16000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(3000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(2000);

            // epoch 152 -> third stake expires
             for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }

            expect(await this.default.currentEpoch()).to.equal(152);
            await expect(userCalls.unstakeTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 150, 152);

            expect(await this.userStakes.numStakes()).to.equal(1);
            expect(await this.userStakes.totalStakedTokens()).to.equal(1000);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(10000);
            expect(await this.token.balanceOf(this.user.address)).to.equal(4000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(1000);

            // epoch 203 -> last stake expires
            for (let i = 0; i <= 50; i++) {
                await this.default.incrementEpoch();
            }            

            expect(await this.default.currentEpoch()).to.equal(203);
            await expect(userCalls.unstakeTokens())
                .to.emit(this.members, "TokensUnstaked")
                .withArgs(this.user.address, 1000, 200, 203);

            expect(await this.userStakes.numStakes()).to.equal(0);
            expect(await this.userStakes.totalStakedTokens()).to.equal(0);
            expect(await this.members.totalEndorsementsAvailableToGive(this.user.address)).to.equal(0);
            expect(await this.token.balanceOf(this.user.address)).to.equal(5000);
            expect(await this.token.balanceOf(this.members.address)).to.equal(0);

        })
        
        it("reverts if user doesn't have enough endorsements after unstaking", async function () {
            const userCalls = this.members.connect(this.user);
            this.members.connect(this.otherUser).register();
            
            await this.default.incrementEpoch();
            expect(await this.default.currentEpoch()).to.equal(50);

            await userCalls.endorseMember(this.otherUser.address, 20000)
            await expect(userCalls.unstakeTokens()).to.be.revertedWith("Not enough endorsements remaining after unstaking");
        })
    })
})