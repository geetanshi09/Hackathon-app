// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeNSeekGameV3 is Ownable {
    
    struct Game {
        address creator;
        uint256 numClues;
        uint256 prizeMoney;
        uint256 entryFee; // Entry fee for participants, now stored in the game struct
        uint256 startTime;
        uint256 endTime;
        string[] clues;
        string[] locations;
        uint256[] latitudes;
        uint256[] longitudes;
        uint256 maxParticipants;
        bool isActive;
        bool treasureFound;
        address winner;
    }

    IERC20 public token; // ERC20 Token for prize and entry fee
    uint256 public gameIdCounter = 1; // Unique identifier for each game
    uint256 public distanceTolerance = 100; // Tolerance range for geolocation matching (in meters)

    mapping(uint256 => Game) public games; // Game ID to Game details mapping
    mapping(uint256 => mapping(address => bool)) public hasJoined; // Tracks if a player has joined a game
    mapping(uint256 => mapping(address => uint256)) public playerProgress; // Tracks player progress in a game
    mapping(uint256 => uint256) public participantCount; // Tracks the number of participants per game
    mapping(address => uint256) public activeGame; // Tracks which game a player is currently active in

    event GameCreated(uint256 gameId, address creator, uint256 prizeMoney, uint256 numClues, uint256 maxParticipants, uint256 endTime, uint256 entryFee);
    event JoinedGame(uint256 gameId, address player);
    event ClueCompleted(uint256 gameId, address player, uint256 clueIndex);
    event TreasureFound(uint256 gameId, address winner, uint256 prizeMoney);
    event GameExpired(uint256 gameId);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Game creator creates a new game with clues, locations, time constraints, max participants, and entry fee
    function createGame(
        uint256 _numClues,
        string[] memory _locations,
        string[] memory _clues,
        uint256[] memory _latitudes,
        uint256[] memory _longitudes,
        uint256 _prizeMoney,
        uint256 _duration, // Time limit in seconds
        uint256 _maxParticipants,
        uint256 _entryFee // Entry fee set by the creator
    ) public {
        require(_locations.length == _numClues, "Number of locations must match clues");
        require(_clues.length == _numClues, "Number of clues must match locations");
        require(_latitudes.length == _numClues && _longitudes.length == _numClues, "Coordinates must match number of clues");
        require(_duration > 0, "Duration must be greater than zero");
        require(_maxParticipants > 0, "Max participants must be greater than zero");

        // Deduct prize money from game creator
        require(token.transferFrom(msg.sender, address(this), _prizeMoney), "Failed to transfer prize money");

        // Create new game
        games[gameIdCounter] = Game({
            creator: msg.sender,
            numClues: _numClues,
            prizeMoney: _prizeMoney,
            entryFee: _entryFee, // Store the entry fee in the game struct
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            clues: _clues,
            locations: _locations,
            latitudes: _latitudes,
            longitudes: _longitudes,
            maxParticipants: _maxParticipants,
            isActive: true,
            treasureFound: false,
            winner: address(0)
        });

        emit GameCreated(gameIdCounter, msg.sender, _prizeMoney, _numClues, _maxParticipants, block.timestamp + _duration, _entryFee);

        gameIdCounter++; // Increment game ID for the next game
    }

    // Players join the game by paying an entry fee
    function joinGame(uint256 _gameId) public {
        require(games[_gameId].isActive, "Game is not active");
        require(!hasJoined[_gameId][msg.sender], "Player already joined");
        require(participantCount[_gameId] < games[_gameId].maxParticipants, "Maximum participants reached");
        require(block.timestamp < games[_gameId].endTime, "Game has expired");
        require(activeGame[msg.sender] == 0, "Player is already participating in another game");

        // Transfer entry fee from the player to the contract
        require(token.transferFrom(msg.sender, address(this), games[_gameId].entryFee), "Failed to pay entry fee");

        hasJoined[_gameId][msg.sender] = true;
        playerProgress[_gameId][msg.sender] = 0; // Player starts with 0 clues completed
        participantCount[_gameId]++;
        activeGame[msg.sender] = _gameId; // Mark the game as the active game for this player

        emit JoinedGame(_gameId, msg.sender);
    }

    // Validate location based on geographic coordinates
    function validateLocation(uint256 _gameId, uint256 _clueIndex, uint256 _latitude, uint256 _longitude) internal view returns (bool) {
        uint256 latDiff = distance(games[_gameId].latitudes[_clueIndex], _latitude);
        uint256 lonDiff = distance(games[_gameId].longitudes[_clueIndex], _longitude);

        return (latDiff <= distanceTolerance && lonDiff <= distanceTolerance);
    }

    // Calculate the distance between two coordinates (simplified for example)
    function distance(uint256 coord1, uint256 coord2) internal pure returns (uint256) {
        if (coord1 > coord2) {
            return coord1 - coord2;
        } else {
            return coord2 - coord1;
        }
    }

    // Players complete clues one by one, with geolocation validation
    function completeClue(uint256 _gameId, uint256 _latitude, uint256 _longitude) public {
        require(games[_gameId].isActive, "Game is not active");
        require(hasJoined[_gameId][msg.sender], "Player not part of the game");
        require(!games[_gameId].treasureFound, "Treasure already found");
        require(block.timestamp < games[_gameId].endTime, "Game has expired");

        uint256 currentProgress = playerProgress[_gameId][msg.sender];
        require(currentProgress < games[_gameId].numClues, "All clues completed");

        // Validate player's current location
        require(validateLocation(_gameId, currentProgress, _latitude, _longitude), "Player not at the correct location");

        // Update player progress
        playerProgress[_gameId][msg.sender]++;
        
        emit ClueCompleted(_gameId, msg.sender, currentProgress + 1);

        // Check if all clues are completed
        if (playerProgress[_gameId][msg.sender] == games[_gameId].numClues) {
            // Mark the player as the winner if the treasure is found first
            games[_gameId].treasureFound = true;
            games[_gameId].winner = msg.sender;
            games[_gameId].isActive = false;

            // Mark the player as inactive in their current game
            activeGame[msg.sender] = 0;

            // Transfer the prize money to the winner
            require(token.transfer(msg.sender, games[_gameId].prizeMoney), "Failed to transfer prize money");

            emit TreasureFound(_gameId, msg.sender, games[_gameId].prizeMoney);
        }
    }

    // Check if the game has expired
    function checkExpiration(uint256 _gameId) public {
        require(block.timestamp > games[_gameId].endTime, "Game is still active");
        if (!games[_gameId].treasureFound) {
            games[_gameId].isActive = false;

            emit GameExpired(_gameId);
        }
    }

    // View game details (clues and locations are hidden from non-participants)
    function getGameDetails(uint256 _gameId) public view returns (address, uint256, uint256, uint256, bool, bool, address, uint256) {
        Game memory game = games[_gameId];
        return (game.creator, game.numClues, game.prizeMoney, game.entryFee, game.isActive, game.treasureFound, game.winner, game.endTime);
    }
}
