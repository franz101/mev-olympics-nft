// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./OneNFT.sol";


/**
 * @title MEV Olympics
 * @author Stuxden
 * @notice Implementation of challenge segments.
 * each segment contains its own ladder, implemented as an NFT
 */

contract MevOlympics is AccessControl {
    /// @notice leading zeroes segment
    OneNFT public zeroesNFT;
    uint public leadingZeroes;

    /// @notice for the sandwich segment
    OneNFT public sandwichNFT;
    uint256 private blockNumber1;
    uint256 private blockNumber2;
    address private txOrigin1;
    address private txOrigin2;

    /// @notice the MergeNft
    OneNFT public mergeNFT;
    uint256 public mergeBlockNumbner;

    constructor(uint leadingZeroes_, uint256 mergeBlockNumbner_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        zeroesNFT = new OneNFT("LeadingZeroes", "LZNFT");
        sandwichNFT = new OneNFT("Sandwich", "SNFT");
        mergeNFT = new OneNFT("MintOnMerge", "MNFT");

        leadingZeroes = leadingZeroes_;
        mergeBlockNumbner = mergeBlockNumbner_;

    }

    function setURIs(address token, uint[] memory tokenIds, string [] memory uris) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i=0; i<uris.length; i++){
            OneNFT(token).setTokenURI(tokenIds[i], uris[i]);
        }
    }

    function getLeadingZeroesRanks(uint amountOfRanks) public view returns (address[] memory) {
        return getTokenOwnersInRange(address(zeroesNFT), 0, amountOfRanks);
    }

    function getSandwichRanks(uint amountOfRanks) public view returns (address[] memory) {
        return getTokenOwnersInRange(address(sandwichNFT), 0, amountOfRanks);
    }

    function getMergeRanks(uint amountOfRanks) public view returns (address[] memory) {
        return getTokenOwnersInRange(address(mergeNFT), 0, amountOfRanks);
    }

    /// @notice gets an ordered array of tokenOwners, assumes linearly incremented tokenId by 1 and not burnable
    function getTokenOwnersInRange(address tokenAddr, uint startRank, uint amountOfRanks) public view returns (address[] memory) {
       address[] memory owners = new address[](amountOfRanks);
        for (uint i=0; i < amountOfRanks; i++) {
            try IERC721(tokenAddr).ownerOf(startRank+i) returns (address ranked) {
                owners[i] = ranked;
            } catch {
                // tokenId value does not exist
               return owners;
            }
        }
        return owners;
    }

    /// @notice  leading zeroes challenge segment
    function mintLeadingZeroes() external returns (uint256) {
        require(
            getLeadingZeroes(msg.sender) >= leadingZeroes,
            "not enough leading zeroes"
        );
        return zeroesNFT.mint(msg.sender);
    }

    /** @notice  sandwich challenge segment
     * requires calling by address whome we wish to mint for.
     * thereafter calling it again with a different address (simulated sandwich)
     * and then calling it again all in the same block inorder to mint
    */
    function mintSandwich() external returns (uint256) {
        if(sandwichTest()) {
        return sandwichNFT.mint(msg.sender);
        }
        setBlockAndOrigin();
        return 0;
    }


    /// @notice merge challenge segment
    function mintMerge() external returns (uint256) {
        require(
            block.number == mergeBlockNumbner,
            "can only mint on mergeblock"
        );
        return mergeNFT.mint(msg.sender);
    }


    /// @dev Leading Zeroes segment helper func, Returns amount of leading zero bytes in a given address
    function getLeadingZeroes(address addr) internal pure returns (uint) {
        bytes20 bytesAdr = bytes20(addr);
        uint counter = 0;
        for (uint i = 0; i < 20; i++) {
            if (uint8(bytesAdr[i]) == 0) {
                counter++;
            } else {
                break;
            }
        }
        return counter;
    }

    /// @notice sandwich segment functions
    function setBlockAndOrigin() internal {
        txOrigin2 = txOrigin1;
        txOrigin1 = tx.origin;

        blockNumber2 = blockNumber1;
        blockNumber1 = block.number;
    }

    function sandwichTest() internal view returns (bool) {
        if ((tx.origin != txOrigin1) && (tx.origin == txOrigin2))
            if (
                (block.number == blockNumber1) && (block.number == blockNumber2)
            ) {
                return true;
            }
        return false;
    }
}
