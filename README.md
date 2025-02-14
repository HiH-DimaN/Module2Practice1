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
- `buyWithToken(address token, uint256 amount)` – покупка myToken за ERC20.
- `buyWithETH()` – покупка myToken за ETH.
- `setWhitelist(address token, bool status)` – управление списком разрешенных токенов.

### `Vault.sol`
- `deposit(address token, uint256 amount)` – депозит в `Vault` с выпуском NFT.
- `withdraw(uint256 tokenId)` – возврат депозита + 2% от комиссий.

### `MyToken.sol`
- Обычный ERC20 с управляемыми параметрами (комиссия, адрес получателя комиссии и т. д.).

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

