// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
    address public tokenSale; // Контракт продажи токенов

    /**
     * @dev Конструктор, устанавливающий название и символ NFT
     */
    constructor() ERC721("VaultNFT", "VNFT") Ownable(msg.sender) {}

    /**
     * @dev Функция установки контракта продажи
     * @param _tokenSale Адрес контракта TokenSale
     */
    function setTokenSale(address _tokenSale) external onlyOwner {
        tokenSale = _tokenSale; // Устанавливаем контракт TokenSale
    }

    /**
     * @dev Функция депозита в Vault
     * @param token Адрес токена
     * @param amount Сумма депозита
     */
    function deposit(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount); // Получаем токены от пользователя
        _mint(msg.sender, nextTokenId); // Минтим NFT пользователю
        deposits[nextTokenId] = amount; // Записываем сумму депозита
        nextTokenId++; // Увеличиваем ID следующего NFT
    }

    /**
     * @dev Функция вывода депозита с NFT
     * @param token Адрес токена
     * @param tokenId ID NFT
     */
    function withdraw(IERC20 token, uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner"); // Проверяем владельца NFT
        uint256 amount = deposits[tokenId]; // Получаем сумму депозита
        uint256 bonus = (amount * 2) / 100; // Вычисляем бонус 2%

        delete deposits[tokenId]; // Удаляем данные о депозите
        _burn(tokenId); // Сжигаем NFT
        token.safeTransfer(msg.sender, amount + bonus); // Отправляем депозит и бонус
    }
}
