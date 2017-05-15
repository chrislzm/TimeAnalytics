//
//  NetClient.swift
//  Time Analytics
//
//  Core client methods for Time Analytics
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

class NetClient {
    
    // MARK: Properties
    
    var session = URLSession.shared
    
    // Moves session variables
    var movesAuthCode:String?
    var movesAccessToken:String?
    var movesExpiresIn:Int?
    var movesRefreshToken:String?
    var movesUserId:UInt64?
    
    // MARK: Methods
    
    // Shared HTTP Method for all HTTP requests
    
    func taskForHTTPMethod(_ apiScheme:String, _ httpMethod:String, _ apiHost: String, _ apiMethod: String, apiParameters: [String:String]?, valuesForHTTPHeader: [(String, String)]?, httpBody: String?, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
 
        /* 1. Build the URL */
        let request = NSMutableURLRequest(url: urlFromParameters(apiScheme, apiHost, apiMethod, apiParameters))
        
        /* 2. Configure the request */
        
        request.httpMethod = httpMethod
        
        // Add other HTTP Header fields and values, if any
        if let valuesForHTTPHeader = valuesForHTTPHeader {
            for (value,headerField) in valuesForHTTPHeader {
                request.addValue(value, forHTTPHeaderField: headerField)
            }
        }
        
        // Add http request body, if any
        if let httpBody = httpBody {
            request.httpBody = httpBody.data(using: String.Encoding.utf8)
        }
        
        /* 3. Make the request */

        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a status code from the response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                sendError("Your request did not return a valid response (no status code).")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard statusCode >= 200 && statusCode <= 299  else {
                var errorString = "Your request returned a status code other than 2xx. Status code returned: \(statusCode).\n"
                // If we received some response, also include it in the error message
                if let errorResponse = response {
                    errorString += "Error response receieved: \(errorResponse)\n"
                }
                // If we received some data, also include it in the error message
                if let errorData = data {
                    let (parsedErrorData,_) = self.convertData(errorData)
                    if let validParsedErrorData = parsedErrorData {
                        errorString += "Error data received: \(validParsedErrorData)\n"
                    }
                }
                sendError(errorString)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 4/5. Parse the data and use the data (happens in completion handler) */
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandler)
        }
        
        /* 6. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: Private helper methods
    
    // Creates a URL from parameters
    private func urlFromParameters(_ apiScheme:String, _ host:String, _ method:String, _ parameters: [String:String]?) -> URL {
        
        var components = URLComponents()
        components.scheme = apiScheme
        components.host = host
        components.path = method
        
        if let parameters = parameters {
            components.queryItems = [URLQueryItem]()
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: value)
                components.queryItems!.append(queryItem)
            }
        }
        
        return components.url!
    }
    
    // Converts raw JSON into a usable Foundation object
    private func convertData(_ data: Data) -> (AnyObject?,NSError?) {
        var parsedResult: AnyObject? = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            let error = NSError(domain: "NetClient.convertData", code: 1, userInfo: userInfo)
            return(nil,error)
        }
        
        return(parsedResult,nil)
    }
    
    // Convenience method
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        let (parsedResult,error) = convertData(data)
        guard error == nil else {
            completionHandlerForConvertData(nil, error)
            return
        }
        completionHandlerForConvertData(parsedResult,nil)
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> NetClient {
        struct Singleton {
            static var sharedInstance = NetClient()
        }
        return Singleton.sharedInstance
    }
}
