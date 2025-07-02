// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1. 创建一个收款函数
// 2. 记录投资人并且查看
// 3. 在锁定期内达到目标值，生产商可以提款
// 4. 在锁定期内没有达到目标值，生产商可以退款

// 去中心化预言机  用于获取链下数据 ETH/USD
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 收款函数
contract FundMe {
    // 用来存储 众筹用户地址和金额
    mapping(address => uint256) public fundersToAmount;
    // 最小众筹金额  1 * 10 ** 18
    uint256 MINIMUM_VALUE = 5 * 10 ** 18; // USD

    AggregatorV3Interface internal dataFeed;

    // 锁定期目标值  10usdt
    uint256 constant TARGET = 20 * 10 ** 18; // USD

    address public owner;

    uint256 deploymentTimestamp;
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
        require(converEthToUsd(msg.value) >= MINIMUM_VALUE, "Send More ETH"); // 控制 输入金额必须大于 最小众筹输入金额 MINIMUM_VALUE
        require(
            block.timestamp < deploymentTimestamp + lockTime,
            "window is closed"
        );
        fundersToAmount[msg.sender] = msg.value;
    }

    /**
     * Returns the latest answer.   返回 ETH/USD 的价格
     */
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
        return (ethAmount * ethPrice) / (10 ** 8);
    }

    function transferOwnership(address newOwner) public onlyOnwer {
        owner = newOwner;
    }

    // 3. 在锁定期内达到目标值，生产商可以提款
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
