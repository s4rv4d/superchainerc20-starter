// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Predeploys} from "@contracts-bedrock/libraries/Predeploys.sol";
import {SuperchainERC20} from "@contracts-bedrock/L2/SuperchainERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {Unauthorized} from "@contracts-bedrock/libraries/errors/CommonErrors.sol";
import {IL2ToL2CrossDomainMessenger} from "@contracts-bedrock/L2/interfaces/IL2ToL2CrossDomainMessenger.sol";
import {ICrossL2Inbox} from "@contracts-bedrock/L2/interfaces/ICrossL2Inbox.sol";

contract L2Native2SuperchainERC20 is SuperchainERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    address internal constant _MESSENGER = Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;

    modifier onlyValidCaller() {
        require(msg.sender == owner() || msg.sender == _MESSENGER, "SToken: caller is not owner or messenger");
        _;
    }

     event OwnerTransferred(address indexed newOwner);

    constructor(address owner_, string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _initializeOwner(owner_);
        _mint(owner_, 1_000_000 * 10 ** _decimals);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTo(address to_, uint256 amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    function transferOwnership(address newOwner) public payable override onlyValidCaller() {

        require(newOwner != address(0), "Cannot set address(0) as new owner");

        _setOwner(newOwner);
        emit OwnerTransferred(newOwner);
    }

    function relayMessage(ICrossL2Inbox.Identifier calldata _id, bytes calldata _msg) external {

        bytes32 selector = abi.decode(_msg[:32], (bytes32));
        require(OwnerTransferred.selector == selector, "Wrong selector");
        require(_id.origin == address(this));

        // Authenticate this cross chain message
        ICrossL2Inbox(Predeploys.CROSS_L2_INBOX).validateMessage(_id, keccak256(_msg));

        // ABI decode the event message & perform actions.
        (address newOwner) = abi.decode(_msg[32:], (address));
        require(newOwner != address(0), "Cannot set address(0) as new owner");
        _setOwner(newOwner);
    }
}
