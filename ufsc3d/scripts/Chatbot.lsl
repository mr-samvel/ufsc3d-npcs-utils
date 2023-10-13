// Server config
integer USE_REVERSE_PROXY=1; // (1)Use chatGPT proxy or (0)actual chatGPT?
string SERVER_URL="http://ufsc3d.inf.ufsc.br:8080/";
string SERVER_CHAT_URL="http://ufsc3d.inf.ufsc.br:8080/chatbot/chat";

default
{
    state_entry()
    {
        // Listen for chat messages
        llListen(0, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        // Check if the chat message is a request
        if (llSubStringIndex(message, "AJUDA") != -1)
        {
            // Make an HTTP request to your external service
            string requestData = llDeleteSubString(message, 0 , 4);
            if (USE_REVERSE_PROXY == 1)
            {
                llHTTPRequest(
                    SERVER_CHAT_URL, 
                    [
                        HTTP_METHOD,
                        "POST",
                        HTTP_MIMETYPE,
                        "application/x-www-form-urlencoded"
                    ],
                    "user_prompt="+(string)requestData
                );

            }
            else
            {
                llHTTPRequest(
                    SERVER_CHAT_URL, 
                    [
                        HTTP_METHOD,
                        "POST",
                        HTTP_MIMETYPE,
                        "application/x-www-form-urlencoded"
                    ],
                    "user_prompt="+(string)requestData+
                    "&use_openai="+TRUE
                );
            }
        }
    }

    // Handle the HTTP response from your external service
    http_response(key request_id, integer status, list metadata, string body)
    {
        if (status == 200)
        {
            // Process the API response here
            llSay(0,"Respost do ajudante: " + body);
        }
        else
        {
            // Handle errors
            llSay(0,"API Request Failed. Status: " + (string)status);
        }
    }
}