// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract RandomWinnerGame is VRFConsumerBase, Ownable {
    // Chainlink variables
    uint256 public fee;
    bytes32 public keyHash;

    // Properties
    address[] public players;
    uint8 maxPlayers;
    bool public isGameStarted;
    uint256 entryFee;
    uint256 public gameId;

    // Events
    event GameStarted(uint256 gameId, uint8 maxPlayers, uint256 entryFee);
    event PlayerJoined(uint256 gameId, address player);
    event GameEnded(uint256 gameId, address winner, bytes32 requestId);

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 vrfKeyHash,
        uint256 vrfFee
    ) VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = vrfKeyHash;
        fee = vrfFee;
        isGameStarted = false;
    }

    function startGame(uint8 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!isGameStarted, "Game is currently running");
        delete players;
        maxPlayers = _maxPlayers;
        entryFee = _entryFee;
        isGameStarted = true;
        gameId += 1;
        emit GameStarted(gameId, maxPlayers, entryFee);
    }

    function joinGame() public payable {
        require(isGameStarted, "Game has not been started yet");
        require(msg.value == entryFee, "Value sent is not equal entryFee");
        require(players.length < maxPlayers, "Game is full");
        players.push(msg.sender);
        emit PlayerJoined(gameId, msg.sender);
        if (players.length == maxPlayers) {
            getRandomWinner();
        }
    }

    function getRandomWinner() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override
    {
        uint256 winnerIndex = randomness % players.length;
        address winner = players[winnerIndex];
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        emit GameEnded(gameId, winner, requestId);
        isGameStarted = false;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
