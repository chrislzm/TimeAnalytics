//
//  NetConstants.swift
//  Time Analytics
//
//  Constants used in the NetClient class
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

extension TANetClient {
    
    struct Constants {
        
        static let ApiScheme = "https"
        static let HttpGet = "GET"
        static let HttpPost = "POST"
        static let HttpPut = "PUT"
        static let HttpDelete = "DELETE"
        
    }

    struct TimeAnalytics {
        static let RedirectUri = "time-analytics://app"
    }
    
    struct MovesApi {
        
        struct Constants {
            static let Host = "api.moves-app.com"
            static let ClientId = "Z0hQuORANlkEb_BmDVu8TntptuUoTv6o"
            static let ClientSecret = "fqKgM1ICYa47DYZfw0PLOtsu473Kyy9E6PHUI5cQzZx5VkgbivTlJE4WlvQn2jZ1"
            static let AccessTokenExpirationBuffer = 60
        }
        
        struct Methods {
            static let Auth = "/oauth/v1/access_token"
            static let UserProfile = "/user/profile"
            static let StoryLine = "/api/1.1/user/storyline/daily"
        }
        
        struct ParameterKeys {
            // For Auth Flow
            static let AccessToken = "access_token"
            static let ClientId = "client_id"
            static let ClientSecret = "client_secret"
            static let Code = "code"
            static let GrantType = "grant_type"
            static let RedirectUri = "redirect_uri"
            static let RefreshToken = "refresh_token"
            
            // For Data Access
            static let FromDate = "from"
            static let ToDate = "to"
            static let TrackPoints = "trackPoints"
            static let UpdatedSince = "updatedSince"
            static let TimeZone = "timeZone"
        }
        
        struct ParameterValues {
            // For Auth Flow
            static let AuthCode = "authorization_code"
            static let RefreshToken = "refresh_token"
            
            // For Data Access
            static let True = "true"
            static let False = "false"
        }
        
        struct JSONResponseKeys {
            // For Auth Flow
            static let AccessToken = "access_token"
            static let TokenType = "token_type"
            static let ExpiresIn = "expires_in"
            static let RefreshToken = "refresh_token"
            static let UserId = "user_id"
            
            // For Data Parsing
            static let Segments = "segments"
            
            // For Data Parsing: Segments
            struct Segment {
                static let EndTime = "endTime"
                static let LastUpdate = "lastUpdate"
                static let Place = "place"
                static let SegmentType = "type"
                static let StartTime = "startTime"
            }
            
            // For Data Parsing: Place
            struct Place {
                static let FacebookPlaceId = "facebookPlaceId"
                static let FoursquareId = "foursquareId"
                static let FoursquareCategoryIds = "foursquareCategoryIds"
                static let Id = "id"
                static let Location = "location"
                static let Longitude = "lon"
                static let Latitude = "lat"
                static let Name = "name"
                static let PlaceType = "type"
            }
            
            // For User Profile
            struct UserProfile {
                static let UserId = "userId"
                static let Profile = "profile"
                static let FirstDate = "firstDate"
                static let CurrentTimeZone = "currentTimeZone"
                static let CurrentTimeZoneId = "id"
                static let CurrentTimeZoneOffset = "offset"
                static let Localization = "localization"
                static let Language = "language"
                static let Locale = "locale"
                static let FirstWeekDay = "firstWeekDay"
                static let Metric = "metric"
                static let CaloriesAvailable = "caloriesAvailable"
                static let Platform = "platform"
            }
        }
        
        struct JSONResponseValues {
            
            // For Data Parsing: Segments
            struct Segment {
                static let Move = "move"
                static let Off = "off"
                static let Place = "place"
            }
        }
    }
}
