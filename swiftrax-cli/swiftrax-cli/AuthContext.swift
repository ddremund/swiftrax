//
//  AuthContect.swift
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

func sendRequestAndReAuth(#url: NSURL, #method: String, #body: String, contentType: String = "application/json", retry: Bool = true, handler: (NSURLResponse, NSData, NSError)->Void, authContext: AuthContext = AuthContext.defaultContext) {
    
    var request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    NSURLConnection.sendAsynchronousRequest(request, queue: authContext.requestQueue, completionHandler:
        {(response, respData, error) in
            if let HTTPResponse = response as? NSHTTPURLResponse {
                if HTTPResponse.statusCode == 401 {
                    if retry {
                        authContext.reAuthenticate()
                        sendRequestAndReAuth(url: url, method: method, body: body, contentType: contentType, retry: false, handler)
                    }
                    else {
                        NSLog("Failure to re-authenticate")
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
        
        NSLog("init auth context")
        authEndpoint = NSURL()
        requestQueue = NSOperationQueue()
        authenticated = false
        JSONResponse = NSDictionary()
        token = AuthToken()
        user = ""
        password = ""
        catalog = ServiceCatalog()
    }
    
    convenience init(user: String, password: String, authEndpoint: NSURL? = nil) {
        
        NSLog("init service catalog and auth")
        self.init()
        if let endpoint = authEndpoint {
            authenticateToEndpoint(endpoint, user: user, password: password)
        }
        else {
            authenticateWithUser(user, password: password)
        }
    }
    
    
    func authenticateWithUser(user: String, password: String) {
        authenticateToEndpoint(defaultAuthEndpoint, user: user, password: password)
    }
    
    func authenticateToEndpoint(endpoint: NSURL, user: String, password: String) {
        
        NSLog("authenticating...")
        authEndpoint = endpoint
        self.user = user
        self.password = password
        let body = "{ \"auth\": { \"passwordCredentials\": {\"username\":\"\(user)\", \"password\":\"\(password)\"}}}"
        var request = NSMutableURLRequest(URL: endpoint)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: self.requestQueue as NSOperationQueue, completionHandler: {(response, responseData, error) in
            println("got data async")
            if let HTTPResponse = response as? NSHTTPURLResponse {
                self.lastResponse = response
                if HTTPResponse.statusCode == 200 {
                    println("auth successful")
                    self.JSONResponse = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    self.updateToken(self.JSONResponse["access"]!["token"]! as NSDictionary)
                    self.authenticated = true
                }
                else {
                    NSLog("Bad auth response code: %d", HTTPResponse.statusCode)
                    println(self.JSONResponse)
                }
            }
            if let responseError = error {
                NSLog("Error in response")
                NSLog(responseError.localizedDescription)
            }
        })
    }
    
    func reAuthenticate() {
        NSLog("Re-authenticating...")
        authenticateToEndpoint(authEndpoint, user: user, password: password)
    }
    
    func updateToken(tokenDict: NSDictionary) -> AuthToken {
        
        NSLog("updating token...")
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
    var user: String
    var password: String
    var authenticated: Bool
    
    var lastResponse: NSURLResponse?
    var JSONResponse: NSDictionary
    var token: AuthToken
    let catalog: ServiceCatalog
    
    var requestQueue: NSOperationQueue
    
}

let DefaultAuthContextInstance = AuthContext()
