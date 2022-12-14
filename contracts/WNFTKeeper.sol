// SPDX-License-Identifier: MIT
// SoulEvo protocol for NFT. WNFTKeeper
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
//import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IERC721Mintable.sol";
import "../interfaces/IERC1155Mintable.sol";

/**
 * @title WNFT Token Keeper
 * @dev Use for hold wnft (like staking) 
 */
contract WNFTKeeper is  ERC721Holder, Ownable {
    using ECDSA for bytes32;

    struct NFT {
        address contractAddress;
        uint256 tokenId;
    } 
 
    // Map from chainId to last spawned nft
    mapping(uint256 => NFT) public lastSpawned;  
    

    // Map from hash to frozen WNFT 
    mapping(bytes32 => NFT) public frozenItems; 

    // Oracle signers status
    mapping(address => bool) public oracleSigners;

    // for MVP
    event NewFreeze(
        uint256 indexed forChain, 
        address indexed spawnerContract, 
        uint256 indexed spawnedTokenId
    );

    event Debug(bytes32 indexed hashed, NFT nft);
    
    function freeze(
        NFT memory _inData, 
        uint256 _forSpawnInChain, 
        bytes32 _secretHashed  // must pass keccak256(abi.encode(uint256Secret)), NOT secret
    ) 
        public 
        returns (NFT memory spawned) 
    {

        require(_forSpawnInChain != 0, "No zero target");
        lastSpawned[_forSpawnInChain].tokenId ++;
        frozenItems[
            keccak256(abi.encode(
                _secretHashed,
                lastSpawned[_forSpawnInChain].contractAddress,
                lastSpawned[_forSpawnInChain].tokenId)
            )
        ] = _inData;



        IERC721Mintable(_inData.contractAddress).transferFrom(
            msg.sender, 
            address(this), 
            _inData.tokenId
        );
        
        spawned = NFT(lastSpawned[_forSpawnInChain].contractAddress,lastSpawned[_forSpawnInChain].tokenId);

        emit NewFreeze(
            _forSpawnInChain, 
            lastSpawned[_forSpawnInChain].contractAddress,
            lastSpawned[_forSpawnInChain].tokenId
        );
    }

    function unFreeze(
        uint256 secret, 
        address spawnedContract, 
        uint256 spawnedtokenId,
        bytes32 _msgForSign, 
        bytes calldata _signature

    ) public 
    {
        // Check signature  author
        require(oracleSigners[_msgForSign.recover(_signature)], "Unexpected signer");

        // Check message integrity 
        require(
            keccak256(abi.encode(
                msg.sender,
                spawnedContract,
                spawnedtokenId
            )).toEthSignedMessageHash() == _msgForSign, 
            "Integrity check fail"
        );

        NFT memory frozzenItem = frozenItems[
            keccak256(abi.encode(
                getHashed(secret),
                spawnedContract,
                spawnedtokenId
            ))
        ];

        IERC721Mintable(frozzenItem.contractAddress).transferFrom(
            address(this),
            msg.sender, 
            frozzenItem.tokenId
        );
        
        delete frozenItems[
            keccak256(abi.encode(
                getHashed(secret),
                spawnedContract,
                spawnedtokenId
            ))
        ];
    }
    ///////////////////////////////////////////////////////////////////////////

    function setSignerStatus(address _signer, bool _status) external onlyOwner {
        oracleSigners[_signer] = _status;
    }

    function setSpawnerContract(uint256 network, NFT calldata nft) external onlyOwner {
        lastSpawned[network] = nft;
    }

    function getHashed(uint256 secret) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(secret));
    }
   
}