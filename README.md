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

## Protocol Tokens

| Token          | Type     | Description                                           |
| -------------- | -------- | ----------------------------------------------------- |
| **SSTR**       | Sui Coin | Represents leveraged SUI exposure (like STRAT in ETH) |
| **CDT**        | Sui Coin | Fungible convertible debt token                       |
| **Option NFT** | NFT      | Non-fungible rights to convert CDT into SSTR          |

## Integration with 1inch

### a) **1inch Fusion+** (Mandatory in MVP)

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

## Roadmap

| Phase       | Timeline | Features                                                            |
| ----------- | -------- | ------------------------------------------------------------------- |
| **Phase 1** | Week 1   | MVP launch, bonding system, Fusion+ integration, basic UI           |
| **Phase 2** | Week 2–3 | 1inch Limit Order integration (TWAP, basic options)                 |
| **Phase 3** | Week 4–5 | Advanced strategy logic, DAO interface, lending module rollout      |
| **Phase 4** | Month 2  | Custom strategy builder, NFT dashboard, vault strategy management   |
| **Phase 5** | Q4 2025  | Launch partner integrations, mobile experience, real-time analytics |

## Summary

SuiStrategy brings structured treasury mechanics and tokenized leverage to the Sui network, drawing direct inspiration from ETH Strategy while extending its potential via:

* Cross-chain asset onboarding (Fusion+)
* Advanced execution strategies (Limit Orders)
* Dynamic conversion mechanics and DAO governance

With a strong MVP foundation and a modular roadmap, SuiStrategy is positioned to become the first **structured DeFi protocol** on Sui that bridges institutional logic with on-chain execution.
