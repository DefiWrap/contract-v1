const { parseEther } = require("@ethersproject/units");

interface ChainAddresses {
  [contractName: string]: string;
}
export const ETHMainNet: ChainAddresses = {
  RpcUrl: "https://mainnet.infura.io/v3/",
  UniswapV2RouterAddress: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  UniswapV2FactoryAddress: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
  WETH_Address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  DAI_Address: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
};

export const BSCTestNet: ChainAddresses = {
  RpcUrl: `https://data-seed-prebsc-2-s3.binance.org:8545/`,
  UniSwapRouterAddress: "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
  Vault: "0x07C0737fdc21adf93200bd625cc70a66B835Cf8b",
  Module: "0x0000000000000000000000000000000000000000",
  ETH_Address: "0x8BaBbB98678facC7342735486C851ABD7A0d17Ca",
  DAI_Address: "0x8a9424745056Eb399FD19a0EC26A14316684e274",
  UniSwapV2RouterAddress: "0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F",
  UniSwapV2FactoryAddress: "0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7",
  WETH_Address: "0xae13d989dac2f0debff460ac112a837c89baa7cd",
  BUSD: "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7",
  VRFCoordinator: "0xa555fC018435bef5A13C6c6870a9d4C11DEC329C",
  VRFKeyHash:"0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c",
  VRFFee: parseEther("0.1"), //0.1 LINK fee
};

export const BSCMainNet: ChainAddresses = {
  RpcUrl: `https://bsc-dataseed.binance.org/`,
  UniSwapRouterAddress: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
  UniSwapV2RouterAddress: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
  UniSwapV2FactoryAddress: "0xca143ce32fe78f1f7019d7d551a6402fc5350c73",
  WETH_Address: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
  BUSD: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
  MULTI_SEND_ADDRESS: "0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761",
};


export const chainIdToAddresses: {
  [id: number]: { [contractName: string]: string };
} = {
  1: { ...ETHMainNet },
  97: { ...BSCTestNet },
  56: { ...BSCMainNet },
};
