//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract DutchAuction{
    address payable private seller;
    address payable private buyer;
    address payable private escrowAgent;

    uint private startingPrice;
    uint private currentPrice;
    uint private auctionEndTime;
    string private item;

    uint8 private auctionState;

    event AuctionStarted(uint256 startingPrice, uint256 auctionEndTime);
    event AuctionEnded(address winner, uint256 finalPrice);
    uint private biddingTime = 5 minutes;

    modifier onlySeller() {
        require(seller == msg.sender, "Only the seller can start the auction.");
        _;
    }

    constructor(address payable _seller, address payable _escrowAgent, uint _startingPrice, string memory _item){
        seller = _seller;
        escrowAgent = _escrowAgent;
        startingPrice = _startingPrice;
        currentPrice = startingPrice;
        item = _item;
        auctionEndTime = block.timestamp + biddingTime;
        auctionState = 0;    
    }

    function startAuction() public onlySeller{
        require(auctionState == 0, "The auction has already started.");
        auctionState = 1;
        emit AuctionStarted(startingPrice, auctionEndTime);
    }
    function getState() public view returns (uint){
        return auctionState;
    }
    function findcurrentPrice() public view returns (uint){
        return currentPrice;
    }

    function reducePrice() public onlySeller{
        require(auctionState == 1, "The auction has not started or has already ended.");
        require(block.timestamp < auctionEndTime, "The auction has already ended.");
        currentPrice = currentPrice-10;
    }

    function bid(uint256 _bid) public {
        require(auctionState == 1, "The auction has not started or has already ended.");
        require(block.timestamp < auctionEndTime, "The auction has already ended.");
        require(_bid >= currentPrice, "Bid must be greater than or equal to the current price.");
        require(_bid <= startingPrice, "Bid must be less than or equal to the starting price.");
        buyer = payable(msg.sender);
        currentPrice = _bid;
    }

    function endAuction() public onlySeller{
        require(auctionState == 1, "The auction has not started or has already ended.");
        if(buyer == address(0)){
            require(block.timestamp >= auctionEndTime, "The auction has not yet ended.");
        }
        auctionState = 2;
        emit AuctionEnded(buyer, currentPrice);
    }
    function buyItem() public payable {
        require(auctionState == 2, "The auction has not started or has already ended.");
        require(buyer == msg.sender, "WRONG GUY...NOT BUYER");
        // Release the funds to the escrow agent    
        escrowAgent.transfer(currentPrice);
    }

    function releaseFunds() public payable{
        require(escrowAgent == msg.sender, "Only the escrow agent can release the funds.");
        require(auctionState == 2, "The auction has not yet ended.");
        seller.transfer(currentPrice);
    }           
}
