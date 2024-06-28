import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { KYC_REGISTRY, PROD_GUARDIAN_OMMF } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deployUSDY_Factory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const signers = await ethers.getSigners();

  // Deploy the factory
  const USDYFactoryDeployment = await deploy("USDYFactory", {
    from: deployer,
    args: [PROD_GUARDIAN_OMMF],
    log: true,
  });
  console.log(`USDYFactory deployed at: ${USDYFactoryDeployment.address}`);

  const usdyfactoryContract = await ethers.getContractAt("USDYFactory", USDYFactoryDeployment.address);

  const deploymentAllowlist = await deployments.get("Allowlist");
  const allowlistAddress = deploymentAllowlist.address;

  const deploymentAggregatorBlocklist = await deployments.get("AggregatorBlocklist");
  const blocklistAddress = deploymentAggregatorBlocklist.address;

  const name = "CMMF";;
  const ticker = "USD Yield Token";
  const listData = [blocklistAddress, allowlistAddress];

  const tx = await usdyfactoryContract.connect(signers[0]).deployUSDY(name, ticker, listData);
  await tx.wait();

  const usdyAddress = await usdyfactoryContract.usdyProxy();
  console.log(`USDY address:`, usdyAddress);

};

deployUSDY_Factory.tags = ["Prod-USDY-Factory", "Prod-USDY-3"];
export default deployUSDY_Factory;
