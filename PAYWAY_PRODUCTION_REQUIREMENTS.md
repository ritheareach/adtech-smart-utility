# Payment Gateway Integration — Requirements & Engagement Request
## ABA PayWay eCommerce Checkout API

---

| | |
|---|---|
| **Date** | June 01, 2025 |
| **To** | ABA Bank — PayWay Merchant Services & Technical Team |
| **From** | [Your Company Name] — Software Solutions |
| **Subject** | Technical Requirements and Information Request for PayWay Payment Gateway Integration on Behalf of Client |

---

## 1. Overview

[Your Company Name] is a software solutions company engaged by **ADTech Co., Ltd.** to design and develop the **ADTech Smart Utility Management System** — a mobile application that enables end-customers to manage and pay utility bills (electricity, water, cooling, and gas).

As part of this engagement, we are responsible for the technical integration of ABA PayWay as the payment gateway. We are writing to formally establish the requirements between our company, our client (ADTech), and ABA Bank, so that the integration can proceed from development through to production deployment smoothly and with full compliance.

This document outlines:

- What we require from the bank in order to develop and deliver the integration
- What the bank requires from us as the integrating software company
- What the bank requires from ADTech as the registered merchant

---

## 2. Scope of Integration

The following PayWay features are within the scope of development:

| Feature | Description |
|---|---|
| Create Transaction API | Initiates payment and retrieves QR image / hosted checkout |
| Check Transaction API | Polls payment status after transaction creation |
| ABA KHQR Payment | QR code scannable by any NBC-approved banking app |
| Credit/Debit Card Payment | Hosted WebView checkout (VISA, Mastercard, UnionPay, JCB) |
| Alipay Payment | QR-based scan to pay |
| WeChat Pay Payment | QR-based scan to pay |
| Callback Signature Verification | HMAC-SHA512 header verification on payment result |
| Deep-link Return Handling | Intercept `paywayapp://` redirect for in-app result handling |

**Platform:** Flutter (Android & iOS)

---

## 3. What We Require from the Bank

The following items are required from ABA PayWay's technical and merchant services teams in order for us to complete and deliver the integration.

### 3.1 Sandbox Access for Development & Testing

| Item | Purpose |
|---|---|
| Sandbox Merchant ID | Needed to authenticate all API requests during development |
| Sandbox API Key | Needed to generate HMAC-SHA512 request signatures |
| Sandbox Secret Key | Needed to verify callback signatures (`X_PAYWAY_HMAC_SHA512`) |
| Sandbox endpoint URLs | Confirm all active sandbox URLs for Create Transaction and Check Transaction |

> We have obtained initial sandbox credentials. We request confirmation that these are valid for all four payment methods (KHQR, Card, Alipay, WeChat).

### 3.2 Test Data

| Item | Purpose |
|---|---|
| Test card numbers | To simulate card payment success and failure in sandbox |
| Test ABA Mobile / KHQR account | To simulate a real QR scan and payment in sandbox |
| Sample webhook/callback payloads | To test our server-side `X_PAYWAY_HMAC_SHA512` verification logic |
| List of transaction status codes | Full list of `status.code` values with their meanings (e.g. `00` = success, `200`/`201` = failure) |

### 3.3 Technical Documentation

| Document | Purpose |
|---|---|
| Full API specification (latest version) | Confirm field names, data types, required vs optional fields |
| Complete `hash` field order reference | Confirm all 23 fields in the exact concatenation order required for signature |
| Payment option identifiers | Confirm exact string values for `payment_option` per method (e.g. `aba_khqr`, `alipay`, `wechat`) |
| Callback / pushback specification | Full spec of POST body fields sent to `return_url` after payment |
| Error code reference | Full list of API error codes and recommended handling |
| Deep-link / mobile return URL guidance | Confirm support for custom deep-link schemes (e.g. `paywayapp://`) on Android and iOS |

### 3.4 Go-Live Process

| Item | Purpose |
|---|---|
| Production readiness checklist | Understand all criteria that must be met before production credentials are issued |
| UAT / review process | Understand how the bank reviews and signs off on an integration |
| Production credential issuance timeline | Understand lead time so we can plan the go-live date with our client |
| Technical point of contact | A named contact at PayWay for escalating integration issues during development |

---

## 4. What the Bank Requires from Us (as the Software Company)

Please clarify and confirm which of the following the bank requires directly from the integrating software company:

| Requirement | Confirmed (Yes / No) |
|---|---|
| Technical integration document describing the implementation | |
| Security review or code audit from our side before go-live | |
| Demonstration / walkthrough of the integration in sandbox | |
| List of server IP addresses that will call PayWay APIs (for whitelisting) | |
| Deep-link / return URL registration with the bank | |
| NDA or software vendor agreement with ABA Bank | |
| Signed declaration that the integration follows PayWay security guidelines | |

> If there are additional requirements not listed above, please provide a complete checklist.

---

## 5. What the Bank Requires from Our Client (ADTech Co., Ltd.)

As the software company, we will coordinate the collection and submission of merchant documents on behalf of our client. Please provide the full list of documents and requirements that ADTech must fulfill as the registered merchant. For reference, we expect this may include:

| Likely Requirement | Confirmed / Please Amend |
|---|---|
| Business Registration Certificate | |
| Tax Registration (Patent) | |
| Bank account details for settlement | |
| National ID / Passport of authorized representative | |
| Signed PayWay Merchant Agreement | |
| Privacy Policy and Terms of Service (live URL) | |
| Application listing on Google Play / App Store | |
| Description of business and payment use case | |

> Please provide the official merchant onboarding form or checklist so we can ensure ADTech submits everything correctly on first submission.

---

## 6. Key Technical Questions

The following questions arise from our current implementation and require clarification before production deployment:

1. Does the `payment_option` field need to be set to specific values (e.g. `alipay`, `wechat`) for Alipay and WeChat QR codes to be returned, or does a single Create Transaction call return all QR types at once?
2. Is the `return_url` field required for mobile deep-link integrations, or is `return_deeplink` sufficient as the sole redirect mechanism?
3. Are there any restrictions on calling the Check Transaction API directly from a mobile client, or must it be proxied through a server backend?
4. What is the expected `status.code` returned when a QR code expires before the customer scans it?
5. Is there a required minimum or maximum transaction amount in KHR?
6. Are there any App Store / Play Store review considerations regarding PayWay's WebView-based hosted checkout on iOS?

---

## 7. Contacts

### Software Company (Integration Team)

| Role | Name | Email | Phone |
|---|---|---|---|
| Technical Lead | [Name] | [Email] | [Phone] |
| Project Manager | [Name] | [Email] | [Phone] |

### Client (Merchant)

| Role | Name | Email | Phone |
|---|---|---|---|
| ADTech Representative | [Name] | [Email] | [Phone] |

---

## 8. Requested Next Steps

We kindly request the following from ABA PayWay to proceed:

1. Confirm receipt of this letter and assign a technical point of contact
2. Provide responses to the questions in Section 6
3. Provide the official merchant onboarding checklist for ADTech (Section 5)
4. Confirm all items in Section 4 that are required from us as the software vendor
5. Provide full test card numbers and sandbox test instructions (Section 3.2)

We are available for a technical meeting at your convenience to discuss any of the above in detail.

---

Yours sincerely,

&nbsp;

___________________________
**[Authorized Signatory Name]**
**[Title]**, [Your Company Name]
**Date:** June 01, 2025
