// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

contract NumberGuessingGame is Ownable {
    using SafeERC20 for IERC20;

    // Token used for the game
    IERC20 public token;

    // Game levels
    enum GameLevel {
        Easy,
        Medium,
        Difficult
    }

    // Player structure
    struct Player {
        uint256 balance;
        uint256 consecutiveWins;
        uint256 consecutiveWinsInARow;
    }

    // Mapping of player addresses to their information
    mapping(address => Player) public players;

    uint public oneQuintillion = 1e18;

    // Percentage of protection fund fee (2%)
    uint256 public protectionFundFeePercentage = 2;

    // Events
    event GamePlayed(address indexed player, GameLevel level, uint256 number, uint256 stake, bool win, uint256 reward);

    // Constructor
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // Function to deposit tokens
    function getPlayerData(address player) public view returns (Player memory) {
        console.log('players', player);
        return players[player];
    }

    // Function to deposit tokens
    function deposit(uint256 amount) external {
        console.log(amount, msg.sender);
        players[msg.sender].balance += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Function to play the game
    function playGame(GameLevel level, uint256 number, uint256 stake) external returns (bool) {
        require(players[msg.sender].balance >= stake, 'Insufficient balance');

        // Calculate protection fund fee
        uint256 protectionFundFee = (stake * protectionFundFeePercentage) / 100;

        // Deduct protection fund fee from player's stake
        uint256 effectiveStake = stake - protectionFundFee;

        // Perform game logic based on the chosen level
        bool win = false;
        uint256 reward = 0;

        if (level == GameLevel.Easy) {
            require((100 * 1e18) >= stake, 'Stake amount should be between 1 - 100');
            require(number >= 1 && number <= 3, 'Number should be between 1 and 3');

            // Easy game logic
            uint256 generatedNumber = generateRandomNumber(3);

            win = (number == generatedNumber);
            reward = calculateEasyReward(stake, win);
        } else if (level == GameLevel.Medium) {
            require((1000 * 1e18) >= stake && stake >= (100 * 1e18), 'Stake amount should be between 100 - 1000');
            require(number >= 1 && number <= 5, 'Number should be between 1 and 5');

            // Medium game logic
            uint256 generatedNumber = generateRandomNumber(5);

            win = (number == generatedNumber);
            reward = calculateMediumReward(stake, win);
        } else if (level == GameLevel.Difficult) {
            require((100000 * 1e18) >= stake && stake >= (1000 * 1e18), 'Stake amount should be between 1000 - 100000');
            require(number >= 1 && number <= 10, 'Number should be between 1 and 10');

            // Difficult game logic
            uint256 generatedNumber = generateRandomNumber(10);

            win = (number == generatedNumber);
            reward = calculateDifficultReward(stake, win);
        }

        // Update player information
        players[msg.sender].consecutiveWins = win ? players[msg.sender].consecutiveWins + 1 : 0;
        players[msg.sender].consecutiveWinsInARow = win ? players[msg.sender].consecutiveWinsInARow + 1 : 0;
       
        // Transfer protection fund fee based on the result
        if (win) {
            // Transfer protection fund fee to project treasury
            token.safeTransfer(owner(), protectionFundFee);
        } else {
            // Return protection fund fee to player's balance
            players[msg.sender].balance += protectionFundFee;
        }
       
        // Transfer tokens based on the result
        if (win) {
            players[msg.sender].balance += reward;
        } else {
            players[msg.sender].balance -= effectiveStake;
        }

        // Emit event
        emit GamePlayed(msg.sender, level, number, stake, win, reward);
        return true;
    }

    // Function to withdraw remaining balance
    function withdraw() external {
        uint256 balance = players[msg.sender].balance;
        require(balance > 0, 'No balance to withdraw');

        token.safeTransfer(msg.sender, balance);
        players[msg.sender].balance = 0;
    }

    // Function to generate a random number within a specified range
    function generateRandomNumber(uint256 upperLimit) internal view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee, block.number, msg.sender)));

        return randomNumber % upperLimit;
    }

    function calculateEasyReward(uint256 stake, bool win) internal view returns (uint256) {
        uint256 baseRewardPercentage = 500; // 500% base reward
        uint256 bonusRewardPercentage = 2000; // 2000% bonus reward

        if (win) {
            // Check if the player has won 3 times in a row
            if (players[msg.sender].consecutiveWins == 3) {
                // If yes, provide 2000% bonus reward
                return (stake * bonusRewardPercentage) / 100;
            } else {
                // Otherwise, provide the base reward
                return (stake * baseRewardPercentage) / 100;
            }
        }

        // If the player loses, no reward
        return 0;
    }

    function calculateMediumReward(uint256 stake, bool win) internal view returns (uint256) {
        uint256 baseRewardPercentage = 1000; // 1000% base reward
        uint256 bonusRewardPercentage = 5000; // 5000% bonus reward

        if (win) {
            // Check if the player has won 7 times in a row
            if (players[msg.sender].consecutiveWins == 7) {
                // If yes, provide 5000% bonus reward
                return (stake * bonusRewardPercentage) / 100;
            } else {
                // Otherwise, provide the base reward
                return (stake * baseRewardPercentage) / 100;
            }
        }

        // If the player loses, no reward
        return 0;
    }

    function calculateDifficultReward(uint256 stake, bool win) internal view returns (uint256) {
        uint256 baseRewardPercentage = 3000; // 3000% base reward
        uint256 initialBonusPercentage = 5000; // 5000% initial bonus
        uint256 bonusIncrementPercentage = 200; // 200% bonus increment

        if (win) {
            // Check if the player has won
            if (players[msg.sender].consecutiveWinsInARow == 1) {
                // If it's the first win in a row, provide the initial bonus
                return (stake * baseRewardPercentage) / 100;
            } else {
                // If it's subsequent wins, increment the bonus
                uint256 currentBonus = initialBonusPercentage + (players[msg.sender].consecutiveWinsInARow - 1) * bonusIncrementPercentage;
                return (stake * currentBonus) / 100;
            }
        }

        // If the player loses, no reward
        return 0;
    }
}