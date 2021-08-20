pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../LErc20.sol";
import "../CToken.sol";
import "../PriceOracle.sol";
import "../EIP20Interface.sol";
import "../Governance/DexPro.sol";
import "../SimplePriceOracle.sol";

interface ComptrollerLensInterface {

    function compSpeeds(address) external view returns (uint);
    function compSupplyState(address) external view returns(uint224, uint32);
    function compBorrowState(address) external view returns(uint224, uint32);
    function compSupplierIndex(address, address) external view returns (uint);
    function compBorrowerIndex(address, address) external view returns (uint);

    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (PriceOracle);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (CToken[] memory);
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
    function getCompAddress() external view returns (address);
}

contract DexProLensDPT is ExponentialNoError {
    struct CTokenDPTData {
        address cToken;
        uint supplyDPTAPY;
        uint borrowDPTAPY;
    }

    function cTokenDPTMetadata(CToken cToken) view public returns (CTokenDPTData memory) {
        ComptrollerLensInterface comptroller = ComptrollerLensInterface(address(cToken.comptroller()));
        uint speed = comptroller.compSpeeds(address(cToken));
        SimplePriceOracle priceOracle = SimplePriceOracle(address(comptroller.oracle()));
        uint bptPrice = priceOracle.assetPrices(comptroller.getCompAddress());
        // 24位小数
        uint exchangeRateCurrent = cToken.exchangeRateStored();
        uint totalPrice = cToken.totalSupply() * exchangeRateCurrent * priceOracle.getUnderlyingPrice(cToken);
        uint supplyAPY = 1000000000000000000 * 1000000 * 10512000 * speed * bptPrice / totalPrice;
        uint totalBorrowPrice = cToken.totalBorrows() * priceOracle.getUnderlyingPrice(cToken);
        uint borrowDPTAPY = 1000000 * 10512000 * speed * bptPrice / totalBorrowPrice;

        return CTokenDPTData({
            cToken: address(cToken),
            supplyDPTAPY: supplyAPY,
            borrowDPTAPY: borrowDPTAPY
            });
    }

    function calcDPTAPYs(CToken[] memory cTokens) public view returns (CTokenDPTData[] memory)  {
        uint cTokenCount = cTokens.length;
        CTokenDPTData[] memory res = new CTokenDPTData[](cTokenCount);

        for (uint i = 0; i < cTokenCount; i++) {
            CToken cToken = cTokens[i];
            res[i] = cTokenDPTMetadata(cToken);
        }
        return res;
    }
}
