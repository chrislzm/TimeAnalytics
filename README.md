![Time Analytics Logo](/Time%20Analytics/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png?raw=true "Time Analytics Logo")

Time Analytics
==============

By Chris Leung

Overview
--------
Learn how you spend your time with Time Analytics. Analyze your data from [Moves](https://moves-app.com/), [Apple Health](https://www.apple.com/ios/health/), and [RescueTime](https://www.rescuetime.com) and view detailed information about the activities, places, and commutes you spend the most time on. Learn how they all relate to each other through automatically generated charts, statistics and detailed history views.

Installation
------------
1. Install [Moves](https://moves-app.com/) and create an account
2. Compile and run Time Analytics
3. Login with Moves

Developed and tested with XCode 8+ and iOS 10+.

How to Use
----------
Basic requirements: Internet connection, [Moves iOS application](https://moves-app.com/)

1. Open the app and follow prompts to login with moves.
2. Data import will begin automatically. You will be prompted to allow access to your Health Data, which you can always turn on or off in the Health app.
3. Once Health Data import is complete, tap "Continue" to enter the app.
4. Tap on the tabs to access each of the three main views: Places, Commutes, Activities.
5. Tap on any item in a table to open a detail view for that item.
6. Within detail views tapping on charts, maps or tables rows will open another detail view for that item. In chart view, you may pinch inwards or outwards along the x and y axis to magnify or shrink that axis.
7. Tap on the gear icon in main views to access the settings menu, where you may manually refresh your data or log out.

Data Assumptions
----------------
Because Moves data can contain gaps and incomplete information, Time Analytics interpolates your data using these assumptions:

* The startTime for the first place segment that begins after a move segment M is equal to the endTime of M
* The endTime for the last place segment that end before a move segment M is equal to the startTime of M
* Given two places P1 and P2, the startTime and endTime of a commute between P1 and P2 is equal to the startTime of P2 minus the endTime of P1
* A commute only exists between P1 and P2 when there are no other place segments between them
* Move segments that begin and end at the same place are ignored

Developer Notes
---------------
Please obtain your own [Moves API ClientId and ClientSecret](https://dev.moves-app.com/apps) values and update their values in "TANetConstants.swift" (TANetClient.MovesApi.ClientId and TANetClient.MovesApi.ClientSecret)

I highly recommend first reading documentation and code in "AppDelegate.swift" and "TAModelNotificationExtensions.swift" to understand the different steps of the data processing flow and their associated notifications.

API documentation:

* [Charts](https://github.com/danielgindi/Charts)
* [HealthKit](https://developer.apple.com/reference/healthkit)
* [Moves](https://dev.moves-app.com/docs/api)
* [RescueTime](https://www.rescuetime.com/apidoc#analytic-api-reference)

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
* For us to pay attention to in the future: Data refresh uses Moves API "lastUpdate" (optional) value as the "updatedSince" parameter in requests for new data in order to optimize the request and only retrieve new data that's been updated by Moves (a.k.a. delta sync). So far I have not seen any Moves Storyline data that does not contain this value. If this value disappears in the future, the refresh process will take longer than needed and we should use a different value for "updatedSince".

Questions
---------
* Create new issues on [GitHub repo](https://github.com/chrislzm/TimeAnalytics/issues) for any bugs found.
* Contact [Chris Leung](https://github.com/chrislzm)
