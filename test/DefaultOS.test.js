const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DefaultOS.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
        this.factory = await (await ethers.getContractFactory("DefaultOSFactory")).deploy()
        this.daos = await this.factory.deployed()

        await this.daos.setOS("0x0000000000000000000000000000000000000000000000000044656661756c74");
        this.default = await ethers.getContractAt("DefaultOS", await this.daos.osMap("0x0000000000000000000000000000000000000000000000000044656661756c74"));

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
        this.DefaultEpochInstaller = await ethers.getContractFactory("def_EpochInstaller");
        this.epochModule = await this.DefaultEpochInstaller.deploy();
        await this.epochModule.deployed();
      })
    })
})