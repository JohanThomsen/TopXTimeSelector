auto app = GetApp();
bool buttonClicked = false;
int positionWanted;
bool buttonClickedOnce = false;
int timeForPositionWanted;
int positionFound;
void Main() {
    positionWanted = 0;
    timeForPositionWanted = CheckForButtonClicksAndExecute(timeForPositionWanted);
    RenderInterface();
    print("up here again");
}

int CheckForButtonClicksAndExecute(int timeForPositionWanted){
    while(true){
            if(buttonClicked == true){
                    print(positionWanted);
                    timeForPositionWanted = GetTopNTime(positionWanted);
                    buttonClickedOnce = true;
                    print(timeForPositionWanted);
                    return timeForPositionWanted;
                }
            else{
                yield();
            }
        }
    return 0;
}

//Primary function to hold all the logic for getting the Top N time
int GetTopNTime(int positionWanted){
    string mapID = get_mapID();
    string someID = "45569279-a101-446d-b5d6-649471deadcf"; // IDK what this is. Find out. Think it is some personal TM.io ID.

    string timeResponse = SendJSONRequest(Net::HttpMethod::Get, "https://trackmania.io/api/leaderboard/" + someID + "/" + mapID); //Get PB time as starting point
    Json::Value top50 = ResponseToJSON(timeResponse, Json::Type::Object);

    int startTime = top50['tops'][0]['time'];
    int startInterval = top50['tops'][14]['time'] - startTime;
    timeForPositionWanted = FindWantedTime(positionWanted, mapID, someID, startTime, startInterval);
    return timeForPositionWanted;
}


int FindWantedTime(int positionWanted, string mapID, string someID, int startTime, int startInterval){
    //TODO Make check for checking for top 15 time
    //TODO Make check for checking for top 65 time
    //TODO for now dont check within the first 65
    bool sentinel = false;
    int searchTime = startTime;
    //Naive Approach
    while(sentinel = true){
        print(searchTime);
        
        string nextTimeResponse = SendJSONRequest(Net::HttpMethod::Get, "https://trackmania.io/api/leaderboard/" + someID + "/" + mapID + "?from=" + searchTime);
        Json::Value next50 = ResponseToJSON(nextTimeResponse, Json::Type::Object);

        int lowestPos = next50['tops'][0]['position'];
        searchTime = next50['tops'][49]['time'];

        if (positionWanted-50 < lowestPos){
            sentinel = true;
            //@beta
            positionFound = next50['tops'][positionWanted-lowestPos]['position'];
            print(tostring("position found: " + positionFound));
            //print("in FineWantedtime" + tostring(next50['tops'][positionWanted-lowestPos]['time']));
            return next50['tops'][positionWanted-lowestPos]['time'];
        }
    }
    return 0;
}

//Gets the map ID, if player is not in a map an error can be thrown
string get_mapID(){
    if(app.RootMap != null){
        string mapID = app.RootMap.MapInfo.MapUid;
        return mapID;
    } else {
        print("Map doesnt exist");
    }
    return "0";
}

//Adds headers to an HTTP request
string SendJSONRequest(const Net::HttpMethod Method, const string &in URL, string Body = "") {
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    return SendHTTPRequest(Method, URL, Body, Headers);
}

//Bundles everything together for an HTTP Request
string SendHTTPRequest(const Net::HttpMethod Method, const string &in URL, const string &in Body, dictionary@ Headers) {
    Net::HttpRequest req;
    req.Method = Method;
    req.Url = URL;
    @req.Headers = Headers;
    req.Body = Body;
    req.Start();
    while (!req.Finished()) {
        yield();
    }
    //@BETA
    print(req.String());
    return req.String();
}

//Headers for a Nadeo request
string SendNadeoRequest(const Net::HttpMethod Method, const string &in URL, string Body = "") {
    dictionary@ Headers = dictionary();
    auto app = cast<CTrackMania>(GetApp());
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    Headers["Authorization"] = "nadeo_v1 t=" + app.ManiaPlanetScriptAPI.Authentication_Token;
    return SendHTTPRequest(Method, URL, Body, Headers);
}

//Handles the responsen
Json::Value ResponseToJSON(const string &in HTTPResponse, Json::Type ExpectedType) {
    Json::Value ReturnedObject;
    try {
        ReturnedObject = Json::Parse(HTTPResponse);
    } catch {
        print("JSON Parsing of string failed!"); //TODO change this to proper errors
        //Error(ErrorType::Error, "ResponseToJSON", "JSON Parsing of string failed!", HTTPResponse);
    }
    if (ReturnedObject.GetType() != ExpectedType) {
        print("Unexpected JSON Type returned"); //TODO change this to proper errors
        //Error(ErrorType::Warn, "ResponseToJSON", "Unexpected JSON Type returned", HTTPResponse);
        return ReturnedObject;
    }
    return ReturnedObject;
}

void RenderInterface(){
    UI::SetNextWindowContentSize(780, 230);
    UI::Begin("TopxSelector");
    positionWanted = UI::InputInt("Input the position you want to find:", positionWanted, 5);
    UI::NewLine();
    buttonClicked = UI::Button("Enter");
    if(buttonClickedOnce == true){
        UI::NewLine();
        UI::Text("Time for position " + positionWanted + ": " + timeForPositionWanted);
    }
    UI::End();
}