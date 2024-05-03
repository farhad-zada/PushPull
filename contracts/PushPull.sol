// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

error OnlyAdmin();

contract PushPull is Initializable, OwnableUpgradeable {
    uint256 public lastOffId;
    uint256 public lastOnId;
    uint256 public totalOffChain;
    uint256 public totalOnChain;
    IERC20Upgradeable public token;

    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert OnlyAdmin();
        _;
    }

    event OffChain(address indexed to, uint256 id, uint256 amount);
    event OnChain(address indexed to, uint256 id, uint256 amount);
    event Admin(address indexed admin, bool status);
    event RenounceAdmin(address indexed admin);
    event Withdraw(address indexed to, uint256 amount, uint256 timestamp);

    function initialize(IERC20Upgradeable _token) public initializer {
        __Ownable_init();
        token = _token;
        setAdmin(msg.sender, true);
    }

    function toOffChain(uint256 amount) public returns (bool success) {
        success = token.transferFrom(msg.sender, address(this), amount);
        totalOffChain += amount;
        lastOffId++;
        emit OffChain(msg.sender, lastOffId, amount);
    }

    function toOnChain(
        address to,
        uint256 amount
    ) public onlyAdmin returns (bool success) {
        success = token.transfer(to, amount);
        totalOnChain += amount;
        lastOnId++;
        emit OnChain(to, amount, lastOnId);
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
            (success, ) = to.call{value: amount}("");
        } else {
            success = IERC20Upgradeable(_token).transfer(to, amount);
        }
        emit Withdraw(to, amount, block.timestamp);
    }

    receive() external payable {}
}
