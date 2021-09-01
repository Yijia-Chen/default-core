const { expect } = require("chai");
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';


// dao: launch os, install token, epoch, treasury, mining. Call configure() on mining after deploy.
// user: get tokens, deposit into treasury to get shares. Call register() on mining after they get shares to start the program.


describe("Mining.sol", function () {
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

    describe("Mining", async function() {      

      it("configures vault", async function() {
        1. that only the operator can configure the vault
        2. that the vault can only be configured once (can't change the vault)
      })

      it(issues rewards)
      1. that the rewards can only be distributed once per epoch
      2. that they are distributed correctly (correct calculations, incl potential rounding errors)

      it (distributes rewards to users)
      1. require users to be registered
      2. claims the correct amount of rewards
    })
})