// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.0;

import "./Mintable.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.5.0
///      echidna ./src/Template.sol --contract TestToken --config ./config.yaml 
///      ```
contract TestToken is MintableToken {
    address echidna = msg.sender;

    constructor() public MintableToken(10_000) {
      owner = echidna;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[msg.sender] <= 10_000;
    }
}