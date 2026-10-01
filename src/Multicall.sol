// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AdminRole} from "./AdminRole.sol";

contract Multicall is Initializable, UUPSUpgradeable, Ownable, AdminRole {
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(address owner_) external initializer {
        _transferOwnership(owner_);
    }

    function setAdmins(address[] memory admins, bool[] memory isActives) external override onlyOwner {
        require(admins.length == isActives.length, "Multicall: length mismatch");
        _setAdmins(admins, isActives);
    }

    function multicall(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas)
        external
        payable
        onlyAdmin
        returns (bytes[] memory results)
    {
        require(targets.length == values.length && targets.length == datas.length, "Multicall: length mismatch");
        results = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            (bool ok, bytes memory ret) = targets[i].call{value: values[i]}(datas[i]);
            results[i] = Address.verifyCallResult(ok, ret, "Multicall: call failed");
        }
    }

    function multiview(address[] calldata targets, bytes[] calldata datas)
        external
        view
        returns (bytes[] memory results)
    {
        require(targets.length == datas.length, "Multicall: length mismatch");
        results = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            results[i] = Address.functionStaticCall(targets[i], datas[i]);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
