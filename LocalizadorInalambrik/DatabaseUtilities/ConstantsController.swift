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
    let REPORT_INTERVAL : Double = 30
    let NUMBER_OF_TRIES = 2
    let BEGIN_REPORT_HOUR = 6
    let END_REPORT_HOUR = 20
    let APP_VERSION = 3.1
    let NUMBER_OF_MAX_PENDING_REPORTS_TO_SEND = 20
    let NUMBER_OF_MAX_SENT_REPORTS_TO_DELETE = 20
    
}
