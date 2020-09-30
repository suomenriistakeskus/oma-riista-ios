//
//  Environment.swift
//  Riista
//
//  Created by Heikki Hautala on 28.5.2020.
//  Copyright © 2020 Riistakeskus. All rights reserved.
//

import Foundation

enum Env {
    case dev
    case staging
    case production
}

#if DEV
let env = Env.dev
#elseif STAGING
let env = Env.staging
#else
let env = Env.production
#endif

@objcMembers
class Environment: NSObject {

    static var apiHostName: String {
        switch env {
        case .dev:
            return "<add your url here>"
        case .staging:
            return "<add your url here>"
        case .production:
            return "oma.riista.fi"
        }
    }
}
