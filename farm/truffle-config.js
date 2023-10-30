const HDWalletProvider = require("@truffle/hdwallet-provider");
https://insiders.vscode.dev/profile/github/9264bf3e0cb6c2765871d5e230075404
require('dotenv').config();

module.exports = {
  contracts_build_directory: "./build",
  
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"
    },
    fantom: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, "https://rpcapi.fantom.network"),
      network_id: 250,
      gasPrice: 22000000000,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    ftmtest: {
      provider: () => new HDWalletProvider(process.env.private_key, `https://rpc.testnet.fantom.network/`),
      network_id: 4002,//0x61,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
  },

  compilers: {
    solc: {
      version: "0.6.12",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200
       },
      }
    }
  },

  plugins: ['truffle-plugin-verify'],
  
  api_keys: {
    etherscan: process.env.etherscan_api_key,
    bscscan: process.env.bscscan_api_key
  },
};
