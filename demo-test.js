const { expect } = require("chai");

// ******************************** @dev ********************************
// Some Waffle matchers return a Promise rather than executing immediately. 
// If you're making a call or sending a transaction, make sure to check 
// Waffle's documentation, and await these Promises. Otherwise your tests 
// may pass without waiting for all checks to complete.
// **********************************************************************


describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});