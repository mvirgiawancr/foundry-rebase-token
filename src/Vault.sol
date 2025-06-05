// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Vault
 * @author mvirgiawancr
 * @notice This contract is a vault that holds a rebase token.
 * @notice It allows users to deposit and withdraw the rebase token.
 * @notice The vault does not manage interest rates or minting/burning of tokens.
 */
contract Vault {
    address private immutable i_rebaseToken;

    constructor(address _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    /**
     * @notice This function returns the address of the rebase token contract.
     * @return The address of the rebase token contract.
     */
    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}
