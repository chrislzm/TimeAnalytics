![Time Analytics Logo](/blob/master/Time%20Analytics/Assets.xcassets/AppIcon.appiconset/Icon-60%403x.png "Time Analytics Logo")

Time Analytics
==============

Programmed by Chris Leung

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
Requires Internet connection, Moves App, and Moves API access  

* Open the app and download your Moves data by opening Settings and tapping "Download ALL Moves Data" or "Download Moves Data" (which will download data for the selected date range)
* Time Analytics processes and interpolate the data, displaying it immediately in the "Recent Locations" view as it progresses
* Tap on any location for detail view, which contains statistics and visit history for the location

Data Assumptions
----------------
Because Moves data can contain gaps, Time Analytics interpolates the data using these assumptions:

* The startTime for the first place segment that begins after a move segment M is equal to the endTime of M
* The endTime for the last place segment that end before a move segment M is equal to the startTime of M
* Given two places P1 and P2, the startTime and endTime of a commute between P1 and P2 is equal to the startTime of P2 minus the endTime of P1
* A commute only exists between P1 and P2 when there are no other place segments between them
* Move segments that begin and end at the same place are ignored

Issues
------
* No such module 'Charts': This is a known issue with Charts. To resolve, compile the project, and the error message should disappear. (May require Xcode restart.)

Developer Notes
---------------
* Under active development
* Uses [Charts 3.0.2](https://github.com/danielgindi/Charts)

Questions & Issues
------------------
* Create new issues on [GitHub repo](https://github.com/chrislzm/TimeAnalytics/issues) for any bugs found.
* Contact [Chris Leung](https://github.com/chrislzm)
