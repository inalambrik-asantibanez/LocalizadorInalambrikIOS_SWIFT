//
//  ViewControllerUtilities.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/22/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import UIKit
import Foundation

extension UIViewController
{
    //Allows to dismiss the keyboard when taps out of the textfield
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //it shows a message to warn the user of any issue or complete process.
    func showInfo(withTitle: String = "Información del Sistema", withMessage: String,action: (() -> Void)? = nil){
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in action?()}))
            self.present(ac, animated: true)
        }
    }
    
    //It performs UIUpdates
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void)
    {
        DispatchQueue.main.async {
            updates()
        }
    }
}
