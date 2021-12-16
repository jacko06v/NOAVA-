require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
// require("hardhat-gas-reporter");
require("hardhat-tracer");

require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

// const RPC_URL = process.env.RINKEBY_RPC_URL;
// const PRIVATE_KEY = process.env.PRIVATE_KEY;

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
const INFURA_API_KEY = process.env.INFURA_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.6",
        settings: {
          optimizer: {
              enabled: true,
              runs: 1000,
          },
      },
    },
    {
      version: "0.5.16",
      settings: {
        optimizer: {
            enabled: true,
            runs: 1000,
        },
    },
  },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
              enabled: true,
              runs: 1000,
          },
      },
    },
    {
      version: "0.6.6",
      settings: {
        optimizer: {
            enabled: true,
            runs: 1000,
        },
    },
  },
    ], 
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    currency: "USD",
    coinmarketcap: COINMARKETCAP_API_KEY,
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://autumn-crimson-sun.bsc.quiknode.pro/ee6b7517d86a347cffbf8bfcef1339e5a1cc28cf/`,
      },
    },
    "matic-mumbai": {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [PRIVATE_KEY],
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
    },

    // ARBITRUM
    "arbitrum-rinkeby": {
      url: `https://arbitrum-rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
    },

    "arbitrum-mainnet": {
      url: `https://arbitrum-mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [PRIVATE_KEY],
    },
  },
};
