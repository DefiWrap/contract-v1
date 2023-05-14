pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWrapContract.sol";
contract UniswapLpWrapContract is IWrapContract{
    IUniswapV2Router02 private _uniswapRouter;

    constructor(address uniswapRouter) {
        _uniswapRouter = IUniswapV2Router02(uniswapRouter);
    }

   function executeOperation(bytes memory params) external payable{
    (
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minAmountA,
        uint256 minAmountB
    ) = abi.decode(params,(address,address,uint256,uint256,uint256,uint256));

    // Rest of the code remains the same
    IERC20(tokenA).approve(address(_uniswapRouter), 0);
    IERC20(tokenB).approve(address(_uniswapRouter), 0);
    IERC20(tokenA).approve(address(_uniswapRouter), amountA);
    IERC20(tokenB).approve(address(_uniswapRouter), amountB);

    _uniswapRouter.addLiquidity(
        tokenA,
        tokenB,
        amountA,
        amountB,
        minAmountA,
        minAmountB,
        address(this),
        block.timestamp
    );
   } 

    function executeWithdrawal(bytes memory params) external {
        (
            address lpToken,
            uint256 liquidity,
            uint256 minAmountA,
            uint256 minAmountB
        ) = abi.decode(params,(address, uint256, uint256,uint256));

        IERC20(lpToken).approve(address(_uniswapRouter), liquidity);

        _uniswapRouter.removeLiquidity(
            IUniswapV2Pair(lpToken).token0(),
            IUniswapV2Pair(lpToken).token1(),
            liquidity,
            minAmountA,
            minAmountB,
            address(this),
            block.timestamp
        );
    }

    function getUnderlyingTokens(address lpToken) external view returns (address tokenA, address tokenB) {
        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
        tokenA = pair.token0();
        tokenB = pair.token1();
    }

     function encodeParams(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minAmountA,
        uint256 minAmountB
    ) external pure returns (bytes memory) {
        return abi.encode(tokenA, tokenB, amountA, amountB, minAmountA, minAmountB);
    }

    function decodeParams(bytes memory params)
        external
        pure
        returns (
            address tokenA,
            address tokenB,
            uint256 amountA,
            uint256 amountB,
            uint256 minAmountA,
            uint256 minAmountB
        )
    {
        return abi.decode(params, (address, address, uint256, uint256, uint256, uint256));
    }


    // Add other functions as needed
}
