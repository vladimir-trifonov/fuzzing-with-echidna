// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../lib/erc1363-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "../lib/erc1363-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./IBondingToken.sol";

/**
 * @title BondingToken
 * @dev A token contract that implements a bonding curve for buying and selling tokens using Ether.
 * The contract uses ERC1363 to accept and transfer tokens, and implements the IBondingToken interface for buying and selling tokens.
 * The contract also implements the IERC1363Receiver interface to receive tokens that are sent to the contract.
 */
contract BondingToken is
    ERC1363,
    IERC1363Receiver,
    IBondingToken,
    ReentrancyGuard
{
    uint256 constant MULTIPLIER = 10 ** 6; // 1_000_000
    uint256 public constant MAX_BUY_AMOUNT_PER_TX = 1_000_000_000;
    uint256 public constant MAX_SUPPLY_THRESHOLD = 1_000_000_000_000;

    /**
     * @dev Throws if the caller is not the token contract.
     */
    modifier onlyAllowedToken() {
        require(msg.sender == address(this), "Only allowed token");
        _;
    }

    /**
     * @dev Initializes the contract with the given name and symbol.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    /**
     * @dev Checks if a contract implements the IBondingToken interface.
     * @param interfaceId The interface ID being checked.
     * @return A boolean indicating if the contract implements the IBondingToken interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1363) returns (bool) {
        return
            interfaceId == type(IBondingToken).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows a user to buy tokens by sending Ether to the contract.
     * @param amount The amount of tokens to buy.
     */
    function buy(uint256 amount) public payable nonReentrant {
        require(msg.value > 0, "Insufficient funds");
        require(amount > 0, "Amount is zero");
        require(amount <= MAX_BUY_AMOUNT_PER_TX, "Amount is too high");

        _buy(msg.sender, amount);
    }

    /**
     * @dev Internal function to buy tokens.
     * @param account The address of the account to receive the tokens.
     * @param amount The amount of tokens to buy.
     */
    function _buy(address account, uint256 amount) private {
        uint256 cost = calculatePriceForTokens(amount);
        require(msg.value >= cost, "Insufficient funds");
        _mint(account, amount);
        require(
            totalSupply() <= MAX_SUPPLY_THRESHOLD,
            "Max supply threshold reached"
        );
        if (msg.value > cost) {
            Address.sendValue(payable(account), msg.value - cost);
        }

        emit Buy(account, amount);
    }

    /**
     * @dev Allows a user to sell tokens back to the contract in exchange for Ether.
     * @param amount The amount of tokens to sell.
     */
    function sell(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient amount");

        bool success = transfer(address(this), amount);
        if (!success) {
            revert("Transfer failed");
        }
    }

    /**
     * @dev Internal function to sell tokens.
     * @param account The address of the account to receive the Ether.
     * @param amount The amount of tokens to sell.
     */
    function _sell(address account, uint256 amount) private {
        _burn(address(this), amount);
        uint256 payout = calculatePriceForTokens(amount);
        Address.sendValue(payable(account), payout);

        emit Sell(account, amount);
    }

    /**
     * @dev Overrides the ERC20 _afterTokenTransfer function to sell tokens when
     * they are transferred to the contract.
     * @param from The address of the account sending the tokens.
     * @param to The address of the account receiving the tokens.
     * @param amount The amount of tokens being transferred.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to == address(this)) {
            _sell(from, amount);
        }
    }

    /**
     * @dev Calculates the cost of buying a given amount of tokens.
     * @param amount The amount of tokens to calculate the cost for.
     * @return The cost of buying the given amount of tokens.
     */
    function calculatePriceForTokens(
        uint256 amount
    ) public view returns (uint256) {
        return calculatePriceForTokens(amount, totalSupply());
    }

    /**
     * @dev Calculates the amount of tokens that can be bought with a given amount of Ether.
     * @param amount The amount of Ether to calculate the token amount for.
     * @return The amount of tokens that can be bought with the given amount of Ether.
     */
    function calculateTokensForPrice(
        uint256 amount
    ) public view returns (uint256) {
        return calculateTokensForPrice(amount, totalSupply());
    }

    /**
     * @dev Called by ERC1363 to indicate that tokens have been transferred to the contract.
     */
    function onTransferReceived(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override onlyAllowedToken returns (bytes4) {
        return IERC1363Receiver.onTransferReceived.selector;
    }

    /**
     * @dev Allows the contract to receive Ether by calling the buy function with the amount of tokens
     * that can be bought with the received Ether.
     */
    fallback(
        bytes calldata _input
    ) external payable returns (bytes memory _output) {
        require(msg.value > 0, "Insufficient funds");
        uint256 amount = calculateTokensForPrice(msg.value);
        uint256 decoded = abi.decode(_input, (uint256));
        require(amount >= decoded, "Slippage is too high");
        buy(amount);
        return abi.encode(amount);
    }

    receive() external payable {
        revert("Not supported");
    }

    /**
     * @dev The `calculatePriceForTokens` function takes an amount of tokens and the current token supply
     * as input and returns the cost of purchasing that amount of tokens in Ether.
     *
     * priceForTokens = poolBalance(tokenSupply + amount) - poolBalance(tokenSupply)
     * poolBalance = ((tokenSupply + 1) ^ 3) / 3
     */
    function calculatePriceForTokens(
        uint256 amount,
        uint256 supply
    ) public pure returns (uint256) {
        return
            ((((supply + amount + 1) ** 3 - (supply + 1) ** 3) * MULTIPLIER) /
                3) - (amount / 3);
    }

    /**
     * @dev The `calculateTokensForPrice` function takes an amount of Ether and the current token supply
     * as input and returns the number of tokens that can be purchased with that amount of Ether.
     */
    function calculateTokensForPrice(
        uint256 amount,
        uint256 supply
    ) public pure returns (uint256) {
        uint256 root = cubeRoot((amount / MULTIPLIER) * 3 + (supply + 1) ** 3);
        require(root >= supply + 1, "Amount is too low");
        return root - supply - 1;
    }

    /**
     * @dev The `cubeRoot` function calculates the cube root of a non-negative integer using the nthRoot
     * function implemented using the binary search algorithm.
     */
    function cubeRoot(uint256 n) internal pure returns (uint256) {
        return nthRoot(n, 3);
    }

    /**
     * @dev  The nthRoot function calculates the integer n-th root of a non-negative integer x
     * using the binary search algorithm. The function begins by initializing the search
     * range to [0, x]. At each iteration of the loop, the function calculates the midpoint
     * mid of the search range and raises it to the n-th power. If mid^n is equal to x,
     * the function returns mid as the result. If mid^n is less than x, the search range is
     * updated to the right half of the previous range. If mid^n is greater than x, the search
     * range is updated to the left half of the previous range. The loop terminates when
     * the search range is reduced to a single integer value, which is then returned as the
     * largest integer y such that y^n <= x.
     *
     * Note: The binary search algorithm implemented in the nthRoot function has a time complexity
     * of O(log x), which makes it more efficient than Newton's method for large values of x.
     * However, the binary search algorithm can only calculate the integer n-th root of a
     * non-negative integer x. It cannot be used to calculate the real-valued n-th root of a
     * non-negative real number x, which is a limitation of the algorithm.
     */
    function nthRoot(uint256 x, uint256 n) internal pure returns (uint256) {
        require(n > 0, "Root must be positive");

        if (x == 0) {
            return 0;
        }

        uint256 left = 0;
        uint256 right = x;

        while (left < right) {
            uint256 mid = (left + right) / 2;
            uint256 midToNthPower = mid ** n;

            if (midToNthPower == x) {
                return mid;
            } else if (midToNthPower < x) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        return left - 1;
    }
}
