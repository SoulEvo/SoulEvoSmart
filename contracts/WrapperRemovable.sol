// SPDX-License-Identifier: MIT
// SoulEvo protocol for NFT. Wrapper - main protocol contract
pragma solidity 0.8.11;

import "./WrapperBaseV1.sol";


contract WrapperRemovable is WrapperBaseV1 {
    
    constructor(address _erc20) WrapperBaseV1(_erc20) {

    }

   
    function removeCollateralItem(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem calldata _collateralItem,
        address _receiver
    ) public virtual {

        require(protocolWhiteList != address(0), "Only with whitelist");
        if (_collateralItem.asset.assetType != ETypes.AssetType.EMPTY) {
            require(
                IAdvancedWhiteList(protocolWhiteList).enabledRemoveFromCollateral(
                _collateralItem.asset.contractAddress),
                "WL:Asset Not enabled for remove"
            );
        }
        // we need know index in collateral array
        (uint256 _amnt, uint256 _index) = getCollateralBalanceAndIndex(
                _wNFTAddress, 
                _wNFTTokenId,
                _collateralItem.asset.assetType, 
                _collateralItem.asset.contractAddress,
                _collateralItem.tokenId
        );


            wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].amount -= _collateralItem.amount;
            // case full remove 
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].amount == 0) {
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].asset.assetType = ETypes.AssetType.EMPTY;
            }

        require(
            _mustTransfered(_collateralItem) == _transferSafe(_collateralItem, address(this), wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestination),
            "Suspicious asset for wrap or collateral"
        );
    } 
}