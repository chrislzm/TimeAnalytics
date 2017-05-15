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
                let errorString = self.getNiceMessageFromHttpNSError(error)
                completionHandler(errorString)
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
    
    // Retrieves all data from Moves for a given time period (note: for this type of request the Moves API limits to 7 days max per request)
    
    func getMovesDataFrom(_ startDate:Date, _ endDate:Date, _ completionHandler: @escaping (_ response:[AnyObject]?, _ error: String?) -> Void) {
        let formattedStartDate = getFormattedDate(startDate)
        let formattedEndDate = getFormattedDate(endDate)
        
        let parameters:[String:String] = [NetClient.MovesApi.ParameterKeys.AccessToken:movesAccessToken!,
                                          NetClient.MovesApi.ParameterKeys.FromDate:formattedStartDate,
                                          NetClient.MovesApi.ParameterKeys.ToDate:formattedEndDate,
                                          NetClient.MovesApi.ParameterKeys.TrackPoints:NetClient.MovesApi.ParameterValues.True]
        
        let _ = taskForHTTPMethod(NetClient.Constants.ApiScheme, NetClient.Constants.HttpGet, NetClient.MovesApi.Constants.Host, NetClient.MovesApi.Methods.StoryLine, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
            
            /* 2. Check for error response from Moves */
            if let error = error {
                let errorString = self.getNiceMessageFromHttpNSError(error)
                completionHandler(nil, errorString)
                return
            }
            
            /* 3. Verify we have received the data we want */
            
            guard let response = results as? [AnyObject] else {
                completionHandler(nil,"Error retrieving data from Moves")
                return
            }
            
            /* 4. Return the data */
            completionHandler(response,nil)
        }
    }
    
    // MARK: Private helper methods

    // Handles NSErrors -- Turns them into user-friendly messages before sending them to the controller's completion handler
    private func getNiceMessageFromHttpNSError(_ error:NSError) -> String {

        let errorString = error.userInfo[NSLocalizedDescriptionKey].debugDescription
        var userFriendlyErrorString = "Please try again."
        
        if errorString.contains("timed out") {
            userFriendlyErrorString = "Couldn't reach server (timed out)"
        } else if errorString.contains("401"){
            userFriendlyErrorString = "Unauthorized"
        } else if errorString.contains("404"){
            userFriendlyErrorString = "Invalid Moves token"
        } else if errorString.contains("network connection was lost"){
            userFriendlyErrorString = "The network connection was lost"
        } else if errorString.contains("Internet connection appears to be offline") {
            userFriendlyErrorString = "The Internet connection appears to be offline"
        }
        
        return userFriendlyErrorString
    }
    
    private func getFormattedDate(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyMMdd"
        return formatter.string(from: date)
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
