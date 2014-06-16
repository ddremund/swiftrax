//
//  swiftrax.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

struct AuthToken
{
    struct _tenant
    {
        var id: String = ""
        var name: String = ""
    }
    var tenant: _tenant = _tenant()
    var id: String = ""
    var expiration = NSDate()
    var authType: String = ""
}

class SwiftRAX: NSObject
{
    
    class var auth:ServiceCatalog {
        return ServiceCatalogSharedInstance
    }
    
    init()
    {
        
    }
    
    
}

let ServiceCatalogSharedInstance = ServiceCatalog()
