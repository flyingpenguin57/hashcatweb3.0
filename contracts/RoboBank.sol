// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Implementing the ERC20Token interface
contract RoboBank is IERC20, Ownable {

    //余额
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    //每个账号可以免费从银行领取100个币
    mapping(address => bool) public hasGetFreeMoney;

    //货币总量 1亿个，精度是10
    uint256 private totalSupply_ = 1000000000;
    //精度10
    uint8 private decimal_ = 1;
    //银行余额 初始为1亿
    uint256 public bankBalance = 1000000000;
    //robot nft合约地址
    address private roboNFTAddress;
    //robot market合约地址
    address private roboMarketAddress;

    //构造函数
    constructor() Ownable(msg.sender) {}  

    //standard erc20 function 获取货币总量
    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }

    //standard erc20 function 查询账户余额
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return balances[account];
    }

    //standard erc20 function 转账
    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    //standard erc20 function 查询allowance
    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    //standard erc20 function 批准allowance
    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //standard erc20 function 花费allowance
    function transferFrom(
        address sender,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(
            amount <= allowances[sender][msg.sender],
            "Insufficient allowance"
        );
        balances[sender] -= amount;
        balances[to] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, to, amount);
        return true;
    }

    //standard erc20 function 查看货币精度
    function decimals() public view override returns (uint8) {
        return decimal_;
    }

    //customized function 查看银行账户余额
    function getBankBalance() external view returns (uint256) {
        return bankBalance;
    }

    //customized function 从银行免费获取100个币，每个账号限一次
    function getFreeMoneyOnlyOneTime(address _addr) external returns (bool) {
        require(hasGetFreeMoney[_addr] == false);
        require(bankBalance >= 1000, "Bank balance insufficient");
        bankBalance -= 1000;
        balances[_addr] += 1000;
        hasGetFreeMoney[_addr] = true;
        return true;
    }

    //customized function 铸造nft时，用户需要向银行付10个币；只用robot nft合约可以进行这个操作
    function transferMonenyBackToBank(uint256 _money, address from) external returns (bool) {
        require(msg.sender == roboNFTAddress, "No Access");
        require(
            balances[from] >= _money,
            "You don't have enough balance."
        );
        balances[from] -= _money;
        bankBalance += _money;
        return true;
    }

    //customize function 用户在购买nft时，向卖家转账；只用robot market合约可以进行这个操作
    function transferWhenBuyNFT(address from, address to, uint amount) external {
        require(msg.sender == roboMarketAddress, "No Access");
        require(balances[from] >= amount, "Insufficient balance");
        balances[from] -= amount;
        balances[to] += amount;
    }

    //设置robo nft合约的地址
    function setRoboNFTAddress(address _addr) public onlyOwner() {
        roboNFTAddress = _addr;
    }

    //设置robo market合约的地址
    function setRoboMarketAddress(address _addr) public onlyOwner() {
        roboMarketAddress = _addr;
    }
}
