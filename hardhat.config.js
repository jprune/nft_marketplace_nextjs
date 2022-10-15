/**
* @type import('hardhat/config').HardhatUserConfig
*/

require('dotenv').config();
// eslint-disable-next-line import/no-extraneous-dependencies
require('@nomiclabs/hardhat-ethers');

const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: {
    compilers: [
      { version: '0.7.3' },
      { version: '0.8.4' },
    ],
  },
  defaultNetwork: 'goerli',
  networks: {
    hardhat: {},
    goerli: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
};
