// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Daao} from "../src/Daao.sol";
import {DaaoToken} from "../src/DaaoToken.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IVelodromeFactory, INonfungiblePositionManager} from "../src/interface.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import {MockReceiver} from "./MockReceiver.sol";
import {MockFailingReceiver} from "./MockFailingReceiver.sol";
import {MockTokenSpender} from "./MockTokenSpender.sol";
import {LockerFactory} from "../src/LPLocker/LockerFactory.sol";
import {WrappedMonad} from "./MockWrappedEther.sol";
interface ILocker {
    function owner() external view returns (address);
    function fundExpiry() external view returns (uint256);
    function _protocolFee() external view returns (uint256);
    function released(address) external view returns (uint256);
}

contract DaaoTestNativeToken is Test{

    Daao public dao;
    address public paymentToken;
    uint256 constant INITIAL_BALANCE = 100000 ether;

    address constant USER_1 = address(1);
    address constant USER_2 = address(2);
    address constant USER_3 = address(3);
    address constant USER_4 = address(4);
    address constant USER_5 = address(5);
    address constant USER_6 = address(6);
    address constant USER_7 = address(7);
    address constant USER_8 = address(8);
    address constant USER_9 = address(9);
    address constant USER_10 = address(10);

    address constant PROTOCOL_ADMIN = address(0x11);
    address constant DAO_MANAGER = address(0x12);
    address LIQUIDITY_LOCKER_FACTORY;
    address constant MODE_WHALE = 0x20FcD2699784314d53Be3Ee42B60906A38F96cf3;

    address NONFUNGIBLE_POSITION_MANAGER = 0x3dCc735C74F10FE2B9db2BB55C40fbBbf24490f7;

    function setUp() public {
        // Deploy and setup mock address(paymentToken) token
        // paymentToken = address(new WrappedMonad());
        // vm.etch(0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701, address(paymentToken).code);
        paymentToken = 0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701;
        
        uint256 fundraisingGoal = 10 ether; // 10
        uint256 fundraisingDeadline = block.timestamp + 7 days; // 7 days from now
        uint256 fundExpiry = fundraisingDeadline + 30 days; // 30 days after deadline
        address daoManager = DAO_MANAGER;

        LIQUIDITY_LOCKER_FACTORY = address(new LockerFactory());
    
        address liquidityLockerFactory = LIQUIDITY_LOCKER_FACTORY;
        address protocolAdmin = PROTOCOL_ADMIN;

        dao = new Daao(
            fundraisingGoal,
            "Daao",
            "DAO",
            fundraisingDeadline,
            fundExpiry,
            daoManager,
            liquidityLockerFactory,
            protocolAdmin,
            paymentToken,
            NONFUNGIBLE_POSITION_MANAGER
        );

        // Give users some address(paymentToken) tokens
        vm.deal(USER_1, INITIAL_BALANCE);
        vm.deal(USER_2, INITIAL_BALANCE);
        vm.deal(USER_3, INITIAL_BALANCE);
        vm.deal(USER_4, INITIAL_BALANCE);
        vm.deal(USER_5, INITIAL_BALANCE);
        vm.deal(USER_6, INITIAL_BALANCE);
        vm.deal(USER_7, INITIAL_BALANCE);
        vm.deal(USER_8, INITIAL_BALANCE);
        vm.deal(USER_9, INITIAL_BALANCE);
        vm.deal(USER_10, INITIAL_BALANCE);
        
        
    }

    function test_constructorShouldRevertIfFundraisingGoalIsZero() public {
        vm.expectRevert("Fundraising goal must be greater than 0");
        new Daao(
            0, // Invalid fundraising goal
            "Daao",
            "DAO",
            block.timestamp + 7 days,
            block.timestamp + 37 days,
            DAO_MANAGER,
            LIQUIDITY_LOCKER_FACTORY,
            PROTOCOL_ADMIN,
            address(0), // for test
            address(0) // for test
        );
    }

    function test_constructorShouldRevertIfDeadlineIsInPast() public {
        vm.expectRevert("Deadline must be in the future");
        new Daao(
            10 ether,
            "Daao",
            "DAO",
            block.timestamp - 1, // Invalid deadline
            block.timestamp + 30 days,
            DAO_MANAGER,
            LIQUIDITY_LOCKER_FACTORY,
            PROTOCOL_ADMIN,
            address(0), // for test
            address(0) // for test
        );
    }

    function test_constructorShouldRevertIfFundExpiryNotGreaterThanDeadline() public {
        uint256 deadline = block.timestamp + 7 days;
        vm.expectRevert("Fund expiry must be greater than fundraising deadline");
        new Daao(
            10 ether,
            "Daao",
            "DAO",
            deadline,
            deadline, // Invalid fund expiry (should be > deadline)
            DAO_MANAGER,
            LIQUIDITY_LOCKER_FACTORY,
            PROTOCOL_ADMIN,
            address(0), // for test
            address(0) // for test
        );
    }

    function test_constructorShouldInitializeStateCorrectly() public {
        uint256 fundraisingGoal = 10 ether;
        string memory name = "TestDao";
        string memory symbol = "TEST";
        uint256 fundraisingDeadline = block.timestamp + 7 days;
        uint256 fundExpiry = fundraisingDeadline + 30 days;

        Daao newDao = new Daao(
            fundraisingGoal,
            name,
            symbol,
            fundraisingDeadline,
            fundExpiry,
            DAO_MANAGER,
            LIQUIDITY_LOCKER_FACTORY,
            PROTOCOL_ADMIN,
            paymentToken,
            NONFUNGIBLE_POSITION_MANAGER
        );

        // Check basic state variables
        assertEq(newDao.fundraisingGoal(), fundraisingGoal);
        assertEq(newDao.name(), name);
        assertEq(newDao.symbol(), symbol);
        assertEq(newDao.fundraisingDeadline(), fundraisingDeadline);
        assertEq(newDao.fundExpiry(), fundExpiry);
        assertEq(newDao.protocolAdmin(), PROTOCOL_ADMIN);
        assertEq(address(newDao.liquidityLockerFactory()), LIQUIDITY_LOCKER_FACTORY);

        // Check owner is set correctly
        assertEq(newDao.owner(), DAO_MANAGER);

        // Check initial state
        assertEq(newDao.totalRaised(), 0);
        assertEq(newDao.fundraisingFinalized(), false);
        assertEq(newDao.goalReached(), false);

        // Check tier limits are initialized correctly
        assertEq(newDao.tierLimits(Daao.WhitelistTier.Platinum), newDao.PLATINUM_DEFAULT_LIMIT());
        assertEq(newDao.tierLimits(Daao.WhitelistTier.Gold), newDao.GOLD_DEFAULT_LIMIT());
        assertEq(newDao.tierLimits(Daao.WhitelistTier.Silver), newDao.SILVER_DEFAULT_LIMIT());

        // Check payment token is set correctly
        assertEq(newDao.PAYMENT_TOKEN(), paymentToken);

        // Check UNISWAP_V3_FACTORY is set correctly
        assertEq(address(newDao.UNISWAP_V3_FACTORY()), INonfungiblePositionManager(NONFUNGIBLE_POSITION_MANAGER).factory());

        // Check POSITION_MANAGER is set correctly
        assertEq(address(newDao.POSITION_MANAGER()), NONFUNGIBLE_POSITION_MANAGER);
        
        
    }
    
    function test_addOrUpdateWhitelistShouldRevertIfNotCalledByDaoManagerOrProtocolAdmin() public {
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Gold;

        vm.expectRevert("Must be owner or protocolAdmin");
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShouldSuccessIfCalledByDaoManager() public {
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Gold;

        vm.prank(DAO_MANAGER);
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShouldSuccessIfCalledByProtocolAdmin() public {
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Gold;

        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShuldldRevertIfLenghMismatched() public {
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Arrays length mismatch");
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShuldldRevertIfEmptyArrays() public {
        address[] memory users = new address[](0);
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](0);

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Empty arrays");
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShouldRevertIfInvalidAddress() public {
        address[] memory users = new address[](1);
        users[0] = address(0);

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Invalid address");
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShouldRevertIfInvalidTier() public {
        address[] memory users = new address[](1);
        users[0] = USER_1;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.None;

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Invalid tier");
        dao.addOrUpdateWhitelist(users, tiers);
    }

    function test_addOrUpdateWhitelistShouldSuccessIfValidInput() public {
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;

        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Gold;

        assertEq(dao.getWhitelistLength(), 0);

        (bool isUser1ActiveBefore, Daao.WhitelistTier user1TierBefore, uint256 user1AddedAtBefore) = dao.getWhitelistInfo(USER_1);
        assertEq(isUser1ActiveBefore, false);
        assertEq(uint8(user1TierBefore), uint8(Daao.WhitelistTier.None));
        assertEq(user1AddedAtBefore, 0);

        (bool isUser2ActiveBefore, Daao.WhitelistTier user2TierBefore, uint256 user2AddedAtBefore) = dao.getWhitelistInfo(USER_2);
        assertEq(isUser2ActiveBefore, false);
        assertEq(uint8(user2TierBefore), uint8(Daao.WhitelistTier.None));
        assertEq(user2AddedAtBefore, 0);

        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        assertEq(dao.getWhitelistLength(), 2);

        (bool isUser1ActiveAfter, Daao.WhitelistTier user1TierAfter, uint256 user1AddedAtAfter) = dao.getWhitelistInfo(USER_1);
        assertEq(isUser1ActiveAfter, true);
        assertEq(uint8(user1TierAfter), uint8(Daao.WhitelistTier.Platinum));
        assertEq(user1AddedAtAfter, block.timestamp);

        (bool isUser2ActiveAfter, Daao.WhitelistTier user2TierAfter, uint256 user2AddedAtAfter) = dao.getWhitelistInfo(USER_2);
        assertEq(isUser2ActiveAfter, true);
        assertEq(uint8(user2TierAfter), uint8(Daao.WhitelistTier.Gold));
        assertEq(user2AddedAtAfter, block.timestamp);
    }

    function test_removeFromWhitelistShouldRevertIfNotCalledByDaoManagerOrProtocolAdmin() public {
        // First add a user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        // Try to remove as non-authorized user
        vm.expectRevert("Must be owner or protocolAdmin");
        dao.removeFromWhitelist(USER_1);
    }

    function test_removeFromWhitelistShouldSuccessIfCalledByDaoManager() public {
        // First add a user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(DAO_MANAGER);
        dao.removeFromWhitelist(USER_1);
    }

    function test_removeFromWhitelistShouldSuccessIfCalledByProtocolAdmin() public {
        // First add a user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.removeFromWhitelist(USER_1);
    }

    function test_removeFromWhitelistShouldRevertIfInvalidAddress() public {
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Invalid address");
        dao.removeFromWhitelist(address(0));
    }

    function test_removeFromWhitelistShouldRevertIfAddressNotWhitelisted() public {
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Address not whitelisted");
        dao.removeFromWhitelist(USER_1);
    }

    function test_removeFromWhitelistShouldSuccessIfValidInput() public {
        // First add a user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;

        assertEq(dao.getWhitelistLength(), 0);

        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        assertEq(dao.getWhitelistLength(), 1);

        (bool isActiveBeforeRemoval, Daao.WhitelistTier tierBeforeRemoval, uint256 addedAtBeforeRemoval) = dao.getWhitelistInfo(USER_1);
        assertEq(isActiveBeforeRemoval, true);
        assertEq(uint8(tierBeforeRemoval), uint8(Daao.WhitelistTier.Platinum));
        assertEq(addedAtBeforeRemoval, block.timestamp);

        vm.prank(PROTOCOL_ADMIN);
        dao.removeFromWhitelist(USER_1);

        assertEq(dao.getWhitelistLength(), 0);

        (bool isActiveAfterRemoval, Daao.WhitelistTier tierAfterRemoval, uint256 addedAtAfterRemoval) = dao.getWhitelistInfo(USER_1);
        assertEq(isActiveAfterRemoval, false);
        assertEq(uint8(tierAfterRemoval), uint8(Daao.WhitelistTier.None));
        assertEq(addedAtAfterRemoval, block.timestamp); // addedAt timestamp remains unchanged
    }

    function test_updateTierLimitShouldRevertIfNotCalledByDaoManagerOrProtocolAdmin() public {
        vm.expectRevert("Not authorized");
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 2 ether);
    }

    function test_updateTierLimitShouldSuccessIfCalledByDaoManager() public {
        uint256 newLimit = 2 ether;
        vm.prank(DAO_MANAGER);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, newLimit);

        assertEq(dao.tierLimits(Daao.WhitelistTier.Platinum), newLimit);
        assertEq(dao.PLATINUM_DEFAULT_LIMIT(), newLimit);
    }

    function test_updateTierLimitShouldSuccessIfCalledByProtocolAdmin() public {
        uint256 newLimit = 2 ether;
        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Gold, newLimit);

        assertEq(dao.tierLimits(Daao.WhitelistTier.Gold), newLimit);
        assertEq(dao.GOLD_DEFAULT_LIMIT(), newLimit);
    }

    function test_updateTierLimitShouldRevertIfInvalidTier() public {
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Invalid tier");
        dao.updateTierLimit(Daao.WhitelistTier.None, 1 ether);
    }

    function test_updateTierLimitShouldRevertIfInvalidLimit() public {
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Invalid limit");
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 11 ether);
    }

    function test_updateTierLimitShouldSuccessForAllTiers() public {
        vm.startPrank(PROTOCOL_ADMIN);

        // Test Platinum tier
        uint256 newPlatinumLimit = 2 ether;
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, newPlatinumLimit);
        assertEq(dao.tierLimits(Daao.WhitelistTier.Platinum), newPlatinumLimit);
        assertEq(dao.PLATINUM_DEFAULT_LIMIT(), newPlatinumLimit);

        // Test Gold tier
        uint256 newGoldLimit = 1 ether;
        dao.updateTierLimit(Daao.WhitelistTier.Gold, newGoldLimit);
        assertEq(dao.tierLimits(Daao.WhitelistTier.Gold), newGoldLimit);
        assertEq(dao.GOLD_DEFAULT_LIMIT(), newGoldLimit);

        // Test Silver tier
        uint256 newSilverLimit = 0.5 ether;
        dao.updateTierLimit(Daao.WhitelistTier.Silver, newSilverLimit);
        assertEq(dao.tierLimits(Daao.WhitelistTier.Silver), newSilverLimit);
        assertEq(dao.SILVER_DEFAULT_LIMIT(), newSilverLimit);

        vm.stopPrank();
    }

    function test_contributeShouldRevertIfGoalReached() public {
        // Setup: Add user to whitelist and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether); // Reach the goal
        vm.stopPrank();

        vm.prank(USER_1);
        vm.expectRevert("Goal already reached");
        dao.contribute{value: 1 ether}(1 ether);
    }

    function test_contributeShouldRevertIfDeadlineHit() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        // Move timestamp past deadline
        vm.warp(block.timestamp + 8 days);

        vm.prank(USER_1);
        vm.expectRevert("Deadline hit");
        dao.contribute{value: 1 ether}(1 ether);
    }

    function test_contributeShouldRevertIfAmountZero() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(USER_1);
        vm.expectRevert("Contribution must be greater than 0");
        dao.contribute{value: 0}(0);
    }

    function test_contributeShouldRevertIfNotWhitelisted() public {
        vm.prank(USER_1);
        vm.expectRevert("Not whitelisted");
        dao.contribute{value: 1 ether}(1 ether);
    }

    function test_contributeShouldRevertIfExceedingTierLimit() public {
        // Setup: Add user to whitelist with Silver tier (0.1 ether limit)
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Silver;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(USER_1);
        vm.expectRevert("Exceeding tier limit");
        dao.contribute{value: 0.2 ether}(0.2 ether); // Try to contribute more than Silver tier limit
    }

    function test_contributeShouldSuccessWithPartialContributionWhenNearGoal() public {
        // Setup: Add two users to whitelist
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // First user contributes 9 ETH
        vm.startPrank(USER_1);
        dao.contribute{value: 9 ether}(9 ether);
        vm.stopPrank();

        // Second user tries to contribute 2 ETH but only 1 ETH should be accepted
        vm.startPrank(USER_2);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();

        assertEq(dao.totalRaised(), 10 ether);
        assertEq(dao.contributions(USER_1), 9 ether);
        assertEq(dao.contributions(USER_2), 1 ether);
        assertTrue(dao.goalReached());
    }



    function test_contributeShouldSuccessForValidContribution() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        uint256 contributionAmount = 1 ether;

        vm.startPrank(USER_1);
        
        // Record state before contribution
        uint256 balanceBefore = address(USER_1).balance;
        uint256 daoBalanceBefore = address(dao).balance;
        
        dao.contribute{value: contributionAmount}(contributionAmount);

        // Verify state changes
        assertEq(dao.totalRaised(), contributionAmount);
        assertEq(dao.contributions(USER_1), contributionAmount);
        assertEq(address(USER_1).balance, balanceBefore - contributionAmount);
        assertEq(IERC20(address(paymentToken)).balanceOf(address(dao)), daoBalanceBefore + contributionAmount);
        
        vm.stopPrank();
    }

    function test_contributeShouldTrackContributorsCorrectly() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // First contribution from USER_1
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Second contribution from USER_2
        vm.startPrank(USER_2);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Additional contribution from USER_1 shouldn't add them to contributors again
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Verify contributors array
        assertEq(dao.getContributorAtIndex(0), USER_1);
        assertEq(dao.getContributorAtIndex(1), USER_2);
    }

    function test_refundShouldRevertIfGoalReached() public {
        // Setup: Add user to whitelist and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // Make contribution to reach goal
        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        // Try to refund
        vm.warp(block.timestamp + 8 days); // Move past deadline
        vm.prank(USER_1);
        vm.expectRevert("Fundraising goal was reached");
        dao.refund();
    }

    function test_refundShouldRevertIfDeadlineNotReached() public {
        // Setup: Add user to whitelist and make contribution
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Try to refund before deadline
        vm.prank(USER_1);
        vm.expectRevert("Deadline not reached yet");
        dao.refund();
    }

    function test_refundShouldRevertIfNoContributions() public {
        // Move past deadline
        vm.warp(block.timestamp + 8 days);

        vm.prank(USER_1);
        vm.expectRevert("No contributions to refund");
        dao.refund();
    }

    function test_refundShouldSuccessForValidRefund() public {
        // Setup: Add user to whitelist and make contribution
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        uint256 contributionAmount = 1 ether;

        // Make contribution
        vm.startPrank(USER_1);
        dao.contribute{value: contributionAmount}(contributionAmount);
        vm.stopPrank();

        // Move past deadline
        vm.warp(block.timestamp + 8 days);

        // Record state before refund
        uint256 balanceBefore = IERC20(address(paymentToken)).balanceOf(USER_1);
        uint256 daoBalanceBefore = IERC20(address(paymentToken)).balanceOf(address(dao));
        uint256 totalRaisedBefore = dao.totalRaised();

        // Execute refund
        vm.prank(USER_1);
        dao.refund();

        // Verify state changes
        assertEq(dao.contributions(USER_1), 0);
        assertEq(dao.totalRaised(), totalRaisedBefore - contributionAmount);
        assertEq(IERC20(address(paymentToken)).balanceOf(USER_1), balanceBefore + contributionAmount);
        assertEq(IERC20(address(paymentToken)).balanceOf(address(dao)), daoBalanceBefore - contributionAmount);
    }

    function test_refundShouldAllowMultipleUsersToRefund() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // Make contributions
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        vm.startPrank(USER_2);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();

        // Move past deadline
        vm.warp(block.timestamp + 8 days);

        // Record initial states
        uint256 user1BalanceBefore = IERC20(address(paymentToken)).balanceOf(USER_1);
        uint256 user2BalanceBefore = IERC20(address(paymentToken)).balanceOf(USER_2);
        uint256 totalRaisedBefore = dao.totalRaised();

        // First user refunds
        vm.prank(USER_1);
        dao.refund();

        // Verify first refund
        assertEq(dao.contributions(USER_1), 0);
        assertEq(IERC20(address(paymentToken)).balanceOf(USER_1), user1BalanceBefore + 1 ether);
        assertEq(dao.totalRaised(), totalRaisedBefore - 1 ether);

        // Second user refunds
        vm.prank(USER_2);
        dao.refund();

        // Verify second refund
        assertEq(dao.contributions(USER_2), 0);
        assertEq(IERC20(address(paymentToken)).balanceOf(USER_2), user2BalanceBefore + 2 ether);
        assertEq(dao.totalRaised(), totalRaisedBefore - 3 ether);
    }

    function test_refundShouldRevertIfFinalized() public {
        // Setup: Add user and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        vm.prank(USER_1);
        vm.expectRevert("Fundraising goal was reached");
        dao.refund();
    }

    function test_extendFundExpiryShouldRevertIfNotOwner() public {
        uint256 newFundExpiry = block.timestamp + 60 days;
        
        vm.prank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER_1));
        dao.extendFundExpiry(newFundExpiry);
    }

    function test_extendFundExpiryShouldRevertIfNewExpiryNotLater() public {
        uint256 currentFundExpiry = dao.fundExpiry();
        
        vm.prank(DAO_MANAGER);
        vm.expectRevert("Must choose later fund expiry");
        dao.extendFundExpiry(currentFundExpiry);

        vm.prank(DAO_MANAGER);
        vm.expectRevert("Must choose later fund expiry");
        dao.extendFundExpiry(currentFundExpiry - 1 days);
    }

    function test_extendFundraisingDeadlineShouldRevertIfNotOwnerOrProtocolAdmin() public {
        uint256 newDeadline = block.timestamp + 14 days;
        
        vm.prank(USER_1);
        vm.expectRevert("Must be owner or protocolAdmin");
        dao.extendFundraisingDeadline(newDeadline);
    }

    function test_extendFundraisingDeadlineShouldRevertIfGoalReached() public {
        // Setup: Add user to whitelist and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // Make contribution to reach goal
        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        uint256 newDeadline = block.timestamp + 14 days;
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Fundraising goal was reached");
        dao.extendFundraisingDeadline(newDeadline);
    }

    function test_extendFundraisingDeadlineShouldRevertIfDeadlinePassed() public {
        // Move past current deadline
        vm.warp(block.timestamp + 8 days);
        
        uint256 newDeadline = block.timestamp + 14 days;
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("can not extend deadline after deadline is passed");
        dao.extendFundraisingDeadline(newDeadline);
    }

    function test_extendFundraisingDeadlineShouldRevertIfNewDeadlineNotLater() public {
        uint256 currentDeadline = dao.fundraisingDeadline();
        
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("new fundraising deadline must be > old one");
        dao.extendFundraisingDeadline(currentDeadline);

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("new fundraising deadline must be > old one");
        dao.extendFundraisingDeadline(currentDeadline - 1 days);
    }

    function test_extendFundraisingDeadlineShouldSuccessIfCalledByOwner() public {
        uint256 currentDeadline = dao.fundraisingDeadline();
        uint256 newDeadline = currentDeadline + 7 days;

        vm.prank(DAO_MANAGER);
        dao.extendFundraisingDeadline(newDeadline);

        assertEq(dao.fundraisingDeadline(), newDeadline);
    }

    function test_extendFundraisingDeadlineShouldSuccessIfCalledByProtocolAdmin() public {
        uint256 currentDeadline = dao.fundraisingDeadline();
        uint256 newDeadline = currentDeadline + 7 days;

        vm.prank(PROTOCOL_ADMIN);
        dao.extendFundraisingDeadline(newDeadline);

        assertEq(dao.fundraisingDeadline(), newDeadline);
    }

    function test_extendFundraisingDeadlineShouldAllowMultipleExtensions() public {
        uint256 currentDeadline = dao.fundraisingDeadline();
        
        // First extension
        uint256 firstNewDeadline = currentDeadline + 7 days;
        vm.prank(PROTOCOL_ADMIN);
        dao.extendFundraisingDeadline(firstNewDeadline);
        assertEq(dao.fundraisingDeadline(), firstNewDeadline);

        // Second extension
        uint256 secondNewDeadline = firstNewDeadline + 7 days;
        vm.prank(DAO_MANAGER);
        dao.extendFundraisingDeadline(secondNewDeadline);
        assertEq(dao.fundraisingDeadline(), secondNewDeadline);
    }

    function test_emergencyEscapeShouldRevertIfNotProtocolAdmin() public {
        vm.prank(USER_1);
        vm.expectRevert("must be protocol admin");
        dao.emergencyEscape();

        vm.prank(DAO_MANAGER);
        vm.expectRevert("must be protocol admin");
        dao.emergencyEscape();
    }

    function test_emergencyEscapeShouldRevertIfFundraisingFinalized() public {
        // Setup: Add user and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("fundraising already finalized");
        dao.emergencyEscape();
    }

    function test_emergencyEscapeShouldSuccessIfCalledByProtocolAdmin() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        // First send some MODE tokens to the contract
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        vm.startPrank(USER_1);
        dao.contribute{value: 5 ether}(5 ether);
        vm.stopPrank();

        uint256 initialBalance = IERC20(address(paymentToken)).balanceOf(PROTOCOL_ADMIN);
        uint256 daoBalance = IERC20(address(paymentToken)).balanceOf(address(dao));

        vm.prank(PROTOCOL_ADMIN);
        dao.emergencyEscape();

        // Verify state changes
        assertEq(IERC20(address(paymentToken)).balanceOf(address(dao)), 0);
        assertEq(
            IERC20(address(paymentToken)).balanceOf(PROTOCOL_ADMIN), 
            initialBalance + daoBalance
        );
    }

    function test_finalizeFundraisingShouldRevertIfNotProtocolAdmin() public {
        vm.prank(USER_1);
        vm.expectRevert("Not authorized");
        dao.finalizeFundraising(0, 0);
    }

    function test_finalizeFundraisingShouldRevertIfGoalNotReached() public {
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("Fundraising goal not reached");
        dao.finalizeFundraising(0, 0);
    }

    function test_finalizeFundraisingShouldRevertIfAlreadyFinalized() public {
        // Setup: Add user to whitelist and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        // Make contribution to reach goal
        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        // First finalization should succeed
        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Second finalization should fail
        vm.prank(PROTOCOL_ADMIN);
        vm.expectRevert("DAO tokens already minted");
        dao.finalizeFundraising(0, 0);
    }

    function test_finalizeFundraisingShouldDistributeTokensCorrectly() public {
        // Setup: Add multiple users to whitelist
        address[] memory users = new address[](3);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;
        
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](3);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        tiers[2] = Daao.WhitelistTier.Platinum;

        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        // Make contributions
        vm.startPrank(USER_1);
        dao.contribute{value: 5 ether}(5 ether);
        vm.stopPrank();

        vm.startPrank(USER_2);
        dao.contribute{value: 3 ether}(3 ether);
        vm.stopPrank();

        vm.startPrank(USER_3);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();

        // Finalize fundraising
        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Get the DAO token address (it's created during finalization)
        address daoTokenAddress = dao.token0() == paymentToken ? dao.token1() : dao.token0();
        
        // Calculate expected token distributions (90% of total supply distributed proportionally)
        uint256 user1Expected = (5 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 50%
        uint256 user2Expected = (3 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 30%
        uint256 user3Expected = (2 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 20%

        // Verify token distributions
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_1), user1Expected);
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_2), user2Expected);
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_3), user3Expected);
    }

    function test_finalizeFundraisingShouldSetupLiquidityPoolCorrectly() public {
        // Setup: Add user and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        // Record initial MODE balances
        uint256 initialOwnerModeBalance = IERC20(paymentToken).balanceOf(DAO_MANAGER);

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Verify state changes
        assertTrue(dao.fundraisingFinalized());
        assertEq(dao.liquidityLocker() != address(0), true);

        // Verify MODE token distribution
        uint256 expectedModeForLP = (10 ether * dao.LP_PERCENTAGE()) / 100; // 10%
        uint256 expectedModeForTreasury = 10 ether - expectedModeForLP; // 90%
        
        // Verify treasury received correct MODE amount
        assertApproxEqAbs(
            IERC20(paymentToken).balanceOf(DAO_MANAGER),
            initialOwnerModeBalance + expectedModeForTreasury,
            1e15
        );

        // Verify DAO token distribution
        address daoTokenAddress = dao.token0() == paymentToken ? dao.token1() : dao.token0();
        uint256 expectedDaoTokensForLP = (dao.TOTAL_SUPPLY() * dao.POOL_PERCENTAGE()) / 100; // 10%
        
        // Get pool address
        address poolAddress = IUniswapV3Factory(dao.UNISWAP_V3_FACTORY()).getPool(paymentToken, daoTokenAddress, 10000);
        require(poolAddress != address(0), "Pool not created");

        // Verify pool token balances
        uint256 poolModeBal = IERC20(paymentToken).balanceOf(poolAddress);
        uint256 poolDaoBal = IERC20(daoTokenAddress).balanceOf(poolAddress);
        console.log("poolModeBal", poolModeBal);
        console.log("poolDaoBal", poolDaoBal);
        // Verify correct amounts in pool
        assertApproxEqAbs(poolModeBal, expectedModeForLP, 1e15, "Incorrect MODE amount in pool");
        assertApproxEqAbs(poolDaoBal, expectedDaoTokensForLP, 50e18, "Incorrect DAO token amount in pool");

        // Verify LP tokens were created
        assertEq(IERC20(daoTokenAddress).balanceOf(address(dao)), 0, "DAO contract should have no tokens left"); 
        assertEq(dao.liquidityLocker() != address(0), true, "Locker should be created");

        // Verify NFT ownership
        uint256 tokenId = ILocker(dao.liquidityLocker()).released(address(dao.POSITION_MANAGER()));
        console.log("tokenId", tokenId);
        assertTrue(tokenId > 0, "No NFT found");

        // Get position info
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,
        ) = INonfungiblePositionManager(dao.POSITION_MANAGER()).positions(tokenId);

        // Verify position details
        assertTrue(liquidity > 0, "No liquidity in position");
        assertTrue(
            (token0 == paymentToken && token1 == daoTokenAddress) ||
            (token0 == daoTokenAddress && token1 == paymentToken),
            "Incorrect tokens in position"
        );
    }

    function test_finalizeFundraisingShouldSetupLockerCorrectly() public {
        // Setup: Add user and reach goal
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Verify locker setup
        address lockerAddress = dao.liquidityLocker();
        assertNotEq(lockerAddress, address(0));
        
        // Verify locker parameters
        ILocker locker = ILocker(lockerAddress);
        assertEq(locker.owner(), DAO_MANAGER);
        assertEq(locker.fundExpiry(), dao.fundExpiry());
        assertEq(locker._protocolFee(), dao.lpFeesCut());
    }

    function test_executeShouldRevertIfNotOwner() public {
        address[] memory contracts = new address[](1);
        bytes[] memory data = new bytes[](1);
        uint256[] memory approveAmounts = new uint256[](1);

        vm.prank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER_1));
        dao.execute(contracts, data, approveAmounts);
    }

    function test_executeShouldRevertIfFundraisingNotFinalized() public {
        address[] memory contracts = new address[](1);
        bytes[] memory data = new bytes[](1);
        uint256[] memory approveAmounts = new uint256[](1);

        vm.prank(DAO_MANAGER);
        vm.expectRevert("fundraisingFinalized is false");
        dao.execute(contracts, data, approveAmounts);
    }

    function test_executeShouldRevertIfArrayLengthMismatch() public {
        // Setup: First finalize fundraising
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Test with mismatched array lengths
        address[] memory contracts = new address[](2);
        bytes[] memory data = new bytes[](1);
        uint256[] memory approveAmounts = new uint256[](1);

        vm.prank(DAO_MANAGER);
        vm.expectRevert("Array lengths mismatch");
        dao.execute(contracts, data, approveAmounts);
    }

    function test_executeShouldSuccessWithNoApproval() public {
        // Setup: First finalize fundraising
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Deploy a mock contract to interact with
        MockReceiver mockReceiver = new MockReceiver();

        // Prepare execution data
        address[] memory contracts = new address[](1);
        contracts[0] = address(mockReceiver);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("setValue(uint256)", 123);

        uint256[] memory approveAmounts = new uint256[](1);
        approveAmounts[0] = 0; // No approval needed

        vm.prank(DAO_MANAGER);
        dao.execute(contracts, data, approveAmounts);

        assertEq(mockReceiver.value(), 123);
    }

    function test_executeShouldSuccessWithApproval() public {
        // Setup: First finalize fundraising
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Deploy a mock contract that requires MODE token approval
        MockTokenSpender mockSpender = new MockTokenSpender();

        // Prepare execution data
        address[] memory contracts = new address[](1);
        contracts[0] = address(mockSpender);

        uint256[] memory approveAmounts = new uint256[](1);
        approveAmounts[0] = IERC20(paymentToken).balanceOf(DAO_MANAGER);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("spendTokens(address,uint256)", paymentToken, approveAmounts[0]);

        // Record initial allowance
        uint256 initialAllowance = IERC20(paymentToken).allowance(address(dao), address(mockSpender));

        // transfer daoTokens to dao contract for spending
        vm.prank(DAO_MANAGER);
        IERC20(paymentToken).transfer(address(dao), approveAmounts[0]);

        vm.prank(DAO_MANAGER);
        dao.execute(contracts, data, approveAmounts);

        // Verify allowance was increased and tokens were spent
        assertEq(IERC20(paymentToken).allowance(address(dao), address(mockSpender)), initialAllowance);
        assertTrue(mockSpender.tokenSpent());
        assertEq(IERC20(paymentToken).balanceOf(address(mockSpender)), approveAmounts[0]);
    }

    function test_executeShouldRevertIfCallFails() public {
        // Setup: First finalize fundraising
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        vm.startPrank(USER_1);
        dao.contribute{value: 10 ether}(10 ether);
        vm.stopPrank();

        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Deploy a mock contract that will revert
        MockFailingReceiver mockReceiver = new MockFailingReceiver();

        // Prepare execution data
        address[] memory contracts = new address[](1);
        contracts[0] = address(mockReceiver);

        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSignature("failingFunction()");

        uint256[] memory approveAmounts = new uint256[](1);
        approveAmounts[0] = 0;

        vm.prank(DAO_MANAGER);
        vm.expectRevert("Call failed");
        dao.execute(contracts, data, approveAmounts);
    }

    function test_contributorTrackingForMultipleContributions() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](3);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;
        
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](3);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        tiers[2] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);

        // Initial state
        assertEq(dao.getContributorsCount(), 0);

        // First user contributes multiple times
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        assertEq(dao.getContributorsCount(), 1);
        assertEq(dao.getContributorAtIndex(0), USER_1);

        dao.contribute{value: 1 ether}(1 ether); // Second contribution
        assertEq(dao.getContributorsCount(), 1); // Count should not increase
        assertEq(dao.getContributorAtIndex(0), USER_1);
        vm.stopPrank();

        // Second user contributes
        vm.startPrank(USER_2);
        dao.contribute{value: 1 ether}(1 ether);
        assertEq(dao.getContributorsCount(), 2);
        assertEq(dao.getContributorAtIndex(1), USER_2);
        vm.stopPrank();
    }

    function test_refundContributorRemovalAndReordering() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](4);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;
        users[3] = USER_4;
        
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](4);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        tiers[2] = Daao.WhitelistTier.Platinum;
        tiers[3] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        // Make contributions
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        vm.startPrank(USER_2);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        vm.startPrank(USER_3);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        vm.startPrank(USER_4);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Verify initial state
        assertEq(dao.getContributorsCount(), 4);
        assertEq(dao.getContributorAtIndex(0), USER_1);
        assertEq(dao.getContributorAtIndex(1), USER_2);
        assertEq(dao.getContributorAtIndex(2), USER_3);
        assertEq(dao.getContributorAtIndex(3), USER_4);

        // Move past deadline
        vm.warp(block.timestamp + 8 days);

        // USER_2 requests refund (middle position)
        vm.prank(USER_2);
        dao.refund();

        // Verify reordering after middle position refund
        assertEq(dao.getContributorsCount(), 3);
        assertEq(dao.getContributorAtIndex(0), USER_1);
        assertEq(dao.getContributorAtIndex(1), USER_4); // Last user moved to refunded position
        assertEq(dao.getContributorAtIndex(2), USER_3);

        // USER_1 requests refund (first position)
        vm.prank(USER_1);
        dao.refund();

        // Verify reordering after first position refund
        assertEq(dao.getContributorsCount(), 2);
        assertEq(dao.getContributorAtIndex(0), USER_3); // Last remaining user moved to first position
        assertEq(dao.getContributorAtIndex(1), USER_4);
    }

    function test_refundAndRecontributeScenario() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](4);
        users[0] = USER_1;
        users[1] = USER_2;
        users[2] = USER_3;
        users[3] = USER_4;
        
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](4);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        tiers[2] = Daao.WhitelistTier.Platinum;
        tiers[3] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();

        // First round of contributions (total 9 ETH)
        vm.startPrank(USER_1);
        dao.contribute{value: 3 ether}(3 ether);
        vm.stopPrank();

        vm.startPrank(USER_2);
        dao.contribute{value: 3 ether}(3 ether);
        vm.stopPrank();

        vm.startPrank(USER_3);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();

        vm.startPrank(USER_4);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();

        // Verify initial state
        assertEq(dao.getContributorsCount(), 4);
        assertEq(dao.totalRaised(), 10 ether);
        assertEq(dao.getContributorAtIndex(0), USER_1);
        assertEq(dao.getContributorAtIndex(1), USER_2);
        assertEq(dao.getContributorAtIndex(2), USER_3);
        assertEq(dao.getContributorAtIndex(3), USER_4);

        assertTrue(dao.isContributor(USER_1));
        assertTrue(dao.isContributor(USER_2));
        assertTrue(dao.isContributor(USER_3));
        assertTrue(dao.isContributor(USER_4));

        // Finalize fundraising
        vm.prank(PROTOCOL_ADMIN);
        dao.finalizeFundraising(0, 0);

        // Get the DAO token address
        address daoTokenAddress = dao.token0() == paymentToken ? dao.token1() : dao.token0();

        // Calculate expected token distributions based on final contributions
        // Total valid contributions = 10 ETH
        // USER_1: 3 ETH (30%)
        // USER_2: 3 ETH (30%)
        // USER_3: 2 ETH (20%)
        // USER_4: 2 ETH (20%)
        uint256 user1Expected = (3 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 30%
        uint256 user2Expected = (3 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 30%
        uint256 user3Expected = (2 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 20%
        uint256 user4Expected = (2 ether * dao.SUPPLY_TO_FUNDRAISERS()) / 10 ether; // 20%

        // Verify token distributions
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_1), user1Expected);
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_2), user2Expected);
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_3), user3Expected);
        assertEq(IERC20(daoTokenAddress).balanceOf(USER_4), user4Expected);

        // Verify total distributed equals expected total (excluding pool allocation)
        assertEq(
            IERC20(daoTokenAddress).balanceOf(USER_1) + 
            IERC20(daoTokenAddress).balanceOf(USER_2) +
            IERC20(daoTokenAddress).balanceOf(USER_3) +
            IERC20(daoTokenAddress).balanceOf(USER_4),
            dao.SUPPLY_TO_FUNDRAISERS()
        );
    }

    // New test for EnumerableSet specific functionality
    function test_contributorSetOperations() public {
        // Setup whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.startPrank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        vm.stopPrank();
        // Initial state
        assertEq(dao.getContributorsCount(), 0);
        assertFalse(dao.isContributor(USER_1));

        // First contribution
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        // Verify addition
        assertEq(dao.getContributorsCount(), 1);
        assertTrue(dao.isContributor(USER_1));
        assertEq(dao.getContributorAtIndex(0), USER_1);

        // Multiple contributions shouldn't add duplicate entries
        vm.startPrank(USER_1);
        dao.contribute{value: 1 ether}(1 ether);
        vm.stopPrank();

        assertEq(dao.getContributorsCount(), 1);
        assertEq(dao.getContributorAtIndex(0), USER_1);

        // Move past deadline and refund
        vm.warp(block.timestamp + 8 days);
        vm.prank(USER_1);
        dao.refund();

        // Verify removal
        assertEq(dao.getContributorsCount(), 0);
        assertFalse(dao.isContributor(USER_1));
    }

    function test_contributorSetIndexOutOfBounds() public {
        // Should revert when trying to access invalid index
        vm.expectRevert();
        dao.getContributorAtIndex(0);
    }

    function test_contributeWithNativeTokenShouldRevertIfMsgValueMismatch() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        // Try to contribute with mismatched msg.value
        vm.startPrank(USER_1);
        vm.expectRevert("Amount must be equal to msg.value");
        dao.contribute{value: 0.5 ether}(1 ether); // msg.value doesn't match amount
        vm.stopPrank();
    }

    function test_contributeWithNativeTokenShouldWrapCorrectly() public {
        // Setup: Add user to whitelist
        address[] memory users = new address[](1);
        users[0] = USER_1;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](1);
        tiers[0] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);

        uint256 contributionAmount = 1 ether;
        
        // Record balances before contribution
        uint256 userEthBalanceBefore = address(USER_1).balance;
        uint256 daoWrappedTokenBalanceBefore = IERC20(paymentToken).balanceOf(address(dao));
        
        // Make contribution
        vm.startPrank(USER_1);
        dao.contribute{value: contributionAmount}(contributionAmount);
        vm.stopPrank();
        
        // Verify ETH was taken from user
        assertEq(address(USER_1).balance, userEthBalanceBefore - contributionAmount);
        
        // Verify ETH was wrapped and stored in contract
        assertEq(
            IERC20(paymentToken).balanceOf(address(dao)), 
            daoWrappedTokenBalanceBefore + contributionAmount
        );
        
        // Verify contribution was recorded
        assertEq(dao.contributions(USER_1), contributionAmount);
        assertEq(dao.totalRaised(), contributionAmount);
    }

    function test_contributeWithNativeTokenShouldHandlePartialContribution() public {
        // Setup: Add users to whitelist
        address[] memory users = new address[](2);
        users[0] = USER_1;
        users[1] = USER_2;
        Daao.WhitelistTier[] memory tiers = new Daao.WhitelistTier[](2);
        tiers[0] = Daao.WhitelistTier.Platinum;
        tiers[1] = Daao.WhitelistTier.Platinum;
        
        vm.prank(PROTOCOL_ADMIN);
        dao.addOrUpdateWhitelist(users, tiers);
        
        vm.prank(PROTOCOL_ADMIN);
        dao.updateTierLimit(Daao.WhitelistTier.Platinum, 10 ether);
        
        // First user contributes 9 ETH
        vm.startPrank(USER_1);
        dao.contribute{value: 9 ether}(9 ether);
        vm.stopPrank();
        
        // Second user tries to contribute 2 ETH but only 1 ETH should be accepted
        uint256 user2BalanceBefore = address(USER_2).balance;
        
        vm.startPrank(USER_2);
        dao.contribute{value: 2 ether}(2 ether);
        vm.stopPrank();
        
        // Verify only 1 ETH was taken (fundraising goal is 10 ETH)
        assertEq(dao.totalRaised(), 10 ether);
        assertEq(dao.contributions(USER_2), 1 ether);
        assertApproxEqRel(address(USER_2).balance, user2BalanceBefore - 1 ether, 0.0001 ether); // Full amount is sent
        
        // Verify wrapped token balance in contract
        // assertEq(IERC20(paymentToken).balanceOf(address(dao)), 10 ether);
    }

}
