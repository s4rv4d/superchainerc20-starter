// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {ICreateX} from "createx/ICreateX.sol";
import {Preinstalls} from "@contracts-bedrock/libraries/Preinstalls.sol";
import {L2Native2SuperchainERC20} from "../src/L2Native2SuperchainERC20.sol";

contract SuperchainERC20Deployer {
    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    /// @notice Foundry cheatcode VM.
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function deployL2NativeSuperchainERC20() public broadcast returns (address addr_) {

        address owner = vm.envAddress("ERC20_OWNER_ADDRESS");
        string memory name = vm.envString("ERC20_NAME");
        string memory symbol = vm.envString("ERC20_SYMBOL");
        uint256 decimals = vm.envOr("ERC20_DECIMALS", uint256(18));
        bytes memory erc20InitCode = type(L2Native2SuperchainERC20).creationCode;
        addr_ = ICreateX(Preinstalls.CreateX).deployCreate3({
            salt: implSalt(),
            initCode: abi.encodePacked(erc20InitCode, abi.encode(owner, name, symbol, decimals))
        });
        console.log("Deployed L2Native2SuperchainERC20 at address: ", addr_, "on chain id: ", block.chainid);
    }

    /// @notice The CREATE3 salt to be used when deploying the token.
    function implSalt() internal view returns (bytes32) {
        string memory salt = vm.envOr("SALT", string("ethers phoenix"));
        bytes32 encodedSalt = keccak256(abi.encodePacked(salt));
        return bytes32(
            // constructed in order to provide permissioned deploy protection: https://github.com/pcaversaccio/createx/blob/058bc3b07e082711457d8ea20d8767a37a5a0021/src/CreateX.sol#L922
            abi.encodePacked(bytes20(msg.sender), hex"00", bytes11(encodedSalt))
        );
    }
}
