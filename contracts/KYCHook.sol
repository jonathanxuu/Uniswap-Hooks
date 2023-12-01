// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";

import {BaseHook} from "./BaseHook.sol";

/**
 * @title An interface for checking whether an address has a valid kycNFT token
 */
interface IKycValidity {
    /// @dev Check whether a given address has a valid kycNFT token
    /// @param _addr Address to check for tokens
    /// @return valid Whether the address has a valid token
    function hasValidToken(address _addr) external view returns (bool valid);
}

/**
 * Only KYC'ed people can trade on the V4 hook'ed pool.
 * Caveat: Relies on external oracle for info on an address's KYC status.
 */
contract KYCSwaps is BaseHook, Ownable {
    IKycValidity public kycValidity;
    address private _preKycValidity;
    uint256 private _setKycValidityReqTimestamp;

    constructor(
        IPoolManager _poolManager,
        address _kycValidity
    ) BaseHook(_poolManager) Ownable(tx.origin) {
        kycValidity = IKycValidity(_kycValidity);
    }

    modifier onlyPermitKYC() {
        require(
            kycValidity.hasValidToken(tx.origin),
            "Swaps available for valid KYC token holders"
        );
        _;
    }

    /// Sorta timelock
    function setKycValidity(address _kycValidity) external onlyOwner {
        if (
            block.timestamp - _setKycValidityReqTimestamp >= 7 days &&
            _kycValidity == _preKycValidity
        ) {
            kycValidity = IKycValidity(_kycValidity);
        } else {
            _preKycValidity = _kycValidity;
            _setKycValidityReqTimestamp = block.timestamp;
        }
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                noOp: false
            });
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata hookData
    ) external view override poolManagerOnly onlyPermitKYC returns (bytes4) {
        return BaseHook.beforeSwap.selector;
    }

    function beforeInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function afterInitialize(
        address sender,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24 tick,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function beforeModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function afterModifyPosition(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function beforeDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external override returns (bytes4) {}

    function afterDonate(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external override returns (bytes4) {}
}
