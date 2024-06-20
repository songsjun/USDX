import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
const { ethers } = require("hardhat");

const deployBlocklist: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy, save } = deployments;
  const { deployer } = await getNamedAccounts();
  const signers = await ethers.getSigners();

  const guardian = signers[1];

  // Deploy Blocklist contract
  const blocklistDeployment = await deploy("Blocklist", {
    from: deployer,
    args: [],
    log: true,
  });

  const blocklistAddress = blocklistDeployment.address;

  // Deploy AggregatorBlocklist contract
  const aggregatorDeployment = await deploy("AggregatorBlocklist", {
    from: deployer,
    args: [],
    log: true,
  });

  const aggregatorAddress = aggregatorDeployment.address;

  // Get contract instances
  const aggregatorContract = await ethers.getContractAt("AggregatorBlocklist", aggregatorAddress);
  const blocklistContract = await ethers.getContractAt("Blocklist", blocklistAddress);

  const exist = await aggregatorContract.connect(signers[0]).blocklistExists(blocklistAddress);

  if (!exist) {
    // Add Blocklist to AggregatorBlocklist
    const tx = await aggregatorContract.connect(signers[0]).addBlocklist(blocklistAddress);
    await tx.wait();
  }

  console.log(`Blocklist deployed at: ${blocklistAddress}`);
  console.log(`AggregatorBlocklist deployed at: ${aggregatorAddress}`);
  console.log(`Blocklist added to AggregatorBlocklist`);
};

deployBlocklist.tags = ["Prod-Blocklist", "Prod-USDY-2"];
export default deployBlocklist;


