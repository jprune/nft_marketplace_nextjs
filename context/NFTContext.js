import React, { useState, useEffect } from 'react';
import axios from 'axios';
// handle wallet integration
import Web3Modal from 'web3modal';
// eslint-disable-next-line import/no-extraneous-dependencies
import { ethers } from 'ethers';
// handle NFT upload to IPFS
import { MarketAddress, MarketAddressABI } from './constants';

export const NFTContext = React.createContext();

const fetchContract = (signerOrProvider) => new ethers.Contract(MarketAddress, MarketAddressABI, signerOrProvider);

export const NFTProvider = ({ children }) => {
  const [currentAccount, setCurrentAccount] = useState('');
  const [isLoadingNFT, setIsLoadingNFT] = useState(false);
  const nftCurrency = 'ETH';

  // Connect wallet to application
  const checkIfWalletIsConnected = async () => {
    // MetaMask injects ethereum object to window object
    if (!window.ethereum) return alert('Please install MetaMask');

    const accounts = await window.ethereum.request({ method: 'eth_accounts' });

    if (accounts.length) {
      setCurrentAccount(accounts[0]);
    } else {
      console.log('No accounts found');
    }
  };

  useEffect(() => {
    checkIfWalletIsConnected();
  }, []);

  const connectWallet = async () => {
    if (!window.ethereum) return alert('Please install MetaMask');

    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });

    setCurrentAccount(accounts[0]);
    window.location.reload();
  };

  const createSale = async (url, formInputPrice, isReselling, id) => {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    // get the user that wants to create the NFT
    const signer = provider.getSigner();

    // convert human ETH into Wei
    const price = ethers.utils.parseUnits(formInputPrice, 'ether');
    // interact with smart contract
    const contract = fetchContract(signer);
    const listingPrice = await contract.getListingPrice();

    // user wants to list or resell?
    const transaction = !isReselling
      ? await contract.createToken(url, price, { value: listingPrice.toString() })
      : await contract.resellToken(id, price, { value: listingPrice.toString() });

    setIsLoadingNFT(true);
    await transaction.wait();
  };

  const fetchNFTs = async () => {
    setIsLoadingNFT(false);
    const provider = new ethers.providers.JsonRpcProvider("https://eth-goerli.g.alchemy.com/v2/sibHvjlUB5oEqwUHmodBTjbIbAd4RsRy");
    const contract = fetchContract(provider);
    // call fetchMarketItems smart contract function
    const data = await contract.fetchMarketItems();

    // Promise.all wait until ALL promises are resolved or rejected --> then returns an array of the data
    // then map over each index to fetch all the data from SC and return it as an object
    const items = await Promise.all(data.map(async ({ tokenId, seller, owner, price: unformattedPrice }) => {
      const tokenURI = await contract.tokenURI(tokenId);
      const { data: { image, name, description } } = await axios.get(tokenURI);
      const price = ethers.utils.formatUnits(unformattedPrice.toString(), 'ether');

      return {
        price,
        tokenId: tokenId.toNumber(),
        seller,
        owner,
        image,
        name,
        description,
        tokenURI,
      };
    }));

    return items;
  };

  // function to fetch either all listed NFTs of a user or all of his NFTs - (parameter type defines which way the function will go)
  const fetchMyNFTsOrListedNFTs = async (type) => {
    setIsLoadingNFT(false);
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    // get the user that wants to create the NFT
    const signer = provider.getSigner();

    const contract = fetchContract(signer);

    const data = type === 'fetchItemsListed'
      ? await contract.fetchItemsListed()
      : await contract.fetchMyNFTs();

    // Promise.all wait until ALL promises are resolved or rejected --> then returns an array of the data
    // then map over each index to fetch all the data from SC and return it as an object
    const items = await Promise.all(data.map(async ({ tokenId, seller, owner, price: unformattedPrice }) => {
      const tokenURI = await contract.tokenURI(tokenId);
      const { data: { image, name, description } } = await axios.get(tokenURI);
      const price = ethers.utils.formatUnits(unformattedPrice.toString(), 'ether');

      return {
        price,
        tokenId: tokenId.toNumber(),
        seller,
        owner,
        image,
        name,
        description,
        tokenURI,
      };
    }));

    return items;
  };

  const buyNFT = async (nft) => {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    // get the user that wants to create the NFT
    const signer = provider.getSigner();

    const contract = fetchContract(signer);
    // convert human ETH into Wei
    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether');

    const transaction = await contract.createMarketSale(nft.tokenId, { value: price });

    setIsLoadingNFT(true);
    await transaction.wait();
    setIsLoadingNFT(false);
  };

  return (
    <NFTContext.Provider value={{ nftCurrency, connectWallet, currentAccount, createSale, fetchNFTs, fetchMyNFTsOrListedNFTs, buyNFT, isLoadingNFT }}>
      {children}
    </NFTContext.Provider>
  );
};
