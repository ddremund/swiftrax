//
//  ServiceCatalog.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

class ServiceCatalog: NSObject
{
    
    init()
    {
        NSLog("init service catalog")
        queue = NSOperationQueue()
        authenticated = false
        JSONResponse = NSDictionary()
        token = AuthToken()
        super.init()
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
        var request = NSMutableURLRequest(URL: endpoint)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: self.queue as NSOperationQueue, completionHandler: {(response, respData, error) in
            NSLog("got data async")
            self.JSONResponse = NSJSONSerialization.JSONObjectWithData(respData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
            self.lastResponse = response
            //self.token = self.catalog!.objectForKey("access").objectForKey("token") as? NSDictionary}
            self.updateToken(self.JSONResponse["access"]!["token"]! as NSDictionary)
            self.authenticated = true}
        )
    }
    
    func updateToken(tokenDict: NSDictionary)
    {
        println(tokenDict)
        token.id = tokenDict["id"]! as String
        token.tenant.id = tokenDict["tenant"]!["id"]! as String
        token.tenant.name = tokenDict["tenant"]!["name"]! as String
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.dateFromString(tokenDict["expires"]! as String)
        {
            token.expiration = date
        }
        /*println(token.id)
        println(token.tenant.id)
        println(token.tenant.name)
        formatter.dateFormat = "yyyy MM dd  HH:mm:ss.SSS"
        println(formatter.stringFromDate(token.expiration))*/
    }
    
    let authEndpoint = NSURL(string: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var lastResponse: NSURLResponse?
    var JSONResponse: NSDictionary
    var token: AuthToken
    var queue: NSOperationQueue
    var authenticated: Bool
    
}

