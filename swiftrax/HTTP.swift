//
//  HTTP.swift
//  swiftrax
//
//  Created by Derek Remund on 6/20/14.
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

/**
 Perform an HTTP request to a URL endpoint, re-authenticating as necessary

 @param endpoint The endpoint to use for authentication
 @param method The HTTP method to use
 @param body The body data for the request
 @param contentType The Content-Type header info for the request
 @param Handler The completion handler for the asynchronous request
 @param retry Whether to retry the request if it fails due to a 401 Unauthorized error
*/
func sendRequestToEndpoint(endpoint: Endpoint, #method: String, #body: String, contentType: String = "application/json", retry: Bool = true, #handler: ((NSData!, NSURLResponse!, NSError!)->Void)!, authContext: AuthContext = AuthContext.defaultContext) {
    
    var request = NSMutableURLRequest(URL: endpoint.publicURL)
    request.HTTPMethod = method
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    
    var session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    if authContext.HTTPDebug {
        logHTTPInfo("Debug Log for authenticateToEndpoint Request", URL: request.URL, method: request.HTTPMethod, headers: request.allHTTPHeaderFields, status: 0, data: request.HTTPBody)
    }
    var task = session.dataTaskWithRequest(request, completionHandler: {(responseData, response, error) in
        if let HTTPResponse = response as? NSHTTPURLResponse {
            if authContext.HTTPDebug {
                logHTTPInfo("Debug Log for sendRequestToEndpoint", URL: HTTPResponse.URL, method: "N/A", headers: HTTPResponse.allHeaderFields, status: HTTPResponse.statusCode, data: responseData)
                
            }
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

/**
 Log info about an HTTP request or response

 @param banner A message to show at the top of the logged info
 @param URL The URL associated with the request/response
 @param method The HTTP method used in the request
 @param headers A dictionary of headers for the request/response
 @param data The data from the request/response
*/
func logHTTPInfo(banner: String, #URL: NSURL, #method: String, #headers: NSDictionary, #status: Int, #data: NSData) {
    
    NSLog("--")
    NSLog(banner)
    NSLog("URL: %@", URL.absoluteString)
    NSLog("Method: %@", method)
    NSLog("Headers: %@", headers)
    NSLog("Status: %i", status)
    NSLog("Data: %@", NSString(data: data, encoding: NSUTF8StringEncoding))
    NSLog("--")
}