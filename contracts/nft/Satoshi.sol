// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";

import "./ISatoshi.sol";
import "./IWhitelist.sol";

contract Satoshi is Ownable, ERC721Enumerable, ERC721Votes, ISatoshi {
  struct Track {
    uint256 tokenId;
    uint256 index;
    uint256 mintAt;
    uint256 mintBlock;
    uint256 tradeAt;
    uint256 tradeBlock;
    uint256 transactionCount;
  }

  uint256[] private TOKEN_IDS = [
       2,    3,    5,    7,   11,   13,   17,   19,   23,   29,
      31,   37,   41,   43,   47,   53,   59,   61,   67,   71,
      73,   79,   83,   89,   97,  101,  103,  107,  109,  113,
     127,  131,  137,  139,  149,  151,  157,  163,  167,  173,
     179,  181,  191,  193,  197,  199,  211,  223,  227,  229,
     233,  239,  241,  251,  257,  263,  269,  271,  277,  281,
     283,  293,  307,  311,  313,  317,  331,  337,  347,  349,
     353,  359,  367,  373,  379,  383,  389,  397,  401,  409,
     419,  421,  431,  433,  439,  443,  449,  457,  461,  463,
     467,  479,  487,  491,  499,  503,  509,  521,  523,  541,
     547,  557,  563,  569,  571,  577,  587,  593,  599,  601,
     607,  613,  617,  619,  631,  641,  643,  647,  653,  659,
     661,  673,  677,  683,  691,  701,  709,  719,  727,  733,
     739,  743,  751,  757,  761,  769,  773,  787,  797,  809,
     811,  821,  823,  827,  829,  839,  853,  857,  859,  863,
     877,  881,  883,  887,  907,  911,  919,  929,  937,  941,
     947,  953,  967,  971,  977,  983,  991,  997, 1009, 1013,
    1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069,
    1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129, 1151,
    1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223
  ];
  mapping (uint256 => bool) private _tokenValids;
  
  uint256 private constant CAPACITY = 200;
  uint256 private constant RESERVED = 107;

  string private _contractURI;
  string private _baseTokenURI;
  uint256 private _geniusPrice;
  address private _fund;

  IWhitelist private _whitelist;

  mapping(uint256 => Track) private _tracks;

  modifier onlyValid(uint256 tokenId) {
    require(_isValid(tokenId), "Satoshi: invalid tokenId");
    _;
  }

  constructor(uint256 geniusPrice_, address fund_, address whitelist_) ERC721("Satoshi", "Satoshi") EIP712("Satoshi", "1") {
    _geniusPrice = geniusPrice_;
    _fund = fund_;
    _whitelist = IWhitelist(whitelist_);

    for(uint256 i = 0; i < TOKEN_IDS.length; i++) {
      _tokenValids[TOKEN_IDS[i]] = true;
    }
  }

  function mint(uint256 tokenId) external override payable onlyValid(tokenId) {
    require(!_isReserved(tokenId), "Satoshi: token is reserved");

    address account = _msgSender();

    uint256 discount;
    if(!_whitelist.isExpired()) {
      require(_whitelist.exists(account), "Satoshi: not on the whitelist");
      
      discount = _whitelist.getDiscount(account);
      require(discount > 0, "Satoshi: discount used");
    }

    uint256 amount = msg.value;
    require(amount == _getPrice(discount), "Satoshi: mint cost error");

    (bool success,) = _fund.call{value:amount}("");
    require(success, 'Satoshi: ether transfer failed');

    _mint(account, account, tokenId);

    if(discount > 0) {
      _whitelist.useDiscount(account);
    }
  }

  function reward(address recipient, uint256 tokenId) external override onlyValid(tokenId) onlyOwner {
    require(_isReserved(tokenId), "Satoshi: token is not reserved");

    _mint(owner(), recipient, tokenId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseTokenURI = baseURI_;
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    _contractURI = contractURI_;
  }

  function baseURI() external view override returns (string memory) {
    return _baseURI();
  }

  function contractURI() external view override returns (string memory) {
    return _contractURI;
  }

  function fund() external view override returns (address) {
    return _fund;
  }

  function capacity() external pure override returns (uint256) {
    return CAPACITY;
  }

  function geniusPrice() external view override returns (uint256) {
    return _geniusPrice;
  }

  function whitelist() external view override returns (address) {
    return address(_whitelist);
  }

  function deadline() external view override returns (uint256) {
    return _whitelist.deadline();
  }

  function isWhitelistExpired() external view override returns (bool) {
    return _whitelist.isExpired();
  }

  function getPrice(address account) external view override returns (uint256) {
    return _getPrice(_whitelist.getDiscount(account));
  }

  function exists(uint256 tokenId) external view override returns (bool) {
    return _exists(tokenId);
  }

  function getData(uint256 tokenId) external view override returns (
    bool valid,
    bool reserved,
    bool minted,
    address owner,
    uint256 index,
    uint256 transactionCount,
    uint256 mintAt,
    uint256 tradeAt,
    uint256 mintBlock,
    uint256 tradeBlock
  ) {
    if(_isValid(tokenId)) {
      valid = true;
      reserved = _isReserved(tokenId);
      minted = _exists(tokenId);

      if(minted) {
        owner = ownerOf(tokenId);
        Track memory track = _tracks[tokenId];
        index = track.index;
        transactionCount = track.transactionCount;
        mintAt = track.mintAt;
        tradeAt = track.tradeAt;
        mintBlock = track.mintBlock;
        tradeBlock = track.tradeBlock;
      }
    }
  }

  function getChainId() external view returns (uint256) {
    return block.chainid;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    return ERC721Enumerable.supportsInterface(interfaceId);
  }

  function _getPrice(uint256 discount) private view returns (uint256) {
    return discount > 0 ? discount : _geniusPrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    super._transfer(from, to, tokenId);

    Track storage track = _tracks[tokenId];
    track.tradeAt = block.timestamp;
    track.tradeBlock = block.number;
    track.transactionCount++;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Votes) {
    ERC721Votes._afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address minter, address recipient, uint256 tokenId) private {
    _mint(recipient, tokenId);

    uint256 index = totalSupply() - 1;
    _tracks[tokenId] = Track(tokenId, index, block.timestamp, block.number, block.timestamp, block.number, 1);

    emit Mint(minter, recipient, tokenId, index);
  }

  function _isValid(uint256 tokenId) private view returns (bool) {
    return _tokenValids[tokenId];
  }

  function _isReserved(uint256 tokenId) private pure returns (bool) {
    return tokenId <= RESERVED;
  }
}