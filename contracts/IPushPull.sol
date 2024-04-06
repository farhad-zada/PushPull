// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IPushPull {
    function totalOffChain() external view returns (uint256);

    function totalOnChain() external view returns (uint256);

    function token() external view returns (IERC20Upgradeable);

    function admins(address) external view returns (bool);

    function toOffChain(uint256 amount) external;

    function toOnChain(
        address to,
        uint256 amount
    ) external returns (bool success);

    function setToken(address _token) external;

    function setAdmin(address _admin, bool _status) external;

    function renounceAdmin() external;

    function withdraw(
        address _token,
        address payable to,
        uint256 amount
    ) external returns (bool success);
}
