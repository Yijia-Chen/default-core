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

    beforeEach(async function () {
      this.EpochInstaller = await ethers.getContractFactory("def_EpochInstaller");
      this.epochModule = await this.EpochInstaller.deploy();
      await this.epochModule.deployed();

      await this.default.installModule(this.epochModule.address);
      this.epoch = await ethers.getContractAt("def_Epoch", await this.default.getModule("0x455043"));
    })

    describe("Epoch", async function() {      

      it("increments epoch correctly", async function() {
        const sevenDays = 7 * 24 * 60 * 60;        

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        await ethers.provider.send('evm_setNextBlockTimestamp', [timestampBefore + sevenDays])
        await ethers.provider.send('evm_mine');

        await this.epoch.incrementEpoch()
        const newEpoch = await this.epoch.current()

        expect(newEpoch).to.equal(2);
      })

      it("rejects premature increment epoch", async function() {
        const sixDays = 6 * 24 * 60 * 60;        

        const blockNumBefore = await ethers.provider.getBlockNumber();
        const blockBefore = await ethers.provider.getBlock(blockNumBefore);
        const timestampBefore = blockBefore.timestamp;

        await ethers.provider.send('evm_setNextBlockTimestamp', [timestampBefore + sixDays])
        await ethers.provider.send('evm_mine');

        // https://github.com/EthWorks/Waffle/issues/95
        await expect(this.epoch.incrementEpoch()).to.be.revertedWith("Epoch.sol: cannot incrementEpoch() before deadline");
      })
    })
})