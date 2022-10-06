// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    //using our PriceConverter library here
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    //immutable use since i_owner is assign later
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 0.5 * 10 ** 18;
    
    //a constructor runs once
    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        //msg.value is consider as first parameter for the function
        //the require keyword ensure the codition is met before funding occurs
        require(msg.value.getConversionRate() >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    //view dont modify the block
    function getVersion() public view returns (uint256){
        // ETH/USD price feed address of Goerli Network.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }
    
    
    modifier onlyOwner {
        // require(msg.sender == owner);

        //if---revert is mostly used
        if (msg.sender != i_owner) revert NotOwner();
        //_ here means the other code
        //if it is before the check, the other codes will run before the check
        _;
    }
    
    //widraw function has a modifier onlyOwner to ensure onlyOwner is run before the function
    function withdraw() public onlyOwner {

        //for loop
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //resetting the funders array to zero element
        funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
   
    //to ensure no funding go through the fund method
    fallback() external payable {
        fund();
    }

    //to ensure no funding go through the fund method
    receive() external payable {
        fund();
    }

}