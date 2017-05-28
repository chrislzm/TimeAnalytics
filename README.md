![Time Analytics Logo](/Time%20Analytics/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png?raw=true "Time Analytics Logo")

Time Analytics
==============

By Chris Leung

Installation
------------
1. Install [Moves](https://moves-app.com/) and create an account
2. Compile and run Time Analytics
3. Login with Moves

Developed and tested with XCode 8+ and iOS 10+.

How to Use
----------
Basic requirements: Internet connection, Moves App

1. Open the app and follow prompts to login with moves
2. Optionally allow access to Health Data
3. Once Health Data import is complete, tap "Continue" to enter the app
4. Tap on the tabs to access the three main views: Places, Commutes, Activities
5. Tap on any item to view detailed information about it
6. Tapping on the chart, map, or tables rows in detail views will open another detail view about that item
7. Tap on the gear icon in main views to access the settings menu, where you may manually refresh the data or log out

Data Assumptions
----------------
Because Moves data can contain gaps and incomplete information, Time Analytics interpolates the data using these assumptions:

* The startTime for the first place segment that begins after a move segment M is equal to the endTime of M
* The endTime for the last place segment that end before a move segment M is equal to the startTime of M
* Given two places P1 and P2, the startTime and endTime of a commute between P1 and P2 is equal to the startTime of P2 minus the endTime of P1
* A commute only exists between P1 and P2 when there are no other place segments between them
* Move segments that begin and end at the same place are ignored

Developer Notes
---------------
Please obtain your own [Moves API ClientId and ClientSecret](https://dev.moves-app.com/apps) values and update their values in "TANetConstants.swift" (TANetClient.MovesApi.ClientId and TANetClient.MovesApi.ClientSecret)

I highly recommend first reading documentation and code in "AppDelegate.swift" and "TAModelNotificationExtensions.swift" to understand the different steps of the data processing flow and their associated notifications.

Additional Settings
-------------------

TAModel.swift

* AutoUpdateInterval: Interval in minutes between background auto-updates of Moves and HealthKit data. Default is 10 minutes.

TANetConstants.swift

* TANetClient.MovesApi.AccessTokenExpirationBuffer: OAuth access token expiration time buffer. Default is 60 seconds. If the user makes a network request within this time buffer of the expiration time, we will first attempt to get a new token before making our network request.

* TANetClient.MovesApi.UpdateWindowBuffer: Time from before the Moves "lastUpdate" to request data from. Default is 1 day before. (Moves doesn't guarentee that it will not update old data, though it seems highly unlikely it will.)

Issues
------
* Xcode "No such module 'Charts'": This is a known issue with Charts. To resolve, compile the project, and the error message should disappear. (May require Xcode restart.)
* For us to pay attention to in the future: Data refresh uses Moves API "lastUpdate" (optional) value as the "updatedSince" parameter in requests for new data in order to optimize the request and only retrieve new data that's been updated by Moves. So far I have not seen any Moves Storyline data that does not contain this value. If this value disappears in the future, the refresh process will take longer than needed and we should use a different value for "updatedSince".

Credits
------
* [Moves](http://moves-app.com)
* [Charts 3.0.2](https://github.com/danielgindi/Charts)

Questions
---------
* Create new issues on [GitHub repo](https://github.com/chrislzm/TimeAnalytics/issues) for any bugs found.
* Contact [Chris Leung](https://github.com/chrislzm)
