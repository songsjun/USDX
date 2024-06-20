import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { PROD_ORACLE, PROD_GUARDIAN_USDY } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deploy_usdyPricer: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const pricerDeployment = await deploy("USDY_Pricer", {
    from: deployer,
    contract: "Pricer",
    args: [PROD_GUARDIAN_USDY, PROD_GUARDIAN_USDY],
    log: true,
  });
  const pricerAddress = pricerDeployment.address;
  console.log("USDY_Pricer deployed", pricerAddress);
};

deploy_usdyPricer.tags = ["Prod-USDY-Pricer", "Prod-USDY-4"];
export default deploy_usdyPricer;
