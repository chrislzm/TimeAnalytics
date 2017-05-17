//
//  NetConvenience.swift
//  Time Analytics
//
//  Time Analytics Network Client convenience methods - Utilizes core network client methods to exchange information with REST APIs.
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import CoreData
import Foundation
import UIKit

extension TANetClient {
    
    // Handles Part 1 of Moves Auth Flow: Getting an auth code from the Moves app
    func obtainMovesAuthCode() {
        let moveHook = "moves://app/authorize?" + "client_id=Z0hQuORANlkEb_BmDVu8TntptuUoTv6o&redirect_uri=time-analytics://app&scope=activity location".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let moveUrl = URL(string: moveHook)
        print(moveUrl!.absoluteString)
        if UIApplication.shared.canOpenURL(moveUrl!)
        {
            UIApplication.shared.open(moveUrl!, options: [:]) { (result) in
                print("Success")
            }
        } else {
            print("That didn't work")
        }
    }
    
    // Handles Part 2 of Moves Auth Flow. (Part 1 is getting an auth code from the Moves app, which is handled by Login ViewController)
    func loginWithMovesAuthCode(authCode:String, completionHandler: @escaping (_ error: String?) -> Void) {
        
        // 1. Save the auth code to our client
        self.movesAuthCode = authCode

        /* 2. Create and run HTTP request to authenticate the userId and password with Udacity */
        
        let parameters:[String:String] = [TANetClient.MovesApi.ParameterKeys.GrantType:TANetClient.MovesApi.ParameterValues.AuthCode,
                                          TANetClient.MovesApi.ParameterKeys.Code:authCode,
                                          TANetClient.MovesApi.ParameterKeys.ClientId:TANetClient.MovesApi.Constants.ClientId,
                                          TANetClient.MovesApi.ParameterKeys.ClientSecret:TANetClient.MovesApi.Constants.ClientSecret,
                                          TANetClient.MovesApi.ParameterKeys.RedirectUri:TANetClient.TimeAnalytics.RedirectUri]
    
        let _ = taskForHTTPMethod(TANetClient.Constants.ApiScheme, TANetClient.Constants.HttpPost, TANetClient.MovesApi.Constants.Host, TANetClient.MovesApi.Methods.Auth, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
            
            /* 3. Send response to auth response handler */
            self.movesAuthResponseHandler(results,error,completionHandler)
        }
    }
    
    func movesAuthResponseHandler(_ results:AnyObject?, _ error:NSError?,_ completionHandler: @escaping (_ error: String?) -> Void) {
        
        /* 1. Check for error response from Moves */
        if let error = error {
            let errorString = self.getNiceMessageFromHttpNSError(error)
            completionHandler(errorString)
            return
        }
        
        /* 2. Verify we have received an access token and are logged in */
        
        guard let response = results as? [String:AnyObject], let accessToken = response[TANetClient.MovesApi.JSONResponseKeys.AccessToken] as? String, let expiresIn = response[TANetClient.MovesApi.JSONResponseKeys.ExpiresIn] as? Int, let refreshToken = response[TANetClient.MovesApi.JSONResponseKeys.RefreshToken] as? String, let userId = response[TANetClient.MovesApi.JSONResponseKeys.UserId] as? UInt64 else {
            completionHandler("Error creating Moves session")
            return
        }
        
        /* 3. Retrieve user's first date so we'll know how to download all his/her data later */
        getMovesUserFirstDate() { (userFirstDate,error) in
            
            guard error == nil else {
                completionHandler(error!)
                return
            }
            
            /* 4. Save all session variables */
            
            // Calculate expiration time of the access token
            var accessTokenExpiration = Date()
            accessTokenExpiration.addTimeInterval(TimeInterval(expiresIn - TANetClient.MovesApi.Constants.AccessTokenExpirationBuffer))
            
            self.movesUserId = userId
            self.movesAccessTokenExpiration = accessTokenExpiration
            self.movesAccessToken = accessToken
            self.movesRefreshToken = refreshToken
            self.movesUserFirstDate = userFirstDate!
            
            TAModel.sharedInstance().saveMovesLoginInfo(movesAuthCode!, userId, accessToken, accessTokenExpiration, refreshToken, userFirstDate)
            
            /* 5. Complete login with no errors */
            
            completionHandler(nil)
        }
        
    }


    // Attemps to ensure our session is authorized before we make any calls to the Moves API
    func verifyLoggedIntoMoves(completionHandler: @escaping (_ error: String?) -> Void) {
        
        // Check: Are we logged in?
        guard movesAccessTokenExpiration != nil else {
            completionHandler("Error: Not logged into Moves")
            return
        }
        
        // Check: Has our session expired?
        if Date() > movesAccessTokenExpiration! {

            print("authorizeMovesSession: Our Moves session expired. Refreshing.")

            // Attempt to refresh our session
            /* 1. Create and run HTTP request to authenticate the userId and password with Udacity */
            
            let parameters:[String:String] = [TANetClient.MovesApi.ParameterKeys.GrantType:TANetClient.MovesApi.ParameterValues.RefreshToken,
                                              TANetClient.MovesApi.ParameterKeys.RefreshToken:movesRefreshToken!,
                                              TANetClient.MovesApi.ParameterKeys.ClientId:TANetClient.MovesApi.Constants.ClientId,
                                              TANetClient.MovesApi.ParameterKeys.ClientSecret:TANetClient.MovesApi.Constants.ClientSecret]
            
            let _ = taskForHTTPMethod(TANetClient.Constants.ApiScheme, TANetClient.Constants.HttpPost, TANetClient.MovesApi.Constants.Host, TANetClient.MovesApi.Methods.Auth, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
                
                self.movesAuthResponseHandler(results,error,completionHandler)
            }
        }
        
        print("authorizeMovesSession: Our Moves session has not expired. Authorized.")
        // Our session hasn't expired -- return with no error
        completionHandler(nil)
    }
    
    // Retrieves all data from Moves for a given time period (note: for this type of request the Moves API limits to 7 days max per request)
    
    func getMovesDataFrom(_ startDate:Date, _ endDate:Date, _ completionHandler: @escaping (_ response:[AnyObject]?, _ error: String?) -> Void) {
        
        verifyLoggedIntoMoves() { (error) in
            
            guard error == nil else {
                completionHandler(nil,error!)
                return
            }
            
            let formattedStartDate = self.getFormattedDate(startDate)
            let formattedEndDate = self.getFormattedDate(endDate)
            
            let parameters:[String:String] = [TANetClient.MovesApi.ParameterKeys.AccessToken:self.movesAccessToken!,
                                              TANetClient.MovesApi.ParameterKeys.FromDate:formattedStartDate,
                                              TANetClient.MovesApi.ParameterKeys.ToDate:formattedEndDate,
                                              TANetClient.MovesApi.ParameterKeys.TrackPoints:TANetClient.MovesApi.ParameterValues.False]
            
            let _ = self.taskForHTTPMethod(TANetClient.Constants.ApiScheme, TANetClient.Constants.HttpGet, TANetClient.MovesApi.Constants.Host, TANetClient.MovesApi.Methods.StoryLine, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
                
                /* 2. Check for error response from Moves */
                if let error = error {
                    let errorString = self.getNiceMessageFromHttpNSError(error)
                    completionHandler(nil, errorString)
                    return
                }
                
                /* 3. Verify we have received the data array */
                guard let response = results as? [AnyObject] else {
                    completionHandler(nil,"Error retrieving data from Moves")
                    return
                }
                
                /* 4. Return the data */
                completionHandler(response,nil)
            }
        }
    }

    // Retrieves the user's first date from his profile
    func getMovesUserFirstDate(completionHandler: @escaping (_ date:String?, _ error: String?) -> Void) {
        getMovesUserProfile() { (response,error) in
            guard error == nil else {
                completionHandler(nil,error!)
                return
            }
            guard let profile = response?[TANetClient.MovesApi.JSONResponseKeys.UserProfile.Profile] as? [String:AnyObject], let firstDate = profile[TANetClient.MovesApi.JSONResponseKeys.UserProfile.FirstDate] as? String else {
                completionHandler(nil,"Unable to parse user profile data")
                return
            }
            completionHandler(firstDate,nil)
        }
    }
    
    
    // Retrieves user profile data
    
    func getMovesUserProfile(completionHandler: @escaping (_ response:[String:AnyObject]?, _ error: String?) -> Void) {
        verifyLoggedIntoMoves() { (error) in
            guard error == nil else {
                completionHandler(nil,error!)
                return
            }
            /* 1. Create and run HTTP request to get user profile */
            let parameters:[String:String] = [TANetClient.MovesApi.ParameterKeys.AccessToken:self.movesAccessToken!]

            let _ = self.taskForHTTPMethod(TANetClient.Constants.ApiScheme, TANetClient.Constants.HttpGet, TANetClient.MovesApi.Constants.Host, TANetClient.MovesApi.Methods.UserProfile, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
                
                /* 2. Check for error response from Moves */
                if let error = error {
                    let errorString = self.getNiceMessageFromHttpNSError(error)
                    completionHandler(nil,errorString)
                    return
                }
                
                /* 3. Verify we have received the array of data*/
                
                guard let response = results as? [String:AnyObject] else {
                    completionHandler(nil,"Error retrieving user profile")
                    return
                }
                
                /* 4. Return the response */
                completionHandler(response,nil)
            }

        }
    }
    
    // Downloads all moves data for the user from the beginning of time
    
    func downloadAllMovesUserData(_ completionHandler: @escaping (_ response:[AnyObject]?, _ error: String?) -> Void)  {
        
        // For every set of 31 days from the first user date to present
        
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
