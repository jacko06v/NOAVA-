// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*

      ___           ___           ___                         ___     
     /\  \         /\  \         /\  \          ___          /\  \    
     \:\  \       /::\  \       /::\  \        /\  \        /::\  \   
      \:\  \     /:/\:\  \     /:/\:\  \       \:\  \      /:/\:\  \  
  _____\:\  \   /:/  \:\  \   /:/ /::\  \       \:\  \    /:/ /::\  \ 
 /::::::::\__\ /:/__/ \:\__\ /:/_/:/\:\__\  ___  \:\__\  /:/_/:/\:\__\
 \:\~~\~~\/__/ \:\  \ /:/  / \:\/:/  \/__/ /\  \ |:|  |  \:\/:/  \/__/
  \:\  \        \:\  /:/  /   \::/__/      \:\  \|:|  |   \::/__/     
   \:\  \        \:\/:/  /     \:\  \       \:\__|:|__|    \:\  \     
    \:\__\        \::/  /       \:\__\       \::::/__/      \:\__\    
     \/__/         \/__/         \/__/        ~~~~           \/__/    


*
* MIT License
* ===========
*
* Copyright (c) 2020 NoavaFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
import "../interfaces/INoavaMinterV2.sol";
import "../interfaces/INoavaPool.sol";
import "../interfaces/IPriceCalculator.sol";

import "../zap/ZapBSC.sol";
import "../library/SafeToken.sol";

contract NoavaMinterV2 is INoavaMinterV2, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public NOAVA;
    address public NOAVA_POOL_V1;

    address public FEE_BOX;
    address private TIMELOCK;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private DEPLOYER;

    uint256 public constant FEE_MAX = 10000;

    IPriceCalculator public priceCalculator;
    ZapBSC public zap;
    IPancakeRouter02 private constant router =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    /* ========== STATE VARIABLES ========== */

    address public noavaChef;
    mapping(address => bool) public _minters;
    address public _deprecated_helper; // deprecated

    uint256 public PERFORMANCE_FEE;
    uint256 public override WITHDRAWAL_FEE_FREE_PERIOD;
    uint256 public override WITHDRAWAL_FEE;

    uint256 public _deprecated_noavaPerProfitBNB; // deprecated
    uint256 public _deprecated_noavaPerNoavaBNBFlip; // deprecated

    uint256 private _floatingRateEmission;
    uint256 private _freThreshold;

    address public noavaPool;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter() {
        require(
            isMinter(msg.sender) == true,
            "NoavaMinterV2: caller is not the minter"
        );
        _;
    }

    modifier onlyNoavaChef() {
        require(
            msg.sender == noavaChef,
            "NoavaMinterV2: caller not the noava chef"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event PerformanceFee(address indexed asset, uint256 amount, uint256 value);

    receive() external payable {}

    /* ========== INITIALIZER ========== */

    function initialize(
        address _token,
        ZapBSC _zap,
        IPriceCalculator _pricecal,
        address _pair,
        address _lock,
        address _feeBox,
        address _deployer
    ) external initializer {
        WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
        WITHDRAWAL_FEE = 50;
        PERFORMANCE_FEE = 3000;
        NOAVA_POOL_V1 = _pair;
        FEE_BOX = _feeBox;
        TIMELOCK = _lock;
        DEPLOYER = _deployer;

        _deprecated_noavaPerProfitBNB = 5e18;
        _deprecated_noavaPerNoavaBNBFlip = 6e18;
        __Ownable_init();
        NOAVA = _token;
        zap = ZapBSC(_zap);
        priceCalculator = _pricecal;

        IBEP20(_token).approve(NOAVA_POOL_V1, uint256(-1));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferNoavaOwner(address _owner) external onlyOwner {
        Ownable(NOAVA).transferOwnership(_owner);
    }

    function setWithdrawalFee(uint256 _fee) external onlyOwner {
        require(_fee < 500, "wrong fee");
        // less 5%
        WITHDRAWAL_FEE = _fee;
    }

    function setPerformanceFee(uint256 _fee) external onlyOwner {
        require(_fee < 5000, "wrong fee");
        PERFORMANCE_FEE = _fee;
    }

    function setWithdrawalFeeFreePeriod(uint256 _period) external onlyOwner {
        WITHDRAWAL_FEE_FREE_PERIOD = _period;
    }

    function setMinter(address minter, bool canMint)
        external
        override
        onlyOwner
    {
        if (canMint) {
            _minters[minter] = canMint;
        } else {
            delete _minters[minter];
        }
    }

    function setNoavaChef(address _noavaChef) external onlyOwner {
        require(
            noavaChef == address(0),
            "NoavaMinterV2: setNoavaChef only once"
        );
        noavaChef = _noavaChef;
    }

    function setFloatingRateEmission(uint256 floatingRateEmission)
        external
        onlyOwner
    {
        require(
            floatingRateEmission > 1e18 && floatingRateEmission < 10e18,
            "NoavaMinterV2: floatingRateEmission wrong range"
        );
        _floatingRateEmission = floatingRateEmission;
    }

    function setFREThreshold(uint256 threshold) external onlyOwner {
        _freThreshold = threshold;
    }

    function setNoavaPool(address _noavaPool) external onlyOwner {
        IBEP20(NOAVA).approve(NOAVA_POOL_V1, 0);
        noavaPool = _noavaPool;
        IBEP20(NOAVA).approve(_noavaPool, uint256(-1));
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view override returns (bool) {
        console.log("isMinter?");
        console.log(NOAVA);
        if (IBEP20(NOAVA).getOwner() != address(this)) {
            console.log("false");
            return false;
        }

        console.log(_minters[account]);
        bool isTrue = _minters[account];
        return isTrue;
    }

    function amountNoavaToMint(uint256 bnbProfit)
        public
        view
        override
        returns (uint256)
    {
        console.log(priceCalculator.priceOfBNB());
        console.log(priceCalculator.priceOfNoava());
        console.log(floatingRateEmission());

        return
            bnbProfit
                .mul(priceCalculator.priceOfBNB())
                .div(priceCalculator.priceOfNoava())
                .mul(floatingRateEmission())
                .div(1e18);
    }

    function amountNoavaToMintForNoavaBNB(uint256 amount, uint256 duration)
        public
        view
        override
        returns (uint256)
    {
        return
            amount
                .mul(_deprecated_noavaPerNoavaBNBFlip)
                .mul(duration)
                .div(365 days)
                .div(1e18);
    }

    function withdrawalFee(uint256 amount, uint256 depositedAt)
        external
        view
        override
        returns (uint256)
    {
        if (depositedAt.add(WITHDRAWAL_FEE_FREE_PERIOD) > block.timestamp) {
            return amount.mul(WITHDRAWAL_FEE).div(FEE_MAX);
        }
        return 0;
    }

    function performanceFee(uint256 profit)
        public
        view
        override
        returns (uint256)
    {
        console.log("ciao");
        return profit.mul(PERFORMANCE_FEE).div(FEE_MAX);
    }

    function floatingRateEmission() public view returns (uint256) {
        return _floatingRateEmission == 0 ? 120e16 : _floatingRateEmission;
    }

    function freThreshold() public view returns (uint256) {
        return _freThreshold == 0 ? 18e18 : _freThreshold;
    }

    function shouldMarketBuy() public view returns (bool) {
        return
            priceCalculator.priceOfNoava().mul(freThreshold()).div(
                priceCalculator.priceOfBNB()
            ) < 1e18;
    }

    /* ========== V1 FUNCTIONS ========== */

    function mintFor(
        address asset,
        uint256 _withdrawalFee,
        uint256 _performanceFee,
        address to,
        uint256
    ) public payable override onlyMinter {
        console.log("mint for 1");
        uint256 feeSum = _performanceFee.add(_withdrawalFee);
        console.log("mint for 2");
        _transferAsset(asset, feeSum);
        console.log("mint for 3");

        if (asset == NOAVA) {
            console.log("mint for if 1");
            IBEP20(NOAVA).safeTransfer(DEAD, feeSum);
            console.log("mint for if 2");
            return;
        }
        console.log("mint for 4");

        bool marketBuy = shouldMarketBuy();
        console.log("mint for 5");
        if (marketBuy == false) {
            console.log("mint for if market");
            if (asset == address(0)) {
                console.log("mint for if if asset");
                // means BNB
                SafeToken.safeTransferETH(FEE_BOX, feeSum);
                console.log("mint for if if asset 2");
            } else {
                console.log("mint for if else");
                IBEP20(asset).safeTransfer(FEE_BOX, feeSum);
                console.log("mint for if else 2");
            }
        } else {
            console.log("mint for else");
            if (_withdrawalFee > 0) {
                console.log("mint for else if");
                if (asset == address(0)) {
                    // means BNB
                    console.log("mint for else if if");
                    SafeToken.safeTransferETH(FEE_BOX, _withdrawalFee);
                    console.log("mint for else if if 2");
                } else {
                    console.log("mint for else if else");
                    IBEP20(asset).safeTransfer(FEE_BOX, _withdrawalFee);
                    console.log("mint for else if else 2");
                }
            }
            console.log("mint for else 1");
            if (_performanceFee == 0) return;
            console.log("mint for else 1 after if");
            _marketBuy(asset, _performanceFee, to);
            console.log("mint for else 2");
            _performanceFee = _performanceFee
                .mul(floatingRateEmission().sub(1e18))
                .div(floatingRateEmission());
            console.log("mint for else 3");
        }
        console.log("mint for uscito");

        (uint256 contributionInBNB, uint256 contributionInUSD) = priceCalculator
            .valueOfAsset(asset, _performanceFee);
        console.log("mint for value ok");
        uint256 mintNoava = amountNoavaToMint(contributionInBNB);
        console.log("mint for amount to mint ok");
        if (mintNoava == 0) return;
        _mint(mintNoava, to);

        if (marketBuy) {
            console.log("sbaglia proprio qui");
            uint256 usd = contributionInUSD.mul(floatingRateEmission()).div(
                floatingRateEmission().sub(1e18)
            );
            console.log("ipotetico errore superato :(");
            emit PerformanceFee(asset, _performanceFee, usd);
        } else {
            emit PerformanceFee(asset, _performanceFee, contributionInUSD);
        }
    }

    /* ========== PancakeSwap V2 FUNCTIONS ========== */

    function mintForV2(
        address asset,
        uint256 _withdrawalFee,
        uint256 _performanceFee,
        address to,
        uint256 timestamp
    ) external payable override onlyMinter {
        mintFor(asset, _withdrawalFee, _performanceFee, to, timestamp);
    }

    /* ========== NoavaChef FUNCTIONS ========== */

    function mint(uint256 amount) external override onlyNoavaChef {
        if (amount == 0) return;
        _mint(amount, address(this));
    }

    function safeNoavaTransfer(address _to, uint256 _amount)
        external
        override
        onlyNoavaChef
    {
        if (_amount == 0) return;

        uint256 bal = IBEP20(NOAVA).balanceOf(address(this));
        if (_amount <= bal) {
            IBEP20(NOAVA).safeTransfer(_to, _amount);
        } else {
            IBEP20(NOAVA).safeTransfer(_to, bal);
        }
    }

    // @dev should be called when determining mint in governance. Noava is transferred to the timelock contract.
    function mintGov(uint256 amount) external override onlyOwner {
        if (amount == 0) return;
        _mint(amount, TIMELOCK);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _marketBuy(
        address asset,
        uint256 amount,
        address to
    ) private {
        console.log("marketBuy");
        uint256 _initNoavaAmount = IBEP20(NOAVA).balanceOf(address(this));
        console.log("marketBuy 1");
        if (asset == address(0)) {
            console.log("marketBuy zap");
            zap.zapIn{value: amount}(NOAVA);
        } else if (
            keccak256(abi.encodePacked(IPancakePair(asset).symbol())) ==
            keccak256("Cake-LP")
        ) {
            console.log("marketBuy cake-lp");
            if (IBEP20(asset).allowance(address(this), address(router)) == 0) {
                IBEP20(asset).safeApprove(address(router), uint256(-1));
            }

            IPancakePair pair = IPancakePair(asset);
            address token0 = pair.token0();
            address token1 = pair.token1();

            // burn
            if (IPancakePair(asset).balanceOf(asset) > 0) {
                IPancakePair(asset).burn(address(zap));
            }

            (uint256 amountToken0, uint256 amountToken1) = router
                .removeLiquidity(
                    token0,
                    token1,
                    amount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

            if (IBEP20(token0).allowance(address(this), address(zap)) == 0) {
                IBEP20(token0).safeApprove(address(zap), uint256(-1));
            }
            if (IBEP20(token1).allowance(address(this), address(zap)) == 0) {
                IBEP20(token1).safeApprove(address(zap), uint256(-1));
            }

            if (token0 != NOAVA) {
                zap.zapInToken(token0, amountToken0, NOAVA);
            }

            if (token1 != NOAVA) {
                zap.zapInToken(token1, amountToken1, NOAVA);
            }
        } else {
            console.log("marketBuy else");
            if (IBEP20(asset).allowance(address(this), address(zap)) == 0) {
                console.log("marketBuy else if");
                IBEP20(asset).safeApprove(address(zap), uint256(-1));
                console.log("marketBuy else if 1");
            }

            zap.zapInToken(asset, amount, NOAVA);
        }

        uint256 noavaAmount = IBEP20(NOAVA).balanceOf(address(this)).sub(
            _initNoavaAmount
        );
        IBEP20(NOAVA).safeTransfer(to, noavaAmount);
    }

    function _transferAsset(address asset, uint256 amount) private {
        if (asset == address(0)) {
            // case) transferred BNB
            require(msg.value >= amount);
        } else {
            IBEP20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function _mint(uint256 amount, address to) private {
        BEP20 tokenNOAVA = BEP20(NOAVA);

        tokenNOAVA.mint(amount);
        if (to != address(this)) {
            tokenNOAVA.transfer(to, amount);
        }

        uint256 noavaForDev = amount.mul(15).div(100);
        tokenNOAVA.mint(noavaForDev);
        if (noavaPool == address(0)) {
            tokenNOAVA.transfer(DEPLOYER, noavaForDev);
        } else {
            INoavaPool(noavaPool).depositOnBehalf(noavaForDev, DEPLOYER);
        }
    }
}
