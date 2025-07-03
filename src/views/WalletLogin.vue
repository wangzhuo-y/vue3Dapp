<template>
  <div class="wallet-login">
    <div class="h-balance">Balances: <span>{{ balances }}</span></div>
    <div class="h-wallet">
      <a-button type="primary" v-if="account" @click="disconnectWallet">断开连接</a-button>
      <a-button type="primary" @click="connectWallet">{{ account ? account.slice(0, 12) + '...' : "Connect Wallet"}}</a-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref} from 'vue'
import { ethers } from "ethers"
import { message } from 'ant-design-vue';

const account = ref<string | undefined>(localStorage.getItem("account") || "") // 钱包地址定义
const chainId = ref<string | undefined>(localStorage.getItem("chainId") || "") // chainId
const balances = ref<string | undefined>("") // chainId

// 连接钱包
const connectWallet = async() => {
  try {
    if (!window.ethereum) {
      console.log("-------------", ethers.getDefaultProvider())
      message.error('请先安装浏览器插件 Metamask');
      return
    }

    const provider = new ethers.BrowserProvider(window.ethereum) // 提供者
    const signer = await provider.getSigner() // 钱包签名
    account.value = await signer.getAddress() // 钱包地址

    const network = await provider.getNetwork()
    chainId.value = network.chainId.toString()
    // 保存相关信息到本地
    localStorage.setItem("chainId", chainId.value)
    localStorage.setItem("account", account.value)
    message.success('连接钱包成功');
    await getBalance(account.value)
  } catch (error) {
    console.log('连接钱包失败：', error)
  }
}

// 断开连接
const disconnectWallet = async() => {
if (localStorage.getItem("account")) {
    account.value = ""
    localStorage.removeItem("account")
    message.warning("断开钱包成功")
    balances.value = ''
  }
}

// 查询钱包余额
const getBalance = async (address: string) => {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const balanceWei = await provider.getBalance(address);
  balances.value = ethers.formatEther(balanceWei); // 转为 ETH 单位
};

onMounted(() => {
  if (window.ethereum) { m
    if(account.value){
      getBalance(account.value || '')
    }
    window.ethereum.on("accountsChanged", function (accounts: string[]) {
      // 钱包账户变化
      console.log("钱包账户变化", accounts[0])
      account.value = accounts[0]
      balances.value = ""
      localStorage.setItem("account", account.value)
    })
    window.ethereum.on("chainChanged", async function async(chainId: number) {
      // 切换网络
      console.log("切换网络", chainId)
      localStorage.setItem("chainId", chainId.toString())
      await getBalance(account.value || "")
    })
  }
})
</script>
<style lang="scss" scoped>
.wallet-login{
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 50px;
    width: 100%;
    padding: 0 20px;
    border-bottom: 1px solid #000;
    .h-balance{
      flex: 1;
      font-weight: bold;
      span {
        color: aqua;

      }
    }
    .h-wallet{
      display: flex;
      gap: 16px;
      width: 220px;
      justify-content: flex-end
    }
  }
</style>
