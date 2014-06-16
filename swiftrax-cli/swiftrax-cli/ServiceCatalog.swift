//
//  ServiceCatalog.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

class ServiceCatalog
{
    
    init()
    {
        NSLog("init service catalog")
        queue = NSOperationQueue()
        authenticated = false
        catalog = NSDictionary()
        token = AuthToken()
    }
    
    convenience init(user: String, password: String)
    {
        NSLog("init service catalog and auth")
        self.init()
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
            self.catalog = NSJSONSerialization.JSONObjectWithData(respData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
            self.lastResponse = response
            //self.token = self.catalog!.objectForKey("access").objectForKey("token") as? NSDictionary}
            //self.updateToken(self.catalog["access"]["token"] as NSDictionary)
            self.authenticated = true}
        )
    }
    
    /*func updateToken(tokenDict: NSDictionary)
    {
        token.id = tokenDict["id"] as String
        token.tenant.name = tokenDict["tenant"]["id"] as String
        token.tenant.id = tokenDict["tenant"]["name"] as String
    }*/
    
    let authEndpoint = NSURL(string: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var lastResponse: NSURLResponse?
    var catalog: NSDictionary
    var token: AuthToken
    var queue: NSOperationQueue
    var authenticated: Bool
    
}

