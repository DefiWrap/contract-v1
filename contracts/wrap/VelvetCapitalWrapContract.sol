pragma solidity ^0.8.0;
import "../interfaces/IWrapContract.sol";

interface IIndexSwap {
    function investInFund(uint256 _slippage) external payable;
    function withdrawFund(uint256 tokenAmount, uint256 _slippage, bool isMultiAsset) external;
    function getTokens() external view returns (address[] memory);
    // function getRecord(address _token) external view returns (IndexSwap.Record memory);
}

contract VelvetCapitalWrapContract is IWrapContract {
    function executeOperation(bytes memory params) external payable {
        (
            address _indexSwapToken,
            address token,
            uint256 slippage
        ) = abi.decode(params, (address, address, uint256));

        IIndexSwap(_indexSwapToken).investInFund{value: msg.value}(slippage);
    }

    function executeWithdrawal(bytes memory params) external {
        (
            address _indexSwapToken,
            address token,
            uint256 tokenAmount,
            uint256 slippage,
            bool isMultiAsset
        ) = abi.decode(params, (address, address, uint256, uint256, bool));

        IIndexSwap(_indexSwapToken).withdrawFund(tokenAmount, slippage, isMultiAsset);
    }

    function getTokens(address _indexSwapToken) external view returns (address[] memory) {
        return IIndexSwap(_indexSwapToken).getTokens();
    }

    // function getRecord(address _indexSwapToken, address token) external view returns (IndexSwap.Record memory) {
    //     return IIndexSwap(_indexSwapToken).getRecord(token);
    // }
}