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


}
