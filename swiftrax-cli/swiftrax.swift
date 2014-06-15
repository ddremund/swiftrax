//
//  swiftrax.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

class SwiftRAX
{
    class var auth:ServiceCatalog {
        return ServiceCatalogSharedInstance
    }
    
    init()
    {
        serviceCatalog = ServiceCatalog()
    }
    
    var serviceCatalog: ServiceCatalog?
}

let ServiceCatalogSharedInstance = ServiceCatalog()
