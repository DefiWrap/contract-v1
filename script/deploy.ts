// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers } from "hardhat";
import { DollarCostAveragingProtocol } from "../typechain";
import { chainIdToAddresses } from "./Address";
// let fs = require("fs");                      
const ETHERSCAN_TX_URL = "https://testnet.bscscan.io/tx/";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");
  const delay = (ms: number | undefined) =>
    new Promise((res) => setTimeout(res, ms));

  // get current chainId
  const { chainId } = await ethers.provider.getNetwork();
  const forkChainId: any = process.env.FORK_CHAINID;

  const addresses = chainIdToAddresses[forkChainId];
  const accounts = await ethers.getSigners();


  // Token Metadata
  const DollarCostAveragingProtocol = await ethers.getContractFactory("DollarCostAveragingProtocol");
  const dollarCostAveragingProtocol = await DollarCostAveragingProtocol.deploy();
  console.log("Contract DollarCostAveragingProtocol deployed to: ", dollarCostAveragingProtocol.address);
 
  await delay(15000);
  console.log("Waited 5s");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
