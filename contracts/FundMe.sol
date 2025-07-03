// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// 使用console.log()输出日志
import "hardhat/console.sol";
// 合约功能一：实现一个简单的待办事项合约，
    // 1.包括发布待办事项、查看待办事项列表
// 合约功能二：实现一个简单的合约锁定期
    // 1.每发送一个待办事项 都需要往合约发送 至少1ETH用于众筹  合约锁定期阈值为 30ETH  合约时效为 30分钟
    // 2.在锁定期内 任何人不能进行提款操作
    // 3.在锁定期外 如果没有达到30ETH阈值 开发商可以对用户进行退款 
    // 3.在锁定期外 如果达到30ETH阈值 开发商可以提款


// 1. 创建一个收款函数
// 2. 记录投资人并且查看
// 3. 在锁定期内达到目标值，生产商可以提款
// 4. 在锁定期内没有达到目标值，生产商可以退款

// 去中心化预言机  用于获取链下数据 ETH/USD
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 收款函数
contract FundMe {

    struct Todo {
        uint256 id;
        address author;
        string message;
        uint256 timestamp;
    }

    // 事件：NewTodo，用于记录新创建的待办事项
    event NewTodo(
        uint256 todoID,
        address indexed from,
        string message,
        uint256 timestamp
    );

    // 事件：SendMoneyToContract，用于记录向合约发送以太币的事件
    event SendMoneyToContract(
        uint256 todoID,
        address receiver,
        string message,
        uint256 timestamp
    );

    // 状态变量：todoID，用于记录待办事项的ID
    // 状态变量：todoList，用于存储待办事项列表
    uint256 public todoID;
    Todo[] public todoList;


    // 用来存储 众筹用户地址和金额
    mapping(address => uint256) public fundersToAmount;
    // 最小众筹金额  1 * 10 ** 18
    uint256 MINIMUM_VALUE = 1 * 10 ** 18;
    AggregatorV3Interface internal dataFeed;
    // 锁定期目标值  
    uint256 constant TARGET = 30 * 10 ** 18;

    // 用于记录合约的拥有者
    address public owner;
    // 当前时间
    uint256 deploymentTimestamp;
    // 阈值时间
    uint256 lockTime;
    address erc20Addr;
    bool public getFundSuccess;
    constructor(uint256 _lockTime) {
        // Sepolia  ETH/USD测试网
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        owner = msg.sender;
        deploymentTimestamp = block.timestamp; // 记录当前时间
        lockTime = _lockTime;
    }

    function fund() external payable {
        require(msg.value >= MINIMUM_VALUE, "Send More ETH"); // 控制 输入金额必须大于 最小众筹输入金额 MINIMUM_VALUE
        require(
            block.timestamp < deploymentTimestamp + lockTime,
            "window is closed"
        );
        fundersToAmount[msg.sender] = msg.value;
    }

    
    // 返回 ETH/USD 的价格
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    // eth 转换为 usd
    function converEthToUsd(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return ethAmount * ethPrice / (10 ** 8);
    }

    function transferOwnership(address newOwner) public onlyOnwer {
        owner = newOwner;
    }

    // 3. 达到目标值，生产商可以提款
    function getFund() external windowClose onlyOnwer {
        require(
            converEthToUsd(address(this).balance) >= TARGET,
            "TARGET is not reached"
        );

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success, "1");

        // call
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(success, "transfer tx failed");

        getFundSuccess = true; // flag
    }

    function getContractBalance() public view returns (uint) {
      return address(this).balance;
    }

    // 4. 在锁定期内没有达到目标值，生产商可以退款
    function refund() external windowClose {
        require(
            converEthToUsd(address(this).balance) < TARGET,
            "TARGET is reached"
        );
        require(fundersToAmount[msg.sender] != 0, "there is no fund for you");

        bool success;
        (success, ) = payable(msg.sender).call{
            value: fundersToAmount[msg.sender]
        }("");
        require(success, "transfer tx failed");
        fundersToAmount[msg.sender] = 0;
    }

    function setFunderToAmount(
        address funder,
        uint256 amountToUpdate
    ) external {
        require(
            msg.sender == erc20Addr,
            "You do not have permission to call this function"
        );
        fundersToAmount[funder] = amountToUpdate;
    }

    function setErc20Addr(address _erc20Addr) public onlyOnwer {
        erc20Addr = _erc20Addr;
    }


    // 查询合约中的ETH
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 用于获取待办事项列表
    function getTodoList() public view returns (Todo[] memory) {
        return todoList;
    }


    // 函数：published，用于发布新的待办事项
    function published(string memory _message) public payable{
      console.log(_message); // 打印字符串


      todoID += 1;
      Todo memory item = Todo(todoID, msg.sender, _message, block.timestamp);

      todoList.push(item);

      emit NewTodo(todoID, msg.sender, _message, block.timestamp);

      require(msg.value == 1 ether, "Must send exactly 1 ETH"); // 1 ETH = 10^18 wei
      console.log(msg.value); // 打印字符串
      // (bool success, ) = payable(address(this)).call{value: msg.value}("");
      // require(success, "\u5411\u5408\u7ea6\u6c47\u6b3e\u5931\u8d25");
      emit SendMoneyToContract(todoID, msg.sender, _message, block.timestamp);

    }

    

    modifier windowClose() {
        require(
            block.timestamp >= deploymentTimestamp + lockTime,
            "window is not closed"
        );
        _;
    }

    modifier onlyOnwer() {
        require(
            msg.sender == owner,
            "this function can onlt be called by owner"
        );
        _;
    }
}
