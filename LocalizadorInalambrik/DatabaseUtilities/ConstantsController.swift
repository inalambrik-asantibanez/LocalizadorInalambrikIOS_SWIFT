//
//  ConstantsController.swift
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/29/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

import Foundation

class ConstantsController
{
    init()
    {
    }
    
    //To control different behaviour of the app
    let HTTP_SECURE = false
    let PRODUCTION_MODE = true
    let INITIAL_INTERVAL: Double = 10
    let REPORT_INTERVAL : Double = 60
    let NUMBER_OF_TRIES = 2
    let BEGIN_REPORT_HOUR = 6
    let END_REPORT_HOUR = 23
}
