// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

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

contract Sections {
    function sections(DEAL calldata deal) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<p class="title">',
                deal.providerName,
                "</p>",
                '<p class="legal-text">THIS CERTIFIES THAT in exchange for the payment by ',
                deal.clientName,
                ' (the "Client") of $',
                deal.dealAmount,
                ' USDC digital stablecoin (the "Purchase Amount") on or about ',
                deal.dealDate,
                ", ",
                deal.providerName,
                ', a services agent (the "Provider"), shall complete the services or other work understood among the parties as "',
                deal.dealNotes,
                '" (the "Work"), subject to the terms described below (altogether, the Work and the terms, this "Deal").</p>',
                '<p class="legal-text">The "Expiry Date" is ',
                deal.expiryDate,
                '. Payment shall be rendered as of the Expiry Date for the Work, or if pending, at the option of the Client through the `unlock()` method after their `escrow()` into the protocol addressed onchain at 0x00000000000044992CB97CB1A57A32e271C04c11 (with the ID of this Deal hashed thereby, the "ESCROW"). The Client shall be entitled to `reclaim()` their assets from the ESCROW after the Expiry Date if undisputed (see below, Miscellaneous, (c) Onchain Arbitration).</p>',
                '<h2 class="section">Terms and Conditions</h2>',
                '<p class="legal-text">(a) Scope of Work. The Provider agrees to perform the Work as described above. Any modifications or additions to the scope must be agreed upon in writing by both parties and may result in adjustments to the Purchase Amount and/or Expiry Date.</p>',
                '<p class="legal-text">(b) Payment Terms. The Purchase Amount shall be held in the ESCROW until the Work is completed to the Client\'s satisfaction or until the Expiry Date, whichever comes first. The Provider acknowledges that they will not receive payment until the Client executes the `unlock()` function or the ESCROW resolver rules in their favor.</p>',
                '<p class="legal-text">(c) Milestones and Deliverables. The parties agree to establish clear milestones and deliverables for the Work. These shall be recorded onchain as part of this Deal and will serve as criteria for the release of funds from the ESCROW.</p>',
                '<p class="legal-text">(d) Intellectual Property. Unless otherwise specified, all intellectual property rights in the Work shall be transferred to the Client upon full payment. The Provider warrants that the Work does not infringe on any third-party intellectual property rights.</p>',
                '<p class="legal-text">(e) Confidentiality. Both parties agree to maintain the confidentiality of any proprietary information shared during the course of this Deal. This obligation survives the termination of this agreement.</p>',
                '<p class="legal-text">(f) Termination. Either party may terminate this Deal before the Expiry Date by calling the `lock()` function on the ESCROW. In such case, the resolver will determine the fair distribution of the escrowed funds based on the work completed and the evidence provided by the parties.</p>',
                '<p class="legal-text">(g) Warranties and Representations. Each party represents and warrants that it has the legal power and authority to enter into this Deal and that all information provided in connection with this Deal is true, accurate, and complete.</p>',
                '<p class="legal-text">(h) Limitation of Liability. Except for breaches of confidentiality or intellectual property rights, neither party shall be liable for any indirect, incidental, special, consequential, or punitive damages.</p>',
                '<p class="legal-text">(i) Data Protection. Both parties agree to comply with all applicable data protection and privacy laws in relation to any personal data processed under this Deal.</p>',
                '<h2 class="section">Miscellaneous</h2>',
                '<p class="legal-text">(a) Onchain Identity. If not otherwise provided by reference to their public key or Ethereum Name Service (ENS) domain, the identity and corporate organization of the parties shall be understood by this document and other evidence provided by the parties in connection with the transactions contemplated hereby.</p>',
                '<p class="legal-text">(b) Code-deference. In the event that this document conflicts with its onchain representation in the ESCROW, the terms embodied by the ESCROW shall prevail unless otherwise agreed among the parties.</p>',
                '<p class="legal-text">(c) Onchain Arbitration. If there is a recovery or resolution event signified by a party calling a `lock()` on the ESCROW before the termination of this Deal, the parties shall conduct online dispute resolution under the UKJT Digital Dispute Resolution Rules and shall abide by the final resolution of the resolver identified in the ESCROW. The resolver shall be selected through mutual agreement of the parties or, failing such agreement, by the ESCROW protocol.</p>',
                '<p class="legal-text">(d) Governing Law. This Deal shall be governed by and construed in accordance with the laws of Delaware, or, if another jurisdiction is specified in the ESCROW, the laws of such jurisdiction, without regard to its conflict of law provisions.</p>',
                '<p class="legal-text">(e) Force Majeure. Neither party shall be liable for any failure or delay in performing their obligations under this Deal due to events beyond their reasonable control, including but not limited to acts of God, war, strikes, or network failures.</p>',
                '<p class="legal-text">(f) Entire Agreement. This Deal, including the onchain ESCROW and any attached exhibits or schedules, constitutes the entire agreement between the parties and supersedes all prior negotiations, understandings, and agreements between the parties, whether written or oral, relating to the subject matter hereof.</p>',
                '<p class="legal-text">(g) Amendments. Any amendments to this Deal must be agreed upon by both parties in writing and recorded onchain.</p>',
                '<p class="legal-text">(h) Severability. If any provision of this Deal is found to be invalid or unenforceable, the remaining provisions shall remain in full force and effect.</p>',
                '<p class="legal-text">(i) Notices. All notices under this Deal shall be in writing and delivered to the addresses specified in the ESCROW, with private key signatures and/or the delivery of a non-fungible token (NFT) constituting valid delivery.</p>',
                '<p class="legal-text">(j) Assignment. Neither party may assign its rights or obligations under this Deal without the prior written consent of the other party.</p>'
            )
        );
    }
}
