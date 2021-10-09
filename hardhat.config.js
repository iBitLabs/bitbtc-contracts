require("@nomiclabs/hardhat-waffle")
require('@openzeppelin/hardhat-upgrades')
require("dotenv").config()

const { MNEMONIC, INFURA_KEY } = process.env

module.exports = {
  defaultNetwork: 'local',
  networks: {
    local: {
      url: "http://0.0.0.0:8545",
      chainId: 1234,
      accounts: {
        mnemonic: MNEMONIC,
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "istanbul",
        },
      },
    ],
  },
  paths: {
    artifacts: "./build/artifacts",
    cache: "./build/cache",
    sources: "./contracts",
  },
}
