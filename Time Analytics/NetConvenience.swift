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
            
            /* 3. Verify we have received the data array */
            guard let response = results as? [AnyObject] else {
                completionHandler(nil,"Error retrieving data from Moves")
                return
            }
            
            /* 4. Return the data */
            completionHandler(response,nil)
        }
    }
    
    func parseAndSaveMovesData(_ stories:[AnyObject]) {

        // Setup the date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        
        for story in stories {
            if let segments = story[NetClient.MovesApi.JSONResponseKeys.Segments] as? [AnyObject] {
                for segment in segments {
                    // TODO: Don't force unwrap optionals here
                    let type = segment[NetClient.MovesApi.JSONResponseKeys.Segment.SegmentType] as! String
                    let startTime = dateFormatter.date(from: segment[NetClient.MovesApi.JSONResponseKeys.Segment.StartTime] as! String)!
                    let endTime = dateFormatter.date(from: segment[NetClient.MovesApi.JSONResponseKeys.Segment.EndTime] as! String)!
                    var lastUpdate:Date? = nil
                    if let optionalLastUpdate = segment[NetClient.MovesApi.JSONResponseKeys.Segment.LastUpdate] as? String{
                        lastUpdate = dateFormatter.date(from: optionalLastUpdate)
                    }

                    switch type {
                    case NetClient.MovesApi.JSONResponseValues.Segment.Move:
                        Model.sharedInstance().createMovesMoveObject(startTime, endTime, lastUpdate)

                    case NetClient.MovesApi.JSONResponseValues.Segment.Place:
                        // TODO: Don't force unwrap optionals below
                        let place = segment[NetClient.MovesApi.JSONResponseKeys.Segment.Place] as! [String:AnyObject]
                        let id = place[NetClient.MovesApi.JSONResponseKeys.Place.Id] as? Int64
                        let name = place[NetClient.MovesApi.JSONResponseKeys.Place.Name] as? String
                        let type = place[NetClient.MovesApi.JSONResponseKeys.Place.PlaceType] as! String
                        let facebookPlaceId = place[NetClient.MovesApi.JSONResponseKeys.Place.FacebookPlaceId] as? String
                        let foursquareId = place[NetClient.MovesApi.JSONResponseKeys.Place.FoursquareId] as? String
                        var foursquareCategoryIds:String?
                        if let optionalFoursquareCategoryIds = place[NetClient.MovesApi.JSONResponseKeys.Place.FoursquareCategoryIds] as? [String] {
                            foursquareCategoryIds = String()
                            for fourSquareCategoryId in optionalFoursquareCategoryIds {
                                foursquareCategoryIds?.append(fourSquareCategoryId + ",")
                            }
                        }
                        let coordinates = place[NetClient.MovesApi.JSONResponseKeys.Place.Location] as! [String:Double]
                        let lat = coordinates[NetClient.MovesApi.JSONResponseKeys.Place.Latitude]!
                        let lon = coordinates[NetClient.MovesApi.JSONResponseKeys.Place.Longitude]!
                        
                        Model.sharedInstance().createMovesPlaceObject(startTime, endTime, type, lat, lon, lastUpdate, id, name, facebookPlaceId, foursquareId, foursquareCategoryIds)
                    default:
                        break
                    }
                }
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
    
    // Substitute a key for the value that is contained within the string
    private func substituteKey(_ string: String, key: String, value: String) -> String? {
        if string.range(of: key) != nil {
            return string.replacingOccurrences(of: key, with: value)
        } else {
            return nil
        }
    }
}
