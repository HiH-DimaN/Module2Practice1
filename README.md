# DeFi Token Vault Protocol

## Описание проекта
Этот протокол позволяет пользователям:
- Покупать кастомный ERC20-токен (`myToken`) за USDT, USDC, DAI или ETH с комиссией 10%.
- Вносить депозиты в `Vault` и получать NFT-чек в подтверждение.
- Выкупать свой депозит, включая 2% от комиссий, накопленных в `Vault`.
- Работает на базе смарт-контрактов Solidity и развертывается через Foundry.

## Архитектура протокола
Протокол состоит из трех контрактов:
1. **MyToken.sol** – кастомный ERC20-токен.
2. **TokenSale.sol** – контракт покупки токена за whitelisted активы с комиссией 10%.
3. **Vault.sol** – контракт хранения депозитов, выпускающий NFT-чек.

## Расчеты токенов
### Покупка myToken
- Пользователь выбирает whitelisted токен (USDT, USDC, DAI, ETH).
- Цена: `1 myToken = 1 USDT = 1 USDC = 1 DAI = 2 ETH`.
- При покупке myToken пользователь платит +10% от стоимости (например, за 100 USDT получит 100 myToken, но заплатит 110 USDT).
- 10% (в данном примере 10 USDT) отправляется в `Vault`.

### Депозит и возврат через Vault
- Пользователь делает депозит в `Vault`, получает NFT-чек.
- При возврате NFT получает:
  - Свой депозит.
  - 2% от накопленных комиссий (`Vault`).

## Функциональность
### `TokenSale.sol`
- `addToWhitelist(address token)` – добавляет токен в белый список.
- `buyWithToken(uint256 amount, IERC20 paymentToken)` – покупка myToken за whitelisted токены.
- `buyWithETH()` – покупка myToken за ETH.
- `receive()` - прием эфира в контракт.

### `Vault.sol`
- `setTokenSale(address _tokenSale) ` - учиановка контракта продажи.
- `setAllowedToken(address token, bool allowed)` - управление списком разрешенных токенов.
- `deposit(IERC20 token, uint256 amount)` – депозит в `Vault`(ERC20) с выпуском NFT.
- `depositETH()` - депозит в `Vault`(ETH) с выпуском NFT.
- `withdrawFunds(uint256 tokenId)` – возврат депозита + 2% от комиссий.

### `MyToken.sol`
- Обычный ERC20 с управляемыми параметрами (выпуск новых токенов с установкой роли минтера).

## Развертывание через Foundry
```sh
forge install openzeppelin/contracts
forge install foundry-rs/forge-std
forge build
forge test
```

## Тестирование
Тесты покрывают более 90% функциональности каждого контракта и включают:
- Юнит-тесты для всех функций в `TokenSale.sol`, `Vault.sol` и `MyToken.sol`.
- Проверку правильности расчетов комиссий, депозитов и вывода средств.
- Проверку работы whitelist в `TokenSale.sol`.
- Проверку безопасных трансферов через SafeERC20.

Запуск тестов:
```sh
forge test --gas-report
```

