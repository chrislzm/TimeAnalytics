//
//  NetConvenience.swift
//  Time Analytics
//
//  Time Analytics Network Client convenience methods - Utilizes core network client methods to exchange information with the Moves REST API. This class is used by TAModel for Moves data and by TALoginViewController for auth flow.
//
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
        let app = UIApplication.shared
        // Try to open the Moves app, if we have it installed
        if app.canOpenURL(moveUrl!) {
            app.open(moveUrl!, options: [:]) { (result) in
            }
        // Else try to open the App Store app page for moves
        } else if let url = URL(string: "itms-apps://itunes.apple.com/app/id509204969"), app.canOpenURL(url){
            app.open(url, options: [:], completionHandler: nil)
        // Else open moves app page website
        } else {
            app.open(URL(string: "https://moves-app.com")!,options: [:],completionHandler: nil)
        }
    }
    
    // Handles Part 2 of Moves Auth Flow: Use the auth code to get OAuth access and refresh tokens
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
    
    // Part 2 of Moves Auth Flow continued
    
    func movesAuthResponseHandler(_ results:AnyObject?, _ error:NSError?,_ completionHandler: @escaping (_ error: String?) -> Void) {
        
        /* 1. Check for error response from Moves */
        guard error == nil else {
            let errorString = self.getNiceMessageFromHttpNSError(error!)
            completionHandler(errorString)
            return
        }
        
        /* 2. Verify we have received an access token and are logged in */
        
        guard let response = results as? [String:AnyObject], let accessToken = response[TANetClient.MovesApi.JSONResponseKeys.AccessToken] as? String, let expiresIn = response[TANetClient.MovesApi.JSONResponseKeys.ExpiresIn] as? Int, let refreshToken = response[TANetClient.MovesApi.JSONResponseKeys.RefreshToken] as? String, let userId = response[TANetClient.MovesApi.JSONResponseKeys.UserId] as? UInt64 else {
            completionHandler("Error creating Moves session")
            return
        }
        
        /* 4. Save retrieved session variables */
        
        // Calculate expiration time of the access token
        var accessTokenExpiration = Date()
        accessTokenExpiration.addTimeInterval(TimeInterval(expiresIn - TANetClient.MovesApi.Constants.AccessTokenExpirationBuffer))
        
        self.movesUserId = userId
        self.movesAccessTokenExpiration = accessTokenExpiration
        self.movesAccessToken = accessToken
        self.movesRefreshToken = refreshToken

        /* 5. Now retrieve user's first date so we'll know how to download all his/her data later */
        getMovesUserFirstDate() { (userFirstDate,error) in
            
            guard error == nil else {
                completionHandler(error!)
                return
            }
            
            self.movesUserFirstDate = userFirstDate!

            /* 6. Save all session info to user defaults for persistence */
            TAModel.sharedInstance().saveMovesLoginInfo(self.movesAuthCode!, userId, accessToken, accessTokenExpiration, refreshToken, userFirstDate!)
            
            /* 7. Complete login with no errors */
            
            completionHandler(nil)
        }
        
    }

    // Ensures our session is authorized before we make any calls to the Moves API, otherwise send an error

    func verifyLoggedIntoMoves(completionHandler: @escaping (_ error: String?) -> Void) {
        
        // Check: Are we logged in?
        guard movesAccessTokenExpiration != nil else {
            completionHandler("Error: Not logged into Moves")
            return
        }
        
        // Check: Has our session expired?
        if Date() > movesAccessTokenExpiration! {

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
        
        // Our session hasn't expired -- return with no error
        completionHandler(nil)
    }
    
    // Retrieves Moves StoryLne data for a given time period
    
    func getMovesDataFrom(_ startDate:Date, _ endDate:Date,_ lastUpdate:Date?, _ completionHandler: @escaping (_ response:[AnyObject]?, _ error: String?) -> Void) {
        
        verifyLoggedIntoMoves() { (error) in
            
            guard error == nil else {
                completionHandler(nil,error!)
                return
            }
            
            let formattedStartDate = self.getFormattedDate(startDate)
            let formattedEndDate = self.getFormattedDate(endDate)
            
            var parameters:[String:String] = [TANetClient.MovesApi.ParameterKeys.AccessToken:self.movesAccessToken!,
                                              TANetClient.MovesApi.ParameterKeys.FromDate:formattedStartDate,
                                              TANetClient.MovesApi.ParameterKeys.ToDate:formattedEndDate,
                                              TANetClient.MovesApi.ParameterKeys.TrackPoints:TANetClient.MovesApi.ParameterValues.False]
            if let lastUpdate = lastUpdate {
                parameters[TANetClient.MovesApi.ParameterKeys.UpdatedSince] = self.getFormattedDateISO8601Date(lastUpdate)
            }
            
            let _ = self.taskForHTTPMethod(TANetClient.Constants.ApiScheme, TANetClient.Constants.HttpGet, TANetClient.MovesApi.Constants.Host, TANetClient.MovesApi.Methods.StoryLine, apiParameters: parameters, valuesForHTTPHeader: nil, httpBody: nil) { (results,error) in
                
                /* 2. Check for error response from Moves */
                guard error == nil else {
                    let errorString = self.getNiceMessageFromHttpNSError(error!)
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

    // Retrieves the Moves user's first data date from his profile
    
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
                guard error == nil else {
                    let errorString = self.getNiceMessageFromHttpNSError(error!)
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
    
    private func getFormattedDateISO8601Date(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter.string(from: date)
    }
}
