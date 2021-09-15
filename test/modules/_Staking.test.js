const { expect } = require("chai");

describe("Staking.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.notOwner = this.signers[1];
    
        this.Staking = await ethers.getContractFactory("MOCK_Staking");
        this.OS = await ethers.getContractFactory("DefaultOS");
    })
    
    describe("internal functions", async function () {
        beforeEach(async function () {
            this.staking = await this.Staking.deploy();
            await this.staking.deployed(); 
        })

        it("sets the correct state", async function () {
            const stakes = await this.staking.getStakesForMember(this.dev.address);
            // console.log(stakes.FIRST);
            expect(stakes.FIRST).to.equal(0);
            expect(stakes.LAST).to.equal(0);
            expect(stakes.numStakes).to.equal(0);
            expect(stakes.totalTokensStaked).to.equal(0);
        })

        it("packs stake id correctly", async function () {
            expect(await this.staking.packStakeId(60, 50)).to.equal((60 * (2**16)) + 50);
            expect(await this.staking.packStakeId(150, 100)).to.equal((150 * (2**16)) + 100);
            // max integer
            expect(await this.staking.packStakeId(65535, 65535)).to.equal((65535 * (2**16)) + 65535);
        })

        it("unpacks stake id correctly", async function () {
            [expiryEpoch, lockDuration] = await this.staking.unpackStakeId((60 * (2**16)) + 50);
            expect(expiryEpoch).to.equal(60);
            expect(lockDuration).to.equal(50);

            [expiryEpoch, lockDuration] = await this.staking.unpackStakeId((150 * (2**16)) + 100);
            expect(expiryEpoch).to.equal(150);
            expect(lockDuration).to.equal(100);

            [expiryEpoch, lockDuration] = await this.staking.unpackStakeId((65535 * (2**16)) + 65535);
            expect(expiryEpoch).to.equal(65535);
            expect(lockDuration).to.equal(65535);
        })

        it("successfully pushes on list n = 0", async function () {
            await this.staking.pushStake(15, 10, 150);
            const stakeId = await this.staking.packStakeId(15, 10);
            const stakes = await this.staking.getStakesForMember(this.dev.address);
            const stake = await this.staking.getStakeForId(stakeId); 

            expect(stakes.FIRST).to.equal(stakeId);
            expect(stakes.LAST).to.equal(stakeId);
            expect(stakes.numStakes).to.equal(1);
            expect(stakes.totalTokensStaked).to.equal(150);

            expect(stake.expiryEpoch).to.equal(15);
            expect(stake.lockDuration).to.equal(10);
            expect(stake.prevStakeId).to.equal(0);
            expect(stake.nextStakeId).to.equal(0);
            expect(stake.amountStaked).to.equal(150);
        })

        it("successfully pushes on list n > 0", async function () {                
            await this.staking.pushStake(13, 10, 150);
            await this.staking.pushStake(24, 10, 200);
            await this.staking.pushStake(35, 10, 300);

            firstStakeId = await this.staking.packStakeId(13, 10);
            FIRST = await this.staking.getStakeForId(firstStakeId); 

            secondStakeId = await this.staking.packStakeId(24, 10);
            MID = await this.staking.getStakeForId(secondStakeId); 

            lastStakeId = await this.staking.packStakeId(35, 10);
            LAST = await this.staking.getStakeForId(lastStakeId); 

            const stakes = await this.staking.getStakesForMember(this.dev.address);

            expect(stakes.FIRST).to.equal(firstStakeId);
            expect(stakes.LAST).to.equal(lastStakeId);

            expect(stakes.numStakes).to.equal(3);
            expect(stakes.totalTokensStaked).to.equal(650);

            expect(FIRST.prevStakeId).to.equal(0);
            expect(FIRST.nextStakeId).to.equal(secondStakeId);
            expect(MID.prevStakeId).to.equal(firstStakeId);
            expect(MID.nextStakeId).to.equal(lastStakeId);
            expect(LAST.prevStakeId).to.equal(secondStakeId);
            expect(LAST.nextStakeId).to.equal(0);
        })

        context("_insertStakeBefore()", async function () {
            it("does not work on empty list", async function () {
                await expect(this.staking.insertStakeBefore(0, 5, 0, 150)).to.be.revertedWith("Staking.sol: cannot insertStakeBefore() in empty list of Stakes");
            })

            it("successfully inserts on list n = 1", async function () {
                await this.staking.pushStake(15, 10, 150);
                lastStakeId = await this.staking.packStakeId(15, 10);
                
                await this.staking.insertStakeBefore(lastStakeId, 13, 11, 200);
                firstStakeId = await this.staking.packStakeId(13, 11);

                firstStake = await this.staking.getStakeForId(firstStakeId); 
                lastStake = await this.staking.getStakeForId(lastStakeId);

                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(2);
                expect(stakes.totalTokensStaked).to.equal(350);

                expect(firstStake.expiryEpoch).to.equal(13);
                expect(firstStake.lockDuration).to.equal(11);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(lastStakeId);
                expect(firstStake.amountStaked).to.equal(200);

                expect(lastStake.expiryEpoch).to.equal(15);
                expect(lastStake.lockDuration).to.equal(10);
                expect(lastStake.prevStakeId).to.equal(firstStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(150);
            })

            it("successfully inserts on list n > 1", async function () {
                await this.staking.pushStake(15, 10, 150);
                lastStakeId = await this.staking.packStakeId(15, 10);
                
                await this.staking.insertStakeBefore(lastStakeId, 13, 11, 200);
                midStakeId = await this.staking.packStakeId(13, 11);
                
                await this.staking.insertStakeBefore(midStakeId, 11, 12, 250);
                firstStakeId = await this.staking.packStakeId(11, 12);
                
                firstStake = await this.staking.getStakeForId(firstStakeId); 
                midStake = await this.staking.getStakeForId(midStakeId); 
                lastStake = await this.staking.getStakeForId(lastStakeId); 

                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(3);
                expect(stakes.totalTokensStaked).to.equal(600);

                expect(firstStake.expiryEpoch).to.equal(11);
                expect(firstStake.lockDuration).to.equal(12);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(midStakeId);
                expect(firstStake.amountStaked).to.equal(250);

                expect(midStake.expiryEpoch).to.equal(13);
                expect(midStake.lockDuration).to.equal(11);
                expect(midStake.prevStakeId).to.equal(firstStakeId);
                expect(midStake.nextStakeId).to.equal(lastStakeId);
                expect(midStake.amountStaked).to.equal(200);

                expect(lastStake.expiryEpoch).to.equal(15);
                expect(lastStake.lockDuration).to.equal(10);
                expect(lastStake.prevStakeId).to.equal(midStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(150);
            })
        })
    })

    describe("public functions", async function () {
        beforeEach(async function () {
            // use internals for the packing/unpacking id functions
            this.staking = await this.Staking.deploy();
            await this.staking.deployed();
        })

        context("registerNewStake()", async function () {

            it("registers successfully for empty stakes", async function (){
                await this.staking.registerNewStake(15, 10, 150);

                const stakeId = await this.staking.packStakeId(15, 10);
                const stake = await this.staking.getStakeForId(stakeId); 
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(stakeId);
                expect(stakes.LAST).to.equal(stakeId);
                expect(stakes.numStakes).to.equal(1);
                expect(stakes.totalTokensStaked).to.equal(150);

                expect(stake.expiryEpoch).to.equal(15);
                expect(stake.lockDuration).to.equal(10);
                expect(stake.prevStakeId).to.equal(0);
                expect(stake.nextStakeId).to.equal(0);
                expect(stake.amountStaked).to.equal(150);
            })

            it("registers successfully for stake at end of list", async function (){
                await this.staking.registerNewStake(15, 10, 150);
                await this.staking.registerNewStake(16, 11, 200);

                const firstStakeId = await this.staking.packStakeId(15, 10);
                const firstStake = await this.staking.getStakeForId(firstStakeId); 
                const lastStakeId = await this.staking.packStakeId(16, 11);
                const lastStake = await this.staking.getStakeForId(lastStakeId);
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(2);
                expect(stakes.totalTokensStaked).to.equal(350);

                expect(firstStake.expiryEpoch).to.equal(15);
                expect(firstStake.lockDuration).to.equal(10);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(lastStakeId);
                expect(firstStake.amountStaked).to.equal(150);

                expect(lastStake.expiryEpoch).to.equal(16);
                expect(lastStake.lockDuration).to.equal(11);
                expect(lastStake.prevStakeId).to.equal(firstStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(200);
            })

            it("registers successfully for stake at beginning of list", async function (){
                // just change order from last test, the expectations should be the same
                await this.staking.registerNewStake(16, 11, 200);
                await this.staking.registerNewStake(15, 10, 150);

                const firstStakeId = await this.staking.packStakeId(15, 10);
                const firstStake = await this.staking.getStakeForId(firstStakeId); 
                const lastStakeId = await this.staking.packStakeId(16, 11);
                const lastStake = await this.staking.getStakeForId(lastStakeId);
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(2);
                expect(stakes.totalTokensStaked).to.equal(350);

                expect(firstStake.expiryEpoch).to.equal(15);
                expect(firstStake.lockDuration).to.equal(10);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(lastStakeId);
                expect(firstStake.amountStaked).to.equal(150);

                expect(lastStake.expiryEpoch).to.equal(16);
                expect(lastStake.lockDuration).to.equal(11);
                expect(lastStake.prevStakeId).to.equal(firstStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(200);
            })

            it("registers successfully for stake at middle of list (different expiry, different lock duration)", async function (){
                await this.staking.registerNewStake(17, 12, 250);
                await this.staking.registerNewStake(16, 11, 200);
                await this.staking.registerNewStake(15, 10, 150);

                const firstStakeId = await this.staking.packStakeId(15, 10);
                const firstStake = await this.staking.getStakeForId(firstStakeId); 
                const midStakeId = await this.staking.packStakeId(16, 11);
                const midStake = await this.staking.getStakeForId(midStakeId);
                const lastStakeId = await this.staking.packStakeId(17, 12);
                const lastStake = await this.staking.getStakeForId(lastStakeId);
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(3);
                expect(stakes.totalTokensStaked).to.equal(600);

                expect(firstStake.expiryEpoch).to.equal(15);
                expect(firstStake.lockDuration).to.equal(10);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(midStakeId);
                expect(firstStake.amountStaked).to.equal(150);

                expect(midStake.expiryEpoch).to.equal(16);
                expect(midStake.lockDuration).to.equal(11);
                expect(midStake.prevStakeId).to.equal(firstStakeId);
                expect(midStake.nextStakeId).to.equal(lastStakeId);
                expect(midStake.amountStaked).to.equal(200);

                expect(lastStake.expiryEpoch).to.equal(17);
                expect(lastStake.lockDuration).to.equal(12);
                expect(lastStake.prevStakeId).to.equal(midStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(250);
            })

            it("registers successfully for stake at middle of list (same expiry, different lock duration)", async function (){
                await this.staking.registerNewStake(17, 12, 250);
                await this.staking.registerNewStake(16, 11, 150);
                // this should go in the middle, since prev stake expiry (16) is != new stake expiry (16)
                await this.staking.registerNewStake(16, 8, 200);

                const firstStakeId = await this.staking.packStakeId(16, 11);
                const firstStake = await this.staking.getStakeForId(firstStakeId); 
                const midStakeId = await this.staking.packStakeId(16, 8);
                const midStake = await this.staking.getStakeForId(midStakeId);
                const lastStakeId = await this.staking.packStakeId(17, 12);
                const lastStake = await this.staking.getStakeForId(lastStakeId);
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(3);
                expect(stakes.totalTokensStaked).to.equal(600);

                expect(firstStake.expiryEpoch).to.equal(16);
                expect(firstStake.lockDuration).to.equal(11);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(midStakeId);
                expect(firstStake.amountStaked).to.equal(150);

                expect(midStake.expiryEpoch).to.equal(16);
                expect(midStake.lockDuration).to.equal(8);
                expect(midStake.prevStakeId).to.equal(firstStakeId);
                expect(midStake.nextStakeId).to.equal(lastStakeId);
                expect(midStake.amountStaked).to.equal(200);

                expect(lastStake.expiryEpoch).to.equal(17);
                expect(lastStake.lockDuration).to.equal(12);
                expect(lastStake.prevStakeId).to.equal(midStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(250);
            })

            it("registers successfully for stake at middle of list (same expiry, same lock duration)", async function () {
                await this.staking.registerNewStake(17, 12, 250);
                await this.staking.registerNewStake(16, 11, 150);
                // this should be added to existing stake
                await this.staking.registerNewStake(16, 11, 200);
                
                const firstStakeId = await this.staking.packStakeId(16, 11);
                const firstStake = await this.staking.getStakeForId(firstStakeId); 
                const lastStakeId = await this.staking.packStakeId(17, 12);
                const lastStake = await this.staking.getStakeForId(lastStakeId);
                const stakes = await this.staking.getStakesForMember(this.dev.address);

                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.numStakes).to.equal(2);
                expect(stakes.totalTokensStaked).to.equal(600);

                expect(firstStake.expiryEpoch).to.equal(16);
                expect(firstStake.lockDuration).to.equal(11);
                expect(firstStake.prevStakeId).to.equal(0);
                expect(firstStake.nextStakeId).to.equal(lastStakeId);
                expect(firstStake.amountStaked).to.equal(350);

                expect(lastStake.expiryEpoch).to.equal(17);
                expect(lastStake.lockDuration).to.equal(12);
                expect(lastStake.prevStakeId).to.equal(firstStakeId);
                expect(lastStake.nextStakeId).to.equal(0);
                expect(lastStake.amountStaked).to.equal(250);
            })
        })

        context("dequeueStake()", async function () {
            it("rejects dequeueing for empty list of stakes", async function () {
                await expect(this.staking.dequeueStake()).to.be.revertedWith("cannot dequeue empty stakes list");
            })

            it("dequeues successfully for non empty list of stakes", async function () {
                // getting the return value for a non view/pure function from javascript is difficult
                // as a write transaction (state changing) will return the transaction metadata instead of the
                // return values. As a result, we cannot set [lockDuration, amount] = await this.staking.dequeueStake();
                // to check if the return values are being accurately determined.

                // instead, make sure to test the correct return values by testing that the correct state changes are
                // being made in the calling contract (MemberContract.sol).

                // in this test, we are only checking to see if the state changes are being properly applied (numstakes and 
                // total tokens staked are being correctly discounted)

                await this.staking.registerNewStake(17, 12, 250);
                await this.staking.registerNewStake(16, 11, 150);

                const firstStakeId = await this.staking.packStakeId(16, 11);
                const lastStakeId = await this.staking.packStakeId(17, 12);
                let stakes = await this.staking.getStakesForMember(this.dev.address);
                
                expect(stakes.FIRST).to.equal(firstStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.totalTokensStaked).to.equal(400);
                expect(stakes.numStakes).to.equal(2);

                await this.staking.dequeueStake();
                stakes = await this.staking.getStakesForMember(this.dev.address);
                
                expect(stakes.FIRST).to.equal(lastStakeId);
                expect(stakes.LAST).to.equal(lastStakeId);
                expect(stakes.totalTokensStaked).to.equal(250);
                expect(stakes.numStakes).to.equal(1);

                await this.staking.dequeueStake();
                stakes = await this.staking.getStakesForMember(this.dev.address);
                
                expect(stakes.FIRST).to.equal(0);
                expect(stakes.LAST).to.equal(0);
                expect(stakes.totalTokensStaked).to.equal(0);
                expect(stakes.numStakes).to.equal(0);

                await expect(this.staking.dequeueStake()).to.be.revertedWith("cannot dequeue empty stakes list");
            })
        })
    })
})