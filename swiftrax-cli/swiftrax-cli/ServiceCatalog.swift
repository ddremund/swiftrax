//
//  ServiceCatalog.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

class ServiceCatalog: NSObject, NSURLConnectionDelegate
{
    
    init()
    {
        super.init()
        NSLog("init service catalog")
    }
    
    init(user: String, password: String)
    {
        super.init()
        NSLog("init service catalog")
        authenticateToEndpoint(authEndpoint, user: user, password: password)
    }
    
    func authenticateWithUser(user: String, password: String)
    {
        authenticateToEndpoint(authEndpoint, user: user, password: password)
    }
    
    func authenticateToEndpoint(endpoint: NSURL, user: String, password: String)
    {
        NSLog("authenticating...")
        let data = "{ \"auth\": { \"passwordCredentials\": {\"username\":\"\(user)\", \"password\":\"\(password)\"}}}"
        NSLog(data)
        var request = NSMutableURLRequest(URL: endpoint)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)

        
        NSLog(NSString(data: request.HTTPBody, encoding: NSUTF8StringEncoding))
        
        
        NSURLConnection.sendAsynchronousRequest(request, queue: self.queue as NSOperationQueue, completionHandler: {(response, respData, error) in
            NSLog("got data async")
            self.JSONResult = NSJSONSerialization.JSONObjectWithData(respData, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
            self.lastResponse = response}
        )
    }
    
    
    let authEndpoint = NSURL(string: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var lastResponse: NSURLResponse?
    var JSONResult: NSDictionary?
    var queue = NSOperationQueue()
}

