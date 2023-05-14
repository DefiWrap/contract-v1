pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../interfaces/IWrapContract.sol";
contract UniswapWrapContract is  IWrapContract{
    IUniswapV2Router02 private _uniswapRouter;
    address private _protocolAddress;

    constructor(address uniswapRouter, address protocolAddress) {
        _uniswapRouter = IUniswapV2Router02(uniswapRouter);
        _protocolAddress = protocolAddress;
    }

    function executeOperation(bytes memory params) external payable{
        (
            address fromToken,
            address toToken,
            uint256 amount
        ) = abi.decode(params,(address, address,uint256));

        require(msg.sender == _protocolAddress, "Only the protocol can call this function");

        // Perform the token swap using Uniswap router
        IERC20(fromToken).approve(address(_uniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;
        _uniswapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function executeWithdrawal(bytes memory params) external {
        (
            address _indexSwapToken,
            address token,
            uint256 tokenAmount,
            uint256 slippage,
            bool isMultiAsset
        ) = abi.decode(params, (address, address, uint256, uint256, bool));
    }

    // Add other functions as needed
}
