//
//  AuthContect.swift
//  swiftrax
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may
//  not use this file except in compliance with the License. You may obtain
//  a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
//  License for the specific language governing permissions and limitations
//  under the License.


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
    
    /** Print an AuthToken */
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


/** A struct representing a single service in a ServiceCatalog */
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
 @property credentials The username and password/API key used to authenticate
 @property authenticated Boolean representing success of last auth attempt
 @property authJSONResponse Contains JSON body of last auth response
 @property authToken Token from last successful auth attempt
 @property catalog Service Catalog from last successful auth attempt
 @property HTTPDebug Sets debugging output for HTTP requests
*/
class AuthContext: NSObject
{
    /** Temporary kludge to account for class vars currently being unsupported */
    class var defaultContext:AuthContext {
        return DefaultAuthContextInstance
    }

    override init() {
        super.init()
        NSLog("init auth context")
    }
    
    /**
     Construct a new AuthContext given a set of credentials
    
     @param credentials The username and password/API key used to authenticate
     @param authType The authentication method to use (.Password or .APIKey)
     @param authEndpoint The endpoint to use for authentication; defaults to defaultAuthEndpoint
    */
    convenience init(credentials: (String, String), authType: AuthType = .Password, authEndpoint: Endpoint? = nil) {
        
        NSLog("init service catalog and auth")
        self.init()
        if let endpoint = authEndpoint {
            authenticateToEndpoint(endpoint, credentials: credentials, authType: authType)
        }
        else {
            authenticateWithCredentials(credentials, authType: authType)
        }
    }
    
    /**
     Authenticate to the default endpoint using a set of credentials
    
     @param credentials The username and password/API key used to authenticate
     @param authType The authentication method to use (.Password or .APIKey)
    */
    func authenticateWithCredentials(credentials: (String, String), authType: AuthType) {
        authenticateToEndpoint(defaultAuthEndpoint, credentials: credentials, authType: authType)
    }
    
    /**
     Authenticate to an endpoint
    
     @param endpoint The endpoint to use for authentication
     @param credentials The username and password/API key used to authenticate
     @param authType The authentication method to use (.Password or .APIKey)
    */
    func authenticateToEndpoint(endpoint: Endpoint, credentials: (String, String), authType: AuthType) {
        
        NSLog("authenticating...")
        authEndpoint = endpoint
        self.credentials = credentials
        self.token.authType = authType
        var body: String
        switch authType {
        case .Password: body = "{ \"auth\": { \"passwordCredentials\": {\"username\":\"\(credentials.0)\", \"password\":\"\(credentials.1)\"}}}"
        case .APIKey: body = "{ \"auth\": { \"RAX-KSKEY:apiKeyCredentials\": {\"username\":\"\(credentials.0)\", \"apiKey\":\"\(credentials.1)\"}}}"
        }
        
        sendRequestToEndpoint(endpoint, method: "POST", body: body, contentType: "application/json", retry: false, handler: {(responseData, response, error) in
            NSLog("got data async")
            if let HTTPResponse = response as?  NSHTTPURLResponse {
                if self.HTTPDebug {
                    logHTTPInfo("Debug Log for authenticateToEndpoint Reponse", URL: HTTPResponse.URL, method: "N/A", headers: HTTPResponse.allHeaderFields, status: HTTPResponse.statusCode, data: responseData)
                }
                if HTTPResponse.statusCode == 200 {
                    NSLog("auth successful")
                    self.authJSONResponse = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                    self.updateToken(self.authJSONResponse["access"]!["token"]! as NSDictionary)
                    self.updateCatalog(self.authJSONResponse["access"]!["serviceCatalog"]! as [NSDictionary])
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
        }, authContext: self)
    }
    
    /** Re-authenticate to the previously-used endpoint using the same credentials */
    func reAuthenticate() {
        NSLog("Re-authenticating...")
        authenticateToEndpoint(authEndpoint, credentials: self.credentials, authType: token.authType)
    }

    /**
     Update authentication token with new state from JSON data
    
     @param tokenDict The JSON dictionary data for the authentication token
    */
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

    /**
     Update service catalog with new state from JSON data
    
     @param service The JSON array data for the service catalog
    */
    func updateCatalog(services: [NSDictionary]) -> ServiceCatalog {

        for service in services {
            
            var newService = Service()
            newService.name = service["name"]! as String
            newService.type = service["type"]! as String
            
            for endpoint in service["endpoints"]! as [NSDictionary] {
                
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

    var credentials: (String, String)!
    var authenticated: Bool = false
    
    var authJSONResponse = NSDictionary()
    var token = AuthToken()
    var catalog = ServiceCatalog()
    
    var HTTPDebug = false
    
}

/** Temporary kludge to account for class vars currently being unsupported */
let DefaultAuthContextInstance = AuthContext()


