// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ERC2510 Liquidity Provision
 * @dev Abstract contract for managing liquidity provision in ERC2510 tokens.
 * Provides mechanisms for adding, removing, and extending liquidity in a secure manner.
 * Designed to be extended by ERC2510 token contracts for integrated liquidity management.
 */
abstract contract ERC2510Liquidity is ReentrancyGuard {

    // Events for tracking liquidity-related actions.
    event AddLiquidity(address indexed provider, uint256 blockToUnlockLiquidity, uint256 value);
    event RemoveLiquidity(address indexed remover, uint256 value);

    // Block number when liquidity can be unlocked.
    uint256 public blockToUnlockLiquidity;

    /**
     * @dev Adds liquidity to the contract with a lock-up period.
     * Only callable by the contract owner or designated liquidity provider role.
     * Emits an {AddLiquidity} event on successful addition of liquidity.
     * @param _blockToUnlockLiquidity The future block number when liquidity can be removed.
     */
    function addLiquidity(uint256 _blockToUnlockLiquidity) external virtual payable {
        // Ensure that liquidity has not been previously added or that the contract
        // does not already have a lock-up period set.
        require(blockToUnlockLiquidity == 0, "Liquidity already added");

        // Check that some value is being added as liquidity.
        require(msg.value > 0, "No ETH sent");

        // The specified block for unlocking liquidity must be greater than the current block.
        require(block.number < _blockToUnlockLiquidity, "Block number too low");
        
        // Update the contract state with the new lock-up period.
        blockToUnlockLiquidity = _blockToUnlockLiquidity;
        
        // Log the liquidity addition.
        emit AddLiquidity(msg.sender, _blockToUnlockLiquidity, msg.value);
    }

    /**
     * @dev Removes liquidity from the contract.
     * Can only be called internally, typically through a public function with access control.
     * Emits a {RemoveLiquidity} event on successful removal of liquidity.
     * Uses ReentrancyGuard to prevent reentrancy attacks during the withdrawal process.
     */
    function removeLiquidity() internal virtual nonReentrant {
        // Ensure the current block is beyond the lock-up period.
        require(block.number > blockToUnlockLiquidity, "Liquidity locked");

        // Store the contract's balance to log it before transferring funds.
        uint256 _internalLiq = address(this).balance;

        // Transfer all the contract's balance to the caller. Assumes the caller is authorized.
        (bool success, ) = payable(msg.sender).call{value: _internalLiq}("");
        require(success, "ETH transfer failed");

        // Log the liquidity removal.
        emit RemoveLiquidity(msg.sender, _internalLiq);
    }

    /**
     * @dev Extends the lock-up period for the liquidity in the contract.
     * Can only be called internally, typically through a public function with access control.
     * The new lock-up period must be greater than the current one.
     * @param _blockToUnlockLiquidity The new block number to unlock the liquidity.
     */
    function extendLiquidityLock(uint256 _blockToUnlockLiquidity) internal virtual {
        // Ensure the new lock-up period is later than the current one.
        require(blockToUnlockLiquidity < _blockToUnlockLiquidity, "You can't shorten duration");

        // Update the lock-up period.
        blockToUnlockLiquidity = _blockToUnlockLiquidity;
    }
}
