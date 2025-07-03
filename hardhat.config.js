import "@nomicfoundation/hardhat-toolbox";
import { config } from 'dotenv'

// 加载 .env.shared 文件（路径相对于 hardhat.config.ts）
config({ path: './.env' }) // 如果 .env.shared 在根目录

const PRIVATE_KEY1 = process.env.PRIVATE_KEY1
const PRIVATE_KEY2 = process.env.PRIVATE_KEY2
const SEPOLIA_URL = process.env.SEPOLIA_URL

export default {
  solidity: '0.8.20',
  defaultNetwork: 'localhost',
  networks: {
    hardhat: {
      chainId: 31337, // 自定义 Chain ID（可选）
    },
    localhost: {
      // 显式配置本地网络（可选）
      url: 'http://127.0.0.1:8545',
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_URL,
      accounts: [PRIVATE_KEY1, PRIVATE_KEY2],
    },
  },
}
// 合约: 0xEDaEf92aD7A99e7f5d82bACC4d22cea0F9bF2F57
