// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RoboBank.sol";

contract RoboNFT is Ownable, ERC721 {
    //robo bank, our erc20 我们自己的erc20
    RoboBank private roboBank;

    //total supply
    uint256 public supplyLeft = 1000000;

    //token uri前缀
    string private tokenUriPreFix;

    //each account will have one commander which help your manage robots
    struct Commander {
        string name;
        string dna;
    }

    struct Robot {
        string dna;
    }

    //array store all commanders, index of array is used as commander's id
    Commander[] public commanders;

    //array store all robots
    Robot[] public robots;

    //account to commander id, which is the index in commanders
    mapping(address => uint) public ownerToCommander;

    //if robot dna exist; robot dna cannot be duplicated;
    mapping(string => bool) public ifRobotDnaExist;

    //robot id to owner address; we use REC721 _owners

    //address to robot count; we use ERC7212 _balances

    //event, new commander
    event NewCommander(uint id, string name, string dna, address indexed owner);

    //event, new robot
    event NewRobot(uint id, string robotDna, address indexed owner);

    constructor(
        address roboRankAddress,
        string memory _tokenUriPrefix,
        string memory _name,
        string memory _symbol
    ) Ownable(msg.sender) ERC721(_name, _symbol) {
        //when you invoke ownerToCommander.get(your account address) get 0,
        //it means that your account don't have a commander,
        //so you need create one. Also, we need ensure that no one's commander
        //will have a index of 0 in commanders array;
        commanders.push(Commander("init", "init"));

        //create roboBank's instance
        roboBank = RoboBank(roboRankAddress);

        tokenUriPreFix = _tokenUriPrefix;
    }

    //create commander
    function createCommander(string calldata name) public {

        require(ownerToCommander[msg.sender] == 0, "You already have a commander.");
        string memory dna = Strings.toString(block.timestamp);
        commanders.push(Commander(name, dna));
        uint commanderId = commanders.length - 1;
        ownerToCommander[msg.sender] = commanderId;

        if (roboBank.bankBalance() >= 1000) {
            if (!roboBank.hasGetFreeMoney(msg.sender)) {
                roboBank.getFreeMoneyOnlyOneTime(msg.sender);
            }
        }

        emit NewCommander(commanderId, name, dna, msg.sender);
    }

    //modify commander name
    function modifyCommanderName(string calldata newName) public {
        commanders[ownerToCommander[msg.sender]].name = newName;
    }

    //modify commander dna
    function modifyCommanderDna(string calldata newDna) public {
        commanders[ownerToCommander[msg.sender]].dna = newDna;
    }

    //mint robot
    function createRobot(string memory robotDna) public {
        require(supplyLeft >= 1, "Cat amount reach limit");
        require(
            ifRobotDnaExist[robotDna] == false,
            "Dna already Exist."
        );
        robots.push(Robot(robotDna));
        uint id = robots.length - 1;
        ifRobotDnaExist[robotDna] = true;

        //ERC721 mint
        _safeMint(msg.sender, id);
        supplyLeft -= 1;

        //pay money
        roboBank.transferMonenyBackToBank(100, msg.sender);
        emit NewRobot(id, robotDna, msg.sender);
    }

    //no burn robot
    // function burn(uint256 robotId) external onlyOwner {
    //     require(msg.sender == _ownerOf(robotId));
    //     ifRobotDnaExist[robots[robotId].dna] = false;
    //     _burn(robotId);
    // }

    struct QueryCatInfo {
        uint id;
        string dna;
    }

    //get myRobot
    function getMyRobots() public view returns (QueryCatInfo[] memory) {
        uint256 count = balanceOf(msg.sender);
        QueryCatInfo[] memory myRobotInfos = new QueryCatInfo[](count);
        if (count <= 0) {
            return myRobotInfos;
        }

        uint i = 0;
        for (uint j = 0; j < robots.length; j ++) {
            if (_ownerOf(j) == msg.sender) {
                myRobotInfos[i] = QueryCatInfo(j, robots[j].dna);
                i ++;
                if (i >= count) {
                    break;
                }
            } 
        }

        return myRobotInfos;
    }

    function tokenURI(uint256 _robotId) public view override returns (string memory) {
        // Implement your own token URI logic here
        return string(abi.encodePacked(tokenUriPreFix, robots[_robotId].dna));
    }

    function setTokenUriPrefix(string memory _newPrefix) public onlyOwner {
        tokenUriPreFix = _newPrefix;
    }

    function totalSupply() public view returns(uint) {
        return 1000000 - supplyLeft;
    }
}
