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
  ZERO_ADDRESS
} from "../../mainnet_constants";
import { parseUnits } from "ethers/lib/utils";
const { ethers } = require("hardhat");


const PROD_MIN_DEPOSIT_AMOUNT = ethers.utils.parseUnits("500", 6);
const PROD_MIN_REDEEM_AMOUNT = ethers.utils.parseUnits("500", 18);
const PROD_MAX_DEPOSIT_AMOUNT = ethers.utils.parseUnits("500", 6);
const PROD_MAX_REDEEM_AMOUNT = ethers.utils.parseUnits("500", 18);

const deploy_usdyManager: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const signers = await ethers.getSigners();

  const factoryUSDY = await ethers.getContract("USDYFactory");
  //const factoryAllow = await ethers.getContract("AllowlistFactory");

  const usdyAddress = await factoryUSDY.usdyProxy();
  // const allowlistAddress = await factoryAllow.allowlistProxy();

  if (usdyAddress == ZERO_ADDRESS) {
    throw new Error("USDY Token not deployed through factory!");
  }

  const deploymentAggregatorBlocklist = await deployments.get("AggregatorBlocklist");
  const blocklistAddress = deploymentAggregatorBlocklist.address;

  const USDYManagerDeployment = await deploy("USDYManager", {
    from: deployer,
    args: [
      USDC_MAINNET, // _collateral
      usdyAddress, // _rwa
      PROD_MANAGER_ADMIN_USDY, // managerAdmin
      PROD_PAUSER_USDY, // pauser
      PROD_ASSET_SENDER_USDY, // _assetSender
      PROD_FEE_RECIPIENT_USDY, // _feeRecipient
      PROD_ASSET_RECIPIENT_USDY, // _assetRecipient
      PROD_MIN_DEPOSIT_AMOUNT,
      PROD_MIN_REDEEM_AMOUNT,
      PROD_MAX_DEPOSIT_AMOUNT,
      PROD_MAX_REDEEM_AMOUNT,
      blocklistAddress, // blocklist
    ],
    log: true,
    gasLimit: 4000000,
  });
  const usdymanagerAddress = USDYManagerDeployment.address;
  console.log("USDYManagerDeployment deployed", usdymanagerAddress);

  const usdyContract = await ethers.getContractAt("USDY", usdyAddress);

  const MINTER_ROLE = await usdyContract.MINTER_ROLE();

  const hasRole = await usdyContract.hasRole(MINTER_ROLE, usdymanagerAddress);

  if (!hasRole) {
    const tx1 = await usdyContract.connect(signers[0]).grantRole(MINTER_ROLE, usdymanagerAddress);
    await tx1.wait();
  }

  const deploymentPricer = await deployments.get("USDY_Pricer");
  const pricerAddress = deploymentPricer.address;
  console.log("USDY Pricer", pricerAddress)

  const usdymanagerContract = await ethers.getContractAt("USDYManager", usdymanagerAddress);
  
  const oldpricer = await usdymanagerContract.pricer();
  if (oldpricer != pricerAddress) {
    const tx2 = await usdymanagerContract.connect(signers[0]).setPricer(pricerAddress);
    console.log("oldpricer", oldpricer);
    await tx2.wait();
  }

  const deploymentAllowlist = await deployments.get("Allowlist");
  const allowlistAddress = deploymentAllowlist.address;


  console.log("Congratulations! All has done.")
  console.log("USDYManager deployed", usdymanagerAddress);
  console.log("USDY deployed", usdyAddress);
  console.log("Allowlist deployed", allowlistAddress);
  console.log("Blocklist(Aggregator) deployed", blocklistAddress);
  console.log("Pricer deployed", pricerAddress);
  
};
deploy_usdyManager.tags = ["Prod-USDYManager", "Prod-USDY-5"];
export default deploy_usdyManager;
