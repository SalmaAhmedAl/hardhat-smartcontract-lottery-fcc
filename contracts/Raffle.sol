//Raffle
//Enter the lottery (playing some amount)
//Pick a random winner (verifiably random)
//Winner to be selected every X minutes -> completly automated
//we wil use -> ChainLink oracle -> Randomness, Automated Execution(Chainlink Keeper)

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFaild();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**
 * @title A sample Raffle Contract
 * @author Salma Ahmed Ali
 * @notice This contract is foe creating an untamperable decenteralized smart contract
 * @dev This implements Chainlink VRF v2 and Chainlink keepers
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface{
    /* Type declarations */

    enum RaffleState {
        OPEN,
        CALCULATING
    } // == uint256 0= OPEN  1= CALCULATING
    /*State Variables*/
    uint256 private immutable i_enterenceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLan;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    //Lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    /*Events */
    event RaffleEvent(address indexed player);
    event ReqeustedRaffleWinner(uint256 indexed reqeustId);
    event winnerPicked(address indexed winner);

    /*Functions */
    constructor(
        address vrfCoordinatorV2,
        uint256 enterenceFee,
        bytes32 gasLan,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_enterenceFee = enterenceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLan = gasLan;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    //if the lottery open, enter Raffle (Simply)
    function enterRaffle() public payable {
        //using custom error(instead of require) is more than Gas efficient
        //because instead of storing this string.. we just store it in our error code in our contract
        if (msg.value < i_enterenceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        //Emit an event when we update a dynamic array or mapping
        //Named events with the function name reversed
        emit RaffleEvent(msg.sender);
    }

    /**
     * @dev This function that chain link keeper nodes call
     * They look for the `upkeepNeeded` to return true
     * in this function if we return true, it's time to get a new random number
     * The following should be true in order to return true
     * 1.Our time interval should hae passed
     * 2.The lottery should have at least one player and some ETH
     * 3. Our subscription is funded with LINK
     * 4.The lottery should be in an open state
     */
    function checkUpkeep(
        bytes memory /* checkData*/
    ) public override returns (bool upKeepNeeded, bytes memory /*performData */) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 reqeustId = i_vrfCoordinator.requestRandomWords(
            i_gasLan, //gasLan
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit ReqeustedRaffleWinner(reqeustId);
    }

    function fulfillRandomWords(
        uint256,
        /* reqeustId*/ uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; //reset the Raffle state
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
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

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

}
