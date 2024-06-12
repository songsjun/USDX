/**SPDX-License-Identifier: BUSL-1.1*/
pragma solidity 0.8.16;
import "contracts/external/openzeppelin/contracts/access/Ownable2Step.sol";
import "contracts/interfaces/IAllowlist2.sol";


/**
 * @title Allowlist
 * @author Ondo Finance
 * @notice This contract manages the allowlist status for accounts.
 */
contract Allowlist is Ownable2Step, IAllowlist {
  constructor() {}

  // {<address> => is account allowed}
  mapping(address => bool) private allowedAddresses;

  /**
   * @notice Returns name of contract
   */
  function name() external pure returns (string memory) {
    return "Ondo Finance Allowlist Oracle";
  }

  /**
   * @notice Function to add a list of accounts to the allowlist
   *
   * @param accounts Array of addresses to allow
   */
  function addToAllowlist(address[] calldata accounts) external onlyOwner {
    for (uint256 i; i < accounts.length; ++i) {
      allowedAddresses[accounts[i]] = true;
    }
    emit AllowedAddressesAdded(accounts);
  }

  /**
   * @notice Function to remove a list of accounts from the allowlist
   *
   * @param accounts Array of addresses to unallow
   */
  function removeFromAllowlist(address[] calldata accounts) external onlyOwner {
    for (uint256 i; i < accounts.length; ++i) {
      allowedAddresses[accounts[i]] = false;
    }
    emit AllowedAddressesRemoved(accounts);
  }

  /**
   * @notice Function to check if an account is allowed
   *
   * @param addr Address to check
   *
   * @return True if account is allowed, false otherwise
   */
  function isAllowed(address addr) external view returns (bool) {
    return allowedAddresses[addr];
  }
}
