//
//  LoginViewController.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/21/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

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
    
    override func viewDidAppear(_ animated: Bool)
    {
        if CLLocationManager.locationServicesEnabled()
        {
            DeviceUtilities.shared().printData("Servicios de localizacion activos")
            
            // -------  VERIFICIÓN DE AUTORIZACIÓN ------
            // Verifico si el Usuario esta autorizado a reportar ubicación con nuestra aplicación.
            let userAuthorized = QueryUtilities.shared().checkUserAuthorization()
            
            // Si está autorizado, entonces quito la pantalla de Login que se pone encima
            if userAuthorized
            {
                DeviceUtilities.shared().printData("Usuario autorizado")
                performSegue(withIdentifier: "locationReportSegue", sender: nil)
            }
            else
            {
                DeviceUtilities.shared().printData("Usuario no autorizado")
            }
        }
        else
        {
            DeviceUtilities.shared().printData("Servicios de ubicacion no activos, se muestra warning...")
            performSegue(withIdentifier: "locationPermissionsSegue", sender: nil)
        }
    }
    
    
    @IBAction func actionActivateDevice(_ sender: Any) {
        fetchUserAuthorization()
    }
    
    //It connects to webservice to check if the device is authorized
    private func fetchUserAuthorization()
    {
        //Get the apple push notification id from the DB
        let apple_pn_id = QueryUtilities.shared().getApplePNID()
        
        loginActivityIndicator.startAnimating()
        self.updateStatusLabel("Verificando activación del Dispositivo...")
        Client.shared().sendAuthorization(textAuthorizationCode.text!,apple_pn_id){
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
                
                DeviceUtilities.shared().printData("RequestMessage=\(requestMessage)")
                DeviceUtilities.shared().printData("requestStatus=\(requestStatus)")
                DeviceUtilities.shared().printData("requestIMEI=\(requestIMEI)")
                 
                if requestStatus == 1
                {
                    let IMEISaveOnKeyChain = CustomObject()
                    let valueSaveStatus = IMEISaveOnKeyChain.saveDeviceID(inKeychain: requestIMEI)
                    if valueSaveStatus == "1"
                    {
                        DeviceUtilities.shared().printData("valuesavestatus=\(valueSaveStatus ?? "0")")
                        if let user = CoreDataStack.shared().loadUserInformation()
                        {
                            let deviceUID = UIDevice.current.identifierForVendor!.uuidString
                            
                            DeviceUtilities.shared().printData("Se va actualizar el usuario")
                            user.setValue("1", forKey: "authorizedDevice")
                            user.setValue(deviceUID, forKey: "deviceIdentifierVendorID")
                            user.setValue(requestIMEI, forKey: "deviceId")
                            CoreDataStack.shared().save()
                            DeviceUtilities.shared().printData("Informacion del usuario ha sido actualizada")
                            DispatchQueue.main.async {
                                DeviceUtilities.shared().printData("dispatched to main")
                                self.performSegue(withIdentifier: "locationReportSegue", sender: nil)
                            }
                        }
                        else
                        {
                            DeviceUtilities.shared().printData("No encontró el usuario")
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
            DeviceUtilities.shared().printData("Se muestra el panel de reportes")
                _ = segue.destination as! LocationReportViewController
        }
        else if segue.identifier == "locationPermissionsSegue"
        {
            DeviceUtilities.shared().printData("Se muestra el panel de location warning")
            _ = segue.destination as! LocationPermissionsWarning
        }
    }
}
