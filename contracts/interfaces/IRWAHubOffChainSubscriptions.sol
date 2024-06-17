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

interface IRWAHubOffChainSubscriptions {
  function requestSubscriptionServicedOffchain(
    address user,
    uint256 amount,
    bytes32 offChainDestination
  ) external;

  function pauseOffChainSubscription() external;

  function unpauseOffChainSubscription() external;

  function setOffChainSubscriptionMinimum(uint256 minimumAmount) external;

  /**
   * @notice Event emitted when offchain subscription request is submitted
   *
   * @param user                      The user requesting to mint
   * @param collateralAmountDeposited The total amount deposited
   * @param depositAmountAfterFee     The value deposited - fee
   * @param feeAmount                 The fee amount taken
   *                                  (units of collateral)
   * @param offChainDestination       Hash of destination to which the 
   *                                  request should be serviced to
   */
  event SubscriptionRequestedServicedOffChain(
    address indexed user,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    bytes32 offChainDestination
  );



  /**
   * @notice Event emitted when the off chain subscription feature is
   *         paused
   *
   * @param caller Address which initiated the pause
   */
  event OffChainSubscriptionPaused(address caller);

  /**
   * @notice Event emitted when the off chain subscription feature is
   *         unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event OffChainSubscriptionUnpaused(address caller);

  /**
   * @notice Event emitted when the off chain subscription minimum is
   *         updated
   *
   * @param oldMinimum the old minimum subscription amount
   * @param newMinimum the new minimum subscription amount
   */
  event OffChainSubscriptionMinimumSet(uint256 oldMinimum, uint256 newMinimum);
}
