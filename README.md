# [𝓁ex𝓉eʞK](https://github.com/z0r0z/BaseSafe)  [![License: AGPL-3.0-only](https://img.shields.io/badge/License-AGPL-black.svg)](https://opensource.org/license/agpl-v3/) [![solidity](https://img.shields.io/badge/solidity-%5E0.8.26-black)](https://docs.soliditylang.org/en/v0.8.26/) [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://getfoundry.sh/)

> [site](https://lextek.eth.limo/)

100% onchain [Y Combinator SAFE](https://www.ycombinator.com/documents) and Escrow DEAL. Uses dynamic SVG to render a formatted legal template with standard clauses tailored to support wallet signatures and ENS. This is returned by a `draft()` view function, and using this onchain output as a document preview and signature object (rather than a centralized e-sign service), a `company` or service `provider` can have guaranteed uptime to call to `send()` their signed document to an `investor` or `client` `0x`/ [`basename ENS`](https://www.base.org/names) to `sign()` as an [ERC1155 NFT](https://ethereum.org/en/developers/docs/standards/tokens/erc-1155/) which allows for convenient communication of offers and invoicing without email* and composable artifacts. This draft offer can then be countersigned and funded in the specified amount for the specified duration in the same transaction, completing the onchain agreement and minting back the sender a matching NFT with the completed signatures. Party details and other material variables are stored onchain using readable strings that are translated by the Intents Engine [IE](https://github.com/NaniDAO/ie/tree/main) into executable calldata.

> * In the present context of contract law, agreements can be formed by all manner of electronic communication that otherwise meet the requirements of valid agreement formation and consent, and the SAFE/DEAL offer terms and evidence of user acceptance are clearly legible in the updated NFT itself. Similarly, [courts in New York and London](https://www.huntonak.com/blockchain-legal-resource/youve-been-served-by-nft) have allowed service of process by means of sending NFTs to wallet addresses.

## SAFE

`SAFE V0`: [`0x2afe00e9DeC100583600270c009BBc0001B400f6`](https://basescan.org/address/0x2afe00e9DeC100583600270c009BBc0001B400f6#code)

```solidity
struct SAFE {
    string companyName;
    string investorName;
    string purchaseAmount; /*USDC*/
    string postMoneyValuationCap;
    string safeDate;
    address companySignature;
    address investorSignature;
}
```

## DEAL

`DEAL V0`: [`0xde48c8005C008509000000D5c6F31BC3a66E1900`](https://basescan.org/address/0xde48c8005C008509000000D5c6F31BC3a66E1900#code)

```solidity
struct DEAL {
    string clientName;
    string providerName;
    string resolverName;
    string dealAmount; /*USDC*/
    string dealNotes;
    string dealDate;
    string expiryDate;
    uint256 expiryTimestamp;
    address providerSignature;
    address clientSignature;
}
```

## Getting Started

Run: `curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup`

Build the foundry project with `forge build`. Run tests with `forge test`. Measure gas with `forge snapshot`. Format with `forge fmt`.

## Disclaimer

*These smart contracts and testing suite are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of anything provided herein or through related user interfaces. This repository and related code have not been audited and as such there can be no assurance anything will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk.*

## License

See [LICENSE](./LICENSE) for more details.
