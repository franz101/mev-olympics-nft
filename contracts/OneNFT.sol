// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";




/**
 * @title MEV Olympics One NFT
 * @author Stuxden
 * @notice Implementation of a mintable NFT with modifier based access controls
 * which allows only one nft minted per address
 */
contract OneNFT is ERC721, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice allows only one token per address
    modifier notNftOwner(address addr) {
        require(balanceOf(addr) == 0, "can only own one token");
        _;
    }

     function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(MINTER_ROLE) {
        _tokenURIs[tokenId] = _tokenURI;
      }

    /**
     * @dev Returns an URI for a given token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {

        return _tokenURIs[tokenId];
    }

    function mint(address to)
        public
        onlyRole(MINTER_ROLE)
        notNftOwner(to)
        returns (uint256)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _tokenIdCounter.increment();
        return tokenId;
    }

    /// @notice disallow transfers to token holders

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public notNftOwner(to) override(ERC721) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public notNftOwner(to) override(ERC721) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public notNftOwner(to) override(ERC721) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
