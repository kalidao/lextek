// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

contract Section4 {
    function section4() public pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<h2 class="section">4. Investor Representations</h2>',
                '<p class="legal-text">(a) The Investor has full legal capacity, power and authority to execute and deliver this Safe and to perform its obligations hereunder. This Safe constitutes valid and binding obligation of the Investor, enforceable in accordance with its terms, except as limited by bankruptcy, insolvency or other laws of general application relating to or affecting the enforcement of creditors\' rights generally and general principles of equity.</p>',
                '<p class="legal-text">(b) The Investor is an accredited investor as such term is defined in Rule 501 of Regulation D under the Securities Act, and acknowledges and agrees that if not an accredited investor at the time of an Equity Financing, the Company may void this Safe or refuse to allow the Investor to convert this Safe. The Investor has been advised that this Safe and the underlying securities have not been registered under the Securities Act, or any state securities laws and, therefore, cannot be resold unless they are registered under the Securities Act and applicable state securities laws or unless an exemption from such registration requirements is available. The Investor is purchasing this Safe and the securities to be acquired by the Investor hereunder for its own account for investment, not as a nominee or agent, and not with a view to, or for resale in connection with, the distribution thereof, and the Investor has no present intention of selling, granting any participation in, or otherwise distributing the same. The Investor has such knowledge and experience in financial and business matters that the Investor is capable of evaluating the merits and risks of such investment, is able to incur a complete loss of such investment without impairing the Investor\'s financial condition and is able to bear the economic risk of such investment for an indefinite period of time.</p>',
                '<p class="legal-text">(c) The Investor has had an opportunity to discuss the Company\'s business, management and financial affairs with directors, officers and management of the Company and has had the opportunity to review the Company\'s operations and facilities. The Investor has also had the opportunity to ask questions of and receive answers from the Company and its management regarding the terms and conditions of this investment.</p>',
                '<p class="legal-text">(d) The Investor understands that this Safe is subject to the Company\'s Prior SAFEs (as defined below), and that this Safe will convert into shares of Capital Stock identical to those issued to purchasers of such Prior SAFEs, as further specified in Sections 1(a) and 1(b).</p>',
                '<p class="legal-text">(e) The Investor understands that this Safe is subject to all the risks associated with investments in early stage companies, including the possible loss of the entire principal amount invested.</p>'
            )
        );
    }
}
