const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

// MAKE SURE TO TEST EVENTS!!!!

describe("Staking.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
    
        this.StakingInternals = await ethers.getContractFactory("TESTONLY_StakingInternalFunctions");
        this.Staking = await ethers.getContractFactory("Staking");
        this.OS = await ethers.getContractFactory("OS");
    })
    
    describe("internal functions", async function () {
        beforeEach(async function () {
            this.internals = await this.StakingInternals.deploy(ZERO_ADDRESS);
            await this.internals.deployed(); 
        })

        it("sets the correct state", async function () {
            expect(await this.internals.EARLIEST()).to.equal(0);
            expect(await this.internals.LATEST()).to.equal(0);
            expect(await this.internals.numStakes()).to.equal(0);
            expect(await this.internals.totalStakedTokens()).to.equal(0);
        })

        context("_pushStake", async function () {
            it("successfully pushes on list n = 0", async function () {
                await this.internals.pushStake(5, 150);
                const stake = await this.internals.getStakeAt(5)

                expect(await this.internals.EARLIEST()).to.equal(5);
                expect(await this.internals.LATEST()).to.equal(5);
                expect(await this.internals.numStakes()).to.equal(1);
                expect(await this.internals.totalStakedTokens()).to.equal(150);

                expect(stake[0]).to.equal(5);
                expect(stake[1]).to.equal(0);
                expect(stake[2]).to.equal(0);
                expect(stake[3]).to.equal(150);
            })

            it("successfully pushes on list n > 0", async function () {                
                await this.internals.pushStake(5, 150);
                await this.internals.pushStake(7, 200);
                await this.internals.pushStake(8, 250);

                expect(await this.internals.EARLIEST()).to.equal(5);
                expect(await this.internals.LATEST()).to.equal(8);

                const EARLIEST = await this.internals.getStakeAt(5);
                const MID = await this.internals.getStakeAt(7);
                const LATEST = await this.internals.getStakeAt(8);

                expect(await this.internals.numStakes()).to.equal(3);
                expect(await this.internals.totalStakedTokens()).to.equal(600);

                expect(EARLIEST[2]).to.equal(7);
                expect(MID[1]).to.equal(5);
                expect(MID[2]).to.equal(8);
                expect(LATEST[1]).to.equal(7);
            })
        })

        context("_dequeueStake", async function () {
            it("successfully dequeues from list n = 3", async function () {
                await this.internals.pushStake(5, 150);
                await this.internals.pushStake(7, 200);
                await this.internals.pushStake(8, 250);
                await this.internals.dequeueStake();

                expect(await this.internals.EARLIEST()).to.equal(7);
                expect(await this.internals.LATEST()).to.equal(8);

                const DEQUEUED = await this.internals.getStakeAt(5);
                const EARLIEST = await this.internals.getStakeAt(7);
                const LATEST = await this.internals.getStakeAt(8);

                expect(await this.internals.numStakes()).to.equal(2);
                expect(await this.internals.totalStakedTokens()).to.equal(450);

                expect(DEQUEUED[0]).to.equal(0);
                expect(DEQUEUED[1]).to.equal(0);
                expect(DEQUEUED[2]).to.equal(0);
                expect(DEQUEUED[3]).to.equal(0);

                expect(EARLIEST[0]).to.equal(7);
                expect(EARLIEST[1]).to.equal(0);
                expect(EARLIEST[2]).to.equal(8);
                expect(EARLIEST[3]).to.equal(200);

                expect(LATEST[0]).to.equal(8);
                expect(LATEST[1]).to.equal(7);
                expect(LATEST[2]).to.equal(0);
                expect(LATEST[3]).to.equal(250);
            })

            it("successfully dequeues on empty list", async function () {                
                await this.internals.pushStake(5, 150);
                await this.internals.dequeueStake();
                await this.internals.dequeueStake();

                const stake = await this.internals.getStakeAt(5);

                expect(await this.internals.EARLIEST()).to.equal(0);
                expect(await this.internals.LATEST()).to.equal(0);
                expect(await this.internals.numStakes()).to.equal(0);
                expect(await this.internals.totalStakedTokens()).to.equal(0);

                expect(stake[0]).to.equal(0);
                expect(stake[1]).to.equal(0);
                expect(stake[2]).to.equal(0);
                expect(stake[3]).to.equal(0);
            })
        })

        context("_insertStakeBefore", async function () {
            it("does not work on empty list", async function () {
                await expect(this.internals.insertStakeBefore(5, 0, 150)).to.be.revertedWith("Staking.sol: cannot insertStakeBefore() in empty list of Stakes");
            })

            it("successfully inserts for list n = 1", async function () {
                await this.internals.pushStake(7, 200);
                await this.internals.insertStakeBefore(7, 5, 150);

                const stake = await this.internals.getStakeAt(7);

                expect(await this.internals.EARLIEST()).to.equal(5);
                expect(await this.internals.LATEST()).to.equal(7);

                const EARLIEST = await this.internals.getStakeAt(5);
                const LATEST = await this.internals.getStakeAt(7);

                expect(await this.internals.numStakes()).to.equal(2);
                expect(await this.internals.totalStakedTokens()).to.equal(350);

                expect(EARLIEST[0]).to.equal(5);
                expect(EARLIEST[1]).to.equal(0);
                expect(EARLIEST[2]).to.equal(7);
                expect(EARLIEST[3]).to.equal(150);

                expect(LATEST[0]).to.equal(7);
                expect(LATEST[1]).to.equal(5);
                expect(LATEST[2]).to.equal(0);
                expect(LATEST[3]).to.equal(200);
            })

            it("successfully inserts for list n > 1", async function () {
                await this.internals.pushStake(3, 250);
                await this.internals.pushStake(6, 300);
                await this.internals.insertStakeBefore(6, 4, 150);

                expect(await this.internals.EARLIEST()).to.equal(3);
                expect(await this.internals.LATEST()).to.equal(6);

                const EARLIEST = await this.internals.getStakeAt(3);
                const INSERTED = await this.internals.getStakeAt(4);
                const LATEST = await this.internals.getStakeAt(6);

                expect(await this.internals.numStakes()).to.equal(3);
                expect(await this.internals.totalStakedTokens()).to.equal(700);

                expect(EARLIEST[0]).to.equal(3);
                expect(EARLIEST[1]).to.equal(0);
                expect(EARLIEST[2]).to.equal(4);
                expect(EARLIEST[3]).to.equal(250);

                expect(INSERTED[0]).to.equal(4);
                expect(INSERTED[1]).to.equal(3);
                expect(INSERTED[2]).to.equal(6);
                expect(INSERTED[3]).to.equal(150);

                expect(LATEST[0]).to.equal(6);
                expect(LATEST[1]).to.equal(4);
                expect(LATEST[2]).to.equal(0);
                expect(LATEST[3]).to.equal(300);
            })
        })
        describe("Stake & Unstake", async function () {
            beforeEach(async function () {
                this.defaultOS = await this.OS.deploy();
                await this.defaultOS.deployed();
    
                this.staking = await this.Staking.deploy(this.defaultOS.address);
                await this.staking.deployed();
                
                await this.defaultOS.connect(this.dev).mint(3000);
                await this.defaultOS.connect(this.dev).approve(this.staking.address, 3000);
            })
    
            context("stakeTokens()", async function () {
                it ("Cannot stake 0 tokens", async function () {
                    await expect(this.staking.stakeTokens(this.dev.address, 0, 10)).to.be.revertedWith("must stake more than 0 tokens");
                })

                it ("Stakes one", async function () {
                    await this.staking.stakeTokens(this.dev.address, 1000, 10);
                    expect(await this.staking.numStakes()).to.equal(1);
                    expect(await this.staking.EARLIEST()).to.equal(10);
                    expect(await this.staking.LATEST()).to.equal(10);
                    expect(await this.staking.totalStakedTokens()).to.equal(1000);

                    const stake = await this.staking.getStakeAt(10);
                    expect(stake[0]).to.equal(10);
                    expect(stake[1]).to.equal(0);
                    expect(stake[2]).to.equal(0);
                    expect(stake[3]).to.equal(1000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(2000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(1000);
                })

                it ("stakes two", async function() {
                    await this.staking.stakeTokens(this.dev.address, 1000, 3);
                    await this.staking.stakeTokens(this.dev.address, 1000, 4);

                    expect(await this.staking.numStakes()).to.equal(2);
                    expect(await this.staking.EARLIEST()).to.equal(3);
                    expect(await this.staking.LATEST()).to.equal(4);
                    expect(await this.staking.totalStakedTokens()).to.equal(2000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(1000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(2000);
                })

                it ("stakes two reverse", async function() {
                    await this.staking.stakeTokens(this.dev.address, 1000, 4);
                    await this.staking.stakeTokens(this.dev.address, 1000, 3);

                    expect(await this.staking.numStakes()).to.equal(2);
                    expect(await this.staking.EARLIEST()).to.equal(3);
                    expect(await this.staking.LATEST()).to.equal(4);
                    expect(await this.staking.totalStakedTokens()).to.equal(2000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(1000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(2000);
                })

                it ("stakes three", async function() {
                    await this.staking.stakeTokens(this.dev.address, 1000, 5);
                    await this.staking.stakeTokens(this.dev.address, 1000, 7);
                    await this.staking.stakeTokens(this.dev.address, 1000, 6);

                    expect(await this.staking.numStakes()).to.equal(3);
                    expect(await this.staking.EARLIEST()).to.equal(5);
                    expect(await this.staking.LATEST()).to.equal(7);
                    expect(await this.staking.totalStakedTokens()).to.equal(3000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(0);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(3000);
                })

                it ("stakes three reverse", async function() {
                    await this.staking.stakeTokens(this.dev.address, 1000, 7);
                    await this.staking.stakeTokens(this.dev.address, 1000, 6);
                    await this.staking.stakeTokens(this.dev.address, 1000, 5);

                    expect(await this.staking.numStakes()).to.equal(3);
                    expect(await this.staking.EARLIEST()).to.equal(5);
                    expect(await this.staking.LATEST()).to.equal(7);
                    expect(await this.staking.totalStakedTokens()).to.equal(3000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(0);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(3000);
                })
            })

            context("withdrawAvailableTokens()", async function () {
                it ("Cannot unstake when there's nothing to unstake", async function () {
                    await expect(this.staking.withdrawAvailableTokens(this.dev.address)).to.be.revertedWith("There is nothing to unstake!");
                })

                it ("Unstakes 1 successfully", async function () {
                    await this.staking.stakeTokens(this.dev.address, 1000, 5);
                    await this.staking.stakeTokens(this.dev.address, 1000, 7);
                    await this.staking.stakeTokens(this.dev.address, 1000, 6);
                    for (i = 0; i < 5; i++) {
                        await this.defaultOS.incrementEpoch();
                    }
                    await this.staking.withdrawAvailableTokens(this.dev.address);

                    expect(await this.staking.numStakes()).to.equal(2);
                    expect(await this.staking.EARLIEST()).to.equal(6);
                    expect(await this.staking.LATEST()).to.equal(7);
                    expect(await this.staking.totalStakedTokens()).to.equal(2000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(1000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(2000);
                })

                it ("Unstakes 2 successfully", async function () {
                    await this.staking.stakeTokens(this.dev.address, 1000, 5);
                    await this.staking.stakeTokens(this.dev.address, 1000, 7);
                    await this.staking.stakeTokens(this.dev.address, 1000, 6);
                    for (i = 0; i < 6; i++) {
                        await this.defaultOS.incrementEpoch();
                    }
                    await this.staking.withdrawAvailableTokens(this.dev.address);

                    expect(await this.staking.numStakes()).to.equal(1);
                    expect(await this.staking.EARLIEST()).to.equal(7);
                    expect(await this.staking.LATEST()).to.equal(7);
                    expect(await this.staking.totalStakedTokens()).to.equal(1000);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(2000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(1000);
                })

                it ("Unstakes 3 successfully", async function () {
                    await this.staking.stakeTokens(this.dev.address, 1000, 5);
                    await this.staking.stakeTokens(this.dev.address, 1000, 7);
                    await this.staking.stakeTokens(this.dev.address, 1000, 6);
                    for (i = 0; i < 10; i++) {
                        await this.defaultOS.incrementEpoch();
                    }
                    await this.staking.withdrawAvailableTokens(this.dev.address);

                    expect(await this.staking.numStakes()).to.equal(0);
                    expect(await this.staking.EARLIEST()).to.equal(0);
                    expect(await this.staking.LATEST()).to.equal(0);
                    expect(await this.staking.totalStakedTokens()).to.equal(0);

                    expect(await this.defaultOS.balanceOf(this.dev.address)).to.equal(3000);
                    expect(await this.defaultOS.balanceOf(this.staking.address)).to.equal(0);
                })
            })
        })
    })

})