// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Multicall} from "../src/Multicall.sol";
import {Counter} from "../src/Counter.sol";

contract MulticallTest is Test {
    Multicall mc;
    Counter a;
    Counter b;
    address owner = address(0xA11CE);
    address admin = address(0xAD);

    function setUp() public {
        Multicall impl = new Multicall();
        mc = Multicall(payable(address(new ERC1967Proxy(address(impl), abi.encodeCall(Multicall.initialize, (owner))))));
        a = new Counter();
        b = new Counter();

        address[] memory admins = new address[](1);
        bool[] memory actives = new bool[](1);
        admins[0] = admin;
        actives[0] = true;
        vm.prank(owner);
        mc.setAdmins(admins, actives);
    }

    function _calls() internal view returns (address[] memory t, uint256[] memory v, bytes[] memory d) {
        t = new address[](3);
        v = new uint256[](3);
        d = new bytes[](3);
        t[0] = address(a);
        d[0] = abi.encodeCall(Counter.setNumber, (41));
        t[1] = address(a);
        d[1] = abi.encodeCall(Counter.increment, ());
        t[2] = address(0xBEEF);
        v[2] = 1 ether;
    }

    function test_Multicall() public {
        (address[] memory t, uint256[] memory v, bytes[] memory d) = _calls();
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        mc.multicall{value: 1 ether}(t, v, d);
        assertEq(a.number(), 42);
        assertEq(address(0xBEEF).balance, 1 ether);
    }

    function test_MulticallOnlyAdmin() public {
        (address[] memory t, uint256[] memory v, bytes[] memory d) = _calls();
        vm.expectRevert("AdminRole: caller is not admin");
        mc.multicall(t, v, d);
    }

    function test_MulticallLengthMismatch() public {
        (address[] memory t,, bytes[] memory d) = _calls();
        vm.prank(admin);
        vm.expectRevert("Multicall: length mismatch");
        mc.multicall(t, new uint256[](1), d);
    }

    function test_MulticallBubblesRevert() public {
        address[] memory t = new address[](1);
        bytes[] memory d = new bytes[](1);
        t[0] = address(mc);
        d[0] = abi.encodeCall(Multicall.initialize, (admin));
        vm.prank(admin);
        vm.expectRevert("Initializable: contract is already initialized");
        mc.multicall(t, new uint256[](1), d);
    }

    function test_Multiview() public {
        a.setNumber(7);
        b.setNumber(9);
        address[] memory t = new address[](2);
        bytes[] memory d = new bytes[](2);
        t[0] = address(a);
        t[1] = address(b);
        d[0] = abi.encodeCall(a.number, ());
        d[1] = d[0];
        bytes[] memory r = mc.multiview(t, d);
        assertEq(abi.decode(r[0], (uint256)), 7);
        assertEq(abi.decode(r[1], (uint256)), 9);
    }

    function test_OnlyOwner() public {
        assertEq(mc.owner(), owner);
        address impl = address(new Multicall());
        vm.expectRevert("Ownable: caller is not the owner");
        mc.upgradeTo(impl);
        vm.expectRevert("Ownable: caller is not the owner");
        mc.setAdmins(new address[](0), new bool[](0));
        vm.prank(owner);
        mc.upgradeTo(impl);
    }
}
