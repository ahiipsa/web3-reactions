import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    testnet: {
      url: "https://api.s0.b.hmny.io",
      accounts: [process.env.TEST_PRIVATE_KEY || ''],
      chainId: 1666700000,
    },
    mainnet: {
      url: "https://api.harmony.one",
      accounts: [process.env.PRIVATE_KEY || ''],
      chainId: 1666600000,
    },
  }
};

export default config;
