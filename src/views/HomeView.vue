<template>
  <div>
    <button @click="connectWallet">Connect Wallet</button>
    <div>Connected Account: {{ account }}</div>
    <div>Connected balance: {{ balance }}</div>

    <input v-model.number="depositAmount" placeholder="输入存款金额 (ETH)" />
    <button @click="depositToContract">向合约存款</button>
    <button @click="getContractBalance">查询合约余额</button>
    <button @click="getMoney">提款</button>
    <p>合约余额: {{ contractBalance }} ETH</p>
  </div>
</template>

<script setup lang="ts">
  import { ref } from 'vue';
  import { ethers } from 'ethers';
  import ContractABI from '../../artifacts/contracts/FundMe.sol/FundMe.json';

  const CONTRACT_ADDRESS = '0xA24409Dd7Bf8A2EA34160182fB792AD269eE7750';

    const account = ref<string>('');
    const balance = ref<string>('');
    const depositAmount = ref<number>(0);
    const contractBalance = ref<string>('0');
    const contract = ref<ethers.Contract | null>(null);

    // 检查是否安装 MetaMask
    const checkMetaMask = () => {
      if (!window.ethereum) {
        alert('请安装 MetaMask!');
        return false;
      }
      return true;
    };

    // 连接 MetaMask 并获取账户
    const connectWallet = async () => {
      console.log(33);

      if (!checkMetaMask()) return;

      try {
        // 请求用户授权
        const accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'
        });
        console.log(35,accounts);


        account.value = accounts[0];
        await initContract();
        await getBalance(account.value); // 查询余额

      } catch (error) {
        console.error('用户拒绝连接:', error);
      }
    };

    // 查询余额
    const getBalance = async (address: string) => {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const balanceWei = await provider.getBalance(address);
      balance.value = ethers.formatEther(balanceWei); // 转为 ETH 单位
    };

    // 初始化合约实例
    const initContract = async () => {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      contract.value = new ethers.Contract(
        CONTRACT_ADDRESS,
        ContractABI.abi,
        signer
      );
    };

    // 调用 payable 方法（附带 ETH）
    const depositToContract = async () => {
      if (!contract.value || depositAmount.value <= 0) return;

      try {
        // const tx = await contract.value.fund({
        //   value: ethers.parseEther(depositAmount.value.toString()) // 将 ETH 转换为 Wei
        // });
        const priceEth = await contract.value.getChainlinkDataFeedLatestAnswer()
        console.log(85,depositAmount.value);
        console.log(85,depositAmount.value / Number(priceEth) * 10 ** 8);



        const tx = await contract.value.fund({
          value: depositAmount.value * 10 ** 26 / Number(priceEth)
        });

        await tx.wait(); // 等待交易确认
        alert('存款成功！');
        await getContractBalance(); // 更新合约余额显示
      } catch (error) {
        console.error('存款失败:', error);
        alert(`失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    };

    // 查询合约余额
    const getContractBalance = async () => {
      if (!contract.value) return;
      console.log(109,contract.value);

      const balanceWei = await contract.value.getContractBalance();
      console.log(102,balanceWei);
      console.log(103,await contract.value.getChainlinkDataFeedLatestAnswer());


      contractBalance.value = ethers.formatEther(balanceWei);
    };

     const getMoney = async () => {
      console.log(118,contract.value);


      const a = await contract.value.refund()
      console.log(121,a);

     }

</script>

<style lang="scss" scoped>
</style>
