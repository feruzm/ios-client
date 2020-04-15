//
//  URL.swift
//  Commun
//
//  Created by Chung Tran on 9/18/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

extension URL {
    #if !APPSTORE
    static var appDomain    =   "dev.commun.com"
    #else
    static var appDomain    =   "commun.com"
    #endif
    static var appURL       =   "https://\(appDomain)"
}