# SuiStrategy: Protocol Overview

*Inspired by [ETH Strategy Protocol](https://www.ethstrat.xyz/). Built natively on Sui.*

#### [Demo]() | [Demo video]() | [Pitchdeck]()

## Overview

**SuiStrategy** is an autonomous, composable treasury protocol on the Sui network designed to accumulate SUI through structured debt and token-based strategies, while enabling cross-chain exposure and advanced financial primitives via integration with the **1inch Fusion+** and **1inch Limit Order Protocol**.

By reimagining convertible bonds and treasury growth mechanics in a modular Sui-native environment, SuiStrategy introduces **SSTR**, a token that offers leveraged exposure to SUI with managed downside risk and no forced liquidation. The protocol is also uniquely designed to enable **cross-chain exposure to ETH and USDC** through 1inch Fusion+, while offering sophisticated order types like **TWAP**, **options**, and **range orders** via the 1inch Limit Order system.

## Background

With growing institutional interest in Sui—highlighted by activity from Fireblocks, Grayscale, and the ongoing development of stablecoins and potential ETF products—the Sui ecosystem is maturing into a high-performance Layer 1 suitable for both infrastructure and strategic finance.

Yet, structured DeFi primitives such as leverage, convertible notes, and cross-chain execution remain underdeveloped on Sui. SuiStrategy aims to fill that gap.

## Objectives

1. Accumulate a large on-chain treasury primarily denominated in SUI
2. Offer **leveraged exposure to SUI** via the SSTR token
3. Enable **cross-chain market entry/exit** using ETH, USDC, and other L1 assets via 1inch Fusion+
4. Provide structured, automated execution strategies through limit orders and time-based systems
5. Use protocol-native debt instruments (convertible notes) to raise capital and stimulate protocol growth

## User Roles

There are two main user groups in SuiStrategy:

* **SSTR Holders**: Represent equity holders with leveraged exposure to SUI
* **Bond Purchasers**: Debt holders that fund the treasury and receive the right to convert debt into SSTR

## Protocol Mechanics

### 1. Bonding System

Two classes of bonds are used to manage protocol leverage and treasury expansion:

#### a) **Long Bonds (Convertible Debt)**

* Users deposit stablecoins (e.g., USDC)
* They receive:

  * **CDT (Convertible Debt Token)** – Fungible ERC20-style token on Sui
  * **NFT Option** – Represents a right to convert debt into SSTR before expiry
* Protocol uses the stablecoins to market-buy SUI and deposit it into treasury

#### b) **Short Bonds (Debt Repayment)**

* Users deposit **CDT + NFT Option** to convert their note into SSTR before expiry
* Alternatively, users can return CDT alone after expiry for stablecoins (principal)
* This reduces protocol liabilities and recycles debt into equity

### 2. Conversion Logic

#### a) **Before Expiry**

* Users deposit their NFT Option + CDT
* They receive SSTR tokens at a predetermined conversion ratio
* The protocol burns the NFT and CDT and issues SSTR

#### b) **After Expiry**

* Users can redeem CDT and expired NFT for the stablecoin value
* No equity is granted; protocol pays out from treasury

### 3. Treasury Growth and SSTR Premium

SSTR trades at a premium to its treasury NAV due to the **implied premium embedded in convertible notes**. The protocol raises **0% interest debt** by embedding value in the conversion rights rather than interest. This:

* Increases treasury size (more SUI accumulated)
* Increases value per SSTR holder (as treasury per SSTR grows)
* Avoids dilution unless the note is economically favorable to convert

This dynamic leads to natural positive pressure on SSTR's value as the treasury accumulates SUI.

### 4. Treasury Lending (Sui-native Aave-like System)

* Treasury SUI is lent into a custom **Sui Lending Pool**
* Only **SSTR tokens** can be used as collateral
* STRAT holders can borrow SUI against SSTR with liquidation thresholds
* Benefits:

  * Increases utility of SSTR
  * Generates lending yield for the treasury
  * Protects against RFV attacks by creating a market-based defense layer

## SuiStrategy vs ETH Strategy Protocol

| Item                         | **ETH Strategy Protocol**                             | **SuiStrategy**                                                                          |
| ---------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Network**                  | Ethereum (EVM-based)                                  | Sui (Move-based, high throughput, low fees)                                              |
| **Base Asset**               | ETH                                                   | SUI                                                                                      |
| **Leverage Asset**           | STRAT (ERC20)                                         | SSTR (Sui-native coin)                                                                   |
| **Bond Structure**           | Convertible debt (long/short bonds)                   | Same structure + NFT options + maintains fungible Sui-native format                      |
| **Swap Functionality**       | None (operates only within ETH ecosystem)             | ✅ **1inch Fusion+ integration**: Enables cross-chain swaps (SUI ↔ ETH / USDC)            |
| **Strategy Automation**      | Limited (manual rebalancing)                          | ✅ Powered by **1inch Limit Orders**: Enables TWAP, option-style orders, and range orders |
| **Strategic Scalability**    | STRAT-backed lending via Morpho ETH pool              | ✅ **SSTR-backed SUI lending pool** built natively on Sui                                 |
| **User Accessibility**       | Primarily for ETH DeFi users                          | ✅ Targets Sui-based retail & institutional users (Grayscale, Fireblocks, etc.)           |
| **Protocol Revenue Model**   | Generates implied premium through zero-interest bonds | Same model + earns protocol fees through strategic swaps and automation                  |
| **Scalability & Modularity** | Rigid structure (dependent on Morpho)                 | ✅ Modular strategy setup, 1inch API support, strategy automation vaults                  |
| **UI/UX Accessibility**      | Basic smart contract interactions                     | ✅ Optimized UI for dashboard, strategy execution, and auto-ordering                      |
| **External Integrations**    | None                                                  | ✅ Supports 1inch REST/Web3 APIs, cross-chain liquidity, and external data sources        |

### Key Differentiators Summary

| Area                      | SuiStrategy Advantage                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------- |
| **Technical Base**        | Leverages Sui’s object-based architecture and fast performance                           |
| **Cross-chain Liquidity** | Supports SUI ↔ ETH asset swaps via 1inch Fusion+                                         |
| **Strategic Flexibility** | Enables TWAPs, option orders, and other strategies through 1inch Limit Orders            |
| **Protocol Growth**       | Combines SUI inflow with decentralized strategy automation, enabling DAO-based expansion |
| **MVP Feasibility**       | Core components (cross-chain swaps, bond model, vault UI) can be built in 7 days         |

## Protocol Tokens

| Token          | Type     | Description                                           |
| -------------- | -------- | ----------------------------------------------------- |
| **SSTR**       | Sui      | Represents leveraged SUI exposure (like STRAT in ETH) |
| **CDT**        | Sui      | Fungible convertible debt token                       |
| **Option NFT** | NFT      | Non-fungible rights to convert CDT into SSTR          |

## Integration with 1inch

### a) **1inch Fusion+**

* Enables **cross-chain swaps between SUI ↔ ETH / USDC**
* Use case: User deposits ETH/USDC on Ethereum → receives SUI on Sui for bonding
* Reverse swap supported for exit strategies
* Seamless integration via 1inch Fusion+ API and Web3 SDK

### b) **1inch Limit Order Protocol** (Advanced Strategy Layer)

Used for:

* **TWAP Swaps**: Break up large SUI buys/sells over time
* **Options-style Strategies**: Use NFT Options + 1inch triggers
* **Concentrated Liquidity Simulation**: Place limit orders within specific price ranges
* **Strategy Automation**: Trigger custom orders on specific market events

These features allow SSTR holders and the DAO to build a **programmable execution layer** directly on-chain without deploying custom market logic.

## Summary

SuiStrategy brings structured treasury mechanics and tokenized leverage to the Sui network, drawing direct inspiration from ETH Strategy while extending its potential via:

* Cross-chain asset onboarding (Fusion+)
* Advanced execution strategies (Limit Orders)
* Dynamic conversion mechanics and DAO governance
