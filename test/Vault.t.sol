// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import {Test, console2} from "forge-std/Test.sol";
import { Vault } from "../src/Vault.sol";
import { DepositToken } from "../src/DepositToken.sol";

contract CounterTest is Test {

  Vault public vault;
  DepositToken public depositToken;
  address tokenOwner = makeAddr("tokenOwner");
  address vaultOwner = makeAddr("vaultOwner");
  address user = makeAddr("user");
  address user2 = makeAddr("user2");

  uint256 depositAmount = 100;
  uint256 withdrawAmount = 50;
  uint256 newVotingParam = 5;

  function setUp() public {
    vm.startPrank(tokenOwner);
    depositToken = new DepositToken(1000);
    depositToken.transfer(user, 100);
    vm.stopPrank();
    vault = new Vault(depositToken, "Vault", "VLT");
  }

  modifier userDeposit() {
    assertEq(depositAmount, depositToken.balanceOf(user));

    vm.startPrank(user);
    depositToken.approve(address(vault), depositAmount);
    vault.deposit(depositAmount, user);
    vm.stopPrank();

    _;
  }

  function test_Vault_Deposit() public userDeposit {
    assertEq(0, depositToken.balanceOf(user));
    assertEq(depositAmount, depositToken.balanceOf(address(vault)));
    assertEq(depositAmount, vault.getBalance(user));
    assertEq(depositAmount, vault.balanceOf(user));
  }
  
  function test_Vault_Withdraw() userDeposit public {
    vm.startPrank(user);

    vault.withdraw(withdrawAmount, user, user);
    assertEq(withdrawAmount, depositToken.balanceOf(user));
    assertEq(withdrawAmount, vault.getBalance(user));

    // cannot withdraw more than deposited
    vm.expectRevert();
    vault.withdraw(depositAmount, user, user);

    vm.stopPrank();
  }

  function test_Initiate_Voting() userDeposit public {
    uint256 initialParam = 0;
    vm.startPrank(user);

    assertEq(initialParam, vault.votingParam());
    assertEq(false, vault.isVoting());

    vault.initiateVoting(newVotingParam);

    // User can intiate a vote
    assertEq(newVotingParam, vault.votingParam());
    assertEq(true, vault.isVoting());
    assertEq(block.number + 10, vault.votingUnlock());

    // User can no longer initiate a second vote
    vm.expectRevert();
    vault.initiateVoting(newVotingParam);

    // User can not close voting yet
    vm.expectRevert();
    vault.closeVoting();
    vm.roll(vault.votingUnlock() / 2);
    vm.expectRevert();
    vault.closeVoting();
   
    // User can skip when voting time is over
    vm.roll(vault.votingUnlock());
    vault.closeVoting();

    vm.stopPrank();

    // Without 20% shares you can not initiate vote
    vm.expectRevert();
    vault.initiateVoting(newVotingParam);
  }

  function test_Voting() userDeposit public {
    vm.startPrank(user);
    vault.initiateVoting(newVotingParam);
    
    assertEq(0, vault.yesVotes());
    assertEq(0, vault.noVotes());
    
    vault.vote(true);
    assertEq(depositAmount, vault.yesVotes());

    vm.stopPrank();

  }
 
  function testFail_Vote_Twice() userDeposit public {
    vm.startPrank(user);
    vault.initiateVoting(newVotingParam);

    vault.vote(true);
    vault.vote(true);

    vm.stopPrank();
  }

  function testFail_Create_Vote_Under_Minimum() userDeposit public {
    vm.prank(tokenOwner);
    depositToken.transfer(user2, 10);

    vm.prank(user2);
    vault.initiateVoting(newVotingParam);
  }

  function test_Vote_Result() userDeposit public {
    vm.startPrank(user);
    vault.initiateVoting(newVotingParam);
    vault.vote(true);
    vm.stopPrank();

    vm.prank(tokenOwner);
    depositToken.transfer(user2, 10);

    vm.prank(user2);
    vault.vote(false);

    vm.roll(vault.votingUnlock());
    vault.closeVoting();
    assertEq(newVotingParam, vault.param());
  }
    
 
}
