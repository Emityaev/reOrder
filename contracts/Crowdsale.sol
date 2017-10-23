pragma solidity ^0.4.15;

import "contracts/RCoin.sol";
import "contracts/common/Owned.sol";
import "contracts/common/SafeMath.sol";

/**
 * @title Crowdsale
 * @dev Implementation for 3 phases and presale phase crowdsale.
*/
contract Crowdsale is Owned {

    using SafeMath for uint256;

    RCoin public token;

    uint256 constant tokenDecimals = 10**18;

    uint256 public totalSupply = 0;
    uint256 public totalAmount = 0;
    uint256 public currentAmount = 0;
    uint public transactionCounter = 0;

    uint256 public constant minCrowdsaleAmount =    35000 * tokenDecimals; // min amount for successfull crowdsale
    uint256 public constant maxAmount =             35000000 * tokenDecimals; // max minting amount
    uint256 public constant developmentFundAmount = 3500000 * tokenDecimals; // amount of development fund
    uint256 public constant teamAmount =            1750000 * tokenDecimals; // amount for team
    uint256 public constant bountyAmount =          1750000 * tokenDecimals; // bounty amount
    uint256 public constant bonusesTimeFrozen = 90 days; // freeze time for get all bonuses
    bool public bonusesPayed = false;

    uint256 public constant rateToEther = 100; // rate to ether, how much tokens gives to 1 ether

    uint public constant presaleBonus =      40;
    uint public constant firstPhaseBonus =   30;
    uint public constant secondPhaseBonus =  20;
    uint public constant thirdPhaseBonus =   10;
    uint256 public constant maxPresaleAmount =      1500000 * tokenDecimals;
    uint256 public constant maxFirstPhaseAmount =   4500000 * tokenDecimals;
    uint256 public constant maxSecondPhaseAmount =  15000000 * tokenDecimals;
    uint256 public constant maxThirdPhaseAmount =   28000000 * tokenDecimals;

    uint256 public constant minPresaleAmountForDeal = 10 * 1000000000000000000;

    mapping (address => uint256) amounts;

    uint public constant startTime =    1510056000; // start at 07 NOV 2017 07:00:00 EST
    uint public constant endTime =      1512648000; // end at   07 DEC 2017 07:00:00 EST

    modifier canBuy() {
        require(!isFinished());
        if (now < startTime) {
            require(msg.value >= minPresaleAmountForDeal && totalSupply < maxPresaleAmount);
        } else {
            require(totalSupply < maxThirdPhaseAmount);
        }
        _;
    }

    modifier canRefund() {
        require(isFinished() && totalSupply < minCrowdsaleAmount);
        _;
    }

    modifier canReward() {
        require(totalSupply >= minCrowdsaleAmount);
        _;
    }

    function Crowdsale() public {
        require(now < startTime);
        token = new RCoin();
    }

    function isFinished() public constant returns (bool) {
        return now > endTime || totalSupply >= maxThirdPhaseAmount;
    }

    function isSuccess() public constant returns (bool) {
        return totalSupply >= minCrowdsaleAmount;
    }

    function() external canBuy payable {
        uint bonus = getBonus();
        uint256 amount = msg.value;
        uint256 givenTokens = amount.mul(rateToEther).div(100).mul(100 + bonus);
        uint256 leftTokens = maxThirdPhaseAmount.sub(totalSupply);

        if (givenTokens > leftTokens) {
            givenTokens = leftTokens;
            uint256 needAmount = givenTokens.mul(100).div(100 + bonus).div(rateToEther);
            require(amount > needAmount);
            require(msg.sender.call.gas(3000000).value(amount - needAmount)());
            amount = needAmount;
        }

        // If success we don't need information about amounts for refunding.
        if (!isSuccess()) {
            amounts[msg.sender] = amount.add(amounts[msg.sender]);
        }

        totalAmount = totalAmount.add(amount);
        currentAmount = currentAmount.add(amount);

        totalSupply = totalSupply.add(givenTokens);
        token.mint(msg.sender, givenTokens);
        transactionCounter = transactionCounter + 1;
    }

    function getBonus() private returns (uint) {
        if (now < startTime) {
            return presaleBonus;
        } else if (totalSupply > maxSecondPhaseAmount) {
            return thirdPhaseBonus;
        } else if (totalSupply > maxFirstPhaseAmount) {
            return secondPhaseBonus;
        }
        return firstPhaseBonus;
    }

    function finishCrowdsale() external onlyOwner {
        require(isFinished() && isSuccess() && !bonusesPayed);
        uint256 bonuses = developmentFundAmount.add(teamAmount).add(bountyAmount);
        token.mint(this, bonuses);
        bonusesPayed = true;
        // after this action token will not be able to mint any more
        token.finishMinting();
    }

    function receiveFrozenBonuses() external onlyOwner {
        require(bonusesPayed);
        require(now > endTime + bonusesTimeFrozen);
        uint256 bonuses = developmentFundAmount.add(teamAmount).add(bountyAmount);
        token.transfer(msg.sender, bonuses);
    }

    //    function migrateToken(address newContract) external onlyOwner {
    //        require(isFinished());
    //        token.changeOwner(newContract);
    //    }

    function refund() external canRefund {
        uint256 amount = amounts[msg.sender];
        require(amount > 0);
        token.transfer(this, token.balanceOf(msg.sender));
        require(msg.sender.call.gas(3000000).value(amount)());
    }

    function withdraw() external onlyOwner canReward {
        require(msg.sender.call.gas(3000000).value(currentAmount)());
        currentAmount = 0;
    }

    function withdrawAmount(uint256 amount) external onlyOwner canReward {
        require(msg.sender.call.gas(3000000).value(amount)());
        if (currentAmount > amount) {
            currentAmount = currentAmount.sub(amount);
        } else {
            currentAmount = 0;
        }
    }
}