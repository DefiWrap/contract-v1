// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DollarCostAveragingProtocol is ERC721, Ownable, Pausable, ReentrancyGuard {
   using SafeMath for uint256;
  using SafeERC20 for IERC20;

    struct Investment {
        address fromToken;
        address toToken;
        uint256 amount;
        uint256 amountOfSwaps;
        uint32 swapInterval;
        uint256 lastInvestmentTime;
        address owner;
    }

    AggregatorV3Interface private priceFeed; // Chainlink price feed
    IUniswapV2Router02 private uniswapRouter; // Uniswap router

  
    uint32 public constant MAX_FEE = 100000; // 10%
    uint16 public constant MAX_PLATFORM_FEE_RATIO = 10000;

    uint256 private nextTokenId;
    mapping(uint256 => Investment) private investments;
    mapping(address => address) private tokenWrapInfo;

    // Event emitted when a token-wrap association is updated
    event TokenWrapUpdated(address indexed token, address indexed wrap);
    
     /**
     * @dev Event emitted when an investment is completed.
     * @param tokenId The ID of the investment NFT.
     * @param investedAmount The amount of tokens invested.
     * @param finalAmount The final amount of tokens after the investment.
     */
    event InvestmentCompleted(
        uint256 indexed tokenId,
        uint256 investedAmount,
        uint256 finalAmount
    );
    event InvestmentCancelled(uint256 indexed _tokenId,uint256 amountToReturn);
    event InvestmentUpdated(uint256 indexed investmentId, address indexed owner, uint256 newAmount, uint32 newSwapInterval);


    constructor(
        address _priceFeedAddress,
        address _uniswapRouterAddress
    ) ERC721("DCA NFT", "DCANFT") {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }

    /**
     * @dev Creates a new investment with the specified parameters.
     * @param _fromToken The address of the token to be used as the source token for swaps.
     * @param _toToken The address of the token to be acquired through swaps.
     * @param _amount The initial amount to be invested.
     * @param _amountOfSwaps The number of swaps to be performed during the investment period.
     * @param _swapInterval The time interval (in seconds) between each swap.
     * @param _owner The address of the owner who will receive the investment tokens and NFT.
     * @return tokenId The ID of the newly created investment NFT.
     */
    function createInvestment(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        uint256 _amountOfSwaps,
        uint32 _swapInterval,
        address _owner
    ) public nonReentrant whenNotPaused returns (uint256) {
        require(_fromToken != address(0), "Invalid from token address");
        require(_toToken != address(0), "Invalid to token address");
        require(_amount > 0, "Investment amount must be greater than 0");
        require(_amountOfSwaps > 0, "Amount of swaps must be greater than 0");

        uint256 tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);

        investments[tokenId] = Investment({
            fromToken: _fromToken,
            toToken: _toToken,
            amount: _amount,
            amountOfSwaps: _amountOfSwaps,
            swapInterval: _swapInterval,
            lastInvestmentTime: block.timestamp,
            owner: _owner
        });

        _mint(_owner, tokenId);

        return tokenId;
    }
    /**
     * @dev Perform the investment by swapping tokens based on the investment settings.
     * @param _tokenId The ID of the investment NFT.
     */
    function invest(uint256 _tokenId) external nonReentrant whenNotPaused {
        Investment storage investment = investments[_tokenId];
        require(investment.fromToken != address(0), "Invalid token ID");

        uint256 elapsedSeconds = block.timestamp.sub(investment.lastInvestmentTime);
        uint256 elapsedPeriods;

        if (investment.swapInterval > 0) {
            elapsedPeriods = elapsedSeconds.div(investment.swapInterval);
        } else {
            revert("Invalid swap interval");
        }

        if (elapsedPeriods > 0) {
            uint256 amountToInvest = investment.amount.mul(elapsedPeriods);

            // Perform the token swap using the Uniswap router
            uint256[] memory amounts = swapTokens(investment.fromToken, investment.toToken, amountToInvest);

            // Update the investment state
            investment.amount = amounts[amounts.length - 1];
            investment.lastInvestmentTime = block.timestamp;

              // Emit an event with investment details
            emit InvestmentCompleted(_tokenId, amountToInvest, amounts[amounts.length - 1]);
        }
    }

    /**
     * @dev Updates an existing investment with the specified ID.
     * Can only be called by the contract owner.
     * Emits an `InvestmentUpdated` event upon successful update.
     * 
     * @param investmentId The ID of the investment to update.
     * @param newAmount The new investment amount.
     * @param newSwapInterval The new swap interval.
     */
    function updateInvestment(
        uint256 investmentId,
        uint256 newAmount,
        uint32 newSwapInterval
    ) external onlyOwner {
        // Ensure the investment ID is valid
        require(investmentId < nextTokenId, "Invalid investment ID");
        
        // Retrieve the investment object
        Investment storage investment = investments[investmentId];

        // Ensure the investment is valid and the new amount is greater than zero
        require(investment.owner != address(0), "Invalid investment");
        require(newAmount > 0, "Invalid amount");
        
        // Emit the InvestmentUpdated event
        emit InvestmentUpdated(investmentId, investment.owner, newAmount, newSwapInterval);

        // Update the investment amount and swap interval
        investment.amount = newAmount;
        investment.swapInterval = newSwapInterval;
    }

    /**
     * @dev Cancel an investment and return the invested tokens to the owner.
     * @param _tokenId The ID of the investment NFT.
     */
    function cancelInvestment(uint256 _tokenId) external nonReentrant whenNotPaused {
        Investment storage investment = investments[_tokenId];
        require(investment.fromToken != address(0), "Invalid token ID");
        require(investment.owner == msg.sender, "Only the owner can cancel the investment");

        uint256 amountToReturn = investment.amount;
        
        // Transfer the invested tokens back to the owner
        IERC20(investment.fromToken).transfer(investment.owner, amountToReturn);

        // Clear the investment details
        delete investments[_tokenId];

        // Burn the investment NFT
        _burn(_tokenId);

        // Emit an event to indicate the cancellation
        emit InvestmentCancelled(_tokenId, amountToReturn);
    }

    /**
     * @dev Internal function to perform token swaps using the Uniswap router.
     * @param _fromToken The address of the token to be swapped.
     * @param _toToken The address of the token to be acquired.
     * @param _amount The amount of tokens to be swapped.
     * @return amounts The amounts of tokens received after each swap.
     */
    function swapTokens(address _fromToken, address _toToken, uint256 _amount) internal returns (uint256[] memory amounts) {
        // Approve the Uniswap router to spend the fromToken
        IERC20(_fromToken).approve(address(uniswapRouter), _amount);

        // Construct the swap path array
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        // Perform the token swap
        amounts = uniswapRouter.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 3600
        );
    }

    /**
     * @dev Get the details of an investment based on the investment NFT's ID.
     * @param _tokenId The ID of the investment NFT.
     * @return fromToken The address of the token used as the source token for swaps.
     * @return toToken The address of the token acquired through swaps.
     * @return amount The initial amount invested.
     * @return amountOfSwaps The number of swaps to be performed during the investment period.
     * @return swapInterval The time interval (in seconds) between each swap.
     * @return lastInvestmentTime The timestamp of the last investment.
     * @return owner The address of the owner who received the investment tokens and NFT.
     */
    function getInvestment(uint256 _tokenId) external view returns (
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 amountOfSwaps,
        uint32 swapInterval,
        uint256 lastInvestmentTime,
        address owner
    ) {
        Investment storage investment = investments[_tokenId];
        require(investment.fromToken != address(0), "Invalid token ID");

        return (
            investment.fromToken,
            investment.toToken,
            investment.amount,
            investment.amountOfSwaps,
            investment.swapInterval,
            investment.lastInvestmentTime,
            investment.owner
        );
    }

    // Associate a token with its corresponding wrap address
    function setTokenWrap(address token, address wrap) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(wrap != address(0), "Invalid wrap address");
        tokenWrapInfo[token] = wrap;
        emit TokenWrapUpdated(token, wrap);
    }

    // Get the wrap address associated with a token
    function getWrapAddress(address token) external view returns (address) {
        return tokenWrapInfo[token];
    }

}