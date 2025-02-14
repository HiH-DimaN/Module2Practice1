// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/MyToken.sol"; // Импорт контракта ERC20-токена
import "src/Vault.sol"; // Импорт контракта хранилища

/**
 * @title TokenSale - Контракт продажи myToken с белым списком и комиссией
 */
contract TokenSale is Ownable {
    using SafeERC20 for IERC20;

    MyToken public myToken; // Контракт токена
    Vault public vault; // Контракт хранилища
    mapping(address => bool) public whiteList; // Белый список одобренных токенов
    uint256 public constant FEE_PERCENT = 10; // Комиссия 10%
    uint256 public constant ETH_RATE = 2; // 1 myToken = 2 ETH

    /**
     * @dev Конструктор, устанавливающий контракт myToken и Vault
     * @param _myToken Адрес контракта myToken
     * @param _vault Адрес контракта Vault
     */
    constructor(address _myToken, address _vault) Ownable(msg.sender) {
        myToken = MyToken(_myToken); // Сохраняем адрес контракта токена
        vault = Vault(_vault); // Сохраняем адрес контракта хранилища
    }

    /**
     * @dev Добавляет токен в белый список
     * @param token Адрес токена
     */
    function addToWhitelist(address token) external onlyOwner {
        whiteList[token] = true; // Добавляем токен в белый список
    }

    /**
     * @dev Покупка myToken за whitelisted токены
     * @param amount Количество myToken
     * @param paymentToken Токен оплаты
     */
    function buyWithToken(uint256 amount, IERC20 paymentToken) external {
        require(whiteList[address(paymentToken)], "Token not whitelisted"); // Проверяем whitelisted

        uint256 fee = (amount * FEE_PERCENT * 100) / 10000; // Вычисляем комиссию
        uint256 totalCost = amount + fee; // Общая сумма покупки

        paymentToken.safeTransferFrom(msg.sender, address(this), totalCost); // Получаем оплату
        paymentToken.safeTransfer(address(vault), fee); // Отправляем комиссию в Vault

        // Минтим myToken для пользователя через роль MINTER_ROLE
        myToken.mint(msg.sender, amount); // Минтим myToken пользователю
        
    }

    /**
     * @dev Покупка myToken за ETH
     */
    function buyWithETH() external payable {
        uint256 amount = (msg.value / ETH_RATE); // Рассчитываем myToken
        uint256 fee = (amount * FEE_PERCENT * 100) / 10000; // Вычисляем комиссию

        // Отправляем комиссию прямо в Vault
        payable(address(vault)).transfer(fee); // Переводим эфир в Vault
        myToken.mint(msg.sender, amount); // Минтим myToken
    }

    /**
     * @dev Функция для приема эфира в контракт
     */
    receive() external payable {
        // Можно добавить логирование или другие действия по мере необходимости
    }
}
