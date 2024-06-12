import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { KYC_REGISTRY } from "../../mainnet_constants";
const { ethers } = require("hardhat");

const deployAllowlist: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployments, getNamedAccounts } = hre;
  const { save } = deployments;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const signers = await ethers.getSigners();

  const guardian = signers[1];

  await deploy("Allowlist", {
    from: deployer,
    args: [],
    log: true,
  });
};

deployAllowlist.tags = ["Prod-Allowlist", "Prod-USDY-1"];
export default deployAllowlist;
