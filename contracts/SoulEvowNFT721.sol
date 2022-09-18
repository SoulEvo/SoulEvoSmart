// SPDX-License-Identifier: MIT
// protocol for NFT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IWrapper.sol";

//v0.0.1
contract SoulEvowNFT721 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    
    address public wrapperMinter;
    string  public baseurl;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl
    ) 
        ERC721(name_, symbol_)  
    {
        wrapperMinter = msg.sender;
        baseurl = string(
            abi.encodePacked(
                _baseurl,
                block.chainid.toString(),
                "/",
                uint160(address(this)).toHexString(),
                "/"
            )
        );

    }

    function mint(address _to, uint256 _tokenId) external {
        require(wrapperMinter == msg.sender, "Trusted address only");
        _mint(_to, _tokenId);
    }


    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(wrapperMinter == msg.sender, "Trusted address only");
        //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function setMinter(address _minter) external onlyOwner {
        wrapperMinter = _minter;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        ETypes.WNFT memory _wnft = IWrapper(wrapperMinter).getWrappedToken(
                address(this),tokenId
            );
            if (
                  (from == address(0) || to == address(0)) // mint & burn (wrap & unwrap)
               || (isContract(from))                       // transfer wNFT from any contract  
            )  
            {} else {
                // Check Core Protocol Rules
                require(
                    !(bytes2(0x0004) == (bytes2(0x0004) & _wnft.rules)),
                    "Trasfer was disabled by author"
                );

                // Check and charge Transfer Fee and pay Royalties
                if (_wnft.fees.length > 0) {
                    IWrapper(wrapperMinter).chargeFees(address(this), tokenId, from, to, 0x00);    
                }
            }
    }

    function wnftInfo(uint256 tokenId) external view returns (ETypes.WNFT memory) {
        return IWrapper(wrapperMinter).getWrappedToken(address(this), tokenId);
    }
    
    
    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view  override returns (string memory) {
        return baseurl;
    }


    function tokenURI(uint256 _tokenId) public view override returns (string memory _uri) {
        _uri = IWrapper(wrapperMinter).getOriginalURI(address(this), _tokenId);
        if (bytes(_uri).length == 0) {
            _uri = ERC721.tokenURI(_tokenId);
        }
        return _uri;
    }

    function exists(uint256 _tokenId) public view returns(bool) {
        return _exists(_tokenId);
    }

    function isContract(address account) internal view returns (bool) {


        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}
