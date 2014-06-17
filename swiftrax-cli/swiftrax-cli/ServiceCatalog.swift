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
        println("init service catalog")
        authEndpoint = NSURL()
        queue = NSOperationQueue()
        authenticated = false
        JSONResponse = NSDictionary()
        token = AuthToken()
        user = ""
        password = ""
        super.init()
    }
    
    convenience init(user: String, password: String)
    {
        println("init service catalog and auth")
        self.init()
        authenticateToEndpoint(authEndpoint, user: user, password: password)
    }
    
    
    func authenticateWithUser(user: String, password: String)
    {
        authenticateToEndpoint(defaultAuthEndpoint, user: user, password: password)
    }
    
    func authenticateToEndpoint(endpoint: NSURL, user: String, password: String)
    {
        println("authenticating...")
        authEndpoint = endpoint
        self.user = user
        self.password = password
        let body = "{ \"auth\": { \"passwordCredentials\": {\"username\":\"\(user)\", \"password\":\"\(password)\"}}}"
        var request = NSMutableURLRequest(URL: endpoint)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: self.queue as NSOperationQueue, completionHandler: {(response, respData, error) in
            println("got data async")
            if let HTTPResponse = response as? NSHTTPURLResponse
            {
                self.lastResponse = response
                if HTTPResponse.statusCode == 200
                {
                    println("auth successful")
                    self.JSONResponse = NSJSONSerialization.JSONObjectWithData(respData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    self.updateToken(self.JSONResponse["access"]!["token"]! as NSDictionary)
                    self.authenticated = true
                }
                else
                {
                    print("Bad auth response code:")
                    println(HTTPResponse.statusCode)
                }
            }
            if let responseError = error
            {
                NSLog(responseError.localizedDescription)
            }}
        )
    }
    
    func reAuthenticate()
    {
        println("Re-authenticating...")
        authenticateToEndpoint(authEndpoint, user: user, password: password)
    }
    
    func updateToken(tokenDict: NSDictionary) -> AuthToken
    {
        println("updating token...")
        token.id = tokenDict["id"]! as String
        token.tenant.id = tokenDict["tenant"]!["id"]! as String
        token.tenant.name = tokenDict["tenant"]!["name"]! as String
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.dateFromString(tokenDict["expires"]! as String)
        {
            token.expiration = date
        }
        return token
    }
    
    
    var authEndpoint: NSURL
    let defaultAuthEndpoint = NSURL(string: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var lastResponse: NSURLResponse?
    var JSONResponse: NSDictionary
    var token: AuthToken
    var queue: NSOperationQueue
    var authenticated: Bool
    var user: String
    var password: String
    
}

