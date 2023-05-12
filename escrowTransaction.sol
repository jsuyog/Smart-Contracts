// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

contract escrowTransaction {

    using Counters for Counters.Counter;

    Counters.Counter private iID;
    address public owner;
    address public escrow;

    uint256 listingFee;

    constructor(address _escrow) {
        owner = msg.sender;
        escrow = _escrow;
    }

    modifier itemExist (uint256 _itemID) {
        require(itemid > 0 && itemid <= iID.current());
        _;
    }

    event sellOrderplaced(uint256 _itemID, uint256 _sellPrice, address _seller);
    event cancelOrderplaced(uint256 _itemID);
    event buyOrderPlaced(uint256 _itemID, address _buyer);
    event buyerClaimedRefund(uint256 _itemID, address _buyer);
    event tradeComplete(uint256 _itemID, address buyer, address seller);

    struct Item {
        uint256 itemID;
        uint256 sellPrice;
        address seller;
        bool isSellerSatisfied;
        bool isBuyerSatisfied;
    }

    struct Buyer{
        address buyerAddress;
        uint256 buyPrice;
        uint256 timeStamp;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Can only be owner");
        _;
    }

    mapping (uint256 => Item) itemIDtoITEM;
    mapping (uint256 => Buyer) itemIDtoBUYER;

    function sellItem(uint256 _sellPrice) external payable {
        require(msg.value > 0 ,"Cannot be zero");
        require(msg.value >= listingFee ,"listing Fee is not there");
        require(_sellPrice > 0, "Can't sell for free");

        iID.increment();
        uint256 _itemID = iID.current();

        itemIDtoITEM[_itemID] = Item(
            _itemID,
            _sellPrice,
            msg.sender,
            false,
            false
        )

        emit sellOrderplaced(_itemID, _sellPrice, msg.sender);
    }

    function cancelSellOrder(uint256 _itemID) external itemExist(_itemID) {
        Item memory item = itemIDtoITEM[_itemID];

        require(item.seller == msg.sender, "Not the seller");

        delete itemIDtoITEM[_itemID];

        emit cancelOrderplaced(_itemID);
    } 

    function buyItem(uint256 _itemID, uint256 _buyPrice) external payable itemExist(_itemID){
        require(_buyPrice > 0, "Cannot buy free");

        Item _item = itemIDtoITEM[_itemID];

        require(_buyPrice >= _item.sellPrice, "Should be equal or greater than selling price");
        require(msg.value == _buyPrice, "Send exact money mentioned in buyPrice");

        itemIDtoBUYER[_itemID] = Buyer(
            msg.sender,
            _buyPrice,
            block.timestamp
        );

        emit(_itemID,msg.sender);
    }

    function isSellerSatisfied(uint256 _itemID, bool _reply) external itemExist(_itemID) returns(bool){
        require(itemIDtoITEM[_itemID].seller == msg.sender, "You are not seller");
        require(itemIDtoBUYER[_itemID].buyerAddress != address(0), "Not bought by anyone");

        itemIDtoITEM[_itemID].isSellerSatisfied = _reply;
        return _reply;
    }

    function isBuyerSatisfied(uint256 _itemID, bool _reply) external itemExist(_itemID) returns(bool) {
        require(itemIDtoBUYER[_itemID].buyerAddress == msg.sender, "You are not buyer");

        itemIDtoITEM[_itemID].isBuyerSatisfied = _reply;
        return _reply;
    }

    function claimRefundBuyer(uint256 _itemID) external itemExist(_itemID) {
        Buyer memory b = itemIDtoBUYER[_itemID];

        require(b.buyerAddress == msg.sender, "You are not buyer");

        payable(b.buyerAddress).transfer(b.buyPrice);

        delete itemIDtoBUYER[_itemID];

        emit buyerClaimedRefund(_item,msg.sender);
    }

    function sendFundToSeller(uint256 _itemID) external onlyOwner itemExist(_itemID) {
        Item memory i = itemIDtoITEM[_itemID];

        if(i.isBuyerSatisfied && i.isSellerSatisfied){
            payable(i.seller).transfer(itemIDtoBUYER[_itemID].buyPrice);

            delete itemIDtoBUYER[_itemID];

            emit tradeComplete(_itemID, itemIDtoBUYER[_itemID].buyerAddress, i.seller);
        }
    }

    function setListingFee(uint256 _listingFee) onlyOwner external returns(uint256) {
        listingFee = _listingFee;
        return listingFee;
    }

}
