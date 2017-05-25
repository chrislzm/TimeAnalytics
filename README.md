![Time Analytics Logo](/Time%20Analytics/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png?raw=true "Time Analytics Logo")

Time Analytics
==============

By Chris Leung

Installation
------------
1. First install the [Moves app](https://moves-app.com/) and create an account
2. Obtain [Moves API ClientId and ClientSecret](https://dev.moves-app.com/apps) values
3. Open "Time Analytics.xcworkspace"
4. Update Moves API values in "TANetConstants.swift": TANetClient.MovesApi.ClientId and ClientSecret
5. Compile and run

Developed and tested with XCode 8+ and iOS 10+.

Optional Settings
-----------------
OAuth access token expiration time buffer - Default is 60 seconds. Change this value in "TANetConstants.swift": TANetClient.MovesApi.AccessTokenExpirationBuffer

If the user makes a network request within the time buffer (default: 60 seconds) of the expiration time, we will first attempt to get a new token before making our network request

How to Use
----------
Basic requirements: Internet connection, Moves App

* Open the app and follow prompts to login with moves
* Optionally allow access to Health Data
* Once Health Data import is complete, tap "Continue" go enter the app
* Tap on the lower left "Commutes" button to toggle through the three main views: Places, Commutes, Activities
* Tap on any item to view detailed information about it
* Tapping on some items in detail views will allow you to view that item's detailed information
* To log out and clear all data, on any main view, tap "Settings" and then "Log Out"

Data Assumptions
----------------
Because Moves data can contain gaps, Time Analytics interpolates the data using these assumptions:

* The startTime for the first place segment that begins after a move segment M is equal to the endTime of M
* The endTime for the last place segment that end before a move segment M is equal to the startTime of M
* Given two places P1 and P2, the startTime and endTime of a commute between P1 and P2 is equal to the startTime of P2 minus the endTime of P1
* A commute only exists between P1 and P2 when there are no other place segments between them
* Move segments that begin and end at the same place are ignored
* We are still located at a place for the place segment with the most recent endTime 

Developer Notes
---------------
* Under active development
* Data refresh uses's' Moves API "lastUpdate" (optional) value to request new data updated since then. So far, I have not seen any Moves Storyline data that does not contain this value. If this value disappears in the future, however, then the refresh process will take longer than needed -- it will continue to request data from either the last "lastUpdate" value ever received or if that value never existed in a user's data, then will request data from Moves user's first date on each refresh.

Issues
------
* No such module 'Charts': This is a known issue with Charts. To resolve, compile the project, and the error message should disappear. (May require Xcode restart.)

Credits
------
* Uses [Charts 3.0.2](https://github.com/danielgindi/Charts)

Questions
---------
* Create new issues on [GitHub repo](https://github.com/chrislzm/TimeAnalytics/issues) for any bugs found.
* Contact [Chris Leung](https://github.com/chrislzm)
