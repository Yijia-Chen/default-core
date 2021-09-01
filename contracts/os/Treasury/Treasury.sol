// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Epoch.sol";
import "./_Vault.sol";

contract def_TreasuryInstaller is DefaultOSModuleInstaller("TSY") {
    string public moduleName = "Default Treasury";

    function install(DefaultOS os_) external override returns (address) {
        def_Treasury treasury = new def_Treasury(os_);
        treasury.transferOwnership(address(os_));
        return address(treasury);
    }
}

contract def_Treasury is DefaultOSModule {

    def_Epoch private _Epoch;

    constructor(DefaultOS os_) DefaultOSModule(os_) {
      _Epoch = def_Epoch(_OS.getModule("EPC"));
    }

    // emitted events
    event VaultOpened(Vault vault, uint16 epochOpened);
    event VaultFeeChanged(Vault vault, uint8 newFee, uint16 epochOpened);
    event Deposited(Vault vault, address member, uint256 amount, uint16 epoch);
    event Withdrawn(Vault vault, address member, uint256 amount, uint16 epoch);

    // a treasury vault
    struct TreasuryVault {
        uint8 fee;
        Vault vault;
    }

    // token contract => vault contract; ensures only one vault per token
    mapping(address => TreasuryVault) public treasuryVaults;

    // **********************************************************************
    //                   OPEN NEW VAULT (GOVERNANCE ONLY)
    // **********************************************************************

    // open a new vault for the treasury (accept deposits for specific token)
    function openVault(address token_, uint8 fee_) external onlyOS {
        // make sure no vault exists for this token
        require(
            address(treasuryVaults[token_].vault) == address(0),
            "def_Treasury | openVault(): vault already exists"
        );
        require(
            fee_ >= 0 && fee_ <= 100,
            "defTreasury | openVault(): fee must be 0 <= fee <= 100"
        );

        // naming standard for the vault share tokens
        IERC20Metadata _AssetData = IERC20Metadata(token_);
        string memory vaultName = string(
            abi.encodePacked("Default Treasury Vault: ", _AssetData.symbol())
        );
        string memory vaultSymbol = string(
            abi.encodePacked(_AssetData.symbol(), "-VS")
        );
        uint8 vaultDecimals = _AssetData.decimals();

        // create the token contract for this vault
        Vault newVault = new Vault(
            token_,
            vaultName,
            vaultSymbol,
            vaultDecimals
        );

        // save it to the registry
        treasuryVaults[token_] = TreasuryVault(fee_, newVault);

        // record event for frontend
        emit VaultOpened(newVault, _Epoch.currentEpoch());
    }

    // **********************************************************************
    //             WITHDRAW FOR FREE FROM VAULT (GOVERNANCE ONLY)
    // **********************************************************************

    // For the DAO/OS to withdraw earned fees from the vault
    function withdrawFromVault(address token_, uint256 amountshares_)
        external
        onlyOS
    {
        // find the treasury vault for the given token
        TreasuryVault memory tsyVault = treasuryVaults[token_];
        require(
            address(tsyVault.vault) != address(0),
            "def_Treasury | deposit(): vault does not exist for token"
        );

        // withdraw from the vault to the OS
        tsyVault.vault.withdraw(address(_OS), amountshares_);

        emit Deposited(
            tsyVault.vault,
            address(this),
            amountshares_,
            _Epoch.currentEpoch()
        );
    }

    // **********************************************************************
    //                   CHANGE VAULT FEE (GOVERNANCE ONLY)
    // **********************************************************************

    function changeFee(address token_, uint8 newFeePctg) external onlyOS {
        require(newFeePctg >= 0 && newFeePctg <= 100);
        // get the treasury vault in storage for the token
        TreasuryVault storage tsyVault = treasuryVaults[token_];

        // set the fee to the new fee
        tsyVault.fee = newFeePctg;

        emit VaultFeeChanged(tsyVault.vault, newFeePctg, _Epoch.currentEpoch());
    }

    // **********************************************************************
    //                   DEPOSIT USER FUNDS INTO VAULT
    // **********************************************************************

    function deposit(address token_, uint256 amountTokens_) external {
        // get the treasury vault in storage for the token
        TreasuryVault memory tsyVault = treasuryVaults[token_];
        require(
            address(tsyVault.vault) != address(0),
            "def_Treasury | deposit(): vault does not exist for token"
        );

        // deposit the users
        tsyVault.vault.deposit(msg.sender, amountTokens_);

        emit Deposited(
            tsyVault.vault,
            msg.sender,
            amountTokens_,
            _Epoch.currentEpoch()
        );
    }

    // **********************************************************************
    //                   WITHDRAW USER FUNDS FROM VAULT
    // **********************************************************************

    function withdraw(address token_, uint256 amountShares_) external {
        TreasuryVault memory tsyVault = treasuryVaults[token_];
        require(
            address(tsyVault.vault) != address(0),
            "def_Treasury | deposit(): vault does not exist for token"
        );

        // calculate the fee collected upon withdraw and transfer shares to the wallet
        uint256 withdrawFeeCollected = (amountShares_ * tsyVault.fee) / 100;
        tsyVault.vault.transferFrom(
            msg.sender,
            address(_OS),
            withdrawFeeCollected
        );

        // use subtraction to avoid rounding errors
        uint256 amountWithdrawn = tsyVault.vault.withdraw(
            msg.sender,
            amountShares_ - withdrawFeeCollected
        );

        emit Withdrawn(
            tsyVault.vault,
            msg.sender,
            amountWithdrawn,
            _Epoch.currentEpoch()
        );
    }
}
