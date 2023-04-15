// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.0;

import "./Token.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.5.0
///      echidna ./src/Template.sol
///      ```
contract TestToken is Token {
    address echidna = tx.origin;

    constructor() public {
        balances[echidna] = 10000;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[echidna] <= 10000;
    }
}