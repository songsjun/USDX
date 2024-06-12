/**SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.16;

interface IAllowlist {
  function addToAllowlist(address[] calldata accounts) external;

  function removeFromAllowlist(address[] calldata accounts) external;

  function isAllowed(address account) external view returns (bool);

  /**
   * @notice Event emitted when addresses are added to the allowlist
   *
   * @param accounts The addresses that were added to the allowlist
   */
  event AllowedAddressesAdded(address[] accounts);

  /**
   * @notice Event emitted when addresses are removed from the allowlist
   *
   * @param accounts The addresses that were removed from the allowlist
   */
  event AllowedAddressesRemoved(address[] accounts);
}

