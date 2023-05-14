pragma solidity ^0.8.16;

interface IWrapContract {
    function executeOperation(bytes memory params) external payable;
    function executeWithdrawal(bytes memory params) external;
}