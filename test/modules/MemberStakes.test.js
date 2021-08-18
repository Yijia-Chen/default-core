const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("MemberStakes.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.notOwner = this.signers[1];
    
        this.MemberStakesInternals = await ethers.getContractFactory("TESTONLY_MemberStakesInternalFunctions");
        this.MemberStakes = await ethers.getContractFactory("MemberStakes");
        // this.OS = await ethers.getContractFactory("DefaultOS");
    })
    
    describe("internal functions", async function () {
        beforeEach(async function () {
            this.internals = await this.MemberStakesInternals.deploy();
            await this.internals.deployed(); 
        })

        it("sets the correct state", async function () {
            expect(await this.internals.FIRST()).to.equal(0);
            expect(await this.internals.LAST()).to.equal(0);
            expect(await this.internals.numStakes()).to.equal(0);
            expect(await this.internals.totalStakedTokens()).to.equal(0);
        })

        context("packing and unpacking stake ids", async function () {
            it("packs stake id correctly", async function () {
                let expectedId = (60 * (2**16)) + 50;
                expect(await this.internals.packStakeId(60, 50)).to.equal(expectedId);

                expectedId = (150 * (2**16)) + 100;
                expect(await this.internals.packStakeId(150, 100)).to.equal(expectedId);

                // max
                expectedId = (65535 * (2**16)) + 65535;
                expect(await this.internals.packStakeId(65535, 65535)).to.equal(expectedId);
            })

            it("unpacks stake id correctly", async function () {
                let expectedId = (60 * (2**16)) + 50;
                let [expiryEpoch, lockDuration] = await this.internals.unpackStakeId(expectedId);
                expect(expiryEpoch).to.equal(60);
                expect(lockDuration).to.equal(50);

                expectedId = (150 * (2**16)) + 100;
                [expiryEpoch, lockDuration] = await this.internals.unpackStakeId(expectedId);
                expect(expiryEpoch).to.equal(150);
                expect(lockDuration).to.equal(100);

                expectedId = (65535 * (2**16)) + 65535;
                [expiryEpoch, lockDuration] = await this.internals.unpackStakeId(expectedId);
                expect(expiryEpoch).to.equal(65535);
                expect(lockDuration).to.equal(65535);
            })
        })

        context("_pushStake", async function () {
            it("successfully pushes on list n = 0", async function () {
                await this.internals.pushStake(15, 10, 150);
                const stakeId = await this.internals.packStakeId(15, 10);
                const stake = await this.internals.getStakeForId(stakeId); 

                expect(await this.internals.FIRST()).to.equal(stakeId);
                expect(await this.internals.LAST()).to.equal(stakeId);
                expect(await this.internals.numStakes()).to.equal(1);
                expect(await this.internals.totalStakedTokens()).to.equal(150);

                expect(stake[0]).to.equal(15);
                expect(stake[1]).to.equal(10);
                expect(stake[2]).to.equal(0);
                expect(stake[3]).to.equal(0);
                expect(stake[4]).to.equal(150);
            })

            it("successfully pushes on list n > 0", async function () {                
                await this.internals.pushStake(13, 10, 150);
                await this.internals.pushStake(24, 10, 200);
                await this.internals.pushStake(35, 10, 300);

                firstStakeId = await this.internals.packStakeId(13, 10);
                FIRST = await this.internals.getStakeForId(firstStakeId); 

                secondStakeId = await this.internals.packStakeId(24, 10);
                MID = await this.internals.getStakeForId(secondStakeId); 

                lastStakeId = await this.internals.packStakeId(35, 10);
                LAST = await this.internals.getStakeForId(lastStakeId); 

                expect(await this.internals.FIRST()).to.equal(firstStakeId);
                expect(await this.internals.LAST()).to.equal(lastStakeId);

                expect(await this.internals.numStakes()).to.equal(3);
                expect(await this.internals.totalStakedTokens()).to.equal(650);

                expect(FIRST[2]).to.equal(0);
                expect(FIRST[3]).to.equal(secondStakeId);
                expect(MID[2]).to.equal(firstStakeId);
                expect(MID[3]).to.equal(lastStakeId);
                expect(LAST[2]).to.equal(secondStakeId);
                expect(LAST[3]).to.equal(0);
            })
        })

        context("_insertStakeBefore()", async function () {
            it("does not work on empty list", async function () {
                await expect(this.internals.insertStakeBefore(0, 5, 0, 150)).to.be.revertedWith("Staking.sol: cannot insertStakeBefore() in empty list of Stakes");
            })

            it("successfully inserts on list n = 1", async function () {
                await this.internals.pushStake(15, 10, 150);
                lastStakeId = await this.internals.packStakeId(15, 10);
                
                await this.internals.insertStakeBefore(lastStakeId, 13, 11, 200);
                firstStakeId = await this.internals.packStakeId(13, 11);

                firstStake = await this.internals.getStakeForId(firstStakeId); 
                lastStake = await this.internals.getStakeForId(lastStakeId); 

                expect(await this.internals.FIRST()).to.equal(firstStakeId);
                expect(await this.internals.LAST()).to.equal(lastStakeId);
                expect(await this.internals.numStakes()).to.equal(2);
                expect(await this.internals.totalStakedTokens()).to.equal(350);

                expect(firstStake[0]).to.equal(13);
                expect(firstStake[1]).to.equal(11);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(lastStakeId);
                expect(firstStake[4]).to.equal(200);

                expect(lastStake[0]).to.equal(15);
                expect(lastStake[1]).to.equal(10);
                expect(lastStake[2]).to.equal(firstStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(150);
            })

            it("successfully inserts on list n > 1", async function () {
                await this.internals.pushStake(15, 10, 150);
                lastStakeId = await this.internals.packStakeId(15, 10);
                
                await this.internals.insertStakeBefore(lastStakeId, 13, 11, 200);
                midStakeId = await this.internals.packStakeId(13, 11);
                
                await this.internals.insertStakeBefore(midStakeId, 11, 12, 250);
                firstStakeId = await this.internals.packStakeId(11, 12);
                
                
                firstStake = await this.internals.getStakeForId(firstStakeId); 
                midStake = await this.internals.getStakeForId(midStakeId); 
                lastStake = await this.internals.getStakeForId(lastStakeId); 

                expect(await this.internals.FIRST()).to.equal(firstStakeId);
                expect(await this.internals.LAST()).to.equal(lastStakeId);
                expect(await this.internals.numStakes()).to.equal(3);
                expect(await this.internals.totalStakedTokens()).to.equal(600);

                expect(firstStake[0]).to.equal(11);
                expect(firstStake[1]).to.equal(12);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(midStakeId);
                expect(firstStake[4]).to.equal(250);

                expect(midStake[0]).to.equal(13);
                expect(midStake[1]).to.equal(11);
                expect(midStake[2]).to.equal(firstStakeId);
                expect(midStake[3]).to.equal(lastStakeId);
                expect(midStake[4]).to.equal(200);

                expect(lastStake[0]).to.equal(15);
                expect(lastStake[1]).to.equal(10);
                expect(lastStake[2]).to.equal(midStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(150);
            })
        })
    })

    describe("public functions", async function () {
        beforeEach(async function () {
            // use internals for the packing/unpacking id functions
            this.internals = await this.MemberStakesInternals.deploy();
            this.stakes = await this.MemberStakes.deploy();

            await this.internals.deployed();
            await this.stakes.deployed(); 
        })

        it("sets correct ownership", async function () {
            const notOwnerCalls = this.stakes.connect(this.notOwner);
            await expect(notOwnerCalls.registerNewStake(0, 0, 0)).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(notOwnerCalls.dequeueStake()).to.be.revertedWith("Ownable: caller is not the owner");
        })

        context("registerNewStake()", async function () {

            it("registers successfully for empty stakes", async function (){
                await this.stakes.registerNewStake(15, 10, 150);

                const stakeId = await this.internals.packStakeId(15, 10);
                const stake = await this.stakes.getStakeForId(stakeId); 

                expect(await this.stakes.FIRST()).to.equal(stakeId);
                expect(await this.stakes.LAST()).to.equal(stakeId);
                expect(await this.stakes.numStakes()).to.equal(1);
                expect(await this.stakes.totalStakedTokens()).to.equal(150);

                expect(stake[0]).to.equal(15);
                expect(stake[1]).to.equal(10);
                expect(stake[2]).to.equal(0);
                expect(stake[3]).to.equal(0);
                expect(stake[4]).to.equal(150);
            })

            it("registers successfully for stake at end of list", async function (){
                await this.stakes.registerNewStake(15, 10, 150);
                await this.stakes.registerNewStake(16, 11, 200);

                const firstStakeId = await this.internals.packStakeId(15, 10);
                const firstStake = await this.stakes.getStakeForId(firstStakeId); 

                const lastStakeId = await this.internals.packStakeId(16, 11);
                const lastStake = await this.stakes.getStakeForId(lastStakeId);

                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.numStakes()).to.equal(2);
                expect(await this.stakes.totalStakedTokens()).to.equal(350);

                expect(firstStake[0]).to.equal(15);
                expect(firstStake[1]).to.equal(10);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(lastStakeId);
                expect(firstStake[4]).to.equal(150);

                expect(lastStake[0]).to.equal(16);
                expect(lastStake[1]).to.equal(11);
                expect(lastStake[2]).to.equal(firstStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(200);
            })

            it("registers successfully for stake at beginning of list", async function (){
                // just change order from last test, the expectations should be the same
                await this.stakes.registerNewStake(16, 11, 200);
                await this.stakes.registerNewStake(15, 10, 150);

                const firstStakeId = await this.internals.packStakeId(15, 10);
                const firstStake = await this.stakes.getStakeForId(firstStakeId); 

                const lastStakeId = await this.internals.packStakeId(16, 11);
                const lastStake = await this.stakes.getStakeForId(lastStakeId);

                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.numStakes()).to.equal(2);
                expect(await this.stakes.totalStakedTokens()).to.equal(350);

                expect(firstStake[0]).to.equal(15);
                expect(firstStake[1]).to.equal(10);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(lastStakeId);
                expect(firstStake[4]).to.equal(150);

                expect(lastStake[0]).to.equal(16);
                expect(lastStake[1]).to.equal(11);
                expect(lastStake[2]).to.equal(firstStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(200);
            })

            it("registers successfully for stake at middle of list (different expiry, different lock duration)", async function (){
                await this.stakes.registerNewStake(17, 12, 250);
                await this.stakes.registerNewStake(16, 11, 200);
                await this.stakes.registerNewStake(15, 10, 150);

                const firstStakeId = await this.internals.packStakeId(15, 10);
                const firstStake = await this.stakes.getStakeForId(firstStakeId); 

                const midStakeId = await this.internals.packStakeId(16, 11);
                const midStake = await this.stakes.getStakeForId(midStakeId);

                const lastStakeId = await this.internals.packStakeId(17, 12);
                const lastStake = await this.stakes.getStakeForId(lastStakeId);

                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.numStakes()).to.equal(3);
                expect(await this.stakes.totalStakedTokens()).to.equal(600);

                expect(firstStake[0]).to.equal(15);
                expect(firstStake[1]).to.equal(10);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(midStakeId);
                expect(firstStake[4]).to.equal(150);

                expect(midStake[0]).to.equal(16);
                expect(midStake[1]).to.equal(11);
                expect(midStake[2]).to.equal(firstStakeId);
                expect(midStake[3]).to.equal(lastStakeId);
                expect(midStake[4]).to.equal(200);

                expect(lastStake[0]).to.equal(17);
                expect(lastStake[1]).to.equal(12);
                expect(lastStake[2]).to.equal(midStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(250);
            })

            it("registers successfully for stake at middle of list (same expiry, different lock duration)", async function (){
                await this.stakes.registerNewStake(17, 12, 250);
                await this.stakes.registerNewStake(16, 11, 150);
                // this should go in the middle, since prev stake expiry (16) is != new stake expiry (16)
                await this.stakes.registerNewStake(16, 8, 200);

                const firstStakeId = await this.internals.packStakeId(16, 11);
                const firstStake = await this.stakes.getStakeForId(firstStakeId); 

                const midStakeId = await this.internals.packStakeId(16, 8);
                const midStake = await this.stakes.getStakeForId(midStakeId);

                const lastStakeId = await this.internals.packStakeId(17, 12);
                const lastStake = await this.stakes.getStakeForId(lastStakeId);

                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.numStakes()).to.equal(3);
                expect(await this.stakes.totalStakedTokens()).to.equal(600);

                expect(firstStake[0]).to.equal(16);
                expect(firstStake[1]).to.equal(11);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(midStakeId);
                expect(firstStake[4]).to.equal(150);

                expect(midStake[0]).to.equal(16);
                expect(midStake[1]).to.equal(8);
                expect(midStake[2]).to.equal(firstStakeId);
                expect(midStake[3]).to.equal(lastStakeId);
                expect(midStake[4]).to.equal(200);

                expect(lastStake[0]).to.equal(17);
                expect(lastStake[1]).to.equal(12);
                expect(lastStake[2]).to.equal(midStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(250);
            })

            it("registers successfully for stake at middle of list (same expiry, same lock duration)", async function (){
                await this.stakes.registerNewStake(17, 12, 250);
                await this.stakes.registerNewStake(16, 11, 150);
                // this should be added to existing stake
                await this.stakes.registerNewStake(16, 11, 200);
                
                const firstStakeId = await this.internals.packStakeId(16, 11);
                const firstStake = await this.stakes.getStakeForId(firstStakeId); 

                const lastStakeId = await this.internals.packStakeId(17, 12);
                const lastStake = await this.stakes.getStakeForId(lastStakeId);

                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.numStakes()).to.equal(2);
                expect(await this.stakes.totalStakedTokens()).to.equal(600);

                expect(firstStake[0]).to.equal(16);
                expect(firstStake[1]).to.equal(11);
                expect(firstStake[2]).to.equal(0);
                expect(firstStake[3]).to.equal(lastStakeId);
                expect(firstStake[4]).to.equal(350);

                expect(lastStake[0]).to.equal(17);
                expect(lastStake[1]).to.equal(12);
                expect(lastStake[2]).to.equal(firstStakeId);
                expect(lastStake[3]).to.equal(0);
                expect(lastStake[4]).to.equal(250);
            })
        })

        context("dequeueStake()", async function () {
            it("rejects dequeueing for empty list of stakes", async function (){
                await expect(this.stakes.dequeueStake()).to.be.revertedWith("cannot dequeue empty stakes list");
            })

            it("dequeues successfully for non empty list of stakes", async function (){
                // getting the return value for a non view/pure function from javascript is difficult
                // as a write transaction (state changing) will return the transaction metadata instead of the
                // return values. As a result, we cannot set [lockDuration, amount] = await this.stakes.dequeueStake();
                // to check if the return values are being accurately determined.

                // instead, make sure to test the correct return values by testing that the correct state changes are
                // being made in the calling contract (MemberContract.sol).

                // in this test, we are only checking to see if the state changes are being properly applied (numstakes and 
                // total tokens staked are being correctly discounted)

                await this.stakes.registerNewStake(17, 12, 250);
                await this.stakes.registerNewStake(16, 11, 150);

                const firstStakeId = await this.internals.packStakeId(16, 11);
                const lastStakeId = await this.internals.packStakeId(17, 12);
                
                expect(await this.stakes.FIRST()).to.equal(firstStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.totalStakedTokens()).to.equal(400);
                expect(await this.stakes.numStakes()).to.equal(2);

                await this.stakes.dequeueStake();
                
                expect(await this.stakes.FIRST()).to.equal(lastStakeId);
                expect(await this.stakes.LAST()).to.equal(lastStakeId);
                expect(await this.stakes.totalStakedTokens()).to.equal(250);
                expect(await this.stakes.numStakes()).to.equal(1);

                await this.stakes.dequeueStake();
                
                expect(await this.stakes.FIRST()).to.equal(0);
                expect(await this.stakes.LAST()).to.equal(0);
                expect(await this.stakes.totalStakedTokens()).to.equal(0);
                expect(await this.stakes.numStakes()).to.equal(0);

                await expect(this.stakes.dequeueStake()).to.be.revertedWith("cannot dequeue empty stakes list");
            })
        })
    })
})