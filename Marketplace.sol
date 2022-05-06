// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is ERC1155Holder {

    struct Listing {
        uint256 tokenId;
        uint256 amount;
        uint256 priceETH;
        address ownerAddress;
    }

    mapping(uint256 => Listing) public listings;
    uint256 private currentListing = 0;
    address private bondAddress;

    constructor(address _bondAddress) {
        bondAddress = _bondAddress;
    }

    function listBond(uint256 _tokenId, uint256 _amount, uint256 _priceETH) external {
        require(_amount > 0, "Marketplace: Amount must be greater than 0.");
        require(_priceETH > 0, "Marketplace: Price must be greater than 0.");
        IERC1155(bondAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        listings[currentListing] = Listing(_tokenId, _amount, _priceETH, msg.sender);
        currentListing = SafeMath.add(currentListing, 1);
    }

    function delistBond(uint256 _listingId) external {
        require(_listingId <= currentListing, "Marketplace: Listing ID does not exist.");
        Listing memory listing = listings[_listingId];
        IERC1155(bondAddress).safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, "");
        delete listings[_listingId];
    }

    function buy(uint256 _listingId) external payable {
        require(_listingId <= currentListing, "Marketplace: Listing ID does not exist.");
        Listing memory listing = listings[_listingId];
        require(listing.amount > 0, "Listing not available.");
        require(msg.value >= listing.priceETH, "Insufficient funds!");
        payable(listing.ownerAddress).transfer(listing.priceETH);
        IERC1155(bondAddress).safeTransferFrom(address(this), msg.sender, listing.tokenId, listing.amount, "");
        delete listings[_listingId];
    }


}
