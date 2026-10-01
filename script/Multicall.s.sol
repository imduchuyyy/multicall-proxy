// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Multicall} from "../src/Multicall.sol";

contract MulticallScript is Script {
    function run() public returns (Multicall mc) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        address owner = vm.envOr("OWNER", deployer);
        address[] memory admins = vm.envOr("ADMINS", ",", new address[](0));

        vm.startBroadcast(pk);
        Multicall impl = new Multicall();
        mc = Multicall(payable(address(new ERC1967Proxy(address(impl), abi.encodeCall(Multicall.initialize, (deployer))))));
        if (admins.length > 0) {
            bool[] memory actives = new bool[](admins.length);
            for (uint256 i = 0; i < admins.length; i++) {
                actives[i] = true;
            }
            mc.setAdmins(admins, actives);
        }
        if (owner != deployer) mc.transferOwnership(owner);
        vm.stopBroadcast();

        console.log("implementation", address(impl));
        console.log("proxy", address(mc));
        console.log("owner", mc.owner());
    }
}
