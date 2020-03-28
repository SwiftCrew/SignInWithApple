//
//  AppleAuthHelper.swift
//  WashOnWheelzz
//
//  Created by Mohd Tahir on 28/03/20.
//  Copyright © 2020 MacBook. All rights reserved.
//

import Foundation
import AuthenticationServices
import CryptoKit

@available(iOS 13.0, *)
class AppleAuthHelper: NSObject {
    static let shared = AppleAuthHelper()
    private override init() {
        super.init()
    }
    private var currentNonce: String?
    @available(iOS 13.0, *)
    typealias AppleSignInCompletion = ((ASAuthorizationAppleIDCredential?, Error?) -> Void)
    var appleSignInCompletion: AppleSignInCompletion?
    /**
    Creates a personalized greeting for a recipient.
    - Parameter onView: Just pass your view object where you want to add Apple Sign In Button Add.
    - Completion: 
     Will give you login user details `ASAuthorizationAppleIDCredential`  and `Error`
    */
    @available(iOS 13.0, *)
    func signInWithApple(onView: UIView, completion: @escaping AppleSignInCompletion) {
          if #available(iOS 13.0, *) {
              appleSignInCompletion = completion
              let signInWithAppleButton = ASAuthorizationAppleIDButton()
              var buttonRect = onView.frame
              buttonRect.origin.x = 0
              buttonRect.origin.y = 0
              signInWithAppleButton.frame = buttonRect
              signInWithAppleButton.addTarget(self, action: #selector(signInWithApplePressed), for: .touchUpInside)
              onView.addSubview(signInWithAppleButton)
          }
      }
    @objc func signInWithApplePressed() {
          if #available(iOS 13.0, *) {
              let nonce = randomNonceString()
              currentNonce = nonce
              let appleIDProvider = ASAuthorizationAppleIDProvider()
              let request = appleIDProvider.createRequest()
              request.requestedScopes = [.fullName, .email]
              request.nonce = self.sha256(nonce)
              let authorizationController = ASAuthorizationController(authorizationRequests: [request])
              authorizationController.delegate = self
              authorizationController.presentationContextProvider = self
              authorizationController.performRequests()
          }
      }
      @available(iOS 13, *)
      private func sha256(_ input: String) -> String {
          let inputData = Data(input.utf8)
          let hashedData = SHA256.hash(data: inputData)
          let hashString = hashedData.compactMap {
              return String(format: "%02x", $0)
          }.joined()
          return hashString
      }
}
@available(iOS 13.0, *)
extension AppleAuthHelper: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                self.appleSignInCompletion?(nil, NSError.init(domain: "apple", code: 1001, userInfo: nil))
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            debugPrint("nonce is: \(nonce)")
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                self.appleSignInCompletion?(nil, NSError.init(domain: "apple", code: 1001, userInfo: nil))
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                self.appleSignInCompletion?(nil, NSError.init(domain: "apple", code: 1001, userInfo: nil))
                return
            }
            debugPrint("idTokenString is: \(idTokenString)")
            //For Firebase use `credential`
            //Just Uncomment credential code
            // for firebase you have to install firebase pod & normal login you don't need to install pod just use socialId
            // socialId = appleIDCredential.user
            // Here Apple `appleIDCredential` (ASAuthorizationAppleIDCredential) will give you login user details
            // You can modify callback according to your requirment
            /*
             let credential = OAuthProvider.credential(
                 withProviderID: "apple.com",
                 idToken: idTokenString,
                 rawNonce: nonce)
             Auth.auth().signIn(with: authCredential) { (_, error) in
                 // Handle error & Parse user
             }
             */
            // Initialize a Firebase credential.
            self.appleSignInCompletion?(appleIDCredential, nil)
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        self.appleSignInCompletion?(nil, error)
        print("Sign in with Apple errored: \(error)")
    }
}
@available(iOS 13.0, *)
extension AppleAuthHelper:
ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Give your window object
        return appDelegate.window ?? UIWindow()
    }
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}
