import Flutter
import UIKit
import Frames

public class SwiftFlutterCheckoutPaymentPlugin: NSObject, FlutterPlugin {

    /// The channel name which it's the bridge between Dart and SWIFT
    private static var CHANNEL_NAME : String = "shadyboshra2012/fluttercheckoutpayment"

    /// Methods name which detect which it called from Flutter.
    private var METHOD_INIT : String = "init"
    private var METHOD_GENERATE_TOKEN : String = "generateToken"
    private var METHOD_IS_CARD_VALID : String = "isCardValid"
    private var METHOD_HANDLE_3DS : String = "handle3DS"

    /// Error codes returned to Flutter if there's an error.
    private var GENERATE_TOKEN_ERROR : String = "2"

    /// Checkout API iOS Platform
    private var checkoutAPIClient : CheckoutAPIClient! = nil

    private var currentFlutterResult: FlutterResult? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCheckoutPaymentPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == METHOD_INIT {

            // Get the args from Flutter.
            guard let args = call.arguments as? [String: Any] else {
                return
            }

            let key : String = args["key"] as! String
            let environmentString : String = args["environment"] as! String

            // Init Checkout API
            checkoutAPIClient = CheckoutAPIClient(publicKey: key, environment: environmentString == "Environment.SANDBOX" ? .sandbox : .live)

            // Return true if success.
            result(true)
        }
        else if call.method == METHOD_GENERATE_TOKEN {
            // Get the args from Flutter.
            let args = call.arguments as? [String: Any]

            let cardNumber : String = args!["number"] as! String
            let name : String = args!["name"] as! String
            let expiryMonth : String = args!["expiryMonth"] as! String
            let expiryYear : String = args!["expiryYear"] as! String
            let cvv : String = args!["cvv"] as! String

            // Init CkoCardTokenRequest without billing model
            // if not found and generate token.
            guard let billingModelDictionary = args!["billingModel"] as? [String: Any], let phoneModelDictionary = billingModelDictionary["phoneModel"] as? [String: Any] else {
                let cardTokenRequest = CkoCardTokenRequest(number: cardNumber, expiryMonth: expiryMonth, expiryYear: expiryYear, cvv: cvv, name: name)

                // create the card token request
                checkoutAPIClient.createCardToken(card: cardTokenRequest, completion: { results in
                    do {
                        switch results {
                        case .success:
                            // Return a result with the token.
                            let jsonEncoder = JSONEncoder()
                            let jsonData = try jsonEncoder.encode(results.get())
                            let json = String(data: jsonData, encoding: String.Encoding.utf8)
                            result(json)
                        case .failure(let ex):
                            result(FlutterError(code: self.GENERATE_TOKEN_ERROR, message: ex.localizedDescription, details: nil))
                        }
                    } catch {
                        result(FlutterError(code: self.GENERATE_TOKEN_ERROR, message: error.localizedDescription, details: nil))
                    }
                })
                return
            }

            let addressLine1 : String = billingModelDictionary["addressLine1"] as! String
            let addressLine2 : String = billingModelDictionary["addressLine2"] as! String
            let city : String = billingModelDictionary["city"] as! String
            let state : String = billingModelDictionary["state"] as! String
            let zip : String = billingModelDictionary["postcode"] as! String
            let country : String = billingModelDictionary["country"] as! String

            let countryCode : String = phoneModelDictionary["countryCode"] as! String
            let phoneNumber : String = phoneModelDictionary["number"] as! String

            // create the phone number
            let phoneModel = CkoPhoneNumber(countryCode: countryCode, number: phoneNumber)

            // create the address
            let billingModel = CkoAddress(addressLine1: addressLine1, addressLine2: addressLine2, city: city, state: state, zip: zip, country: country)

            // create the card token request and generate the token.
            let cardTokenRequest = CkoCardTokenRequest(number: cardNumber, expiryMonth: expiryMonth, expiryYear: expiryYear, cvv: cvv, name: name, billingAddress: billingModel, phone: phoneModel)

            // create the card token request
            checkoutAPIClient.createCardToken(card: cardTokenRequest, completion: { [self] results in
                do {
                    switch results {
                    case .success:
                        // Return a result with the token.
                        let jsonEncoder = JSONEncoder()
                        let jsonData = try jsonEncoder.encode(results.get())
                        let json = String(data: jsonData, encoding: String.Encoding.utf8)
                        result(json)
                    case .failure(let ex):
                        result(FlutterError(code: self.GENERATE_TOKEN_ERROR, message: ex.localizedDescription, details: nil))
                    }
                } catch {
                    result(FlutterError(code: self.GENERATE_TOKEN_ERROR, message: error.localizedDescription, details: nil))
                }
            })
//            result(FlutterError(code: error.requestId, message: error.errorType, details: nil))
        }
        else if call.method == METHOD_IS_CARD_VALID {

            // Get the args from Flutter.
            let args = call.arguments as? [String: Any]

            let cardNumber : String = args!["number"] as! String

            /// verify card number
            let cardUtils = CardUtils()
            let isCardValid = cardUtils.isValid(cardNumber: cardNumber)

            // Return the boolean result.
            result(isCardValid)
        }
        else if call.method == METHOD_HANDLE_3DS {
            currentFlutterResult = result

            let args = call.arguments as? [String: Any]

            let successUrl : String = args!["successUrl"] as! String
            let failUrl : String = args!["failUrl"] as! String
            let authUrl : String = args!["authUrl"] as! String

            let threeDSWebViewController = ThreedsWebViewController.init(
                successUrl: URL(string: successUrl)!,
                failUrl: URL(string: failUrl)!)
            threeDSWebViewController.authUrl = URL(string: authUrl)
            threeDSWebViewController.delegate = self

            let rootViewController: UIViewController! = UIApplication.shared.windows.first { $0.isKeyWindow}?.rootViewController

            var navigationController: UINavigationController! = nil
            if (rootViewController is UINavigationController) {
                navigationController = rootViewController as? UINavigationController
            } else {
                navigationController = UINavigationController(rootViewController: threeDSWebViewController)
            }

            navigationController.presentationController?.delegate = self
            rootViewController.present(navigationController, animated: true, completion: nil)
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }
}

extension SwiftFlutterCheckoutPaymentPlugin: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // user dismissed the sheet, treat as failure
        if let result = currentFlutterResult {
            result(nil)
            currentFlutterResult = nil
        }
    }
}

extension SwiftFlutterCheckoutPaymentPlugin: ThreedsWebViewControllerDelegate {

    public func threeDSWebViewControllerAuthenticationDidSucceed(_ threeDSWebViewController: ThreedsWebViewController, token: String?) {
        // Handle successful 3DS.
        let rootViewController: UIViewController! = UIApplication.shared.windows.first { $0.isKeyWindow}?.rootViewController
        rootViewController.dismiss(animated: true)

        if let result = currentFlutterResult {
            result(token)
            currentFlutterResult = nil
        }
    }

    public func threeDSWebViewControllerAuthenticationDidFail(_ threeDSWebViewController: ThreedsWebViewController) {
        // Handle failed 3DS.
        let rootViewController: UIViewController! = UIApplication.shared.windows.first { $0.isKeyWindow}?.rootViewController
        rootViewController.dismiss(animated: true)

        if let result = currentFlutterResult {
            result(nil)
            currentFlutterResult = nil
        }
    }

}
