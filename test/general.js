const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const { boolean } = require("hardhat/internal/core/params/argumentTypes");

const cyan = "\x1b[36m%s\x1b[0m";
const yellow = "\x1b[33m%s\x1b[0m";

/*
 * @dev @openzeppelin/test-helpers
 * Time helpers to increase time
 * Ex. await time.increase(MONTH * 2);
 */


const DAY = 86400;
const MONTH = DAY * 30; // Supposing every month 30 days

// Get date from unix timestamp
const displayTime = unixTime => {
  var date = new Date(unixTime * 1000).toLocaleString("it-IT");
  return date;
};

const displayBlockTime = async () => {
  currentBlock = await time.latest();
  const currentBlockNumber = await time.latestBlock();

  console.debug("\t\t\tCurrent Block Number", currentBlockNumber.toString());
  console.debug("\t\t\tCurrent Block Timestamp", currentBlock.toString());
  console.debug("\t\t\tCurrent Block Time", displayTime(Number(currentBlock.toString())));
};

describe("OVRLand Renting - TEST", () => {
  let Pricecal, pricecal;
  let Dashboard, dashboard;
  let Chef, chef;
  let Minter, minter;
  let Cake2cake, cake2cake;

  let Token, token;
  let cakeAddr = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"
  let routerAddr = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
  const provider = ethers.getDefaultProvider();
  let owner;
  let cake;
  let router;

  let initialTotalSupply;
  let currentBlock;


  beforeEach(async () => {
    Cake2cake = await ethers.getContractFactory("VaultCakeToCake");
    Token = await ethers.getContractFactory("BunnyToken");
    Pricecal = await ethers.getContractFactory("PriceCalculatorBSC");
    Chef = await ethers.getContractFactory("BunnyChef");
    Minter = await ethers.getContractFactory("BunnyMinterV2");
    [
      owner, // 50 ether
      addr1, // 0
      addr2, // 0
      addr3, // 0
      addr4, // 0
      addr5, // 0
      addr6, // 0
      addr7, // 0
      addr8, // 0
      addr9, // 0
      addr10, // 0
      addr11, // 0
      addr12, // 0
      addr13, // 0
      addr14, // 0
      addr15, // 0
      addr16, // 0
      addr17, // 0
      addr18, // 1000 ether
    ] = await ethers.getSigners();
  });

  describe("Current Block", () => {
    it("Should exist", async () => {
      displayBlockTime();
    });
  });

  describe("Should deploy", () => {
  
    it("Should deploy", async () => {
      token = await Token.deploy();
      await token.deployed();
        console.debug(`\t\t\tToken Contract Address: ${cyan}`, token.address);
    });
    it("deploy minter", async () => {
        minter = await Minter.deploy();
        await minter.deployed();
        console.debug(`\t\t\tMinter Contract Address: ${cyan}`, minter.address);
        await token.transferOwnership(minter.address)
        const tokenOwner = await token.owner();
        console.debug(`\t\t\tToken Owner Address: ${cyan}`, tokenOwner);
    });
    it("deploy cake2cake", async () => {
      cake2cake = await Cake2cake.deploy();
      await cake2cake.deployed();
      console.debug(`\t\t\tcake2cake Contract Address: ${cyan}`, cake2cake.address);
      await minter.initialize(token.address)
      console.debug(`\t\t\tMinter ${cyan} initialized`);
      const owner = await minter.owner();
      console.debug(`\t\t\tMinter ${cyan} initialized`, owner);
     await cake2cake.initialize(minter.address, token.address) 
     console.debug(`\t\t\tcakvault ${cyan} initialized`, minter.address);
     await minter.setMinter(cake2cake.address, true) 
     console.debug(`\t\t\tMinter ${cyan} cake setted on minter`);
      
  });

/*   it("deploy chef", async () => {
    minter = await Minter.deploy();
    await minter.deployed();
    console.debug(`\t\t\tMinter Contract Address: ${cyan}`, minter.address);
    await token.transferOwnership(minter.address)
    const tokenOwner = await token.owner();
    console.debug(`\t\t\tToken Owner Address: ${cyan}`, tokenOwner);
}); */
  });

  describe("create contract", () => {
    it("should create ovr and uniswap contract", async () => {
      cake = await hre.ethers.getContractAt("CakeToken", cakeAddr);

      router = await hre.ethers.getContractAt("PancakeRouter", routerAddr);
    });
  });
  describe("buy", () => {
  it("Should buy", async () => {
    let path = ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
    await router.swapExactETHForTokens(0, path, owner.address, deadline, { value: web3.utils.toWei("1", "ether") });

    console.debug(`\t\t\tOVR Token Contract Address: ${cyan}`, cakeAddr);

    const balance = await provider.getBalance(owner.address);
    const ovrBalance = await cake.balanceOf(owner.address);
    const tokenBalance = await token.balanceOf(owner.address);
    console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
    console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
  });
});
describe("allowance", () => {
  it("allowance stake", async () => {
    await cake.approve(cake2cake.address, web3.utils.toWei("1000", "ether"));
    const allowance = await cake.allowance(owner.address, cake2cake.address);
    expect(allowance.toString()).to.equal("1000000000000000000000");
  });
});
  describe("stake", () => {
    it("stake cake", async () => {
      await cake2cake.deposit(web3.utils.toWei("10", 'ether'))
      const balance = await provider.getBalance(owner.address);
    const ovrBalance = await cake.balanceOf(owner.address);
    const tokenBalance = await token.balanceOf(owner.address);
    const earned = await cake2cake.earned(owner.address);
    const principal = await cake2cake.principalOf(owner.address);

    console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
    console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.debug("\t\t\tOWNER earned Balance:", earned.toString());
    console.debug("\t\t\tOWNER principal Balance:", principal.toString());
    await time.increase(DAY * 70);
    });
    it("earned", async () => {
     
      const balance = await provider.getBalance(owner.address);
    const ovrBalance = await cake.balanceOf(owner.address);
    const tokenBalance = await token.balanceOf(owner.address);
    const earned = await cake2cake.earned(owner.address);
    const principal = await cake2cake.principalOf(owner.address);
    console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
    console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.debug("\t\t\tOWNER earned Balance:", earned.toString());
    console.debug("\t\t\tOWNER principal Balance:", principal.toString());
    await time.increase(DAY * 1.5);
    });
    it("reward", async () => {

      await cake2cake.connect(owner).getReward()
      const balance = await provider.getBalance(owner.address);
    const ovrBalance = await cake.balanceOf(owner.address);
    const tokenBalance = await token.balanceOf(owner.address);
    const earned = await cake2cake.earned(owner.address);
    console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
    console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.debug("\t\t\tOWNER earned Balance:", earned.toString());
    await time.increase(DAY * 30);
    });
    it("earned", async () => {
     
      const balance = await provider.getBalance(owner.address);
    const ovrBalance = await cake.balanceOf(owner.address);
    const tokenBalance = await token.balanceOf(owner.address);
    const earned = await cake2cake.earned(owner.address);
    const principal = await cake2cake.principalOf(owner.address);
    console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
    console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.debug("\t\t\tOWNER earned Balance:", earned.toString());
    console.debug("\t\t\tOWNER principal Balance:", principal.toString());
    await time.increase(DAY * 1.5);
    });
    it("reward", async () => {

      await cake2cake.connect(owner).getReward()
      const balance = await provider.getBalance(owner.address);
      console.debug(`\t\t\tOWNER Address: ${yellow}`, owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    const ovrBalance = await cake.balanceOf(owner.address);
    console.debug("\t\t\tOWNER cake Balance:", ovrBalance.toString());
    const tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    const earned = await cake2cake.earned(owner.address);
   
  
    
    console.debug("\t\t\tOWNER earned Balance:", earned.toString());
    await time.increase(DAY * 30);
    });
  });



});