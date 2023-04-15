// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.0;

import "./Token.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.5.0
///      echidna ./src/Template.sol --contract TestToken --test-mode assertion
///      ```
///      or by providing a config
///      ```
///      echidna ./src/Template.sol --contract TestToken --config ./config.yaml
///      ```
contract TestToken is Token {
    constructor() public {
        balances[msg.sender] = 2**256 - 1;
    }

    function transfer(address to, uint256 value) public {
        uint256 fromBalance = balances[msg.sender];
        uint256 toBalance = balances[to];
        super.transfer(to, value);
        assert(balances[msg.sender] <= fromBalance);
        assert(balances[to] >= toBalance);
    }
}