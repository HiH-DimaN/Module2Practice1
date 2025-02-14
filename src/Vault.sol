// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title Vault - Хранилище комиссий и депозитов
 */
contract Vault is ReentrancyGuard, Ownable, ERC721 {
    using SafeERC20 for IERC20;

    uint256 public nextTokenId; // ID следующего NFT
    mapping(uint256 => uint256) public deposits; // Хранение суммы депозита по NFT
    mapping(uint256 => bool) public isETHDeposit; // Флаг, является ли депозит ETH
    address public tokenSale; // Контракт продажи токенов

    event TokenSaleUpdated(address indexed newTokenSale); // Событие обновления TokenSale
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 tokenId); // Депозит (ERC20)
    event DepositETH(address indexed user, uint256 amount, uint256 tokenId); // Депозит ETH
    event Withdraw(address indexed user, address indexed token, uint256 amount, uint256 bonus, uint256 tokenId); // Вывод (ERC20)
    event WithdrawETH(address indexed user, uint256 amount, uint256 bonus, uint256 tokenId); // Вывод ETH

    /**
     * @dev Конструктор, устанавливающий название и символ NFT
     */
    constructor() ERC721("VaultNFT", "VNFT") Ownable(msg.sender) {}

    /**
     * @dev Функция установки контракта продажи
     * @param _tokenSale Адрес контракта TokenSale
     */
    function setTokenSale(address _tokenSale) external onlyOwner {
        require(_tokenSale != address(0), "Invalid address"); // Проверяем, что адрес не нулевой
        tokenSale = _tokenSale; // Устанавливаем контракт TokenSale
        emit TokenSaleUpdated(_tokenSale); // Вызываем событие обновления TokenSale
    }

    /**
     * @dev Функция депозита в Vault (ERC20)
     * @param token Адрес токена
     * @param amount Сумма депозита
     */
    function deposit(IERC20 token, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0"); // Проверяем сумму
        token.safeTransferFrom(msg.sender, address(this), amount); // Получаем токены от пользователя

        _mint(msg.sender, nextTokenId); // Минтим NFT пользователю
        deposits[nextTokenId] = amount; // Записываем сумму депозита

        isETHDeposit[nextTokenId] = false; // Депозит не в ETH
        emit Deposit(msg.sender, address(token), amount, nextTokenId); // Логируем событие
        nextTokenId++; // Увеличиваем ID следующего NFT
    }

    /**
     * @dev Функция депозита в Vault (ETH)
     */
    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH"); // Проверяем, что отправлена ненулевая сумма

        (bool success, ) = address(this).call{value: 0}(""); // Безопасный вызов call()
        require(success, "Call failed"); // Проверяем успешность вызова

        _mint(msg.sender, nextTokenId); // Минтим NFT пользователю
        deposits[nextTokenId] = msg.value; // Записываем сумму депозита
        emit DepositETH(msg.sender, msg.value, nextTokenId); // Логируем событие
        nextTokenId++; // Увеличиваем ID следующего NFT
    }

    /**
     * @dev Функция вывода депозита с NFT (ERC20)
     * @param token Адрес токена
     * @param tokenId ID NFT
     */
    function withdraw(IERC20 token, uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner"); // Проверяем владельца NFT
        require(!isETHDeposit[tokenId], "Use withdrawETH for ETH deposits"); // Проверяем, что это не ETH-депозит

        uint256 amount = deposits[tokenId]; // Получаем сумму депозита
        uint256 bonus = (amount * 2) / 100; // Вычисляем бонус 2%

        delete deposits[tokenId]; // Удаляем данные о депозите
        _burn(tokenId); // Сжигаем NFT
        token.safeTransfer(msg.sender, amount + bonus); // Отправляем депозит и бонус

        emit Withdraw(msg.sender, address(token), amount, bonus, tokenId); // Логируем событие
    }

     /**
     * @dev Функция вывода депозита с NFT (ETH)
     * @param tokenId ID NFT
     */
    function withdrawETH(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner"); // Проверяем владельца NFT
        require(isETHDeposit[tokenId], "Use withdraw for ERC20 deposits"); // Проверяем, что это ETH-депозит

        uint256 amount = deposits[tokenId]; // Получаем сумму депозита
        uint256 bonus = (amount * 2) / 100; // Вычисляем бонус 2%

        delete deposits[tokenId]; // Удаляем данные о депозите
        _burn(tokenId); // Сжигаем NFT

        (bool success, ) = msg.sender.call{value: amount + bonus}(""); // Отправляем ETH пользователю
        require(success, "ETH transfer failed"); // Проверяем успешность перевода

         emit WithdrawETH(msg.sender, amount, bonus, tokenId); // Логируем событие
    }

    /**
     * @dev Функция для получения ETH контрактом
     */
    receive() external payable {}
}
