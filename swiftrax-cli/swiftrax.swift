//
//  swiftrax.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

struct AuthToken {
    
    struct _tenant {
        var id: String = ""
        var name: String = ""
    }
    
    var tenant: _tenant = _tenant()
    var id: String = ""
    var expiration = NSDate()
    var authType: String = ""
    
    func print() {
        
        println("Auth Token")
        println("ID: \(id)")
        println("Tenant ID: \(tenant.id)")
        println("Tenant Name: \(tenant.name)")
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd  HH:mm:ss.SSS"
        println("Expiration: \(formatter.stringFromDate(expiration))")
    }
}

func sendRequestAndReAuth(#url: NSURL, #method: String, #body: String, contentType: String = "application/json", retry: Bool = true, handler: (NSURLResponse, NSData, NSError)->Void) {
    
    var request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    NSURLConnection.sendAsynchronousRequest(request, queue: requestQueue, completionHandler:
        {(response, respData, error) in
            if let HTTPResponse = response as? NSHTTPURLResponse {
                if HTTPResponse.statusCode == 401 {
                    if retry {
                        SwiftRAX.auth.reAuthenticate()
                        sendRequestAndReAuth(url: url, method: method, body: body, contentType: contentType, retry: false, handler)
                    }
                    else {
                        println("Failure to re-authenticate")
                    }
                }
                else {
                    handler(response, respData, error)
                }
            }
        }
    )
}

class AuthContext: NSObject
{
    
    class var defaultContext:AuthContext {
        return DefaultAuthContextInstance
    }
    
    init() {
        
        catalog = ServiceCatalog()
    }
    
    let catalog: ServiceCatalog
    
    
}

let DefaultAuthContextInstance = AuthContext()
var requestQueue = NSOperationQueue()
