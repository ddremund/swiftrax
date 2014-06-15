//
//  util.swift
//  swiftrax-cli
//
//  Created by Derek Remund on 6/14/14.
//  Copyright (c) 2014 Derek Remund. All rights reserved.
//

import Foundation


func sendRequestToURL(urlPath: String, #method: String, #data: String, #headers: (String, String)[], #delegate: AnyObject) -> NSURLConnection
{
    let url = NSURL(string: urlPath)
    var request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    for (header, value) in headers
    {
        request.setValue(header, forHTTPHeaderField: value)
    }
    request.HTTPBody = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    print(request)
    var connection = NSURLConnection(request: request, delegate: delegate, startImmediately: true)
    return connection
}

