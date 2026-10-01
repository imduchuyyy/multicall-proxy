// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract AdminRole {
    mapping(address => bool) public isAdmins;

    event AdminsUpdated(address[] admins, bool[] status);

    modifier onlyAdmin() {
        require(isAdmins[msg.sender], "AdminRole: caller is not admin");
        _;
    }

    function _setAdmins(address[] memory admins, bool[] memory isActives) internal {
        for (uint256 i = 0; i < admins.length; i++) {
            isAdmins[admins[i]] = isActives[i];
        }

        emit AdminsUpdated(admins, isActives);
    }

    function setAdmins(address[] memory admins, bool[] memory isActives) external virtual;
}
