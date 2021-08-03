require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    ropsten: {
      url: "https://ropsten.infura.io/v3/cb3b2911315442f68e6d83936c5b46dd",
      accounts: [process.env.PRIVATE_KEY]
    },
    matic: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/bDBqT7mYkjP0qY25LC5q0isOyL9RggUT",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  solidity: "0.8.0",
};
