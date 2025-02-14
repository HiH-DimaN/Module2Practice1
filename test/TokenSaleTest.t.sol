// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/TokenSale.sol"; // Контракт TokenSale
import "src/MyToken.sol";   // Контракт MyToken (ERC20)
import "src/Vault.sol";     // Контракт Vault

contract TokenSaleTest is Test {
    TokenSale public tokenSale;  // Экземпляр контракта TokenSale
    MyToken public myToken;      // Экземпляр контракта MyToken
    Vault public vault;          // Экземпляр контракта Vault
    ERC20 public mockToken;      // Мок-токен для тестирования

    address public user = address(0x123); // Адрес пользователя
    address public owner = address(0x456); // Адрес владельца

    uint256 public initialSupply = 10000 * 10 ** 18; // Начальный баланс токенов

    function setUp() public {
        // Разворачиваем контракты перед каждым тестом
        vault = new Vault(); // Создаем новый контракт Vault
        myToken = new MyToken("MyToken", "MTK"); // Создаем новый контракт MyToken
        mockToken = new MockToken(); // Создаем мок-токен

        tokenSale = new TokenSale(address(myToken), address payable(vault)); // Создаем контракт TokenSale

        // Раздаем токены пользователю и владельцу
        vm.deal(owner, 10 ether); // Даем владельцу эфир
        mockToken._mint(owner, initialSupply); // Минтим токены для владельца
        mockToken._mint(user, initialSupply); // Минтим токены для пользователя

        // Устанавливаем белый список для токенов
        tokenSale.addToWhitelist(address(mockToken)); // Добавляем mockToken в белый список
    }

    // Тестируем покупку через токены
    function testBuyWithToken() public {
        uint256 amount = 100 * 10 ** 18; // Количество myToken для покупки
        uint256 fee = (amount * tokenSale.FEE_PERCENT()) / 100; // Комиссия
        uint256 totalCost = amount + fee; // Общая стоимость

        // Делаем approve для mockToken перед покупкой
        mockToken.approve(address(tokenSale), totalCost);

        // Проверяем начальные балансы
        uint256 initialBalanceUser = myToken.balanceOf(user); // Баланс пользователя до покупки
        uint256 initialBalanceVault = mockToken.balanceOf(address(vault)); // Баланс Vault до покупки

        // Выполняем покупку
        tokenSale.buyWithToken(amount, mockToken);

        // Проверяем, что баланс токенов увеличился на покупаемое количество
        assertEq(myToken.balanceOf(user), initialBalanceUser + amount); // Баланс myToken у пользователя должен увеличиться

        // Проверяем, что комиссия ушла в Vault
        assertEq(mockToken.balanceOf(address(vault)), initialBalanceVault + fee); // Баланс Vault должен увеличиться на комиссию
    }

    // Тестируем покупку через ETH
    function testBuyWithETH() public {
        uint256 amount = 2 ether / tokenSale.ETH_RATE(); // Количество myToken для покупки
        uint256 fee = (amount * tokenSale.FEE_PERCENT()) / 100; // Комиссия

        // Проверяем начальные балансы
        uint256 initialBalanceUser = myToken.balanceOf(user); // Баланс пользователя до покупки
        uint256 initialBalanceVault = address(vault).balance; // Баланс Vault до покупки

        // Отправляем эфир на контракт TokenSale
        vm.prank(user); // Имитация вызова от пользователя
        tokenSale.buyWithETH{value: 2 ether}(); // Выполняем покупку

        // Проверяем, что баланс myToken у пользователя увеличился
        assertEq(myToken.balanceOf(user), initialBalanceUser + amount); // Баланс myToken у пользователя должен увеличиться

        // Проверяем, что комиссия ушла в Vault
        assertEq(address(vault).balance, initialBalanceVault + fee); // Баланс Vault должен увеличиться на комиссию
    }

    // Тестируем добавление токена в белый список
    function testAddToWhitelist() public {
        address newToken = address(0x789); // Новый токен для добавления в белый список

        // Проверяем, что токен не в белом списке
        assertFalse(tokenSale.whiteList(newToken)); // Новый токен не должен быть в белом списке

        // Добавляем токен в белый список
        tokenSale.addToWhitelist(newToken);

        // Проверяем, что токен добавлен в белый список
        assertTrue(tokenSale.whiteList(newToken)); // Новый токен должен быть в белом списке
    }

    // Тестируем, что покупка невозможна для токенов, не добавленных в белый список
    function testFailBuyWithNonWhitelistedToken() public {
        address nonWhitelistedToken = address(0x789); // Токен, не добавленный в белый список

        // Проверяем, что покупка не возможна для токенов, не добавленных в белый список
        vm.expectRevert("Token not whitelisted"); // Ожидаем ошибку
        tokenSale.buyWithToken(100 * 10 ** 18, IERC20(nonWhitelistedToken)); // Попытка покупки с не белого токена
    }

    // Тестируем, что покупка невозможна, если пользователь не имеет достаточно токенов
    function testFailInsufficientTokens() public {
        uint256 amount = 100 * 10 ** 18; // Количество myToken для покупки
        uint256 fee = (amount * tokenSale.FEE_PERCENT()) / 100; // Комиссия
        uint256 totalCost = amount + fee; // Общая стоимость

        // Делаем approve для mockToken перед покупкой
        mockToken.approve(address(tokenSale), totalCost);

        // Переводим меньше токенов пользователю
        mockToken._mint(user, totalCost - 1);

        // Ожидаем, что транзакция не пройдет из-за недостаточно токенов
        vm.expectRevert("ERC20: transfer amount exceeds balance"); // Ожидаем ошибку
        tokenSale.buyWithToken(amount, mockToken);
    }

    // Тестируем, что если пользователи отправляют слишком мало эфира, покупка не пройдет
    function testFailNotEnoughETH() public {
        uint256 amount = 100 * 10 ** 18; // Количество myToken для покупки
        uint256 fee = (amount * tokenSale.FEE_PERCENT()) / 100; // Комиссия

        // Проверяем, что покупка не пройдет, если эфира недостаточно
        vm.expectRevert("not enough ETH sent"); // Ожидаем ошибку
        tokenSale.buyWithETH{value: 1 ether}(); // Попытка отправить недостаточно эфира
    }

    // Тестируем покупку с использованием не поддерживаемого токена
    function testFailBuyWithUnsupportedToken() public {
        address unsupportedToken = address(0x789); // Токен, не добавленный в белый список

        // Проверяем, что покупка не возможна с неподдерживаемым токеном
        vm.expectRevert("Token not whitelisted"); // Ожидаем ошибку
        tokenSale.buyWithToken(100 * 10 ** 18, IERC20(unsupportedToken)); // Попытка покупки с неподдерживаемым токеном
    }
}
