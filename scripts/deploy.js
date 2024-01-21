const { ethers } = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RoboBankContract = await ethers.getContractFactory('RoboBank');
  const roboBank = await RoboBankContract.deploy();

  console.log("RoboBank address:", await roboBank.getAddress());

  const roboBankAddress = await roboBank.getAddress();
  const RoboNFTContract = await ethers.getContractFactory('RoboNFT');
  const roboNFT = await RoboNFTContract.deploy(roboBankAddress, "https://robohash.org/", "RoboHash", "RoboHash");

  console.log("RoboNFT address:", await roboNFT.getAddress());

  const roboNFTAddress = await roboNFT.getAddress();
  const RoboMarketContract = await ethers.getContractFactory('RoboMarket');
  const roboMarket = await RoboMarketContract.deploy(roboNFTAddress, roboBankAddress);

  console.log("RoboMarket address:", await roboMarket.getAddress());

  const result1 = await roboBank.setRoboNFTAddress(roboNFTAddress);
  console.log('Result of someFunction:', result1.toString());

  const result2 = await roboBank.setRoboMarketAddress(roboBankAddress);
  console.log('Result of someFunction:', result2.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
