// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Predeploys} from "@contracts-bedrock/libraries/Predeploys.sol";
import {SuperchainERC20} from "@contracts-bedrock/L2/SuperchainERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {Unauthorized} from "@contracts-bedrock/libraries/errors/CommonErrors.sol";
import {IL2ToL2CrossDomainMessenger} from "@contracts-bedrock/L2/interfaces/IL2ToL2CrossDomainMessenger.sol";

contract L2NativeSuperchainERC20 is SuperchainERC20, Ownable {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    uint256[] private _allowedChainIds;

    address internal constant _MESSENGER = Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;

    modifier onlyValidCaller() {
        require(msg.sender == owner() || msg.sender == _MESSENGER, "SToken: caller is not owner or messenger");
        _;
    }

    constructor(address owner_, string memory name_, string memory symbol_, uint8 decimals_, uint256[] memory allowedChainIds_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _allowedChainIds = allowedChainIds_;

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

        if (msg.sender == _MESSENGER) {
            // just update
            if (IL2ToL2CrossDomainMessenger(_MESSENGER).crossDomainMessageSender() != address(this)) {
                revert Unauthorized();
            }

            _setOwner(newOwner);

        } else {
            // emit to other chains
            _setOwner(newOwner);

             for (uint256 i = 0; i < _allowedChainIds.length; i++) {
                if (_allowedChainIds[i] != block.chainid) {
                    bytes memory _message = abi.encodeCall(this.transferOwnership, (newOwner));
                    IL2ToL2CrossDomainMessenger(_MESSENGER).sendMessage(_allowedChainIds[i], address(this), _message);
                }
            }
        }
    }
}
