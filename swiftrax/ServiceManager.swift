//
//  ServiceManager.swift
//  swiftrax
//
//  Created by Derek Remund on 6/21/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

class ServiceManager: NSObject {
    
    init() {
        
        super.init()
    }
    
    convenience init(endpoint: Endpoint) {
        
        self.init()
        self.endpoint = endpoint
    }
    
    func create() {
        
    }
    
    func head() {
        
    }
    
    func get(id: String) -> BaseResource {
        
        return BaseResource(id: id)
    }
    
    func update(resource: BaseResource) -> BaseResource {
       
        return resource
    }
    
    
    func list() {
        
    }
    
    func delete() {
        
    }
    
    var endpoint: Endpoint!
    
}