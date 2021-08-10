// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {

  // main contract
  const Operator           = await hre.ethers.getContractFactory("Operator");

  // modules
  const Memberships        = await hre.ethers.getContractFactory("Memberships");
  const DefToken           = await hre.ethers.getContractFactory("DefaultToken");
  const TreasuryVault      = await hre.ethers.getContractFactory("TreasuryVaultV1");
  const BalanceSheetMining = await hre.ethers.getContractFactory("BalanceSheetMiningV1");
  const ContributorBudget  = await hre.ethers.getContractFactory("ContributorBudgetV1");

  // states
  const ClaimableRewards   = await hre.ethers.getContractFactory("ClaimableRewards");
  const VaultShares        = await hre.ethers.getContractFactory("VaultShares");

  const defToken = await DefToken.deploy();
  await defToken.deployed();
  console.log("[CONTRACT DEPLOYED] Default Token: ", defToken.address);

  const memberships = await Memberships.deploy(process.env.CONTRIBUTOR_WHITELIST.split(' '));
  await memberships.deployed();
  console.log("[CONTRACT DEPLOYED] Memberships: ", memberships.address);
  
  const defVault = await TreasuryVault.deploy(defToken.address, 85);
  await defVault.deployed();
  const defShares = await hre.ethers.getContractAt("VaultShares", await defVault.Shares());
  console.log("[CONTRACT DEPLOYED] DEF Treasury Vault: ", defVault.address);
  console.log("[CONTRACT DEPLOYED] DEF Treasury Vault Shares: ", defShares.address);

  const usdcVault = await TreasuryVault.deploy(process.env.POLYGON_MAINNET_USDC_CONTRACT_ADDRESS, 10);
  await usdcVault.deployed();
  const usdcShares = await hre.ethers.getContractAt("VaultShares", await usdcVault.Shares());
  console.log("[CONTRACT DEPLOYED] USDC Treasury Vault: ", usdcVault.address);
  console.log("[CONTRACT DEPLOYED] USDC Treasury Vault Shares: ", usdcShares.address);

  const mining = await BalanceSheetMining.deploy(usdcShares.address, defShares.address);
  await mining.deployed();
  const rewards = await hre.ethers.getContractAt("ClaimableRewards", await mining.Rewards());
  console.log("[CONTRACT DEPLOYED] Balance Sheet Mining: ", mining.address);
  console.log("[CONTRACT DEPLOYED] Rewards: ", mining.address);

  const budget = await ContributorBudget.deploy(defShares.address, memberships.address);
  await budget.deployed();
  console.log("[CONTRACT DEPLOYED] Contributor Budget: ", budget.address);

  const operator = await Operator.deploy(
    memberships.address,
    defToken.address,
    usdcVault.address,
    defVault.address,
    mining.address,
    budget.address
  )
  await operator.deployed();
  console.log("[CONTRACT DEPLOYED] Operator: ", operator.address);

  await defToken.approveApplication(operator.address);
  console.log("[CONTRACT APPROVED] Default Token -> Operator");

  await mining.approveApplication(operator.address);
  console.log("[CONTRACT APPROVED] Mining -> Operator");

  await defVault.approveApplication(operator.address);
  console.log("[CONTRACT APPROVED] Treasury Vault: DEF -> Operator");

  await usdcVault.approveApplication(operator.address);
  console.log("[CONTRACT APPROVED] Treasury Vault: USDC -> Operator");

  await defShares.approveApplication(operator.address);
  console.log("[CONTRACT APPROVED] VaultShares: DEF-VS -> Operator");

  await defShares.approveApplication(mining.address);
  console.log("[CONTRACT APPROVED] VaultShares: DEF-VS -> Mining");

  await defShares.approveApplication(budget.address)
  console.log("[CONTRACT APPROVED] VaultShares: DEF-VS -> Mining");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
