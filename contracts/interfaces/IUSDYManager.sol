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

interface IUSDYManager {
  // struct to save user deposit or redemption amount and epoch
  struct UserOperator {
    uint256 amount;
    uint256 epochTimestamp;
  }

  function setClaimableTimestamp(
    uint256 claimDate,
    bytes32[] calldata depositIds
  ) external;

  function setMaximumDepositAmountInEpoch(
    uint256 _maximumDepositAmountInEpoch
  ) external;

  function setMaximumRedemptionAmountInEpoch(
    uint256 _maximumRedemptionAmountInEpoch
  ) external;

  function setEpochStartTime(
    uint256 _epochStartTime
  ) external;

  function setEpochInterval(
    uint256 _epochInterval
  ) external;

  /**
   * @notice Event emitted when claimable timestamp is set
   *
   * @param claimTimestamp The timestamp at which the mint can be claimed
   * @param depositId      The depositId that can claim at the given 
                           `claimTimestamp`
   */
  event ClaimableTimestampSet(
    uint256 indexed claimTimestamp,
    bytes32 indexed depositId
  );

  /**
   * @notice Event emitted when a new epoch deposit maximum is set.
   *         All units are in 1e18
   *
   * @param oldEpochDepositMaximum The old deposit maximum value
   * @param newEpochDepositMaximum The new deposit maximum value
   */
  event MaximumDepositAmountInEpochSet(
    uint256 oldEpochDepositMaximum,
    uint256 newEpochDepositMaximum
  );

  /**
   * @notice Event emitted when a new epoch redemption maximum is set.
   *         All units are in 1e18
   *
   * @param oldEpochRedemptionMaximum The old redemption maximum value
   * @param newEpochRedemptionMaximum The new redemption maximum value
   */
  event MaximumRedemptionAmountInEpochSet(
    uint256 oldEpochRedemptionMaximum,
    uint256 newEpochRedemptionMaximum
  );


  /**
   * @notice Event emitted when a new epoch start time is set.
   *
   * @param oldEpochStartTime The old epoch start timestamp value
   * @param newEpochStartTime The new epoch start timestamp value
   */
  event EpochStartTimestampSet(
    uint256 oldEpochStartTime,
    uint256 newEpochStartTime
  );

  /**
   * @notice Event emitted when a new epoch interval is set.
   *
   * @param oldEpochInterval The old epoch interval value
   * @param newEpochInterval The new epoch interval value
   */
  event EpochIntervalSet(
    uint256 oldEpochInterval,
    uint256 newEpochInterval
  );

  /// ERRORS ///
  error MintNotYetClaimable();
  error ClaimableTimestampInPast();
  error ClaimableTimestampNotSet();
  error EpochStartTimestampNotPast();
  error DepositAmountExceedEpochMaximum();
  error RedemptionAmountExceedEpochMaximum();
}
