// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ERC2510 Keeper Contract
 * @dev This contract is responsible for managing the liquidity pool's funds for ERC2510 tokens.
 * It provides a secure way to retrieve value from the liquidity pool, ensuring only authorized operations.
 * The keeper's role is critical for the ERC2510 token economy, enabling controlled liquidity and value retrieval.
 */
contract ERC2510Keeper {
    // The address that has the exclusive right to execute critical functions.
    address private _keeper;

    /**
     * @dev Sets the deployer as the initial keeper of the contract.
     */
    constructor() payable {
        _keeper = msg.sender;
    }

    /**
     * @dev Ensures that only the keeper can call the function modified by this.
     */
    modifier keepOp {
        require(msg.sender == _keeper, "Only keeper can execute");
        _;
    }

    /**
     * @notice Allows the keeper to send value from the contract to a specified address.
     * This function is critical for managing the liquidity pool's funds.
     * @param _to The address to which the funds will be sent.
     * @param _amount The amount of funds to send.
     */
    function retrieveValue(address _to, uint256 _amount) external keepOp {
        require(address(this).balance >= _amount, "insufficient balance");
        Address.sendValue(payable(_to), _amount);
    }

    /**
     * @dev Allows the contract to receive ether directly to its balance.
     * This is necessary for the contract to accumulate liquidity.
     */
    receive() payable external {}
}
