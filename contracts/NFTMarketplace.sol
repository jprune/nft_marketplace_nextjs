// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// Using ERC721 standard
// Functionality we can use
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

// public means available from the client application
// view means it's not doing any transaction work

// Creating our contract ->Inherited from ERC721URIStorage

contract NFTMarketplace is ERC721URIStorage {
     // allows us to use the counter utility
    using Counters for Counters.Counter;
    
    // when the first token is minted it'll get a value of zero, the second one is one
    // and then using counters this we'll increment token ids
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    // fee to list an nft on the marketplace
    uint256 listingPrice = 0.025 ether;

    // declaring the owner of the contract
    // owner earns a commision on every item sold
    address payable owner;


    // keeping up with all the items that have been created
    // pass in the integer which is the item id and it returns a market item.
    // to fetch a market item, we only need the item id
    mapping(uint256 => MarketItem) private idToMarketItem;

    // similar to js object
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // have an event for when a market item is created.
    // this event matches the MarketItem
    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // set the owner as the msg.sender
    // the owner of the contract is the one deploying it
    constructor() ERC721("Metaverse Tokens", "METT") {
      owner = payable(msg.sender);
    }

}