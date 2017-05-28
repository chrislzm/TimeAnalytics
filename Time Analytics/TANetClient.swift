//
//  NetClient.swift
//  Time Analytics
//
//  Core client methods for Time Analytics. Used by TANetClientConvenience methods to make requests of the Moves REST API.
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

class TANetClient {
    
    // MARK: Properties
    
    var session = URLSession.shared

    // MARK: Session Variables
    
    // A copy of all these session variables are stored in UserDefaults, and loaded by the AppDelegate when the app is opened
    
    // Moves session variables
    var movesAuthCode:String?
    var movesAccessToken:String?
    var movesAccessTokenExpiration:Date?
    var movesRefreshToken:String?
    var movesUserId:UInt64?
    var movesUserFirstDate:String?
    var movesLatestUpdate:Date?
    
    // Internal session variables
    var lastCheckedForNewData:Date?
    
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
            
            /* 4. Attempt to parse the data */
            let (parseResult,error) = self.convertData(data)
            
            /* 5. Send the result to the completion handler */
            completionHandler(parseResult,error)
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
    
    // Attemps to convert raw JSON into a usable Foundation object. Returns an error if unsuccessful.
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
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> TANetClient {
        struct Singleton {
            static var sharedInstance = TANetClient()
        }
        return Singleton.sharedInstance
    }
}
