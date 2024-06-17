// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorBlocklist {
    event BlocklistAdded(address blocklist);
    event BlocklistRemoved(address blocklist);

    function addBlocklist(address blocklist) external;
    function removeBlocklist(address blocklist) external;
}