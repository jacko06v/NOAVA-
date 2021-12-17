// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./library/pancakeswap/IBEP20.sol";
import "./library/pancakeswap/BEP20.sol";
import "./library/pancakeswap/SafeMath.sol";

import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/legacy/IStrategyHelper.sol";

// no storage
// There are only calculations for apy, tvl, etc.
contract StrategyHelperV1 is IStrategyHelper {
    using SafeMath for uint256;
    address private constant CAKE_POOL =
        0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6;
    address private constant BNB_BUSD_POOL =
        0x1B96B92314C44b159149f7E0303511fB2Fc4774f;

    IBEP20 private constant WBNB =
        IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IBEP20 private constant CAKE =
        IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IBEP20 private constant BUSD =
        IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    IMasterChef private constant master =
        IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    IPancakeFactory private constant factory =
        IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    function tokenPriceInBNB(address _token)
        public
        view
        override
        returns (uint256)
    {
        address pair = factory.getPair(_token, address(WBNB));
        uint256 decimal = uint256(BEP20(_token).decimals());

        return
            WBNB.balanceOf(pair).mul(10**decimal).div(
                IBEP20(_token).balanceOf(pair)
            );
    }

    function cakePriceInBNB() public view override returns (uint256) {
        return
            WBNB.balanceOf(CAKE_POOL).mul(1e18).div(CAKE.balanceOf(CAKE_POOL));
    }

    function bnbPriceInUSD() public view override returns (uint256) {
        return
            BUSD.balanceOf(BNB_BUSD_POOL).mul(1e18).div(
                WBNB.balanceOf(BNB_BUSD_POOL)
            );
    }

    function cakePerYearOfPool(uint256 pid) public view returns (uint256) {
        (, uint256 allocPoint, , ) = master.poolInfo(pid);
        return
            master.cakePerBlock().mul(blockPerYear()).mul(allocPoint).div(
                master.totalAllocPoint()
            );
    }

    function blockPerYear() public pure returns (uint256) {
        // 86400 / 3 * 365
        return 10512000;
    }

    function profitOf(
        IPinkMinterV1 minter,
        address flip,
        uint256 amount
    )
        external
        view
        override
        returns (
            uint256 _usd,
            uint256 _pink,
            uint256 _bnb
        )
    {
        _usd = tvl(flip, amount);
        if (address(minter) == address(0)) {
            _pink = 0;
        } else {
            uint256 performanceFee = minter.performanceFee(_usd);
            _usd = _usd.sub(performanceFee);
            uint256 bnbAmount = performanceFee.mul(1e18).div(bnbPriceInUSD());
            _pink = minter.amountPinkToMint(bnbAmount);
        }
        _bnb = 0;
    }

    // apy() = cakePrice * (cakePerBlock * blockPerYear * weight) / PoolValue(=WBNB*2)
    function _apy(uint256 pid) private view returns (uint256) {
        (address token, , , ) = master.poolInfo(pid);
        uint256 poolSize = tvl(token, IBEP20(token).balanceOf(address(master)))
            .mul(1e18)
            .div(bnbPriceInUSD());
        return cakePriceInBNB().mul(cakePerYearOfPool(pid)).div(poolSize);
    }

    function apy(IPinkMinterV1, uint256 pid)
        public
        view
        override
        returns (
            uint256 _usd,
            uint256 _pink,
            uint256 _bnb
        )
    {
        _usd = compoundingAPY(pid, 1 days);
        _pink = 0;
        _bnb = 0;
    }

    function tvl(address _flip, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        if (_flip == address(CAKE)) {
            return cakePriceInBNB().mul(bnbPriceInUSD()).mul(amount).div(1e36);
        }
        address _token0 = IPancakePair(_flip).token0();
        address _token1 = IPancakePair(_flip).token1();
        if (_token0 == address(WBNB) || _token1 == address(WBNB)) {
            uint256 bnb = WBNB.balanceOf(address(_flip)).mul(amount).div(
                IBEP20(_flip).totalSupply()
            );
            uint256 price = bnbPriceInUSD();
            return bnb.mul(price).div(1e18).mul(2);
        }

        uint256 balanceToken0 = IBEP20(_token0).balanceOf(_flip);
        uint256 price = tokenPriceInBNB(_token0);
        return
            balanceToken0
                .mul(price)
                .div(1e18)
                .mul(bnbPriceInUSD())
                .div(1e18)
                .mul(2);
    }

    function tvlInBNB(address _flip, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        if (_flip == address(CAKE)) {
            return cakePriceInBNB().mul(amount).div(1e18);
        }
        address _token0 = IPancakePair(_flip).token0();
        address _token1 = IPancakePair(_flip).token1();
        if (_token0 == address(WBNB) || _token1 == address(WBNB)) {
            uint256 bnb = WBNB.balanceOf(address(_flip)).mul(amount).div(
                IBEP20(_flip).totalSupply()
            );
            return bnb.mul(2);
        }

        uint256 balanceToken0 = IBEP20(_token0).balanceOf(_flip);
        uint256 price = tokenPriceInBNB(_token0);
        return balanceToken0.mul(price).div(1e18).mul(2);
    }

    function compoundingAPY(uint256 pid, uint256 compoundUnit)
        public
        view
        override
        returns (uint256)
    {
        uint256 __apy = _apy(pid);
        uint256 compoundTimes = 365 days / compoundUnit;
        uint256 unitAPY = 1e18 + (__apy / compoundTimes);
        uint256 result = 1e18;

        for (uint256 i = 0; i < compoundTimes; i++) {
            result = (result * unitAPY) / 1e18;
        }

        return result - 1e18;
    }
}
