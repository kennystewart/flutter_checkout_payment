# Flutter Checkout Payment  


## Explain

This plugin is for Checkout online payment. It's implemented the native SDKs to work on Flutter environment.

![](https://logos-download.com/wp-content/uploads/2019/07/Checkout.com_Logo.png)

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_checkout_payment: ^1.1.0
```

### Android

No additional work required

### iOS

The SDK build for >= iOS 10.0, so you need to set the platform version in the `Podfile` to iOS 10 or above.

```
platform: :ios, '10.0'
```


## Usage

You just have to import the package with

```dart
import 'package:flutter_checkout_payment/flutter_checkout_payment.dart';
```

Then, you need to initialize the API with you public key. Your public key is found on Checkout dashboard.

```dart
await FlutterCheckoutPayment.init(key: "YOUR_PUBLIC_KEY");
```

And when you are ready for production you have to set the environment to Live.

```dart
await FlutterCheckoutPayment.init(key: "YOUR_PUBLIC_KEY", environment: Environment.LIVE);
```

Now, you can generate the Token which you will use to proceed the payment.

```dart
CardTokenisationResponse response = await FlutterCheckoutPayment.generateToken(number: "4242424242424242", name: "name", expiryMonth: "05", expiryYear: "21", cvv: "100");
print(response.token);
```


## Public Static Methods Summary

| Return                    | Description |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Future\<bool> | **init(@required String key, Environment environment** *default* **Environment.SANDBOX})** <br>Initialize the Checkout API with key and environment. Return a bool of the successful status.|
| Future\<CardTokenisationResponse> | **generateToken({@required String number, @required String name, @required String expiryMonth, @required String expiryYear, @required String cvv, BillingModel billingModel})** <br>Generate the token which it will be used to make the payment, return the CardTokenisationResponse value.|
| Future\<bool> | **isCardValid({@required String number})** <br>Check whether the card number is valid or not, return a bool with the result.|
| Future\<String> | **handle3DS({@required String authUrl, @required String successUrl, @required String failUrl})** <br>Handle a 3DS challenge, returns token if success or null if failure. |

The rest of methods are under development.


## Objects

```dart
class BillingModel {
  final String addressLine1;
  final String addressLine2;
  final String postcode;
  final String country;
  final String city;
  final String state;
  final PhoneModel phoneModel;
}

class PhoneModel {
  final String countryCode;
  final String number;
}

class CardTokenisationResponse {
  final String? type;
  final String? token;
  final String? expiresOn;
  final int? expiryMonth;
  final int? expiryYear;
  final String? scheme;
  final String? last4;
  final String? bin;
  final String? cardType;
  final String? cardCategory;
  final String? issuer;
  final String? issuerCountry;
  final String? productId;
  final String? productType;
  final BillingModel? billingAddress;
  final PhoneModel? phone;
  final String? name;
}
```
