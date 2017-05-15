//
//  NetConstants.swift
//  Time Analytics
//
//  Constants used in the NetClient class
//
//  Created by Chris Leung on 5/14/17.
//  Copyright © 2017 Chris Leung. All rights reserved.
//

extension NetClient {
    
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
        }
        
        struct Methods {
            static let Auth = "/oauth/v1/access_token"
        }
        
        struct ParameterKeys {
            static let GrantType = "grant_type"
            static let Code = "code"
            static let ClientId = "client_id"
            static let ClientSecret = "client_secret"
            static let RedirectUri = "redirect_uri"
        }
        
        struct ParameterValues {
            static let GrantType = "authorization_code"
        }
        
        struct JSONResponseKeys {
            static let AccessToken = "access_token"
            static let TokenType = "token_type"
            static let ExpiresIn = "expires_in"
            static let RefreshToken = "refresh_token"
            static let UserId = "user_id"
        }
    }
}
