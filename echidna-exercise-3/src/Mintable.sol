// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.0;

import "./Token.sol";

contract MintableToken is Token {
    int256 public totalMinted;
    int256 public totalMintable;

    constructor(int256 totalMintable_) public {
        totalMintable = totalMintable_;
    }

    function mint(uint256 value) public onlyOwner {
        require(int256(value) + totalMinted >= totalMinted);
        require(int256(value) + totalMinted < totalMintable);
        totalMinted += int256(value);
        balances[msg.sender] += value;
    }
}