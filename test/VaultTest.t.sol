// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/MyToken.sol";
import "src/TokenSale.sol";
import "src/Vault.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @title VaultTest
 * @dev Тесты для контракта хранилища Vault
 */
contract VaultTest is Test {
    MyToken token; // Экземпляр токена
    Vault vault; // Экземпляр контракта хранилища
    address user = address(0x1); // Тестовый пользователь
    address usdt = address(0x2); // Адрес токена USDT
    
    /**
     * @dev Устанавливает начальное состояние перед каждым тестом
     */
    function setUp() public {
        vault = new Vault(); // Создание нового хранилища
    }
    
    /**
     * @dev Тестирует депозит и вывод средств из хранилища
     */
    function testDepositWithdraw() public {
        deal(usdt, user, 100 * 10 ** 18); // Выдача тестовому пользователю 100 USDT
        vm.startPrank(user); // Переключение контекста на пользователя
        IERC20(usdt).approve(address(vault), 100 * 10 ** 18); // Разрешение на депозит USDT
        uint256 tokenId = vault.deposit(usdt, 100 * 10 ** 18); // Депозит 100 USDT, получение NFT-чека
        vault.withdraw(tokenId); // Вывод депозита и начисленных процентов
        vm.stopPrank(); // Завершение имитации вызова от имени пользователя
        assertEq(IERC20(usdt).balanceOf(user), 102 * 10 ** 18); // Проверка увеличенного баланса пользователя
    }
}