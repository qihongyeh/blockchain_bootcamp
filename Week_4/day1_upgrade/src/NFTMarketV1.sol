// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract NFTMarketV1 is Initializable {
    // 声明nft的挂单价
    mapping(uint256 tokenId => uint256 price) public tokenIdPrice;
    // 声明nft的挂单者
    mapping(uint256 tokenId => address seller) public tokenIdSeller;
    // 声明token
    address public token;
    // 声明nft
    address public nft;

    // // 初始化token与nft
    // constructor(address _token, address _nftToken) {
    //     token = _token;
    //     nftToken = _nftToken;
    // }

    // 代理合约部署时的初始化
    function initialize(address _token, address _nft) public initializer {
        token = _token;
        nft  = _nft;
    }

    // ERC721Received
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // 出售nft，但需要先对nft的转移进行授权
    function list(uint256 tokenId, uint256 price) external returns (bool) {
        // 转移nft至市场中
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId, "");
        // 记录挂单价
        tokenIdPrice[tokenId] = price;
        // 记录挂单者
        tokenIdSeller[tokenId] = msg.sender;

        return true;
    }

    // 购买nft，但需要先对token的转移进行授权
    function buy(uint256 tokenId, uint256 price) external returns (bool) {
        // 检查报价是否过低
        require(price >= tokenIdPrice[tokenId], "Bid price too low!!!");
        // 检查nft是否已经售卖
        require(IERC721(nft).ownerOf(tokenId) == address(this), "The nft already sold!!!");
        // 将token转移给卖家
        IERC20(token).transferFrom(msg.sender, tokenIdSeller[tokenId], tokenIdPrice[tokenId]);
        // 将nft转移给买家
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);

        return true;
    }
}
