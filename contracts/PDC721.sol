//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./LilOwnable.sol";
import "./Merkle.sol";
import "@rari-capital/solmate/tokens/ERC721.sol";
import "@rari-capital/solmate/utils/SafeTransferLib.sol";

error DoesNotExist();
error NoTokensLeft();
error NotEnoughETH();
error TooManyMintAtOnce();
error NotOnWhitelist();
error WhitelistMintNotStarted();
error MintNotStarted();

contract ERC721Token is LilOwnable, ERC721 {
    uint256 public constant TOTAL_SUPPLY = 7727;
    uint256 public constant PRICE_PER_MINT = 0.05 ether;
    uint256 public maxMintAmount = 10;

    bool public whitelistMintStarted = false;
    bool public mintStarted = false;
    bool public revealed = false;

    uint256 public totalSupply;

    string public baseURI;
    string public notRevealedURI;

    bytes32 public immutable merkleRoot;

    constructor(
        string memory name,
        string memory symbol,
        bytes memory _merkleRoot,
        string memory _baseURI,
        string memory _nonRevealedBaseUri
    ) payable ERC721(name, symbol) {
        merkleRoot = _merkleRoot;
        setBaseURI(_newBaseURI);
        setNotRevealedUri(_nonRevealedBaseUri);
    }

    
    function verifyWhitelist(bytes32[] memory _proof, uint256[] memory _positions) 
      public 
      view 
      returns (bool) 
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleRoot, _leaf, _proof, _positions);
    }

    function mint(uint16 amount) external payable {
        if (!mintStarted) revert MintNotStarted();
        if (totalSupply + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
        if (msg.value < amount * PRICE_PER_MINT) revert NotEnoughETH();
        if (amount > maxMintAmount) revert TooManyMintAtOnce();

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply++);
            }
        }
    }

    function whitelistMint(uint16 amount, bytes32 _proof, uint256 _positions) external payable {
        if (!whitelistSaleHasStarted) revert WhitelistSaleNotActive();
        if (totalSupply + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
        if (msg.value < amount * PRICE_PER_MINT) revert NotEnoughETH();
        if (amount > maxMintAmount) revert TooManyMintAtOnce();
        if (verifyWhitelist(_proof, _positions) == false) revert NotOnWhitelist();
        
        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply++);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        if (revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI,tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function startWhitelistMint(bool started) public onlyOwner {
        whitelistMintStarted = true;
    }
    
    function startMint(bool started) public onlyOwner {
        mintStarted = true;
    }

    function setMerkleRoot(bytes32 _merkleRootValue) external onlyOwner returns (bytes32){
        merkleRoot = _merkleRootValue;
        return merkleRoot;
    }

    function withdraw() external {
        if (msg.sender != _owner) revert NotOwner();

        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(LilOwnable, ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}
