pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Bond is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

contract Jar is ERC1155Holder, ERC721Holder {

    struct BondInfo {
        uint256 unlockTime;
        address tokenAddress;
        uint256 tokenId; // NFT token ID
    }

    mapping(uint256 => BondInfo) public bonds; // Bond ID => Bond Info
    uint256 private currentId = 0;

    Bond public immutable bond;

    constructor() {
        bond = new Bond();
    }

    function _lock(address _token, uint256 _tokenId, uint256 _amount, uint256 _unlockTime) external {
        bond.mint(msg.sender, currentId, _amount, "");
        bonds[currentId] = BondInfo(_unlockTime, _token, _tokenId);
        currentId += 1;
    }

    function _unlock(uint256 _id, uint256 _amount) external {
        bond.safeTransferFrom(msg.sender, address(this), _id, _amount, "");
        bond.burn(address(this), _id, _amount);
    }

    function lockFT(address _token, uint256 _amount, uint256 _unlockTime) external {
        require(_amount > 0, "Jar: Amount must be >0");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        this._lock(_token, 0, _amount, _unlockTime);
    }

    function unlockFT(uint256 _id, uint256 _amount) external {
        require(_amount > 0, "Jar: Amount must be >0");
        BondInfo info = bonds[_id];
        require(block.timestamp >= info.unlockTime, "Jar: Tokens not unlocked yet.");
        this._unlock(_id, _amount);
        IERC20(info.tokenAddress).transfer(msg.sender, _amount);
    }

    function lockNFT(address _token, uint256 _tokenId, uint256 _unlockTime) external {
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        this._lock(_token, _tokenId, 1, _unlockTime);
    }

    function unlockNFT(uint256 _id) external {
        BondInfo info = bonds[_id];
        require(block.timestamp >= info.unlockTime, "Jar: Token not unlocked yet.");
        this._unlock(_id, 1);
        IERC721(info.tokenAddress).safeTransferFrom(address(this), msg.sender, info.tokenId);
    }

}
