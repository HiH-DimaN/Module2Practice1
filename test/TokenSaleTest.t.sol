// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/MyToken.sol";
import "src/TokenSale.sol";
import "src/Vault.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title TokenSaleTest
 * @dev Тесты для контракта продажи токенов TokenSale
 */
contract TokenSaleTest is Test {
    MyToken token; // Экземпляр токена
    TokenSale sale; // Экземпляр контракта продажи токенов
    Vault vault; // Экземпляр хранилища
    address user = address(0x1); // Тестовый пользователь
    address usdt = address(0x2); // Адрес токена USDT
    
    /**
     * @dev Устанавливает начальное состояние перед каждым тестом
     */
    function setUp() public {
        token = new MyToken("MyToken", "MTK"); // Создание нового токена
        vault = new Vault(); // Создание нового хранилища
        sale = new TokenSale(address(token), address(vault)); // Создание контракта продажи
        token.transfer(address(sale), 1000000 * 10 ** 18); // Перевод токенов на контракт продажи
        sale.setWhitelist(usdt, true); // Добавление USDT в whitelist
    }
    
    /**
     * @dev Тестирует покупку токенов за whitelisted токен
     */
    function testBuyWithToken() public {
        deal(usdt, user, 110 * 10 ** 18); // Выдача тестовому пользователю 110 USDT
        vm.startPrank(user); // Переключение контекста на пользователя
        IERC20(usdt).approve(address(sale), 110 * 10 ** 18); // Разрешение на трату USDT
        sale.buyWithToken(usdt, 100 * 10 ** 18); // Покупка 100 myToken
        vm.stopPrank(); // Завершение имитации вызова от имени пользователя
        assertEq(token.balanceOf(user), 100 * 10 ** 18); // Проверка баланса пользователя
    }
}
