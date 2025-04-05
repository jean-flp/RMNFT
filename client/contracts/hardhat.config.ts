import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();


const privateKeys = (process.env.PRIVATE_KEY || "").split(",").map(k => k.trim());


const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    Ganache: {
      url: process.env.PROVIDER_URL,
      accounts: privateKeys,
    }
  }
};

export default config;
