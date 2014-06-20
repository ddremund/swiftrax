//
//  AuthContect.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation

/** An enum representing the type of credentials in use for an AuthContext */
enum AuthType {
    
    case Password
    case APIKey
}

/** A struct representing an authentication token returned by an auth request to the API */
struct AuthToken {
    
    /** A struct representing the tenant portion of an AuthToken */
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

/** A struct representing an API endpoint including its URL, region name, and tenant ID */
struct Endpoint {
    
    var publicURL: NSURL = NSURL()
    var region: String = ""
    var tenantID: String = ""
    
    init() {}
    
    /**
     Construct a new endpoint given a URL.
    
     @param fromURL The URL of the endpoint.
    */
    init(fromURL URL: String) {
        
        publicURL = NSURL(string: URL)
    }
    
    /**
     Construct a new endpoint given a URL and a region
    
     @param fromURL The URL of the endpoint
     @param withRegion The region of the endpoint
    */
    init(fromURL URL: String, withRegion region: String) {
        publicURL = NSURL(string: URL)
        self.region = region
    }
    
    /** Print an endpoint */
    func print() {
        
        println("Endpoint")
        println("Public URL: \(publicURL.absoluteString)")
        println("Tenant ID: \(tenantID)")
    }
}

/** A struct representing a single service in a ServiceCatalog. */
struct Service {
    
    var name: String = ""
    var type: String = ""
    
    /** Endpoints indexed by region */
    var endpoints: Dictionary<String, Endpoint> = [:] /** Endpoints indexed by region */
    
    /** Print a Service */
    func print() {
        
        println("Service")
        println("Name: \(name)")
        println("Type: \(type)")
        for endpoint in endpoints {
            endpoint.1.print()
        }
    }
}

/** A Dictionary of Services indexed by type */
typealias ServiceCatalog = Dictionary<String, Service>


/**
 A class representing an authenticated API session

 @property authEndpoint The Endpoint used for authentication
 @property defaultAuthEndpoint The default Endpoint for API authenticaiton
 @property user The user used when authenticating
 @property password The password or API key used when authenticating
 @property authenticated Boolean representing success of last auth attempt
 @property JSONResponse Contains JSON body of last auth response
 @property authToken Token from last successful auth attempt
 @property catalog Service Catalog from last successful auth attempt
*/
class AuthContext: NSObject
{
    /** Temporary kludge to account for class vars currently being unsupported */
    class var defaultContext:AuthContext {
        return DefaultAuthContextInstance
    }

    init() {
        super.init()
        NSLog("init auth context")
    }
    
    /**
     Construct a new AuthContext given a set of credentials
    */
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
                newService.endpoints[newEndpoint.region] = newEndpoint
            }
            catalog[newService.type] = newService
        }
        
        return catalog
    }
    
    var authEndpoint = Endpoint()
    let defaultAuthEndpoint = Endpoint(fromURL: "https://identity.api.rackspacecloud.com/v2.0/tokens")
    var user: String = ""
    var password: String = ""
    var authenticated: Bool = false
    
    var JSONResponse = NSDictionary()
    var token = AuthToken()
    var catalog = ServiceCatalog()

    
}

/** Temporary kludge to account for class vars currently being unsupported */
let DefaultAuthContextInstance = AuthContext()

func sendRequestToEndpoint(endpoint: Endpoint, #method: String, #body: String, contentType: String = "application/json", retry: Bool = true, #handler: ((NSData!, NSURLResponse!, NSError!)->Void)!, authContext: AuthContext = AuthContext.defaultContext) {
    
    var request = NSMutableURLRequest(URL: endpoint.publicURL)
    request.HTTPMethod = method
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    
    var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var task = session.dataTaskWithRequest(request, completionHandler: {(responseData, response, error) in
        if let HTTPResponse = response as? NSHTTPURLResponse {
            if HTTPResponse.statusCode == 401 {
                authContext.authenticated = false
                if retry {
                    authContext.reAuthenticate()
                    sendRequestToEndpoint(endpoint, method: method, body: body, contentType: contentType, retry: false, handler: handler)
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
