// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../src/BondingToken.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.19
///      echidna ./test/TestBondingToken.sol --contract TestBondingToken --config ./config.yaml
///      ```
contract TestBondingToken {
    BondingToken bondingToken;

    event Balance(uint256 amount, uint256 price, uint256 balance);
    event Payout(uint256 amount, uint256 tokens, uint256 decoded);

    constructor() payable {
        bondingToken = new BondingToken("TestBondingToken", "TBT");
    }

    function test_buy(uint256 amount) public {
        amount = amount > 0 ? amount : bondingToken.MAX_BUY_AMOUNT_PER_TX();
        amount = 1 + (amount % bondingToken.MAX_BUY_AMOUNT_PER_TX());
        uint256 balance = bondingToken.balanceOf(address(this));
        uint256 cost = bondingToken.calculatePriceForTokens(amount);
        bondingToken.buy{value: cost}(amount);

        assert(bondingToken.balanceOf(address(this)) == balance + amount);
    }

    function test_supply(uint256 amount, bool isBuy) public {
        amount = amount > 0 ? amount : bondingToken.MAX_BUY_AMOUNT_PER_TX();
        if (isBuy) {
            amount = 1 + (amount % bondingToken.MAX_BUY_AMOUNT_PER_TX());
            uint256 cost = bondingToken.calculatePriceForTokens(amount);
            bondingToken.buy{value: cost}(amount);
        } else {
            uint256 balance = bondingToken.balanceOf(address(this));
            if (balance > 0) {
                amount = 1 + (amount % balance);
                amount = amount > 0 ? amount : balance;
                try bondingToken.sell(amount) {
                    assert(true);
                } catch {
                    emit Balance(
                        amount,
                        bondingToken.calculatePriceForTokens(amount),
                        address(bondingToken).balance
                    );
                    assert(false);
                }
            }
        }

        assert(
            bondingToken.totalSupply() <= bondingToken.MAX_SUPPLY_THRESHOLD()
        );
    }

    function test_balance(uint256 amount) public {
        amount = amount > 0 ? amount : bondingToken.MAX_BUY_AMOUNT_PER_TX();
        uint256 initialBalance = bondingToken.balanceOf(address(this));
        uint256 initialEth = address(this).balance;
        amount = 1 + (amount % bondingToken.MAX_BUY_AMOUNT_PER_TX());
        uint256 cost = bondingToken.calculatePriceForTokens(amount);
        bondingToken.buy{value: cost}(amount);
        try bondingToken.sell(amount) {
            assert(true);
        } catch {
            assert(false);
        }

        assert(bondingToken.balanceOf(address(this)) == initialBalance);
        assert(initialEth == address(this).balance);
    }

    function test_payout(uint256 amount) public {
        amount = 1 + (amount % 100);
        uint256 initSupply = bondingToken.totalSupply();
        uint256 balance = bondingToken.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;
        uint256 tokenEthBalance = address(bondingToken).balance;

        if (amount == 0) {
            amount = 1 + (amount % ethBalance);
        } else {
            amount = amount * 10 ** 18;
        }
        uint256 tokens = bondingToken.calculateTokensForPrice(amount);

        require(tokens > 0 && tokens <= bondingToken.MAX_BUY_AMOUNT_PER_TX());

        (bool success, bytes memory output) = address(bondingToken).call{
            value: amount
        }(abi.encode(tokens));
        uint256 bought = bondingToken.balanceOf(address(this)) - balance;
        uint256 cost = bondingToken.calculatePriceForTokens(bought, initSupply);
        uint256 decoded = abi.decode(output, (uint256));

        emit Payout(amount, tokens, decoded);

        assert(success);
        assert(decoded == tokens);
        assert(address(this).balance == ethBalance - cost);
        assert(address(bondingToken).balance == tokenEthBalance + cost);
    }

    function test_transfer(uint256 amount) public {
        uint256 balance = bondingToken.balanceOf(address(this));
        amount = 1 + (amount % balance);
        uint256 ethBalance = address(this).balance;
        require(amount > 0, "balance is zero");

        bondingToken.transfer(address(bondingToken), amount);
        uint256 payout = bondingToken.calculatePriceForTokens(amount);

        assert(bondingToken.balanceOf(address(this)) == balance - amount);
        assert(address(this).balance == ethBalance + payout);
    }

    receive() external payable {}
}
