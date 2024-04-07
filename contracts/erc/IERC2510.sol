// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title ERC2510 Interface
 * @dev ERC2510 extends the ERC20 standard to enhance token stability and value transparency
 * by introducing a base liquidity pool mechanism. This allows tokens to maintain a base value
 * and facilitates easier and more stable trading mechanisms within the Ethereum ecosystem.
 */
interface IERC2510 is IERC20Metadata {

    /**
     * @notice Emitted when liquidity is enhanced by an address
     * @param _enhancer Address enhancing liquidity
     * @param _valued Amount of value added to the liquidity pool
     */
    event EnhanceValue(address indexed _enhancer, uint256 _valued);

    /**
     * @notice Emitted when a token holder retrieves value from the base liquidity pool
     * @param _retriever Address retrieving value
     * @param _valued Amount of value retrieved from the pool
     */
    event RetrieveValue(address indexed _retriever, uint256 _valued);

    /**
     * @notice Emitted on token swap operation
     * @param sender Address initiating the swap
     * @param amount0In Amount of input tokens
     * @param amount1In Amount of input counterpart tokens
     * @param amount0Out Amount of output tokens
     * @param amount1Out Amount of output counterpart tokens
     */
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out
    );

    /**
     * @notice Calculates the amount of output tokens for a given input value
     * @dev Used for trading and swap operations to determine the output based on the current liquidity pool state
     * @param value Amount of input tokens
     * @param _buy Flag indicating if the operation is a buy (true) or sell (false)
     * @return Amount of output tokens
     */
    function getAmountOut(uint256 value, bool _buy) external view returns(uint256);

    /**
     * @notice Retrieves the current state of the liquidity reserves
     * @return reserve0 Amount of ETH in the contract
     * @return reserve1 Amount of ERC2510 tokens in the contract
     */
    function getReserves() external view returns (uint256, uint256);

    /**
     * @notice Returns the total value locked in the base liquidity pool
     * @dev Represents the minimum guaranteed value of ERC2510 tokens
     * @return Total value in the base liquidity pool
     */
    function solidValue() external view returns (uint256);

    /**
     * @notice Enhances the token's value by adding liquidity to the base pool
     * @dev Allows the token ecosystem to dynamically increase the backing of each token
     */
    function enhanceTokenValue() external payable;

    /**
     * @notice Allows token holders to retrieve value from the base liquidity pool by burning tokens
     * @dev Reduces the total supply of tokens in circulation and increases the value of the remaining tokens
     * @param _amount Amount of tokens to burn
     */
    function retrieveTokenValue(uint256 _amount) external;

}
