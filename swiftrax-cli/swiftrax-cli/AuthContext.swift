//
//  AuthContect.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

enum AuthType {
    
    case Password
    case APIKey
}


struct AuthToken {
    
    struct _tenant {
        var id: String = ""
        var name: String = ""
    }
    
    var tenant: _tenant = _tenant()
    var id: String = ""
    var expiration = NSDate()
    var authType: AuthType = .Password
    
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

struct Endpoint {
    
    var publicURL: NSURL = NSURL()
    var region: String = ""
    var tenantID: String = ""
    
    init() {}
    init(fromURL URL: String) {
        
        publicURL = NSURL(string: URL)
    }
    
    func print() {
        
        println("Endpoint")
        println("Public URL: \(publicURL.absoluteString)")
        println("Tenant ID: \(tenantID)")
    }
}

struct Service {
    
    var name: String = ""
    var type: String = ""
    var endpoints: Endpoint[] = []
    
    func print() {
        
        println("Service")
        println("Name: \(name)")
        println("Type: \(type)")
        for endpoint in endpoints {
            endpoint.print()
        }
    }
}

typealias ServiceCatalog = Service[]



class AuthContext: NSObject
{
    
    class var defaultContext:AuthContext {
        return DefaultAuthContextInstance
    }
    
    init() {
        super.init()
        NSLog("init auth context")
    }
    
    convenience init(user: String, password: String, authType: AuthType = .Password, authEndpoint: Endpoint? = nil) {
        
        NSLog("init service catalog and auth")
        self.init()
        if let endpoint = authEndpoint {
            authenticateToEndpoint(endpoint, user: user, password: password, authType: authType)
        }
        else {
            authenticateWithUser(user, password: password, authType: authType)
        }
    }
    
    
    func authenticateWithUser(user: String, password: String, authType: AuthType) {
        authenticateToEndpoint(defaultAuthEndpoint, user: user, password: password, authType: authType)
    }
    
    func authenticateToEndpoint(endpoint: Endpoint, user: String, password: String, authType: AuthType) {
        
        NSLog("authenticating...")
        authEndpoint = endpoint
        self.user = user
        self.password = password
        self.token.authType = authType
        var body: String
        switch authType {
        case .Password: body = "{ \"auth\": { \"passwordCredentials\": {\"username\":\"\(user)\", \"password\":\"\(password)\"}}}"
        case .APIKey: body = "{ \"auth\": { \"RAX-KSKEY:apiKeyCredentials\": {\"username\":\"\(user)\", \"apiKey\":\"\(password)\"}}}"
        }
        var request = NSMutableURLRequest(URL: endpoint.publicURL)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        var authTask = session.dataTaskWithRequest(request, completionHandler: {(responseData, response, error) in
            NSLog("got data async")
            if let HTTPResponse = response as?  NSHTTPURLResponse {
                self.lastResponse = response
                if HTTPResponse.statusCode == 200 {
                    NSLog("auth successful")
                    self.JSONResponse = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    self.updateToken(self.JSONResponse["access"]!["token"]! as NSDictionary)
                    self.updateCatalog(self.JSONResponse["access"]!["serviceCatalog"]! as NSDictionary[])
                    self.authenticated = true
                }
                else {
                    NSLog("Bad auth response code: %d", HTTPResponse.statusCode)
                    NSLog(NSHTTPURLResponse.localizedStringForStatusCode(HTTPResponse.statusCode))
                    self.authenticated = false
                }
            }
            if let responseError = error {
                NSLog("Error in response")
                NSLog(responseError.localizedDescription)
                self.authenticated = false
            }
        })
        authTask.resume()
    }
    
    func reAuthenticate() {
        NSLog("Re-authenticating...")
        authenticateToEndpoint(authEndpoint, user: user, password: password, authType: token.authType)
    }
    
    func updateToken(tokenDict: NSDictionary) -> AuthToken {
        
        NSLog("updating token...")
        token.id = tokenDict["id"]! as String
        token.tenant.id = tokenDict["tenant"]!["id"]! as String
        token.tenant.name = tokenDict["tenant"]!["name"]! as String
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = formatter.dateFromString(tokenDict["expires"]! as String) {
            token.expiration = date
        }
        return token
    }

    func updateCatalog(services: NSDictionary[]) -> ServiceCatalog {

        for service in services {
            
            var newService = Service()
            newService.name = service["name"]! as String
            newService.type = service["type"]! as String
            
            for endpoint in service["endpoints"]! as NSDictionary[]{
                
                var newEndpoint = Endpoint(fromURL: endpoint["publicURL"]! as String)
                if let region = endpoint["region"] as? String {
                    newEndpoint.region = region
                }
                newEndpoint.tenantID = endpoint["tenantId"]! as String
                newService.endpoints.append(newEndpoint)
            }
            catalog.append(newService)
        }
        
        return catalog
    }
    
    
    var authEndpoint = Endpoint()
    let defaultAuthEndpoint = Endpoint(fromURL: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var user: String = ""
    var password: String = ""
    var authenticated: Bool = false
    
    var lastResponse: NSURLResponse?
    var JSONResponse = NSDictionary()
    var token = AuthToken()
    var catalog = ServiceCatalog()

    
}

let DefaultAuthContextInstance = AuthContext()

func sendRequestAndReAuth(#url: NSURL, #method: String, #body: String, contentType: String = "application/json", retry: Bool = true, handler: (NSData, NSURLResponse, NSError)->Void, authContext: AuthContext = AuthContext.defaultContext) {
    
    var request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    
    var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var task = session.dataTaskWithRequest(request, completionHandler: {(responseData, response, error) in
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
                handler(responseData, response, error)
            }
        }
        })
    task.resume()
}
