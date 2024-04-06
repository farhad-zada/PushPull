// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

error InsufficientAllowance();
error TransferFail();
error InsufficientBalance();

contract PushPull is Initializable, OwnableUpgradeable {
    uint256 public totalOffChain;
    uint256 public totalOnChain;
    IERC20Upgradeable public token;

    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "PushPull: only admin");
        _;
    }

    event OffChain(address indexed to, uint256 amount, uint256 timestamp);
    event OnChain(address indexed to, uint256 amount, uint256 timestamp);
    event Admin(address indexed admin, bool status);
    event RenounceAdmin(address indexed admin);
    event Withdraw(address indexed to, uint256 amount, uint256 timestamp);

    function initialize(IERC20Upgradeable _token) public initializer {
        __Ownable_init();
        token = _token;
        setAdmin(msg.sender, true);
    }

    function toOffChain(uint256 amount) public {
        uint256 totalApproved = token.allowance(msg.sender, address(this));
        if (totalApproved < amount) revert InsufficientAllowance();
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFail();
        totalOffChain += amount;
        emit OffChain(msg.sender, amount, block.timestamp);
    }

    function toOnChain(
        address to,
        uint256 amount
    ) public onlyAdmin returns (bool success) {
        success = token.transfer(to, amount);
        if (!success) revert TransferFail();
        totalOnChain += amount;
        emit OnChain(to, amount, block.timestamp);
    }

    function setToken(address _token) public onlyOwner {
        token = IERC20Upgradeable(_token);
    }

    function setAdmin(address _admin, bool _status) public onlyOwner {
        admins[_admin] = _status;
        emit Admin(_admin, _status);
    }

    function renounceAdmin() public onlyAdmin {
        admins[msg.sender] = false;
        emit RenounceAdmin(msg.sender);
    }

    function withdraw(
        address _token,
        address payable to,
        uint256 amount
    ) public payable onlyOwner returns (bool success) {
        if (_token == address(0)) {
            if (amount > address(this).balance) revert InsufficientBalance();
            (success, ) = to.call{value: amount}("");
            if (!success) revert TransferFail();
        } else {
            if (amount > IERC20Upgradeable(_token).balanceOf(address(this)))
                revert InsufficientBalance();
            success = IERC20Upgradeable(_token).transfer(to, amount);
            if (!success) revert TransferFail();
        }
        emit Withdraw(to, amount, block.timestamp);
    }
}
