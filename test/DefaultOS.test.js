const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe("DefaultOS.sol", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.dev = this.signers[0];
    
        this.DefaultOS = await (await ethers.getContractFactory("DefaultOS")).deploy("Default DAO");
        this.default = await this.DefaultOS.deployed();
    })

    // testing is not done here, use a ModuleInstaller stub instead of the Token module
    describe("DefaultOSModule", async function () {
        beforeEach(async function () {
            this.DefaultTokenInstaller = await ethers.getContractFactory("DefaultERC20Installer");
            this.tokenModule = await this.DefaultTokenInstaller.deploy();
            await this.tokenModule.deployed();
        })

        it("configures the OS correctly", async function () {
            await this.default.installModule(this.tokenModule.address);
            this.token = await ethers.getContractAt("DefaultERC20", await this.default.getModule("0x544b4e")); // "TKN"

            // console.log("os signer: ", this.default.signer);
            // await this.token.mint(this.dev.address, 1000);
            // expect(await this.token.balanceOf(this.dev.address)).to.equal(1000);
        })

    })
})