const { expect } = require("chai");

import "./mocks/MockState.sol";

describe("StateContract.sol", function () {
    it("Should return the new greeting once it's changed", async function () {
      const MockContract = await ethers.getContractFactory("MockState");
      const contract = await MockContract.deploy());
      await contract.deployed();
  
      expect(await contract.deployed()).to.equal("Hello, world!");
  
      const setGreetingTx = await greeter.setGreeting("Hola, mundo!");
  
      // wait until the transaction is mined
      await setGreetingTx.wait();
  
      expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
  });