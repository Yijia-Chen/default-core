/* 

  Deploys Default contracts

  usage:
  npx hardhat run scripts/deploy.js --network dev
*/
const deploy = require('./init');
deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });