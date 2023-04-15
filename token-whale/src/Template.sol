// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.4.21;

import "./TokenWhaleChallenge.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.4.26
///      echidna ./src/Template.sol --contract TestToken --config ./config.yaml
///      ```
contract TestToken is TokenWhaleChallenge {
    address echidna = msg.sender;

    constructor() public TokenWhaleChallenge(echidna) {}

    function echidna_property() public view returns (bool) {
        return !super.isComplete();
    }
}
