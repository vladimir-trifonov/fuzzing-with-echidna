// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.0;

contract Ownable {
    address public owner = msg.sender;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

contract Pausable is Ownable {
    bool private _paused;

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOwner {
        _paused = true;
    }

    function resume() public onlyOwner {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: Contract is paused.");
        _;
    }
}

contract Token is Ownable, Pausable {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 value) public whenNotPaused {
        require(balances[msg.sender] >= value, "Insufficient balance.");
        balances[msg.sender] -= value;
        balances[to] += value;
    }
}