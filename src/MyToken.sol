// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken - Кастомный ERC20-токен протокола
 */
contract MyToken is IERC20, Ownable {
    /**
     * @dev Конструктор, создающий токен с названием MyToken и тикером MTK
     */
    constructor() IERC20("MyToken", "MTK") Ownable(msg.sender){}

    /**
     * @dev Функция выпуска новых токенов
     * @param to Адрес получателя
     * @param amount Количество токенов
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _safeMint(to, amount); // Выпускаем новые токены и отправляем их на адрес to
    }
}

