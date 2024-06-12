import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import {
  PROD_GUARDIAN_OMMF,
  PROD_ASSET_SENDER_USDY,
  PROD_FEE_RECIPIENT_USDY,
  PROD_ASSET_RECIPIENT_USDY,
  PROD_MANAGER_ADMIN_USDY,
  PROD_ORACLE,
  PROD_PAUSER_USDY,
  USDC_MAINNET,
  ZERO_ADDRESS,
  BLOCK_LIST,
  ALLOW_LIST,
  SANCTION_LIST
} from "../../mainnet_constants";
import { parseUnits } from "ethers/lib/utils";
const { ethers } = require("hardhat");

const deploy_usdyManager: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const factoryUSDY = await ethers.getContract("USDYFactory");
  //const factoryAllow = await ethers.getContract("AllowlistFactory");

  const usdyAddress = await factoryUSDY.usdyProxy();
  // const allowlistAddress = await factoryAllow.allowlistProxy();

  if (usdyAddress == ZERO_ADDRESS) {
    throw new Error("USDY Token not deployed through factory!");
  }

  await deploy("USDYManager", {
    from: deployer,
    args: [
      USDC_MAINNET, // _collateral
      usdyAddress, // _rwa
      PROD_MANAGER_ADMIN_USDY, // managerAdmin
      PROD_PAUSER_USDY, // pauser
      PROD_ASSET_SENDER_USDY, // _assetSender
      PROD_FEE_RECIPIENT_USDY, // _feeRecipient
      PROD_ASSET_RECIPIENT_USDY, // _assetRecipient
      parseUnits("500", 6), // _minimumDepositAmount
      parseUnits("500", 18), // _minimumRedemptionAmount
      BLOCK_LIST, // blocklist
      SANCTION_LIST, // sanctionsList
    ],
    log: true,
    gasLimit: 4000000,
  });
};
deploy_usdyManager.tags = ["Prod-USDYManager", "Prod-USDY-4"];
export default deploy_usdyManager;
