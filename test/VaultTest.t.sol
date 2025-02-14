// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/Vault.sol"; // Контракт Vault

contract VaultTest is Test {
    Vault public vault;            // Экземпляр контракта Vault
    ERC20 public allowedToken;     // Экземпляр разрешенного токена
    address public user = address(0x123); // Адрес пользователя
    address public owner = address(0x456); // Адрес владельца

    uint256 public initialSupply = 10000 * 10 ** 18; // Начальный баланс токенов

    function setUp() public {
        // Разворачиваем контракты перед каждым тестом
        vault = new Vault(); // Создаем новый контракт Vault
        allowedToken = new ERC20("Allowed Token", "ALDT"); // Создаем разрешенный токен

        // Минтим токены для владельца и пользователя
        allowedToken._mint(owner, initialSupply);
        allowedToken._mint(user, initialSupply);

        // Устанавливаем разрешенные токены
        vault.setAllowedToken(address(allowedToken), true);

        // Устанавливаем владельца контракта
        vm.startPrank(owner);
    }

    // Тестируем депозиты с ERC20 токенами
    function testDepositERC20() public {
        uint256 amount = 100 * 10 ** 18; // Количество токенов для депозита

        // Проверяем начальные балансы
        uint256 initialBalanceUser = allowedToken.balanceOf(user);
        uint256 initialBalanceVault = allowedToken.balanceOf(address(vault));

        // Разрешаем контракту Vault использовать наши токены
        allowedToken.approve(address(vault), amount);

        // Делаем депозит
        vault.deposit(allowedToken, amount);

        // Проверяем, что баланс пользователя уменьшился
        assertEq(allowedToken.balanceOf(user), initialBalanceUser - amount);

        // Проверяем, что баланс Vault увеличился
        assertEq(allowedToken.balanceOf(address(vault)), initialBalanceVault + amount);

        // Проверяем, что был сгенерирован NFT
        assertEq(vault.nextTokenId(), 1); // Следующий токен должен быть 1
    }

    // Тестируем депозиты с ETH
    function testDepositETH() public payable {
        uint256 amount = 1 ether; // Сумма депозита в ETH

        // Проверяем начальный баланс
        uint256 initialBalanceUser = user.balance;
        uint256 initialBalanceVault = address(vault).balance;

        // Делаем депозит
        vm.deal(user, amount); // Добавляем ETH пользователю
        vm.prank(user); // Прокси для пользователя
        vault.depositETH{value: amount}();

        // Проверяем, что баланс пользователя уменьшился
        assertEq(user.balance, initialBalanceUser - amount);

        // Проверяем, что баланс Vault увеличился
        assertEq(address(vault).balance, initialBalanceVault + amount);

        // Проверяем, что был сгенерирован NFT
        assertEq(vault.nextTokenId(), 1); // Следующий токен должен быть 1
    }

    // Тестируем вывод средств с бонусом
    function testWithdrawFunds() public {
        uint256 depositAmount = 100 * 10 ** 18; // Количество для депозита
        allowedToken.approve(address(vault), depositAmount);
        vault.deposit(allowedToken, depositAmount);

        uint256 tokenId = 0; // Используем первый токен (NFT)

        // Проверяем начальный баланс пользователя
        uint256 initialBalanceUser = allowedToken.balanceOf(user);
        uint256 initialBalanceVault = allowedToken.balanceOf(address(vault));

        // Выполняем вывод средств
        vault.withdrawFunds(tokenId);

        // Проверяем, что баланс Vault уменьшился на депозит
        assertEq(allowedToken.balanceOf(address(vault)), initialBalanceVault - depositAmount);

        // Проверяем, что баланс пользователя увеличился на депозит + бонус
        uint256 bonus = (depositAmount * 200) / 10000; // 2% бонус
        assertEq(allowedToken.balanceOf(user), initialBalanceUser + depositAmount + bonus);
    }

    // Тестируем, что вывод средств невозможен для чужого NFT
    function testFailWithdrawFundsNotOwner() public {
        uint256 depositAmount = 100 * 10 ** 18; // Количество для депозита
        allowedToken.approve(address(vault), depositAmount);
        vault.deposit(allowedToken, depositAmount);

        uint256 tokenId = 0; // Используем первый токен (NFT)

        // Прокси для другого пользователя
        vm.prank(address(0x789));

        // Ожидаем, что транзакция не пройдет, потому что вызывающий не владелец
        vm.expectRevert("Not NFT owner");
        vault.withdrawFunds(tokenId);
    }

    // Тестируем обновление TokenSale
    function testSetTokenSale() public {
        address newTokenSale = address(0x789); // Новый адрес TokenSale

        // Проверяем, что текущий адрес TokenSale равен нулю
        assertEq(vault.tokenSale(), address(0));

        // Устанавливаем новый адрес TokenSale
        vault.setTokenSale(newTokenSale);

        // Проверяем, что новый адрес был установлен
        assertEq(vault.tokenSale(), newTokenSale);
    }

    // Тестируем, что установка токенов не в белом списке вызывает ошибку
    function testFailDepositTokenNotAllowed() public {
        ERC20 notAllowedToken = new ERC20("Not Allowed Token", "NAT"); // Токен, не в белом списке

        // Минтим токены
        notAllowedToken._mint(user, 100 * 10 ** 18);

        // Проверяем, что депозит не возможен для не разрешенного токена
        vm.expectRevert("Token not allowed");
        vault.deposit(notAllowedToken, 100 * 10 ** 18);
    }

    // Тестируем, что депозит с нулевой суммой вызывает ошибку
    function testFailDepositZeroAmount() public {
        // Проверяем, что депозит с нулевой суммой вызывает ошибку
        vm.expectRevert("Amount must be greater than 0");
        vault.deposit(allowedToken, 0);
    }
}
