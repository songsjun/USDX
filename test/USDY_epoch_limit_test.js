const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { keccak256, parseUnits, hexZeroPad, hexlify } = require("ethers/lib/utils");

describe("USDYManager", function () {
  async function deployFixture() {
    const [admin, addr1, addr2] = await ethers.getSigners();

    const USDC = await ethers.getContractFactory("MockERC20");
    const usdc = await USDC.deploy("USDC TOKEN", "USDC");
    const USER_AMOUNT = parseUnits("1000", 18);
    await usdc.mint(addr1.address, USER_AMOUNT);
    await usdc.mint(addr2.address, USER_AMOUNT);

    const AllowList = await ethers.getContractFactory("Allowlist");
    const allowList = await AllowList.deploy();
    await allowList.addToAllowlist([addr1.address, addr2.address]);

    const BlockList = await ethers.getContractFactory("Blocklist");
    const blockList = await BlockList.deploy();

    const FACTORY = await ethers.getContractFactory("USDYFactory");
    const factory = await FACTORY.deploy(admin.address);

    const name = "CMMF";;
    const ticker = "USD Yield Token";
    const listData = [blockList.address, allowList.address];
    await factory.deployUSDY(name, ticker, listData);

    const usdyAddress = await factory.usdyProxy();

    const Pricer = await ethers.getContractFactory("Pricer");
    const pricer = await Pricer.deploy(admin.address, admin.address);
    await pricer.addPrice(parseUnits("1", 18), time.latest());

    const PROD_MIN_DEPOSIT_AMOUNT = parseUnits("100", 18);
    const PROD_MIN_REDEEM_AMOUNT = parseUnits("100", 18);
    const PROD_MAX_DEPOSIT_AMOUNT = parseUnits("5000", 18);
    const PROD_MAX_REDEEM_AMOUNT = parseUnits("5000", 18);

    const UsdyManager = await ethers.getContractFactory("USDYManager");
    const usdyManager = await UsdyManager.deploy(
        usdc.address, usdyAddress, admin.address, admin.address, admin.address, admin.address, admin.address,
        PROD_MIN_DEPOSIT_AMOUNT, PROD_MIN_REDEEM_AMOUNT, PROD_MAX_DEPOSIT_AMOUNT,
        PROD_MAX_REDEEM_AMOUNT, blockList.address);

    const usdy = await ethers.getContractAt("USDY", usdyAddress);
    const MINTER_ROLE = await usdy.MINTER_ROLE();
    await usdy.grantRole(MINTER_ROLE, usdyManager.address);

    await allowList.addToAllowlist([usdyManager.address]);

    await usdyManager.setPricer(pricer.address);
    await usdyManager.grantRole(keccak256(Buffer.from("PRICE_ID_SETTER_ROLE", "utf-8")), admin.address);
    await usdyManager.grantRole(keccak256(Buffer.from("TIMESTAMP_SETTER_ROLE", "utf-8")), admin.address);

    await usdc.connect(addr1).approve(usdyManager.address, USER_AMOUNT);
    await usdc.connect(addr2).approve(usdyManager.address, USER_AMOUNT);
    await usdy.connect(addr1).approve(usdyManager.address, USER_AMOUNT);
    await usdy.connect(addr2).approve(usdyManager.address, USER_AMOUNT);
    // Fixtures can return anything you consider useful for your tests
    return { usdy, usdyManager, admin, addr1, addr2 };
  }

  it("Should request deposit and redemption successfully", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);

    await expect(usdyManager.connect(addr1).requestSubscription(parseUnits("1000", 18))).not.to.be.reverted;
    await expect(usdyManager.connect(addr2).requestSubscription(parseUnits("1000", 18))).not.to.be.reverted;

    await usdyManager.setPriceIdForDeposits([hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)],[1,1]);
    let timestamp = await time.latest();
    await usdyManager.setClaimableTimestamp(timestamp + 1, [hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)]);

    await time.increase(20);

    await usdyManager.claimMint([hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)]);

    await expect(usdyManager.connect(addr1).requestRedemption(parseUnits("1000", 18))).not.to.be.reverted;
    await expect(usdyManager.connect(addr2).requestRedemption(parseUnits("1000", 18))).not.to.be.reverted;
  });

  it("Should request deposit and redemption offchain successfully", async function () {
    const { blockList, usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);

    await usdyManager.grantRole(keccak256(Buffer.from("RELAYER_ROLE", "utf-8")), admin.address);
    await expect(usdyManager.requestSubscriptionServicedOffchain(addr1.address, parseUnits("1000", 18), hexZeroPad(hexlify(1), 32))).not.to.be.reverted;
    await expect(usdyManager.requestSubscriptionServicedOffchain(addr2.address, parseUnits("1000", 18), hexZeroPad(hexlify(2), 32))).not.to.be.reverted;

    await usdyManager.setPriceIdForDeposits([hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)],[1,1]);
    let timestamp = await time.latest();
    await usdyManager.setClaimableTimestamp(timestamp + 1, [hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)]);

    await time.increase(20);

    await usdyManager.claimMint([hexZeroPad(hexlify(1), 32),hexZeroPad(hexlify(2), 32)]);

    await expect(usdyManager.connect(addr1).requestRedemptionServicedOffchain(parseUnits("1000", 18), hexZeroPad(hexlify(1), 32))).not.to.be.reverted;
    await expect(usdyManager.connect(addr2).requestRedemptionServicedOffchain(parseUnits("1000", 18), hexZeroPad(hexlify(2), 32))).not.to.be.reverted;
  });

  it("Should request deposit/redemption failed if exceed limit in epoch", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);

    await usdyManager.setMaximumDepositAmountInEpoch(parseUnits("500", 18));
    await usdyManager.setMaximumRedemptionAmountInEpoch(parseUnits("500", 18));
    await usdyManager.setEpochInterval(3600);

    await expect(usdyManager.connect(addr1).requestSubscription(parseUnits("500", 18))).not.to.be.reverted;
    await time.increase(100);

    await expect(usdyManager.connect(addr1).requestSubscription(parseUnits("100", 18))).to.be.revertedWith("DepositAmountExceedEpochMaximum");

    await time.increase(3600);
    await expect(usdyManager.connect(addr1).requestSubscription(parseUnits("200", 18))).not.to.be.reverted;

    await usdyManager.setPriceIdForDeposits([hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)], [1, 1]);
    let timestamp = await time.latest();
    await usdyManager.setClaimableTimestamp(timestamp + 1, [hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)]);
    await usdyManager.claimMint([hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)]);


    await expect(usdyManager.connect(addr1).requestRedemption(parseUnits("500", 18))).not.to.be.reverted;

    await expect(usdyManager.connect(addr1).requestRedemption(parseUnits("500", 18))).to.be.revertedWith("RedemptionAmountExceedEpochMaximum");
    await time.increase(3600);

    await expect(usdyManager.connect(addr1).requestRedemption(parseUnits("200", 18))).not.to.be.reverted;
  });

  it("Should request deposit/redemption offchain failed if exceed limit in epoch", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);

    await usdyManager.setMaximumDepositAmountInEpoch(parseUnits("500", 18));
    await usdyManager.setMaximumRedemptionAmountInEpoch(parseUnits("500", 18));
    await usdyManager.setEpochInterval(3600);

    await usdyManager.grantRole(keccak256(Buffer.from("RELAYER_ROLE", "utf-8")), admin.address);
    await expect(usdyManager.requestSubscriptionServicedOffchain(addr1.address, parseUnits("500", 18), hexZeroPad(hexlify(1), 32))).not.to.be.reverted;
    await time.increase(100);

    await expect(usdyManager.requestSubscriptionServicedOffchain(addr1.address, parseUnits("500", 18), hexZeroPad(hexlify(2), 32))).to.be.revertedWith("DepositAmountExceedEpochMaximum");

    await time.increase(3600);
    await expect(usdyManager.requestSubscriptionServicedOffchain(addr1.address, parseUnits("500", 18), hexZeroPad(hexlify(2), 32))).not.to.be.reverted;

    await usdyManager.setPriceIdForDeposits([hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)], [1, 1]);
    let timestamp = await time.latest();
    await usdyManager.setClaimableTimestamp(timestamp + 1, [hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)]);
    await usdyManager.claimMint([hexZeroPad(hexlify(1), 32), hexZeroPad(hexlify(2), 32)]);

    await expect(usdyManager.connect(addr1).requestRedemptionServicedOffchain(parseUnits("500", 18), hexZeroPad(hexlify(1), 32))).not.to.be.reverted;

    await expect(usdyManager.connect(addr1).requestRedemptionServicedOffchain(parseUnits("500", 18), hexZeroPad(hexlify(1), 32))).to.be.revertedWith("RedemptionAmountExceedEpochMaximum");
    await time.increase(3600);

    await expect(usdyManager.connect(addr1).requestRedemptionServicedOffchain(parseUnits("500", 18), hexZeroPad(hexlify(2), 32))).not.to.be.reverted;
  });

  it("Should set deposit epoch limit failed if not admin", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);
    const limit = parseUnits("500", 18);
    await expect(usdyManager.connect(addr1).setMaximumDepositAmountInEpoch(limit)).to.be.reverted;
    await expect(usdyManager.setMaximumDepositAmountInEpoch(limit)).not.to.be.reverted;

    expect(await usdyManager.maximumDepositAmountInEpoch()).to.equal(limit);
  });

  it("Should set redemption epoch limit failed if not admin", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);
    const limit = parseUnits("1000", 18);
    await expect(usdyManager.connect(addr1).setMaximumRedemptionAmountInEpoch(limit)).to.be.reverted;
    await expect(usdyManager.setMaximumRedemptionAmountInEpoch(limit)).not.to.be.reverted;

    expect(await usdyManager.maximumRedemptionAmountInEpoch()).to.equal(limit);
  });

  it("Should set epoch interval failed if not admin", async function () {
    const { usdy, usdyManager, admin, addr1, addr2 } = await loadFixture(deployFixture);
    const interval = 7200;
    await expect(usdyManager.connect(addr1).setEpochInterval(interval)).to.be.reverted;
    await expect(usdyManager.setEpochInterval(interval)).not.to.be.reverted;

    let epochtime = parseInt((await time.latest()) / interval) * interval;

    expect(await usdyManager.epochInterval()).to.equal(interval);
    expect(await usdyManager.currentEpochTimestamp()).to.equal(epochtime);

  });

});
