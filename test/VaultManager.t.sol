// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../src/VaultManager.sol";
import "forge-std/Test.sol";

contract VaultManagerTest is Test {
    VaultManager vaultManager =
        VaultManager(0x33394e0FBd995469186cE7F9773067695e3FCF59);
    IERC20 token;
    IOtherDeed otherdeed =
        IOtherDeed(0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258);

    address constant HASAN = 0x692E668E741a28C4529d059E84Fadf110a9161d4;

    address[] kycWallets = [address(1), address(2)];

    function setUp() public {
        vm.deal(HASAN, 100 ether);

        vm.startPrank(0xF977814e90dA44bFA03b6295A0616a897441aceC);
        token = vaultManager.singleton().token();
        token.transfer(HASAN, 305000 ether);
        vm.stopPrank();

        vm.prank(0xcDA9742761cB069ff70b5cD5fCb8DD636a453961);
        otherdeed.startPublicSale(100 ether, 305 ether, 305 ether, 2, 2, false);
    }

    function testVaultClone() external {
        vm.prank(HASAN);
        vaultManager.createVault();
        Vault vault = vaultManager.vaults(HASAN);

        assertEq(vault.owner(), HASAN);
        assertEq(
            address(vault.token()),
            0x4d224452801ACEd8B2F0aebE155379bb5D594381
        );
        assertEq(
            address(vault.otherdeed()),
            0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258
        );

        vm.expectRevert(
            abi.encodeWithSignature("VaultExists(address)", address(vault))
        );

        vm.prank(HASAN);
        vaultManager.createVault();

        vm.expectRevert(abi.encodeWithSignature("NotOwner()"));
        vault.withdraw(HASAN);
    }

    function testBundleMint() external {
        vm.startPrank(HASAN);

        vaultManager.createVault();
        Vault vault = vaultManager.vaults(HASAN);
        token.approve(address(vault), type(uint256).max);

        vault.disperse{value: 2 ether}(
            kycWallets,
            otherdeed.getMintPrice() * 2
        );
        vm.stopPrank();

        vm.startPrank(address(1));
        token.approve(address(otherdeed), type(uint256).max);
        otherdeed.setApprovalForAll(address(vault), true);
        vm.stopPrank();

        vm.startPrank(address(2));
        token.approve(address(otherdeed), type(uint256).max);
        otherdeed.setApprovalForAll(address(vault), true);
        vm.stopPrank();

        assertTrue(address(1).balance > 1 ether);
        assertTrue(address(2).balance > 1 ether);

        bytes32[] memory proof = new bytes32[](0);

        uint256 maxMintPerTx = otherdeed.maxMintPerTx();

        vm.startPrank(address(1), address(1));
        otherdeed.mintLands(maxMintPerTx, proof);
        vm.stopPrank();

        vm.startPrank(address(2), address(2));
        otherdeed.mintLands(maxMintPerTx, proof);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("NotOwner()"));
        vault.claimTokensBundle(kycWallets, maxMintPerTx);

        vm.prank(HASAN);
        vault.claimTokensBundle(kycWallets, maxMintPerTx);
    }

    function testNormalMint() external {
        vm.startPrank(HASAN);

        vaultManager.createVault();
        Vault vault = vaultManager.vaults(HASAN);
        token.approve(address(vault), type(uint256).max);

        vault.disperse{value: 2 ether}(
            kycWallets,
            otherdeed.getMintPrice() * 2
        );
        vm.stopPrank();

        vm.startPrank(address(1));
        token.approve(address(otherdeed), type(uint256).max);
        otherdeed.setApprovalForAll(address(vault), true);
        vm.stopPrank();

        vm.startPrank(address(2));
        token.approve(address(otherdeed), type(uint256).max);
        otherdeed.setApprovalForAll(address(vault), true);
        vm.stopPrank();

        assertTrue(address(1).balance > 1 ether);
        assertTrue(address(2).balance > 1 ether);

        bytes32[] memory proof = new bytes32[](0);

        uint256 maxMintPerTx = otherdeed.maxMintPerTx();

        vm.startPrank(address(1), address(1));
        otherdeed.mintLands(maxMintPerTx, proof);
        vm.stopPrank();

        vm.startPrank(address(2), address(2));
        otherdeed.mintLands(maxMintPerTx, proof);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSignature("NotOwner()"));
        vault.claimTokens(kycWallets);

        vm.prank(HASAN);
        vault.claimTokens(kycWallets);
    }
}

interface IOtherDeed {
    struct Metadata {
        bytes32 metadataHash;
        bytes32 shuffledArrayHash;
        uint256 startIndex;
        uint256 endIndex;
    }

    function MAX_ALPHA_NFT_AMOUNT() external view returns (uint256);

    function MAX_BETA_NFT_AMOUNT() external view returns (uint256);

    function MAX_FUTURE_LANDS() external view returns (uint256);

    function MAX_LANDS() external view returns (uint256);

    function MAX_LANDS_WITH_FUTURE() external view returns (uint256);

    function MAX_MINT_PER_BLOCK() external view returns (uint256);

    function MAX_PUBLIC_SALE_AMOUNT() external view returns (uint256);

    function RESERVED_CONTRIBUTORS_AMOUNT() external view returns (uint256);

    function adminClaimStarted() external view returns (bool);

    function alphaClaimed(uint256) external view returns (bool);

    function alphaClaimedAmount() external view returns (uint256);

    function alphaContract() external view returns (address);

    function alphaOffset() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function betaClaimed(uint256) external view returns (bool);

    function betaClaimedAmount() external view returns (uint256);

    function betaContract() external view returns (address);

    function betaNftIdCurrent() external view returns (uint256);

    function betaOffset() external view returns (uint256);

    function claimUnclaimedAndUnsoldLands(address recipient) external;

    function claimUnclaimedAndUnsoldLandsWithAmount(
        address recipient,
        uint256 maxAmount
    ) external;

    function claimableActive() external view returns (bool);

    function contributors(address) external view returns (uint256);

    function contributorsClaimActive() external view returns (bool);

    function contributorsClaimLand(uint256 amount, address recipient) external;

    function currentNumLandsMintedPublicSale() external view returns (uint256);

    function fee() external view returns (uint256);

    function flipClaimableState() external;

    function futureLandsNftIdCurrent() external view returns (uint256);

    function futureMinter() external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function getMintPrice() external view returns (uint256);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isRandomRequestForPublicSaleAndContributors(bytes32)
        external
        view
        returns (bool);

    function keyHash() external view returns (bytes32);

    function kycMerkleRoot() external view returns (bytes32);

    function loadLandMetadata(Metadata memory _landMetadata) external;

    function maxMintPerAddress() external view returns (uint256);

    function maxMintPerTx() external view returns (uint256);

    function metadataHashes(uint256)
        external
        view
        returns (
            bytes32 metadataHash,
            bytes32 shuffledArrayHash,
            uint256 startIndex,
            uint256 endIndex
        );

    function mintFutureLands(address recipient) external;

    function mintFutureLandsWithAmount(address recipient, uint256 maxAmount)
        external;

    function mintIndexPublicSaleAndContributors()
        external
        view
        returns (uint256);

    function mintLands(uint256 numLands, bytes32[] calldata merkleProof)
        external;

    function mintedPerAddress(address) external view returns (uint256);

    function name() external view returns (string calldata);

    function nftOwnerClaimLand(
        uint256[] calldata alphaTokenIds,
        uint256[] calldata betaTokenIds
    ) external;

    function operator() external view returns (address);

    function owner() external view returns (address);

    function ownerClaimRandomnessRequested() external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function publicSaleActive() external view returns (bool);

    function publicSaleAndContributorsOffset() external view returns (uint256);

    function publicSaleAndContributorsRandomnessRequested()
        external
        view
        returns (bool);

    function publicSaleEndingPrice() external view returns (uint256);

    function publicSalePriceLoweringDuration() external view returns (uint256);

    function publicSaleStartPrice() external view returns (uint256);

    function publicSaleStartTime() external view returns (uint256);

    function putLandMetadataAtIndex(
        uint256 index,
        Metadata memory _landMetadata
    ) external;

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external;

    function renounceOwnership() external;

    function requestRandomnessForOwnerClaim()
        external
        returns (bytes32 requestId);

    function requestRandomnessForPublicSaleAndContributors()
        external
        returns (bytes32 requestId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory uri) external;

    function setFutureMinter(address _futureMinter) external;

    function setKycCheckRequired(bool _isKycCheckRequired) external;

    function setKycMerkleRoot(bytes32 _kycMerkleRoot) external;

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external;

    function setMaxMintPerTx(uint256 _maxMintPerTx) external;

    function setOperator(address _operator) external;

    function startContributorsClaimPeriod() external;

    function startPublicSale(
        uint256 _publicSalePriceLoweringDuration,
        uint256 _publicSaleStartPrice,
        uint256 _publicSaleEndingPrice,
        uint256 _maxMintPerTx,
        uint256 _maxMintPerAddress,
        bool _isKycCheckRequired
    ) external;

    function stopContributorsClaimPeriod() external;

    function stopPublicSale() external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string calldata);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenContract() external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string calldata);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;

    function withdraw() external;
}
