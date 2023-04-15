// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Dex.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.19
///      echidna ./src/TestDex.sol --contract TestDex --config ./config.yaml
///      ```
contract TestDex {
    address echidna = address(this);

    Dex dex;
    SwappableToken token1;
    SwappableToken token2;

    constructor() {
        dex = new Dex();
        token1 = new SwappableToken(address(dex), "Token 1", "T1", 110);
        token2 = new SwappableToken(address(dex), "Token 2", "T2", 110);

        dex.setTokens(address(token1), address(token2));

        token1.approve(echidna, address(dex), 2 ** 256 - 1);
        token2.approve(echidna, address(dex), 2 ** 256 - 1);

        dex.addLiquidity(address(token1), 100);
        dex.addLiquidity(address(token2), 100);

        dex.renounceOwnership();
    }

    function test_swap(uint amount, bool token1From) public {
        uint256 balance1 = token1.balanceOf(echidna);
        uint256 balance2 = token2.balanceOf(echidna);

        uint256 amount1 = 1 + (amount % balance1);
        uint256 amount2 = 1 + (amount % balance2);

        if (token1From && balance1 >= amount1) {
            dex.swap(address(token1), address(token2), amount1);
        } else if (balance2 >= amount2) {
            dex.swap(address(token2), address(token1), amount2);
        } else if (balance1 >= amount1) {
            dex.swap(address(token1), address(token2), amount1);
        } 

        assert(dex.balanceOf(address(token1), address(dex)) > 0);
        assert(dex.balanceOf(address(token2), address(dex)) > 0);
    }
}
