//Raffle
//Enter the lottery (playing some amount)
//Pick a random winner (verifiably random)
//Winner to be selected every X minutes -> completly automated

//we wil use -> ChainLink oracle -> Randomness, Automated Execution(Chainlink Keeper)

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFaild();

contract Raffle is VRFConsumerBaseV2 {
    /*State Variables*/
    uint256 private immutable i_enterenceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLan;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQEUST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //Lottery variables
    address private s_recentWinner;
    /*Events */
    event RaffleEvent(address indexed player);
    event ReqeustedRaffleWinner(uint256 indexed reqeustId);
    event winnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 enterenceFee,
        bytes32 gasLan,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_enterenceFee = enterenceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLan = gasLan;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        //using custom error(instead of require) is more than Gas efficient
        //because instead of storing this string.. we just store it in our error code in our contract
        if (msg.value < i_enterenceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));
        //Emit an event when we update a dynamic array or mapping
        //Named events with the function name reversed
        emit RaffleEvent(msg.sender);
    }

    function requestRandomWinner() external {
        uint256 reqeustId = i_vrfCoordinator.requestRandomWords(
            i_gasLan, //gasLan
            i_subscriptionId,
            REQEUST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit ReqeustedRaffleWinner(reqeustId);
    }

    function fulfillRandomWords(uint256,/* reqeustId*/ uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        //require(success)
        if (!success) {
            revert Raffle__TransferFaild();
        }
        emit winnerPicked(recentWinner);
    }

    /* view/ pure functions*/
    function getEnterenceFee() public view returns (uint256) {
        return i_enterenceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
