// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC2510.sol";
import "./ERC2510Liquidity.sol";
import "./ERC2510Keeper.sol";

/**
 * @title ERC2510 Token Implementation
 * @notice Implements the ERC2510 token standard with built-in liquidity and value recovery mechanisms.
 * @dev Extends ERC20 to support enhanced stability and transparent value through a base liquidity pool.
 */
contract ERC2510 is Context, IERC2510, ERC2510Liquidity, IERC165 {

    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    ERC2510Keeper private _keeper;
    // Mapping to prevent multiple operations within the same block by a single address.
    mapping(address account => uint32) private lastTransaction;

    /**
     * @dev Sets the values for {name}, {symbol} and {totalSupply}. 
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) payable {
        _name = name_;
        _symbol = symbol_;
        _keeper = new ERC2510Keeper();
        // _mint(msg.sender, _totalSupply);
        if(msg.value > 0) {
            payable(_keeper).transfer(msg.value);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId 
            || interfaceId == type(IERC2510).interfaceId;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    /**
     * @dev Returns the number of decimals used to get its user representation.
     */

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the total value locked in the base liquidity pool
     * @dev Represents the minimum guaranteed value of ERC2510 tokens
     * @return Total value in the base liquidity pool
     */
    function solidValue() external view returns (uint256) {
        return address(_keeper).balance;
    }

    /**
     * @dev Enhances the token's value by contributing to the base liquidity pool.
     * This method allows the token ecosystem to dynamically increase the backing of each token, enhancing its value and stability.
     */
    function enhanceTokenValue() external payable {
        require(msg.value > 0, "enhance value should gt 0");
        payable(_keeper).transfer(msg.value);
        emit EnhanceValue(msg.sender, msg.value);
    }

    /**
     * @notice Allows token holders to retrieve value from the base liquidity pool by burning tokens
     * @dev Reduces the total supply of tokens in circulation and increases the value of the remaining tokens
     * @param _amount Amount of tokens to burn
     */
    function retrieveTokenValue(uint256 _amount) external {
        require(_balances[msg.sender] >= _amount, "insufficient balance");
        require(_amount > 0, "retrieve value should be gt 0");
        require(_totalSupply > 0, "Total supply cannot be zero");
        uint256 payval = address(_keeper).balance * _amount / _totalSupply;
        _burn(msg.sender, _amount);
        _keeper.retrieveValue(msg.sender, payval);
    }

    /**
     * @notice Retrieves the current state of the liquidity reserves
     * @return reserve0 Amount of ETH in the contract
     * @return reserve1 Amount of ERC2510 tokens in the contract
     */
    function getReserves() public view returns (uint256, uint256) {
        return (address(this).balance, _balances[address(this)]);
    }

    /**
    * @dev Estimates the amount of tokens or ETH to receive when buying or selling.
    * @param value: the amount of ETH or tokens to swap.
    * @param _buy: true if buying, false if selling.
    */
    function getAmountOut(uint256 value, bool _buy) public view returns(uint256) {

        (uint256 reserveETH, uint256 reserveToken) = getReserves();

        if (_buy) {
            return (value * reserveToken) / (reserveETH + value);
        } else {
            return (value * reserveETH) / (reserveToken + value);
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - the caller must have a balance of at least `value`.
     * - if the receiver is the contract, the caller must send the amount of tokens to sell
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        // sell or transfer
        if (to == address(this)) {
            sell(value);
        }
        else{
            _transfer(msg.sender, to, value);
        }
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively burns if `to` is the zero address.
     * All customizations to transfers and burns should be done by overriding this function.
     * This function includes MEV protection, which prevents the same address from making two transactions in the same block.(lastTransaction)
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 value) internal virtual {
        
        require(lastTransaction[msg.sender] != block.number, "You can't make two transactions in the same block");

        lastTransaction[msg.sender] = uint32(block.number);

        require (_balances[from] >= value, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = _balances[from] - value;
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
    * @dev Buys tokens with ETH.
    * internal function
    */
    function buy() internal {
        uint256 token_amount = (msg.value * _balances[address(this)]) / (address(this).balance);
        _beforeTokenTransfer(address(this), msg.sender, token_amount);

        _transfer(address(this), msg.sender, token_amount);

        emit Swap(msg.sender, msg.value,0,0,token_amount);
        _afterTokenTransfer(address(this), msg.sender, token_amount);
    }

    /**
    * @dev Sells tokens for ETH.
    * internal function
    */
    function sell(uint256 sellAmount) internal {
        uint256 ethAmount = (sellAmount * address(this).balance) / (_balances[address(this)] + sellAmount);
        _beforeTokenTransfer(address(this), msg.sender, sellAmount);

        require(ethAmount > 0, "Sell amount too low");
        require(address(this).balance >= ethAmount, "Insufficient ETH in reserves");

        _transfer(msg.sender, address(this), sellAmount);
        payable(msg.sender).transfer(ethAmount);

        emit Swap(msg.sender, 0,sellAmount,ethAmount,0);
        _afterTokenTransfer(address(this), msg.sender, sellAmount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
    * @dev Fallback function to buy tokens with ETH.
    */
    receive() external payable {
        buy();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
