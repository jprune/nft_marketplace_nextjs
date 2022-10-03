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
    constructor() ERC721("Friend's Couch", "FRIC") {
      owner = payable(msg.sender);
    }

    function updateListingPrice(uint _listingPrice) public payable {
        require(owner == msg.sender, "Only marketplace owner can update the listing price");

        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    // private means, that this function is only called within the smart contract and not from a UI
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    //list your item for sale
    function resellToken(uint256 tokenId, uint256 price) public payable {
        //does the token belong to you?
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        // do you pay the right amount to list your NFT?
        require(msg.value == listingPrice, "Price must be equal to listing price");

        // item is now available for sale
        idToMarketItem[tokenId].sold = false;
        // seller wants to sell for different price
        idToMarketItem[tokenId].price = price;
        // update seller address
        idToMarketItem[tokenId].seller = payable(msg.sender);
        // give ownership to marketplace
        idToMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // process an order on the market place
    function createMarketSale(uint256 tokenId) public payable {
        // get the selling price of the market offer
        uint price = idToMarketItem[tokenId].price;
        // is the buyer paying the asking price?
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        // person who is buying is becoming owner
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        // set seller to contract address
        idToMarketItem[tokenId].seller = payable(address(0));

        _itemsSold.increment();

        //actually tranfer ownership from contract address to buyer
        _transfer(address(this), msg.sender, tokenId);

        // transfer listing fee from buyer to the person that created that NFT (creator) - royalty        
        payable(owner).transfer(listingPrice);
        // transfer ETH to the seller
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }

    // returns all unsold market items - "view" means no logic processing - "returns an array of MarketItems"
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        // create new array of MarketItem(s) called items --> in () specify the length of the array, type of the array is MarketItem
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for(uint i = 0; i < itemCount; i++) {
            // get reference to market item 
            if(idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        // return an array with all listed NFTs
        return items;
    }

    // get all NFTs that the user owns
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // figure out the number of items that the user owns
        for(uint i = 0; i < totalItemCount; i++) {
            // does this NFT belong to the user?
            if(idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {
            // get reference to market item 
            if(idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        
        // return the array with my NFTs
        return items;
    }

    // return current items listed for sale of the USER
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // figure out the number of items that the user owns
        for(uint i = 0; i < totalItemCount; i++) {
            // does this user offer the NFT for sale?
            if(idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {
            // get reference to market item 
            if(idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }
        
        // return the array with the lists of open sales
        return items;
    }
}