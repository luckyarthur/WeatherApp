## Requirements
- Xcode 16.2 or later
- iOS 18.2 or later (simulator or device)
- Swift 5
- No third-party dependencies and no API key

## How to run
Open `Weather.xcodeproj`, choose the `Weather` scheme and an iPhone simulator, then press Run.

## Architecture: 
### MVVM
- Model: data models live here
- View: UI related Views live here
- ViewModel: the bridge between UI and data, handle all logic 

### api(Open-Meteo free api)
- searchPlaces: get the possible places with its Latitude and Longitude 
- fetchForecast: use place Latitude and Longitude to get the weather info

### features
- search field to input the place name with suggestions of a place list
- 7 day for forecast
- refresh the data for the current place
- network timeout and retry logic
- loading state handling and error handling

### trade-off
- use MVVM to separate logic from UI, easy to test the logic
- use SwiftUI and Swift Modern concurrency to write the code
- use protocol to represent the api service to hide type info and make test easier
- inject the viewmodel into the view, make mock viewmodel easily
- handle the search states in different scenarios
- use 350ms to filter the input from user to avoid frequent unnecessary request to api
- add timeout and retry handle to the network request
- use RequestId to filter old and new request handle
- use separate Task in refreshable to avoid re-render cancel the task 



