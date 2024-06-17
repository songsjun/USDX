// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/access/Ownable2Step.sol";
import "contracts/interfaces/IBlocklist.sol";
import "contracts/interfaces/IAggregatorBlocklist.sol";

/**
 * @title AggregatorBlocklist
 * @notice This contract aggregates multiple blocklists and checks if an address is blocked by any of them.
 */
contract AggregatorBlocklist is Ownable2Step, IAggregatorBlocklist, IBlocklist {
    address[] public blocklists;
    mapping(address => bool) private blocklistExists;

    /**
     * @notice Add a new blocklist contract to the aggregator.
     *
     * @param blocklist Address of the blocklist contract to add
     */
    function addBlocklist(address blocklist) external onlyOwner {
        require(blocklist != address(0), "Invalid blocklist address");
        require(!blocklistExists[blocklist], "Blocklist already exists");
        
        blocklists.push(blocklist);
        blocklistExists[blocklist] = true;
        emit BlocklistAdded(blocklist);
    }

    /**
     * @notice Remove a blocklist contract from the aggregator.
     *
     * @param blocklist Address of the blocklist contract to remove
     */
    function removeBlocklist(address blocklist) external onlyOwner {
        require(blocklistExists[blocklist], "Blocklist does not exist");

        for (uint256 i = 0; i < blocklists.length; i++) {
            if (blocklists[i] == blocklist) {
                blocklists[i] = blocklists[blocklists.length - 1];
                blocklists.pop();
                delete blocklistExists[blocklist];
                emit BlocklistRemoved(blocklist);
                break;
            }
        }
    }

    /**
     * @notice Check if an address is blocked by any of the aggregated blocklists.
     *
     * @param addr Address to check
     *
     * @return True if the address is blocked by any blocklist, false otherwise
     */
    function isBlocked(address addr) external view override returns (bool) {
        for (uint256 i = 0; i < blocklists.length; i++) {
            if (IBlocklist(blocklists[i]).isBlocked(addr)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Empty implementation of addToBlocklist to satisfy IBlocklist interface.
     *
     * @param accounts Addresses to add to the blocklist
     */
    function addToBlocklist(address[] calldata accounts) external override {
        // No implementation needed for aggregator
    }

    /**
     * @notice Empty implementation of removeFromBlocklist to satisfy IBlocklist interface.
     *
     * @param accounts Addresses to remove from the blocklist
     */
    function removeFromBlocklist(address[] calldata accounts) external override {
        // No implementation needed for aggregator
    }
}