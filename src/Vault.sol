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
    mapping(address => bool) public allowedTokens; // Разрешенные токены
     mapping(uint256 => address) public depositToken; // Хранение токена депозита по NFT
    address public tokenSale; // Контракт продажи токенов

    event TokenSaleUpdated(address indexed newTokenSale); // Событие обновления TokenSale
    event TokenAllowed(address indexed token, bool allowed); // Событие изменения статуса разрешенного токена
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 tokenId); // Депозит (ERC20)
    event DepositETH(address indexed user, uint256 amount, uint256 tokenId); // Депозит ETH
    event Withdraw(address indexed user, uint256 amount, uint256 bonus, uint256 tokenId); // Вывод 

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
     * @dev Добавляет или удаляет токен из списка разрешенных
     * @param token Адрес токена
     * @param allowed Статус разрешения (true/false)
     */
    function setAllowedToken(address token, bool allowed) external onlyOwner {
        require(token != address(0), "Invalid token address"); // Проверяем, что адрес не нулевой
        allowedTokens[token] = allowed; // Обновляем статус токена в маппинге
        emit TokenAllowed(token, allowed); // Вызываем событие
    }

    /**
     * @dev Функция депозита в Vault (ERC20)
     * @param token Адрес токена
     * @param amount Сумма депозита
     */
    function deposit(IERC20 token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0"); // Проверяем сумму
        require(allowedTokens[address(token)], "Token not allowed"); // Проверяем, что токен разрешен
        token.safeTransferFrom(msg.sender, address(this), amount); // Получаем токены от пользователя

        _safeMint(msg.sender, nextTokenId); // Минтим NFT пользователю с проверкой на возможность приема токенов
        deposits[nextTokenId] = amount; // Записываем сумму депозита
        isETHDeposit[nextTokenId] = false; // Депозит не в ETH
        depositToken[nextTokenId] = address(token); // Записываем адрес токена


        emit Deposit(msg.sender, address(token), amount, nextTokenId); // Логируем событие
        nextTokenId++; // Увеличиваем ID следующего NFT
    }

    /**
     * @dev Функция депозита в Vault (ETH)
     */
    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Must send ETH"); // Проверяем, что отправлена ненулевая сумма

        _safeMint(msg.sender, nextTokenId); // Минтим NFT пользователю с проверкой на возможность приема токенов
        deposits[nextTokenId] = msg.value; // Записываем сумму депозита
        isETHDeposit[nextTokenId] = true; // Указываем, что это ETH депозит

        emit DepositETH(msg.sender, msg.value, nextTokenId); // Логируем событие
        nextTokenId++; // Увеличиваем ID следующего NFT
    }

     /**
     * @dev Вывод средств с бонусом 2%
     * @param tokenId ID NFT
     */
    function withdrawFunds(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner"); // Проверяем владельца NFT
        uint256 amount = deposits[tokenId]; // Получаем сумму депозита
        require(amount > 0, "No funds to withdraw"); // Проверяем, что есть средства

        uint256 bonus = (amount * 200) / 10000; // Рассчитываем бонус 2%
        uint256 totalAmount = amount + bonus; // Итоговая сумма к выводу
        
        // Получаем токен, который был использован для депозита
        address token = depositToken[tokenId];
        require(token != address(0), "Invalid token"); // Проверяем, что токен существует

        // Обновляем состояние до внешнего вызова
        deposits[tokenId] = 0; // Обнуляем депозит перед выводом
        _burn(tokenId); // Удаляем NFT после вывода средств

        if (isETHDeposit[tokenId]) { // Проверка, если депозит был в ETH
            // Отправляем ETH после обновления состояния 
            // Проверяем, что контракт имеет достаточно эфира
            require(address(this).balance >= totalAmount, "Insufficient balance in contract");
           
            (bool successETH, ) = payable(msg.sender).call{value: totalAmount}(""); 
            require(successETH, "ETH transfer failed"); // Проверяем успешность перевода ETH
        } else { // Если депозит был в токенах
            // Проверяем, что токен для вывода совпадает с токеном, который был использован для депозита
            address tokenForWithdrawal = depositToken[tokenId]; // Получаем токен для вывода
            require(tokenForWithdrawal == token, "Token mismatch"); // Проверяем совпадение токенов

            _burn(tokenId); // Удаляем NFT после вывода средств

            // Вторая call-функция для перевода токенов через address
            (bool successToken, ) = address(tokenForWithdrawal).call(
                abi.encodeWithSelector(IERC20(tokenForWithdrawal).transfer.selector, msg.sender, totalAmount)
            );
            require(successToken, "Token transfer failed"); // Проверяем успешность перевода токенов
        }

        emit Withdraw(msg.sender, amount, bonus, tokenId); // Эмитируем событие вывода средств
    }



    receive() external payable {}
}
