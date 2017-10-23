pragma solidity ^0.4.15;

import "contracts/common/MintableToken.sol";

contract RCoin is MintableToken {

    string public constant name = "R Coin";

    string public constant symbol = "R";

    uint32 public constant decimals = 18;
}
