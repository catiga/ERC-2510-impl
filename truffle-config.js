const HDWalletProvider = require('@truffle/hdwallet-provider')
const dotenv = require("dotenv")

dotenv.config()
const infuraKey = process.env.INFURA_KEY || ''
const infuraSecret = process.env.INFURA_SECRET || ''
const liveNetworkPK = process.env.LIVE_PK || ''
const updateDeployerPK = process.env.NEW_DEPLOYER_PK || ''
const mintfunDeployerPK = process.env.MINTFUN_DEPLOYER_PK || ''
const polygonDeployerPK = process.env.POLYGON_TEST_PK || ''
const liveNetworkPKBase = process.env.BASE_PK || ''
const playPK = process.env.PLAY_PK

const privateKey = [ liveNetworkPK, mintfunDeployerPK, playPK ]
const privateAddress = process.env.LIVE_ADDRESS
const etherscanApiKey = process.env.ETHERS_SCAN_API_KEY || ''
const polygonApiKey = process.env.POLYGON_SCAN_API_KEY || ''
const bscApiKey = process.env.BSC_SCAN_API_KEY || ''

/* just for treasury deploy and manage */
const updatePrivateKey = [updateDeployerPK]
const updatePrivateAddress = process.env.NEW_DEPLOYER_ADDRESS
/* just for treasury deploy and manage */

/* just for mintfun */
const mfPrivateKey = [mintfunDeployerPK]
const mfPrivateAddress = process.env.MINTFUN_DEPLOYER_ADDRESS
/* just for mintfun */

/* polygon testnet */
const polygonPrivateKey = [polygonDeployerPK]
const polygonPrivateAddress = process.env.POLYGON_TEST_ADDRESS
/* polygon testnet */

/* base */
const privateKeyBase = [ liveNetworkPKBase ]
const privateAddressBase = process.env.BASE_ADDRESS

module.exports = {
  networks: {
    ganache: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777",
      websocket: true
    },
    dis_mainnet: {
      provider: () => new HDWalletProvider({
        //privateKeys: updatePrivateKey,
        privateKeys: privateKey,
        providerOrUrl: `https://rpc.dischain.xyz`,
        pollingInterval: 56000
      }),
      network_id: 513100,
      confirmations: 2,
      timeoutBlocks: 100,
      skipDryRun: true,
      // from: updatePrivateAddress,
      from: privateAddress,
      networkCheckTimeout: 99999999
    },
    eth_mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: mfPrivateKey,
        providerOrUrl: `https://mainnet.infura.io/v3/db7ad163cfed48c181c8456f2ab3fe54`,
        pollingInterval: 56000
      }),
      network_id: 1,
      confirmations: 2,
      timeoutBlocks: 100,
      skipDryRun: true,
      from: mfPrivateAddress,
      networkCheckTimeout: 999999
    },
    bsc_mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: privateKey,
        providerOrUrl: `https://bsc-dataseed1.ninicoin.io`,
        pollingInterval: 56000
      }),
      network_id: 56,
      confirmations: 2,
      timeoutBlocks: 100,
      skipDryRun: true,
      from: privateAddress,
      networkCheckTimeout: 999999
    },
    base_mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: privateKeyBase,
        providerOrUrl: `https://mainnet.base.org`,
        pollingInterval: 56000
      }),
      network_id: 8453,
      confirmations: 2,
      timeoutBlocks: 100,
      skipDryRun: true,
      from: privateAddressBase,
      networkCheckTimeout: 999999,
      gasPrice: 1000000000
    },
    bsc_testnet: {
      provider: () => new HDWalletProvider({
        privateKeys: privateKey,
        providerOrUrl: `https://data-seed-prebsc-1-s3.bnbchain.org:8545`, //`https://endpoints.omniatech.io/v1/bsc/testnet/public`,
        pollingInterval: 56000
      }),
      network_id: 97,
      confirmations: 2,
      timeoutBlocks: 100,
      skipDryRun: true,
      from: privateAddress,
      networkCheckTimeout: 999999,
      gasPrice: 8000000000,
      gas: 5000000
    }
  },
  mocha: {
    timeout: 100_000
  },
  compilers: {
    solc: {
      version: "0.8.20",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: "london"
      }
    }
  },
  db: {
    enabled: false
  },
  plugins: ['truffle-plugin-verify'],
  api_keys: {
    etherscan: etherscanApiKey,
    bscscan: bscApiKey,
    polygonscan: polygonApiKey
  }
};
