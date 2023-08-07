// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Conmigo provides a service for multiple people to collaborate to buy an NFT. The Conmigo account owns the NFT, and the owners of the Conmigo account hold Conmigo counts that correspond to the original Conmigo account and the NFT.
// - A Conmigo account is created with a collection of owners and a target NFT that they want to buy.
// - The Conmigo account has a balance of ETH.
// - The Conmigo account can buy the NFT in its name.
// - Any owner can deposit ETH into the Conmigo account, and the Conmigo contract will send them the same amount of ConmigoCoins for this instance of the contract, representing their ownership percentage of the original NFT.
// - If an owner has all the ConmigoCoins for this instance of the contract, then the Conmigo account can transfer the NFT to them to own by themselves.
contract Conmigo {
  // The seller of the NFT that this Conmigo account is buying.
  address public seller;

  // The NFT that this Conmigo account is buying.
  ERC721 public NFT;

  // The price of the NFT.
  uint256 public price;

  // The ConmigoCoin instance for this account.
  ConmigoCoin public conmigoCoin;

  // The owners of the Conmigo account.
  address[] public owners;

  // The Conmigo account's balance.
  uint256 public balance;

  constructor(address _seller, ERC721 _NFT, uint256 _price) {
    conmigoCoin = new ConmigoCoin(address(this), _NFT);
    seller = _seller;
    NFT = _NFT;
    price = _price;
  }

  function isRegistered(address user) public view returns (bool) {
    // Check if the user is in the list of owners.
    for (uint256 i = 0; i < owners.length; i++) {
      if (owners[i] == user) {
        return true;
      }
    }
    return false;
  }

  // Register a new owner, who deposits ETH into the Conmigo account. The 
  // same number of Conmigo coints are minted and sent to them.
  function register() external payable {
    // The owner must not already be registered.
    require(!isRegistered(msg.sender), "Conmigo: user is already registered");

    // Add the owner to the list of owners.
    owners.push(msg.sender);
  }

  function deposit() external payable {
    // The owner must be registered.
    require(isRegistered(msg.sender), "Conmigo: user is not registered");

    // The owner must deposit some ETH.
    require(msg.value > 0, "Conmigo: message value must be positive");

    // The deposit must not exceed the price of the NFT.
    require(balance + msg.value <= price, "Conmigo: deposit exceeds NFT price");

    // Transfer the sender's ETH to the Conmigo account's balance.
    balance += msg.value;

    // Mint the same number of Conmigo coins and send them to the owner.
    conmigoCoin.mint(msg.sender, msg.value);
  }

  // Buy the NFT in the name of the Conmigo account.
  function buy() external {
    // The Conmigo account must have enough funds to buy the NFT.
    require(balance == price, "Conmigo: insufficient funds to buy NFT");

    // Transfer the NFT to the Conmigo account.
    NFT.transferFrom(seller, address(this), price);
  }
}

// The Conmigo contract "breaks up" the original NFT into many ConmigoCoins.
contract ConmigoCoin is ERC721, Ownable {
  address public creator;
  ERC721 public NFT;

  uint256 _freshTokenId = 0;

  constructor(address _creator, ERC721 _NFT) ERC721("Conmigo", "CMG") {
    creator = _creator;
    NFT = _NFT;
  }

  function mint(address to, uint256 amount) public {
    // Only the creator can mint new tokens.
    require(msg.sender == creator, "ConmigoCoin: only the creator can mint");

    _freshTokenId = _freshTokenId + 1;

    uint256 finalFreshTokenId = _freshTokenId + amount;
    for (uint256 tokenId = _freshTokenId; tokenId < finalFreshTokenId; tokenId++) {
      super._mint(to, tokenId);
    }
    _freshTokenId = finalFreshTokenId;
  }
}

