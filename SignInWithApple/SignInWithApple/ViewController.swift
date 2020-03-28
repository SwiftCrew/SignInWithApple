//
//  ViewController.swift
//  SignInWithApple
//
//  Created by Mohd Tahir on 28/03/20.
//  Copyright © 2020 Mohd Tahir. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var signInWithApple: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    // Mark: - SignInWithApple
    private func signInApple() {
        AppleAuthHelper.shared.signInWithApple(onView: self.signInWithApple) { (userCredential, error) in
            if let unwrapError = error {
                debugPrint(unwrapError.localizedDescription)
                return
            }
            debugPrint(userCredential?.email ?? "")
            debugPrint(userCredential?.fullName?.description ?? "")
            debugPrint(userCredential?.user ?? "") // It is social id
        }
    }
}

