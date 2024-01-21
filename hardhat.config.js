require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    hardhat: {
      gasPrice: 8000000000, // 设置 Gas Price
      gas: 12450000, // 设置 Gas Limit
    },
  }
};
