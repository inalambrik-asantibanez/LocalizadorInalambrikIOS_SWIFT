//
//  LocationPermissionsWarning.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/28/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation
import UIKit

class LocationPermissionsWarning : UIViewController
{
    
    override func viewDidLoad() {
        DeviceUtilities.shared().printData("Se muestra el panel porque no estan habilitados los permisos")
    }
    
    @IBAction func actionRefreshLocationServices(_ sender: Any) {
        performSegue(withIdentifier: "locationReportPanelSegue", sender: nil)
        
    }
    
    //Show Location Report ViewController
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "locationReportPanelSegue"
        {
            _ = segue.destination as! LocationReportViewController
        }
    }
}
