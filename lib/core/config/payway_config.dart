class PayWayConfig {
  static const String merchantId = 'ec475768';
  static const String apiKey = '833b6a3404d9783d7d93db0de996b559404f475b';

  static const bool isSandbox = true;

  static const String _sandboxCheckout =
      'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/purchase';
  static const String _prodCheckout =
      'https://checkout.payway.com.kh/api/payment-gateway/v1/payments/purchase';

  static const String _sandboxCheck =
      'https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction';
  static const String _prodCheck =
      'https://checkout.payway.com.kh/api/payment-gateway/v1/payments/check-transaction';

  static String get checkoutUrl => isSandbox ? _sandboxCheckout : _prodCheckout;
  static String get checkTransactionUrl => isSandbox ? _sandboxCheck : _prodCheck;

  static const String returnScheme = 'paywayapp';
  static const String returnDeeplink = 'paywayapp://payment/result';
}
