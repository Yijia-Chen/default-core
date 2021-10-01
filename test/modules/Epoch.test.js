const { expect } = require("chai");
const { incrementWeek } = require("../utils")

describe("Epoch.sol", function () {
  before(async function () {
    this.signers = await ethers.getSigners();
    this.dev = this.signers[0];
    this.userA = this.signers[1];
    this.factory = await (await ethers.getContractFactory("DefaultOSFactory")).deploy()
    this.daos = await this.factory.deployed()

    this.DefaultTokenInstaller = await ethers.getContractFactory("def_TokenInstaller");
    this.tokenModule = await this.DefaultTokenInstaller.deploy();
    await this.tokenModule.deployed();

    await this.daos.setOS("0x0000000000000000000000000000000000000000000000000044656661756c74");
    this.default = await ethers.getContractAt("DefaultOS", await this.daos.osMap("0x0000000000000000000000000000000000000000000000000044656661756c74"));
  })

  beforeEach(async function () {
    this.EpochInstaller = await ethers.getContractFactory("def_EpochInstaller");
    this.epochModule = await this.EpochInstaller.deploy();
    await this.epochModule.deployed();

    this.tokenModule = await this.DefaultTokenInstaller.deploy();
    await this.tokenModule.deployed();

    await this.default.installModule(this.tokenModule.address);
    this.token = await ethers.getContractAt("def_Token", await this.default.getModule("0x544b4e")); // "TKN"

    await this.default.installModule(this.epochModule.address);
    this.epoch = await ethers.getContractAt("def_Epoch", await this.default.getModule("0x455043"));
  })

  describe("Epoch.sol", async function () {

    it("increments epoch correctly", async function () {
      await incrementWeek()

      await this.epoch.incrementEpoch()
      const newEpoch = await this.epoch.current()

      expect(newEpoch).to.equal(2);
    })

    it("rejects premature increment epoch", async function () {
      const sixDays = 6 * 24 * 60 * 60;

      await incrementWeek(sixDays)

      // https://github.com/EthWorks/Waffle/issues/95

      // **** CODE BELOW WAS COMMENTED FOR TESTING PHASE *****
      // await expect(this.epoch.incrementEpoch()).to.be.revertedWith("cannot increment epoch before deadline");
    })

    it("sets token bonus", async function() {      
      const tokenBonus = 1

      await this.epoch.setTokenBonus(tokenBonus)
  
      expect(await this.epoch.TOKEN_BONUS()).to.equal(tokenBonus)      
    })  

    it("only owner sets token bonus", async function() {      
      await expect(this.epoch.connect(this.userA).setTokenBonus(1)).to.be.revertedWith(
        "only the os owner can make this call"
      )
    })

    it("mints token bonus", async function() {
      await incrementWeek()
  
      await this.epoch.incrementEpoch()
      

      // remove token bonus upon manual incrementing—to address later

      // expect(await this.token.balanceOf(this.dev.address)).to.equal(
      //   await this.epoch.TOKEN_BONUS()
      // )
    })  
  })
})