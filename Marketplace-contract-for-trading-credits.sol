// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title CreditMarketplace
 * @dev Contract for listing, buying and trading credits
 */
contract CreditMarketplace {
    // Credit structure
    struct Credit {
        uint id;
        address owner;
        string creditType; // e.g. "Carbon", "Renewable Energy", etc.
        uint amount;
        uint pricePerUnit;
        bool isListed;
    }

    // Credit ID counter
    uint private nextCreditId = 1;
    
    // Mapping from credit ID to Credit
    mapping(uint => Credit) public credits;
    
    // Events
    event CreditListed(uint indexed creditId, address indexed owner, string creditType, uint amount, uint pricePerUnit);
    event CreditPurchased(uint indexed creditId, address indexed oldOwner, address indexed newOwner, uint amount, uint totalPrice);
    event CreditDelisted(uint indexed creditId, address indexed owner);

    /**
     * @dev Lists a new credit on the marketplace
     * @param _creditType Type of the credit
     * @param _amount Amount of credits
     * @param _pricePerUnit Price per unit of credit
     * @return creditId The ID of the newly created credit
     */
    function listCredit(string memory _creditType, uint _amount, uint _pricePerUnit) public returns (uint) {
        require(_amount > 0, "Amount must be greater than zero");
        require(_pricePerUnit > 0, "Price must be greater than zero");
        
        uint creditId = nextCreditId++;
        
        credits[creditId] = Credit({
            id: creditId,
            owner: msg.sender,
            creditType: _creditType,
            amount: _amount,
            pricePerUnit: _pricePerUnit,
            isListed: true
        });
        
        emit CreditListed(creditId, msg.sender, _creditType, _amount, _pricePerUnit);
        
        return creditId;
    }
    
    /**
     * @dev Purchases credits from the marketplace
     * @param _creditId The ID of the credit to purchase
     * @param _amount Amount of credits to purchase
     */
    function purchaseCredit(uint _creditId, uint _amount) public payable {
        Credit storage credit = credits[_creditId];
        
        require(credit.isListed, "Credit is not listed for sale");
        require(credit.owner != msg.sender, "You cannot buy your own credits");
        require(credit.amount >= _amount, "Not enough credits available");
        
        uint totalPrice = _amount * credit.pricePerUnit;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        address payable seller = payable(credit.owner);
        
        // Update credit amount or remove if all purchased
        if (credit.amount == _amount) {
            credit.isListed = false;
        }
        credit.amount -= _amount;
        
        // Send payment to seller
        seller.transfer(totalPrice);
        
        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        
        emit CreditPurchased(_creditId, seller, msg.sender, _amount, totalPrice);
    }
    
    /**
     * @dev Removes a credit listing from the marketplace
     * @param _creditId The ID of the credit to delist
     */
    function delistCredit(uint _creditId) public {
        Credit storage credit = credits[_creditId];
        
        require(credit.owner == msg.sender, "Only owner can delist credits");
        require(credit.isListed, "Credit is not listed");
        
        credit.isListed = false;
        
        emit CreditDelisted(_creditId, msg.sender);
    }
    
    /**
     * @dev Gets details of a specific credit
     * @param _creditId The ID of the credit to fetch
     * @return id The ID of the credit
     * @return owner The address of the credit owner
     * @return creditType The type of credit
     * @return amount The amount of credits available
     * @return pricePerUnit The price per unit of credit
     * @return isListed Whether the credit is currently listed
     */
    function getCreditDetails(uint _creditId) public view returns (
        uint id,
        address owner,
        string memory creditType,
        uint amount,
        uint pricePerUnit,
        bool isListed
    ) {
        Credit storage credit = credits[_creditId];
        return (
            credit.id,
            credit.owner,
            credit.creditType,
            credit.amount,
            credit.pricePerUnit,
            credit.isListed
        );
    }
}
