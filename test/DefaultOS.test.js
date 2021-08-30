const { expect } = require("chai");
const { ethers } = require("hardhat");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("DefaultOS.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.DaoTracker = await (await ethers.getContractFactory("DaoTracker")).deploy()
        this.daos = await this.DaoTracker.deployed()
        // console.log("D: ", this.daos.address)

        this.DefaultOS = await (await ethers.getContractFactory("DefaultOS")).deploy(
          "Default DAO",
          "default",
          this.daos.address
        );
        this.default = await this.DefaultOS.deployed();
    })

    // testing is not done here, use a ModuleInstaller stub instead of the Token module
    describe("DefaultOSModule", async function () {
        beforeEach(async function () {
            this.DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
            this.tokenModule = await this.DefaultTokenInstaller.deploy();
            await this.tokenModule.deployed();
        })

        it("configures the OS correctly", async function () {
            await this.default.installModule(this.tokenModule.address);
            this.token = await ethers.getContractAt("def_Token", await this.default.getModule("0x544b4e")); // "TKN"
            
            await this.token.mint(this.dev.address, 1000);
            const balance = await this.token.balanceOf(this.dev.address)            
            expect(balance.toNumber()).to.equal(1000);
        })
    })

    describe("DefaultOS", async function() {
      beforeEach(async function () {
        this.DefaultPeerRewardInstaller = await ethers.getContractFactory("def_PeerRewardsInstaller");
        this.peerRewardsModule = await this.DefaultPeerRewardInstaller.deploy();
        await this.peerRewardsModule.deployed();
      })

      it("increments epoch correctly", async function() {
        const sevenDays = 7 * 24 * 60 * 60;        

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        await ethers.provider.send('evm_setNextBlockTimestamp', [timestampBefore + sevenDays])
        await ethers.provider.send('evm_mine');

        await this.default.incrementEpoch()
        const newEpoch = await this.default.currentEpoch()

        expect(newEpoch).to.equal(1);
      })

      it("rejects premature increment epoch", async function() {
        const sixDays = 6 * 24 * 60 * 60;        

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        await ethers.provider.send('evm_setNextBlockTimestamp', [timestampBefore + sixDays])
        await ethers.provider.send('evm_mine');

        // https://github.com/EthWorks/Waffle/issues/95
        await expect(this.default.incrementEpoch()).to.be.revertedWith("DefaultOS.sol: cannot incrementEpoch() before deadline");
      })
    })
})