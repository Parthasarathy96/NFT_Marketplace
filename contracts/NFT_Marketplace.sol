// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title NFT Marketplace
/// @author Parthasarathy
/// @notice You can use this contract for buying and selling NFTs
contract MyNFTMarket is Ownable{

using Counters for Counters.Counter;
Counters.Counter private _NFTCount;

mapping(uint256 => MarketNFT) public MarketItemID;
enum NFTStatus{OPEN,UNPAID, UNSOLD, SOLD}

struct MarketNFT {
      uint256 id;
      address NFTcontract;
      uint256 tokenId;
      address payable seller;
      uint256 initialBid;
      uint256 endAuction;
      address highestBidder;
      uint256 currentBid;
      uint256 bidCount;
      NFTStatus _status;
    }

/// @notice  emited when a NFT is added to Marketplace
/// @dev Emitted at AddNFTToMarket function
event MarketItemCreated (
     uint256 id,
      address NFTcontract,
      uint256 tokenId,
      address payable seller,
      uint256 initialBid,
      uint256 endAuction,
      address highestBidder,
      uint256 currentBid,
      uint256 bidCount,
      NFTStatus _status

    );

event newBid(uint256 ID, uint256 newBid);
event NFTClaimed(uint256 ID, uint256 TokenID, address claimedBy);
event ETHClaimed(uint256 ID, uint256 TokenID, address seller);
event NFTRefunded(uint256 ID, uint256 TokenID, address seller);


 function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

function createAuction(address _contract, uint _tokenID, uint _initialBid, uint _endAuction) public  {
    require(isContract(_contract),"Invalid NFT Collection contract address");  
    require(IERC721(_contract).ownerOf(_tokenID) == msg.sender,"Caller is not the owner of the NFT");
    require(IERC721(_contract).getApproved(_tokenID) == address(this), "NFT must be approved to market");
    IERC721(_contract).transferFrom(msg.sender,address(this),_tokenID);

    _NFTCount.increment();
    uint ID = _NFTCount.current();

    address payable currentBidder = payable(address(0));

    MarketItemID[_tokenID] = MarketNFT(
        ID,
        _contract,
        _tokenID,
        payable(msg.sender),
        _initialBid,
        _endAuction,
        currentBidder,
        0,
        0,
        NFTStatus.OPEN
    );

    emit MarketItemCreated(
        ID,
        _contract,
        _tokenID,
        payable(msg.sender),
        _initialBid,
        _endAuction,
        currentBidder,
        0,
        0,
        NFTStatus.OPEN
    );

}

function bid(uint _auctionId, uint _amount) external  returns(bool bidStatus){

    require(MarketItemID[_auctionId]._status == NFTStatus.OPEN, "Auction is not open");
    MarketNFT storage auction = MarketItemID[_auctionId];
    if(_amount > auction.initialBid && _amount > auction.currentBid){
    address payable newBidder = payable(msg.sender);
    MarketItemID[_auctionId].highestBidder = newBidder;
    MarketItemID[_auctionId].currentBid = _amount;
    MarketItemID[_auctionId].bidCount++;

    emit newBid(auction.id, _amount);
    }
    return true;

}

function claimNFT(uint256 _auctionId) payable external{
    require(MarketItemID[_auctionId]._status == NFTStatus.OPEN, "Auction is still open");
    MarketNFT storage auction = MarketItemID[_auctionId];
    require(auction.highestBidder == msg.sender, "NFT can only claimed by the highest bidder");

    require(msg.value == auction.currentBid, "Send the exact Bid amount");
    IERC721(auction.NFTcontract).safeTransferFrom(address(this),auction.highestBidder, auction.tokenId);
    
    emit NFTClaimed(_auctionId, auction.tokenId, msg.sender);
}

function claimETH(uint256 _auctionId) external payable{
    require(MarketItemID[_auctionId]._status == NFTStatus.SOLD, "Auction is not complete");
    require(MarketItemID[_auctionId].seller == msg.sender, "Only seller allowed");
    MarketNFT storage auction = MarketItemID[_auctionId];
    address payable sellerAddress = payable(MarketItemID[_auctionId].seller);
    sellerAddress.transfer(MarketItemID[_auctionId].currentBid);
    emit ETHClaimed(_auctionId, auction.tokenId, msg.sender);
}

function Refund(uint256 _auctionId) external{
require(MarketItemID[_auctionId]._status == NFTStatus.UNSOLD, "Auction is still open");
MarketNFT storage auction = MarketItemID[_auctionId];
require(block.timestamp >= auction.endAuction);
IERC721(auction.NFTcontract).safeTransferFrom(address(this),auction.seller, auction.tokenId);
emit NFTRefunded(_auctionId, auction.tokenId, msg.sender);

}

function checkAuction(uint256 _auctionId) external returns(NFTStatus _status) {
    MarketNFT storage auction = MarketItemID[_auctionId];
    if(block.timestamp >= auction.endAuction){
        auction._status = NFTStatus.UNSOLD;
    }
    return auction._status;
}

}