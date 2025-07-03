<template>
  <div class="home-view">
    <WalletLogin />

    <!-- <input v-model.number="depositAmount" placeholder="输入存款金额 (ETH)" />
    <button @click="depositToContract">向合约存款</button> -->
    <button @click="getContractBalance">查询合约余额</button>
    <!-- <button @click="getMoney">提款</button> -->
    <p>合约余额: {{ contractBalance }} ETH</p>
    <a-textarea
      v-model:value="messageValue"
      placeholder="Autosize height based on content lines"
      auto-size
    />
    <a-button type="primary" @click="sendMessage">记账</a-button>
    <a-button type="primary" @click="getContractTodoList">查询列表</a-button>
  </div>
</template>

<script setup lang="ts">
  import { Todo } from '../types/ethers.ts'
  import WalletLogin from './WalletLogin.vue';
  import { onMounted, ref } from 'vue';
  import { ethers } from 'ethers';
  import ContractABI from '../../artifacts/contracts/FundMe.sol/FundMe.json';
  import { message } from 'ant-design-vue';

    const CONTRACT_ADDRESS = '0xc6e7DF5E7b4f2A278906862b61205850344D4e7d';

    const contractBalance = ref<string>('0');
    const contract = ref<ethers.Contract | null>(null);

    const messageValue = ref<string>('');
    const todoCount = ref<number>(0)
    const todoList = ref<Todo[]>([])


    // 初始化合约实例
    const initContract = async () => {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const contractInstance = new ethers.Contract(
        CONTRACT_ADDRESS,
        ContractABI.abi,
        signer
      );
      contract.value = contractInstance;

      contractInstance.on('SendMoneyToContract', (id, receiver, message, timestamp) => {
        localStorage.setItem("todoCount", id)
        const todoList = localStorage.getItem("todoList")
        let list: Todo[] = []
        if (todoList) {
          list = JSON.parse(todoList)
        }
        const todo = new Todo(id, receiver, message, timestamp)
        list.push(todo)
        todoCount.value = list.length
        localStorage.setItem("todoList", JSON.stringify(list))
      });
    };
    // 查询合约余额
    const getContractBalance = async () => {
      if (!contract.value) return;
      const balanceWei = await contract.value.getContractBalance();
      contractBalance.value = ethers.formatEther(balanceWei);
    };
    // 查询合约 todoList 列表
    const getContractTodoList = async()=>{
      if (!contract.value) return;
      todoList.value = await contract.value.getTodoList()
      console.log('合约记账列表',todoList.value);
    }

    const sendMessage = async() => {
      if (!contract.value) return;
      const tx = await contract.value.published(messageValue.value,{
        value: ethers.parseEther("1")
      })
      await tx.wait(); // 等待交易确认
      alert('存款成功！');
    }


    // 调用 payable 方法（附带 ETH）
    // const depositToContract = async () => {
    //   if (!contract.value || depositAmount.value <= 0) return;

    //   try {
    //     // const tx = await contract.value.fund({
    //     //   value: ethers.parseEther(depositAmount.value.toString()) // 将 ETH 转换为 Wei
    //     // });
    //     const priceEth = await contract.value.getChainlinkDataFeedLatestAnswer()
    //     console.log(85,depositAmount.value);
    //     console.log(85,depositAmount.value / Number(priceEth) * 10 ** 8);



    //     const tx = await contract.value.fund({
    //       value: depositAmount.value * 10 ** 26 / Number(priceEth)
    //     });

    //     await tx.wait(); // 等待交易确认
    //     alert('存款成功！');
    //     await getContractBalance(); // 更新合约余额显示
    //   } catch (error) {
    //     const errorMessage = parseError(error)
    //     alert(`存款失败: ${errorMessage}`);
    //   }
    // };




onMounted(()=>{
  if (!window.ethereum) {
    message.error("请先安装浏览器插件 Metamask")
    return
  }
  initContract()
  getContractBalance()
})

</script>

<style lang="scss" scoped>
.home-view{
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 800px;
  height: 600px;
  border-radius: 5px;
  border: solid 1px #000;
  .header{
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 50px;
    width: 100%;
    padding: 0 20px;
    border-bottom: 1px solid #000;
    .h-balance{
      font-weight: bold;
      span {
        color: aqua;

      }
    }
  }
}
</style>
