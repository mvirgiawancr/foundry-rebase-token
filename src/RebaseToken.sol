// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RebaseToken
 * @author mvirgiawancr
 * @notice This is a cross-chain rebase token that insentivises users to deposit into a vault.
 * @notice The interest rate in the smart contract can only decreased.
 * @notice Each user will have their own interest rate that is the global interest rate at the time of deposit.
 */
contract RebaseToken is ERC20 {
    // ERROR
    error RebaseToken__InterestRateDecreaseOnly(uint256 oldInterestRate, uint256 newInterestRate);

    // STATE VARIABLES
    uint256 private s_interestRate = 5e10;
    uint256 private constant PRECISION_FACTOR = 1e18;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    // EVENTS
    event InterestRateUpdated(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice This function sets the interest rate for the token.
     * @param _newInterestRate The new interest rate to be set.
     * @dev The interest rate can only be decreased, not increased.
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateDecreaseOnly(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateUpdated(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external {
        mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault.
     * @param _from The address of the user to burn tokens from.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     *
     * @param _user The address of the user to get the balance for.
     * @return The balance of the user, including the accumulated interest.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        return super.balanceOf(_user) + _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    /**
     * @notice This function transfers tokens from the sender to the recipient.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of tokens to transfer.
     * @return bool indicating whether the transfer was successful.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        mintAccruedInterest(msg.sender);
        mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice This function transfers tokens from one user to another.
     * @param _sender The address of the sender.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of tokens to transfer.
     * @return bool indicating whether the transfer was successful.
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        mintAccruedInterest(_sender);
        mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice This function returns the principle balance of a user, which is the balance without accumulated interest.
     * @param _user The address of the user to get the principle balance for.
     * @return uint256 The principle balance of the user.
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice This function calculates the accumulated interest for a user since their last update.
     * @param _user The address of the user to calculate the interest for.
     * @return linearInterest The accumulated interest for the user.
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     * @notice This function mints the accrued interest for a user.
     * @param _user The address of the user to mint the interest for.
     * @dev This function should be called before minting new tokens to ensure that the user's balance is updated
     * with the accrued interest.
     */
    function mintAccruedInterest(address _user) internal {
        uint256 previousBalance = super.balanceOf(_user);

        uint256 currentBalance = balanceOf(_user);

        uint256 balanceIncrease = currentBalance - previousBalance;

        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice This function returns the current interest rate of the token. Any future deposits will use this rate.
     * @return The current interest rate of the token.
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @param _user The address of the user to get the interest rate for.
     * @return The interest rate of the user.
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
