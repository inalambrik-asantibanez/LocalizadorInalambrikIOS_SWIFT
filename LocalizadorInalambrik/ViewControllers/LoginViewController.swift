//
//  LoginViewController.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit

class LoginViewController: UIViewController
{
    //Declaration of Variables to use the controls
    @IBOutlet weak var buttonActivate: UIView!
    @IBOutlet weak var textAuthorizationCode: UITextField!
    @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginStatusIndicator: UILabel!
    override func viewDidLoad()
    {
        self.hideKeyboardWhenTappedAround()
        self.loginActivityIndicator.stopAnimating()
        updateStatusLabel("")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // -------  VERIFICIÓN DE AUTORIZACIÓN ------
        // Verifico si el Usuario esta autorizado a reportar ubicación con nuestra aplicación.
        let userAuthorized = QueryUtilities.shared().checkUserAuthorization()
    
        // Si está autorizado, entonces quito la pantalla de Login que se pone encima
        if userAuthorized
        {
            print("Usuario autorizado")
            performSegue(withIdentifier: "locationReportSegue", sender: nil)
        }
        else
        {
            print("Usuario no autorizado")
        }
    }
    
    
    @IBAction func actionActivateDevice(_ sender: Any) {
        fetchUserAuthorization()
    }
    
    //It connects to webservice to check if the device is authorized
    private func fetchUserAuthorization()
    {
        loginActivityIndicator.startAnimating()
        self.updateStatusLabel("Verificando activación del Dispositivo...")
        if (textAuthorizationCode.text?.count)! > 0
        {
            Client.shared().sendAuthorization(textAuthorizationCode.text!){
                (userResponse, error) in
                self.performUIUpdatesOnMain {
                    self.loginActivityIndicator.stopAnimating()
                    self.loginStatusIndicator.text = ""
                }
                
                //After calling the webservice and this finished then check if there exist a response
                if let userResponse = userResponse
                {
                    let requestMessage = userResponse.request_message
                    let requestStatus = userResponse.request_status
                    let requestIMEI = userResponse.request_imei
                    
                    /*let requestMessage = ""
                     let requestStatus = 1
                     let requestIMEI = "IOS776Y93WJUQP1"*/
                    
                    print("RequestMessage=",requestMessage)
                    print("requestStatus=",requestStatus)
                    print("requestIMEI=",requestIMEI)
                    
                    if requestStatus == 1
                    {
                        let IMEISaveOnKeyChain = CustomObject()
                        let valueSaveStatus = IMEISaveOnKeyChain.saveDeviceID(inKeychain: requestIMEI)
                        if valueSaveStatus == "1"
                        {
                            print("valuesavestatus=",valueSaveStatus ?? "0")
                            if let user = CoreDataStack.shared().loadUserInformation()
                            {
                                let deviceUID = UIDevice.current.identifierForVendor!.uuidString
                                
                                print("Se va actualizar el usuario")
                                user.setValue("1", forKey: "authorizedDevice")
                                user.setValue(deviceUID, forKey: "deviceIdentifierVendorID")
                                user.setValue(requestIMEI, forKey: "deviceId")
                                CoreDataStack.shared().save()
                                print("Informacion del usuario ha sido actualizada")
                                DispatchQueue.main.async {
                                    print("dispatched to main")
                                    self.performSegue(withIdentifier: "locationReportSegue", sender: nil)
                                }
                            }
                            else
                            {
                                print("No encontró el usuario")
                            }
                        }
                        else
                        {
                            self.showInfo(withMessage: "Error inesperado")
                        }
                    }
                    else
                    {
                        self.showInfo(withMessage: requestMessage)
                    }
                }
            }
        }
        else
        {
            let IMEIGetOnKeyChain = CustomObject()
            let IMEIGetFromKeyChain = IMEIGetOnKeyChain.getGeneratedDeviceIDFromKeychain()
            
            if IMEIGetFromKeyChain != ""
            {
                print("IMEIGetFromKeyChain=",IMEIGetFromKeyChain ?? "")
                if let user = CoreDataStack.shared().loadUserInformation()
                {
                    let deviceUID = UIDevice.current.identifierForVendor!.uuidString
                    print("Se va actualizar el usuario sin enviar codigo de autorizacion")
                    user.setValue("1", forKey: "authorizedDevice")
                    user.setValue(deviceUID, forKey: "deviceIdentifierVendorID")
                    user.setValue(IMEIGetFromKeyChain, forKey: "deviceId")
                    CoreDataStack.shared().save()
                    print("Informacion del usuario ha sido actualizada")
                    DispatchQueue.main.async {
                        print("dispatched to main")
                        self.performSegue(withIdentifier: "locationReportSegue", sender: nil)
                    }
                }
                else
                {
                    print("Error al obtener el usuario")
                }
            }
            else
            {
                print("Error al obtener el IMEI desde el KEYCHAIN")
            }
        }
    }
    
    //it updates the  status of the label
    private func updateStatusLabel(_ text: String) {
        self.performUIUpdatesOnMain {
            self.loginStatusIndicator.adjustsFontSizeToFitWidth = true
            self.loginStatusIndicator.text = text
        }
    }
    
    //Show Location Report ViewController
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "locationReportSegue"
        {
            _ = segue.destination as! LocationReportViewController
        }
    }
    
    
}
