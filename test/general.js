const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const { boolean } = require("hardhat/internal/core/params/argumentTypes");
const { default: BigNumber } = require("bignumber.js");
const ether = require("@openzeppelin/test-helpers/src/ether");

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
  let Zap, zap;
  let pairAddr
  let Lock, lock;
  let Box, box;
  let Pool, pool;
  let Vault, vault;
  let Helper, helper;
  let wbnbT

  let Token, token;
  let wbnbAddr = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
  let cakeAddr = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"
  let routerAddr = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
  let factoryAddr = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
  const provider = ethers.getDefaultProvider();
  let pair;
  let owner;
  let cake;
  let factory;
  let router;
  let Safeswap, safeswap

  let initialTotalSupply;
  let currentBlock;


  beforeEach(async () => {
    Cake2cake = await ethers.getContractFactory("VaultCakeToCake");
    Token = await ethers.getContractFactory("NoavaToken");
    Pricecal = await ethers.getContractFactory("PriceCalculatorBSC");
    Chef = await ethers.getContractFactory("NoavaChef");
    Minter = await ethers.getContractFactory("NoavaMinterV2");
    Safeswap = await ethers.getContractFactory("safeSwapBNB");
    Zap = await ethers.getContractFactory("ZapBSC");
    pair =  await ethers.getContractFactory("PancakePair1");
    Lock = await ethers.getContractFactory("Timelock");
    Box = await ethers.getContractFactory("NoavaFeeBox");
    Helper = await ethers.getContractFactory("StrategyHelperV1");
    Pool = await ethers.getContractFactory("NoavaPool");
    Vault = await ethers.getContractFactory("VaultNoava");
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

    it("deploy helper", async () => {
      helper = await Helper.deploy();
      await helper.deployed();
      console.debug(`\t\t\thelper Contract Address: ${cyan}`, helper.address);
     
  });


    it("deploy lock", async () => {
      lock = await Lock.deploy(owner.address, 1123200);
      await lock.deployed();
      console.debug(`\t\t\tlock Contract Address: ${cyan}`, lock.address);
     
  });
  
    it("Should deploy", async () => {
      token = await Token.deploy();
      await token.deployed();
        console.debug(`\t\t\tToken Contract Address: ${cyan}`, token.address);
       
        await token.minare(owner.address, web3.utils.toWei("10000", 'ether'))
        console.debug(`\t\t\tToken owner balance: ${cyan}`, await token.balanceOf(owner.address));
        const supply = await token.totalSupply()
        console.debug(`\t\t\tToken totalSupply: ${yellow}`, supply);
    });
    

    it("Should create factory", async () => {
      factory = await hre.ethers.getContractAt("PancakeFactory", factoryAddr);
      
    });
    it("deploy price calc", async () => {
      pricecal = await Pricecal.deploy();
      await pricecal.deployed();
      console.debug(`\t\t\tpricecal Contract Address: ${cyan}`, pricecal.address);
     
  });
  it("deploy chef", async () => {
    chef = await Chef.deploy();
    await chef.deployed();
    await chef.initialize(13556793, BigInt(523211567732115677), token.address)
    console.debug(`\t\t\tchef Contract Address: ${cyan}`, chef.address);
});
    
    it("deploy safeswapBNB", async () => {
      safeswap = await Safeswap.deploy();
      await safeswap.deployed();
      console.debug(`\t\t\tsafeswap Contract Address: ${cyan}`, safeswap.address);
  });
  it("deploy zap", async () => {
    zap = await Zap.deploy();
    await zap.deployed();
    console.debug(`\t\t\tzap Contract Address: ${cyan}`, zap.address);
    await zap.initialize(token.address);
    await zap.setSafeSwapBNB(safeswap.address);
});
    it("deploy minter", async () => {
        minter = await Minter.deploy();
        await minter.deployed();
        console.debug(`\t\t\tMinter Contract Address: ${cyan}`, minter.address);
        
        await token.transferOwnership(minter.address)
        const tokenOwner = await token.owner();
        console.debug(`\t\t\tToken Owner Address: ${cyan}`, tokenOwner);
        await  chef.setMinter(minter.address)
        
    });
    it("deploy vaultNoava", async () => {
      vault = await Vault.deploy();
      await helper.deployed();
      console.debug(`\t\t\thelper Contract Address: ${cyan}`, helper.address);
      console.debug(`\t\t\thelper Contract Address: ${yellow}`, minter.address);
      console.debug(`\t\t\thelper Contract Address: ${yellow}`, await token.getOwner());
      await vault.initialize(token.address)
     await vault.setMinter(minter.address)
      await vault.setNoavaChef(chef.address)
     
     
  });
    it("deploy cake2cake", async () => {
      cake2cake = await Cake2cake.deploy();
      await cake2cake.deployed();
      console.debug(`\t\t\tcake2cake Contract Address: ${cyan}`, cake2cake.address);
      
      const token1 = await minter.NOAVA();
      console.debug(`\t\t\tMinter ${cyan} initialized`, token1);
      const owner = await minter.owner();
      console.debug(`\t\t\tMinter ${cyan} initialized`, owner);
     await cake2cake.initialize(minter.address, token.address) 
     console.debug(`\t\t\tcakvault ${cyan} initialized`, minter.address);
     
     await chef.addVault(cake2cake.address, cakeAddr, 100)
      
  });
});

  describe("create contract and add liq", () => {
    it("should create ovr and uniswap contract", async () => {
      cake = await hre.ethers.getContractAt("CakeToken", cakeAddr);

      router = await hre.ethers.getContractAt("PancakeRouter", routerAddr);
      wbnbT = await hre.ethers.getContractAt("NoavaToken", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
    });
    
    it("should add liq", async () => {
      
      await token.approve(router.address, web3.utils.toWei("10000", 'ether'));

     console.log("--------------------------")
      
      await router.addLiquidityETH(token.address, web3.utils.toWei("1000", 'ether'), web3.utils.toWei("1000", 'ether'), web3.utils.toWei("1", 'ether'), owner.address, Math.floor(Date.now() / 1000) + 60 * 10,
        { value: web3.utils.toWei("1", 'ether') }
      
      ); 

      const tokenAddr =  token.address;
      console.debug(`\t\t\ttokenaddr: ${yellow}`, tokenAddr);
      console.debug(`\t\t\twbnbaddr: ${yellow}`, wbnbAddr);
      pairAddr = await factory.getPair(wbnbAddr, tokenAddr)
     
     console.debug(`\t\t\tpair: ${yellow}`, pairAddr);
     const Pair = await hre.ethers.getContractAt("PancakePair1", pairAddr); 
     const balance = await Pair.balanceOf(owner.address);
     console.debug(`\t\t\tpair balance: ${yellow}`, balance);
      const reserve = await Pair.getReserves()
      console.debug(`\t\t\tpair reserves 0: ${yellow}`,reserve[0]);
      console.debug(`\t\t\tpair reserves 1: ${yellow}`,reserve[1]);
      await pricecal.initialize(token.address, pairAddr)
  
      await  pricecal.setTokenFeed(cakeAddr, "0xB6064eD41d4f67e353768aA239cA86f4F73665a1")
      await  pricecal.setTokenFeed("0x0000000000000000000000000000000000000000", "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE")
      await  pricecal.setTokenFeed("0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE")


     const price =  await pricecal.priceOfNoava()
     console.debug(`\t\t\tPRICE: ${yellow}`, price);

     console.log("---------------------------")
     let path = ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", token.address];
    const deadline = Math.floor(Date.now() / 1000) + 60 * 10;
    await router.swapExactETHForTokens(0, path, owner.address, deadline, { value: web3.utils.toWei("1", "ether") });
    const balanceto = await token.balanceOf(owner.address);
    console.debug(`\t\t\t Token owner balance: ${cyan}`, balanceto);
    console.log("---------------------------")

    const reserve1 = await Pair.getReserves()
    console.debug(`\t\t\tpair reserves 0: ${yellow}`,reserve1[0]);
      console.debug(`\t\t\tpair reserves 1: ${yellow}`,reserve1[1]);


   const price2 =  await pricecal.priceOfNoava()
   console.debug(`\t\t\tPRICE: ${yellow}`, price2);

      
      
    });
    it("deploy feeBox", async () => {
      box = await Box.deploy();
      await box.deployed();
      box.initialize(safeswap.address, zap.address, token.address, pairAddr)
      console.debug(`\t\t\tbox Contract Address: ${cyan}`, box.address);
     
  });
  it("deploy pool", async () => {
    const Pair = await hre.ethers.getContractAt("PancakePair1", pairAddr); 
    const balance = await Pair.balanceOf(owner.address);
    pool = await Pool.deploy();
    await pool.deployed();
    console.debug(`\t\t\tpool Contract Address: ${cyan}`, pool.address);
    await pool.initialize(token.address, box.address)
    await pool.setRewardsToken(pairAddr)
    await pool.setHelper(helper.address)
    
    await Pair.transfer(pool.address, balance);
     
   
});
  it("init minter", async () => {
    await minter.initialize(token.address, zap.address, pricecal.address,pairAddr, lock.address, box.address, owner.address)
      console.debug(`\t\t\tMinter ${cyan} initialized`);
     await minter.setMinter(cake2cake.address, true) 
     console.debug(`\t\t\tMinter ${cyan} cake setted on minter`);
     await minter.setMinter(vault.address, true) 
     console.debug(`\t\t\tMinter ${cyan} vault setted on minter`);
     await minter.setNoavaChef(chef.address)
   
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
    await time.increase(DAY * 50);
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
    
    it("approve owner token on pool", async () => {
      await token.approve(pool.address, BigInt(123456789876543212345664544334556654))
      console.debug(`\t\t\towner approved the pool`)
    })
    it("deposit on pool", async () => {
      let tokenbalance = await token.balanceOf(owner.address)
      tokenbalance = tokenbalance/2
      await pool.deposit(BigInt(tokenbalance))
      console.debug(`\t\t\towner deposited on pool`)
    })
    it("get reward from pool", async () => {

      await time.increase(DAY * 30);
      let balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    let tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    let wbnbBalance = await wbnbT.balanceOf(owner.address);
    console.debug("\t\t\tOWNER wbnb Balance:", wbnbBalance.toString());
    console.log("--------------------------------------------------")
      await pool.getReward()
      console.debug(`\t\t\towner got reward from pool`)
      console.log("--------------------------------------------------")
       balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
     tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
     wbnbBalance = await wbnbT.balanceOf(owner.address);
    console.debug("\t\t\tOWNER wbnb Balance:", wbnbBalance.toString());
    })
    it("get reward from pool", async () => {

      await time.increase(DAY * 30);
      let balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    let tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    let wbnbBalance = await wbnbT.balanceOf(owner.address);
    console.debug("\t\t\tOWNER wbnb Balance:", wbnbBalance.toString());
    console.log("--------------------------------------------------")
      await pool.getReward()
      console.debug(`\t\t\towner got reward from pool`)
      console.log("--------------------------------------------------")
       balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
     tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
     wbnbBalance = await wbnbT.balanceOf(owner.address);
    console.debug("\t\t\tOWNER wbnb Balance:", wbnbBalance.toString());
    })
    it("approve owner token on pool", async () => {
      await chef.addVault(vault.address, token.address, 100)
      await token.approve(vault.address, BigInt(123456789876543212345664544334556654))
      console.debug(`\t\t\towner approved the vault`)
    })
    it("deposit on vault", async () => {
      await vault.depositAll()
      console.debug(`\t\t\towner deposited on vault`)
    })
    it("get reward from vault", async () => {

      await time.increase(DAY * 30);
      let balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    let tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.log("--------------------------------------------------")
      await vault.getReward()
      console.debug(`\t\t\towner got reward from vault`)
      console.log("--------------------------------------------------")
       balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
     tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    })
    it("get reward from vault", async () => {

      await time.increase(DAY * 30);
      let balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
    let tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    console.log("--------------------------------------------------")
      await vault.getReward()
      console.debug(`\t\t\towner got reward from vault`)
      console.log("--------------------------------------------------")
       balance = await provider.getBalance(owner.address);
      console.debug("\t\t\tOWNER ETH Balance:", balance.toString());
     tokenBalance = await token.balanceOf(owner.address);
    console.debug("\t\t\tOWNER token Balance:", tokenBalance.toString());
    })
  });

});
