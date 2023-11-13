//  _   _             _ _   
// | | | |           | | |  
// | | | | __ _ _   _| | |_ 
// | | | |/ _` | | | | | __|
// \ \_/ / (_| | |_| | | |_ 
//  \___/ \__,_|\__,_|_|\__|
//                         
// * ERC-4626 Vault Contract
// 
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC4626 {
    mapping(address => uint256) public shareHolders;
    mapping(address => mapping(uint => bool)) public hasVoted; //user > epoch > hasvoted

    uint256 public votingParam;
    uint256 public param;
    uint256 public votingTime; // Voting duration in blocks
    uint256 public votingUnlock;
    uint256 public yesVotes;
    uint256 public noVotes;
    uint256 public votingEpoch;

    bool public isVoting;


	constructor(
		ERC20 _asset,
		string memory _name,
		string memory _symbol
	) ERC4626(_asset) ERC20(_name, _symbol) {
      votingParam = 0;
      isVoting = false;
      votingTime = 10;
      votingEpoch = 0;
    }


    // -- Override Preset Methods --
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
      uint256 shares = super.deposit(assets, receiver);
      shareHolders[receiver] += assets;

      return shares;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override returns (uint256) {
      require(assets <= shareHolders[owner], 'Cannot withdraw more than deposot amount');

      shareHolders[owner] -= assets;
      uint256 shares = super.withdraw(assets, receiver, owner);
      
      return shares;
    }

    function getBalance(address holder) public virtual returns (uint256) {
      return shareHolders[holder];
    }


    // -- DAO Methods --
    function initiateVoting(uint256 suggestedParam) public {
      require(isVoting == false, 'Cannot initiate vote while another vote is in progress');
      require(totalSupply() / 5 < balanceOf(msg.sender), 'Need to own > 20% shares');

      votingParam = suggestedParam;
      votingUnlock = block.number + votingTime;
      isVoting = true;
      yesVotes = 0;
      noVotes = 0;
    }

    function vote(bool isYesVote) public {
      require(isVoting, 'Not currently voting');
      require(block.number < votingUnlock, 'Voting deadline has closed');
      require(hasVoted[msg.sender][votingEpoch] == false, 'Cannot vote twice');
      
      if (isYesVote) {
        yesVotes += balanceOf(msg.sender); // One vote for each share
      }
      else {
        noVotes += balanceOf(msg.sender);
      }
      hasVoted[msg.sender][votingEpoch] = true;
     }

    function closeVoting() public {
      require(block.number >= votingUnlock, 'Cannot stop voting before unlock time');

      isVoting = false;
      votingEpoch += 1;

      bool quorum = yesVotes + noVotes > totalSupply() / 10; // quorum hardcoded to 10%

      if ((quorum) && (yesVotes > noVotes)) {
        param = votingParam;
      }
    }

}
