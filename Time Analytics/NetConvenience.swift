//
//  NetConvenience.swift
//  Time Analytics
//
//  Time Analytics Network Client convenience methods - Utilizes core network client methods to exchange information with REST APIs.
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import Foundation

extension NetClient {
    
    // Handles Part 2 of Moves Auth Flow. (Part 1 is getting an auth code from the Moves app, which is handled by Login ViewController)
    func loginWithMovesAuthCode(authCode:String, completionHandler: @escaping (_ error: String?) -> Void) {
        
        /* 1. Create and run HTTP request to authenticate the userId and password with Udacity */
        
        let parameters:[String:String] = [NetClient.MovesApi.ParameterKeys.GrantType:NetClient.MovesApi.ParameterValues.GrantType,
                                          NetClient.MovesApi.ParameterKeys.Code:authCode,
                                          NetClient.MovesApi.ParameterKeys.ClientId:NetClient.MovesApi.Constants.ClientId,
                                          NetClient.MovesApi.ParameterKeys.ClientSecret:NetClient.MovesApi.Constants.ClientSecret,
                                          NetClient.MovesApi.ParameterKeys.RedirectUri:NetClient.TimeAnalytics.RedirectUri]
    
        let _ = taskForHTTPMethod(NetClient.Constants.ApiScheme, NetClient.Constants.HttpPost, NetClient.MovesApi.Constants.Host, NetClient.MovesApi.Methods.Auth, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
            
            /* 2. Check for error response from Moves */
            if let error = error {
                self.handleHttpNSError(error,completionHandler)
                return
            }
            
            /* 3. Verify we have received an access token and are logged in */
            
            guard let response = results as? [String:AnyObject], let accessToken = response[NetClient.MovesApi.JSONResponseKeys.AccessToken] as? String, let expiresIn = response[NetClient.MovesApi.JSONResponseKeys.ExpiresIn] as? Int, let refreshToken = response[NetClient.MovesApi.JSONResponseKeys.RefreshToken] as? String, let userId = response[NetClient.MovesApi.JSONResponseKeys.UserId] as? UInt64 else {
                completionHandler("Error creating Moves session")
                return
            }
            
            /* 4. Save all session variables */
            
            self.movesAuthCode = authCode
            self.movesUserId = userId
            self.movesExpiresIn = expiresIn
            self.movesAccessToken = accessToken
            self.movesRefreshToken = refreshToken
            
            /* 5. Complete login with no errors */
            
            completionHandler(nil)
        }
    }
    
    // MARK: Private helper methods

    // Handles NSErrors -- Turns them into user-friendly messages before sending them to the controller's completion handler
    private func handleHttpNSError(_ error:NSError,_ completionHandler: @escaping (_ errorString: String?) -> Void) {

        let errorString = error.userInfo[NSLocalizedDescriptionKey].debugDescription

        if errorString.contains("timed out") {
            completionHandler("Couldn't reach server (timed out)")
        } else if errorString.contains("404"){
            completionHandler("Invalid Moves token")
        } else if errorString.contains("network connection was lost"){
            completionHandler("The network connection was lost")
        } else if errorString.contains("Internet connection appears to be offline") {
            completionHandler("The Internet connection appears to be offline")
        } else {
            completionHandler("Please try again.")
        }
    }
    
    // Substitute a key for the value that is contained within the string
    private func substituteKey(_ string: String, key: String, value: String) -> String? {
        if string.range(of: key) != nil {
            return string.replacingOccurrences(of: key, with: value)
        } else {
            return nil
        }
    }
}
