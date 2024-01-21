// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RoboNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RoboMarket is IERC721Receiver {

    RoboNFT roboNFT;
    RoboBank roboBank;
    address roboNFTAddress;

    struct SaleInfo {
        uint robotId;
        uint price;
    }

    SaleInfo[] public market;

    mapping(uint => uint) public robotIdToMarketId;
    mapping(uint => address) public robotIdToSalerAccount;

    constructor(address _robotNFTAddress, address _roboBankAddress) {
        roboNFT = RoboNFT(_robotNFTAddress);
        roboBank = RoboBank(_roboBankAddress);
        roboNFTAddress = _robotNFTAddress;
    }

    //sale
    //当用户在erc721合约中，把nft转到robo market合约账户下时，会调用这个函数
    //注意，这时候nft已经到了robo market的账户下
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        //这行代码没用
        require(operator != address(0));
        //只有我们的erc721合约才能调用这个函数
        require(msg.sender == roboNFTAddress);

        market.push(SaleInfo(tokenId, bytesToUint(data)));
        uint marketId = market.length - 1;
        robotIdToMarketId[tokenId] = marketId;
        robotIdToSalerAccount[tokenId] = from;
        return IERC721Receiver.onERC721Received.selector;
    }

    //unsale
    function unsale(uint robotId) public {
        //判断是否上架
        address saler = robotIdToSalerAccount[robotId];
        require( saler != address(0), "Robot is not in sale.");
        //判断是否是robot的所有者
        require(msg.sender == robotIdToSalerAccount[robotId], "Not your robot.");

        //把要下架的商品和最后一个商品交换位置
        uint marketId = robotIdToMarketId[robotId];
        SaleInfo memory saleInfo = market[market.length - 1];
        market[marketId] = saleInfo;
        robotIdToMarketId[saleInfo.robotId] = marketId;
        robotIdToMarketId[robotId] = market.length - 1;

        market.pop();
        //robotIdToMarketId可以不用管，我们通过robotIdToSalerAccount来判断是否处于出售状态
        robotIdToSalerAccount[robotId] = address(0);

        //把nft从robo market的账户下转回给saler
        roboNFT.safeTransferFrom(address(this), saler, robotId);
    }

    //buy
    function buyRobot(uint robotId) public {
        address saler = robotIdToSalerAccount[robotId];
        require(saler != address(0), "Not in sale");

        uint marketId = robotIdToMarketId[robotId];

        //pay money
        uint price = market[marketId].price;
        roboBank.transferWhenBuyNFT(msg.sender, saler, price);

        //offline in market 
        SaleInfo memory saleInfo = market[market.length - 1];
        market[marketId] = saleInfo;
        robotIdToMarketId[saleInfo.robotId] = marketId;
        robotIdToMarketId[robotId] = market.length - 1;

        market.pop();

        robotIdToSalerAccount[robotId] = address(0);

        //transfer ownership
        roboNFT.safeTransferFrom(address(this), msg.sender, robotId);
    }

    //set price
    function setPrice(uint _robotId, uint _price) public {
        require(robotIdToSalerAccount[_robotId] == msg.sender, "Not your robot");
        market[robotIdToMarketId[_robotId]].price = _price;
    }

    function bytesToUint(bytes memory data) private pure returns (uint256) {
        uint256 result;
        assembly {
            result := mload(add(data, 32))
        }
        return result;
    }

    function getMySale(address addr) public view returns(SaleInfo[] memory) {
        //初始长度2
        SaleInfo[] memory mysales = new SaleInfo[](0);
        uint j = 0;
        //遍历市场
        for (uint i =0; i<market.length; i++) {
            //如果是我的cat
            if (robotIdToSalerAccount[market[i].robotId] == addr) {
                //先看是否要扩容
                if (j >= mysales.length) {
                    SaleInfo[] memory newmysales = new SaleInfo[](mysales.length + 1);
                    for (uint e = 0; e<mysales.length; e++) {
                        newmysales[e] = mysales[e];
                    }
                    mysales = newmysales;
                }
                mysales[j] = market[i];
                j++;
            }
        }
        return mysales;
    }

    function getSaleCount() public view returns(uint256) {
        return market.length;
    }

    
}