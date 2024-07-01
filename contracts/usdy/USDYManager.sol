/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

pragma solidity 0.8.16;

import "contracts/RWAHubOffChainRedemptions.sol";
import "contracts/usdy/blocklist/BlocklistClient.sol";
import "contracts/interfaces/IUSDYManager.sol";

contract USDYManager is
  RWAHubOffChainRedemptions,
  BlocklistClient,
  IUSDYManager
{
  bytes32 public constant TIMESTAMP_SETTER_ROLE =
    keccak256("TIMESTAMP_SETTER_ROLE");

  mapping(bytes32 => uint256) public depositIdToClaimableTimestamp;

  // The maximum deposit amount for each user in one epoch
  uint256 public maximumDepositAmountInEpoch;
  // The maximum redemption amount for each user in one epoch
  uint256 public maximumRedemptionAmountInEpoch;
  // The epoch start timestamp
  uint256 public epochStartTimestamp;
  // The time interval of epoch
  uint256 public epochInterval;

  // The maximum deposit amount for all users in one epoch
  uint256 public totalMaximumDepositAmountInEpoch;
  // The maximum redemption amount for all users in one epoch
  uint256 public totalMaximumRedemptionAmountInEpoch;

  mapping(address => UserOperator) public depositEpochUserOperator;
  mapping(address => UserOperator) public redemptionEpochUserOperator;

  UserOperator public totalDepositEpochOperater;
  UserOperator public totalRedemptionEpochOperator;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    address _assetRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount,
    uint256 _maximumDepositAmount,
    uint256 _maximumRedemptionAmount,
    address blocklist
  )
    RWAHubOffChainRedemptions(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _assetRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount,
      _maximumDepositAmount,
      _maximumRedemptionAmount
    )
    BlocklistClient(blocklist)
  {}

  /**
   * @notice Function to enforce blocklist and sanctionslist restrictions to be
   *         implemented on calls to `requestSubscription` and
   *         `claimRedemption`
   *
   * @param account The account to check blocklist and sanctions list status
   *                for
   */
  function _checkRestrictions(address account) internal view override {
    if (_isBlocked(account)) {
      revert BlockedAccount();
    }
  }

  /**
   * @notice Internal hook that is called by `claimMint` to enforce the time
   *         at which a user can claim their USDY
   *
   * @param depositId The depositId to check the claimable timestamp for
   *
   * @dev This function will call the `_claimMint` function in the parent
   *      once USDY-specific checks have been made
   */
  function _claimMint(bytes32 depositId) internal virtual override {
    if (depositIdToClaimableTimestamp[depositId] == 0) {
      revert ClaimableTimestampNotSet();
    }

    if (depositIdToClaimableTimestamp[depositId] > block.timestamp) {
      revert MintNotYetClaimable();
    }

    super._claimMint(depositId);
    delete depositIdToClaimableTimestamp[depositId];
  }

  /**
   * @notice Update blocklist address
   *
   * @param blocklist The new blocklist address
   */
  function setBlocklist(
    address blocklist
  ) external override onlyRole(MANAGER_ADMIN) {
    _setBlocklist(blocklist);
  }

  /**
   * @notice Set the claimable timestamp for a list of depositIds
   *
   * @param claimTimestamp The timestamp at which the deposit can be claimed
   * @param depositIds The depositIds to set the claimable timestamp for
   */
  function setClaimableTimestamp(
    uint256 claimTimestamp,
    bytes32[] calldata depositIds
  ) external onlyRole(TIMESTAMP_SETTER_ROLE) {
    if (claimTimestamp < block.timestamp) {
      revert ClaimableTimestampInPast();
    }

    uint256 depositsSize = depositIds.length;
    for (uint256 i; i < depositsSize; ++i) {
      depositIdToClaimableTimestamp[depositIds[i]] = claimTimestamp;
      emit ClaimableTimestampSet(claimTimestamp, depositIds[i]);
    }
  }

  function setMaximumDepositAmountInEpoch(
    uint256 _maximumDepositAmountInEpoch
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldAmount = maximumDepositAmountInEpoch;
    maximumDepositAmountInEpoch = _maximumDepositAmountInEpoch;
    emit MaximumDepositAmountInEpochSet(oldAmount, _maximumDepositAmountInEpoch);
  }

  function setMaximumRedemptionAmountInEpoch(
    uint256 _maximumRedemptionAmountInEpoch
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldAmount = maximumRedemptionAmountInEpoch;
    maximumRedemptionAmountInEpoch = _maximumRedemptionAmountInEpoch;
    emit MaximumRedemptionAmountInEpochSet(oldAmount, _maximumRedemptionAmountInEpoch);
  }

  function setEpochStartTime(
    uint256 _epochStartTime
  ) external onlyRole(MANAGER_ADMIN) {
    if (_epochStartTime >= block.timestamp) {
      revert EpochStartTimestampNotPast();
    }

    uint256 oldtime = epochStartTimestamp;
    epochStartTimestamp = _epochStartTime;
    emit EpochStartTimestampSet(oldtime, _epochStartTime);
  }

  function setEpochInterval(
    uint256 _epochInterval
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldInterval = epochInterval;
    epochInterval = _epochInterval;
    emit EpochIntervalSet(oldInterval, _epochInterval);
  }

  function setTotalMaximumDepositAmountInEpoch(
    uint256 _totalMaximumDepositAmountInEpoch
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldAmount = totalMaximumDepositAmountInEpoch;
    totalMaximumDepositAmountInEpoch = _totalMaximumDepositAmountInEpoch;
    emit TotalMaximumDepositAmountInEpochSet(oldAmount, _totalMaximumDepositAmountInEpoch);
  }

  function setTotalMaximumRedemptionAmountInEpoch(
    uint256 _totalMaximumRedemptionAmountInEpoch
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldAmount = totalMaximumRedemptionAmountInEpoch;
    totalMaximumRedemptionAmountInEpoch = _totalMaximumRedemptionAmountInEpoch;
    emit TotalMaximumDepositAmountInEpochSet(oldAmount, _totalMaximumRedemptionAmountInEpoch);
  }

  function _udpateEpoch() internal view returns (uint256) {
    uint256 currentEpochTimestamp = 0;
    if (epochInterval != 0 && epochStartTimestamp != 0) {
      currentEpochTimestamp = (block.timestamp - epochStartTimestamp) / epochInterval * epochInterval;
    }

    return currentEpochTimestamp;
  }

  function _checkAndUpdateDepositLimit(address account, uint256 amount) internal {
    if (epochInterval == 0 || maximumDepositAmountInEpoch == 0) return;

    uint256 currentEpochTimestamp = _udpateEpoch();

    UserOperator memory operator = depositEpochUserOperator[account];
    if (currentEpochTimestamp > operator.epochTimestamp) {
      operator.amount = 0;
    }

    operator.amount += amount;
    if (operator.amount > maximumDepositAmountInEpoch) {
      revert DepositAmountExceedEpochMaximum();
    }
    operator.epochTimestamp = currentEpochTimestamp;
    depositEpochUserOperator[account] = operator;
  }

  function _checkAndUpdateRedemptionLimit(address account, uint256 amount) internal {
    if (epochInterval == 0 || maximumRedemptionAmountInEpoch == 0) return;

    uint256 currentEpochTimestamp = _udpateEpoch();

    UserOperator memory operator = redemptionEpochUserOperator[account];
    if (currentEpochTimestamp > operator.epochTimestamp) {
      operator.amount = 0;
    }

    operator.amount += amount;
    if (operator.amount > maximumRedemptionAmountInEpoch) {
      revert RedemptionAmountExceedEpochMaximum();
    }
    operator.epochTimestamp = currentEpochTimestamp;
    redemptionEpochUserOperator[account] = operator;
  }

  function _checkAndUpdateTotalDepositLimit(uint256 amount) internal {
    if (epochInterval == 0 || totalMaximumDepositAmountInEpoch == 0) return;

    uint256 currentEpochTimestamp = _udpateEpoch();

    uint256 totalAmount = amount;
    if (currentEpochTimestamp <= totalDepositEpochOperater.epochTimestamp) {
      totalAmount += totalDepositEpochOperater.amount;
    }

    if (totalAmount > totalMaximumDepositAmountInEpoch) {
      revert DepositAmountExceedEpochTotalMaximum();
    }
    totalDepositEpochOperater.epochTimestamp = currentEpochTimestamp;
    totalDepositEpochOperater.amount = totalAmount;
  }

  function _checkAndUpdateTotalRedemptionLimit(uint256 amount) internal {
    if (epochInterval == 0 || totalMaximumRedemptionAmountInEpoch == 0) return;

    uint256 currentEpochTimestamp = _udpateEpoch();

    uint256 totalAmount = amount;
    if (currentEpochTimestamp <= totalRedemptionEpochOperator.epochTimestamp) {
      totalAmount += totalRedemptionEpochOperator.amount;
    }

    if (totalAmount > totalMaximumRedemptionAmountInEpoch) {
      revert RedemptionAmountExceedEpochTotalMaximum();
    }
    totalRedemptionEpochOperator.epochTimestamp = currentEpochTimestamp;
    totalRedemptionEpochOperator.amount = totalAmount;
  }


  /*//////////////////////////////////////////////////////////////
            Override the Subscription/Redemption Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function used by users to request subscription to the fund
   *
   * @param amount The amount of collateral one wished to deposit
   */
  function requestSubscription(
    uint256 amount
  )
    public
    virtual
    override
  {
    _checkAndUpdateTotalDepositLimit(amount);
    _checkAndUpdateDepositLimit(msg.sender, amount);
    super.requestSubscription(amount);
  }


  /**
   * @notice Function used by users to request a redemption from the fund
   *
   * @param amount The amount (in units of `rwa`) that a user wishes to redeem
   *               from the fund
   */
  function requestRedemption(
    uint256 amount
  )
    public
    virtual
    override
  {
    _checkAndUpdateTotalRedemptionLimit(amount);
    _checkAndUpdateRedemptionLimit(msg.sender, amount);
    super.requestRedemption(amount);
  }

  /**
   * @notice Request a redemption to be serviced off chain.
   *
   * @param amountRWATokenToRedeem The requested redemption amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestRedemptionServicedOffchain(
    uint256 amountRWATokenToRedeem,
    bytes32 offChainDestination
  )
    public
    virtual
    override
  {
    _checkAndUpdateTotalRedemptionLimit(amountRWATokenToRedeem);
    _checkAndUpdateRedemptionLimit(msg.sender, amountRWATokenToRedeem);
    super.requestRedemptionServicedOffchain(amountRWATokenToRedeem, offChainDestination);
  }

  /**
   * @notice Request a subscription to be serviced off chain.
   *
   * @param user                   The address of the user who made the deposit
   * @param amount                 The requested subscription amount
   * @param offChainDestination    A hash of the destination to which
   *                               the request should be serviced to.
   */
  function requestSubscriptionServicedOffchain(
    address user,
    uint256 amount,
    bytes32 offChainDestination
  )
    public
    virtual
    override
  {
    _checkAndUpdateTotalDepositLimit(amount);
    _checkAndUpdateDepositLimit(user, amount);
    super.requestSubscriptionServicedOffchain(user, amount, offChainDestination);
  }

}
