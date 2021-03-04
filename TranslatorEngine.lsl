/////////////////////////////////////////////////////////////
//
// Author: CLAENG
// Date: 21.02.2021
//
// Description v1.0:
// - Receive new message to translate
// - send the translated messages back to the IO script
//
////////////////////////////////////////////////////////////

// Variables and constants
////////////////////////////////////////////////////////////

integer debug_output        = TRUE; //Start and stop debug output

key g_user                  = NULL_KEY;   //uuid of the user who has the translater attached 
key g_requestHandle         = NULL_KEY;   //a list with all handles with valid requests for translations

string  g_notecardName      = "TranslatorConfigNC";
integer g_notecardLine      = 0;
key     g_notecardQueryId   = NULL_KEY;

string g_accountName = "";
string g_password = "";
string g_fromLang = "";
string g_toLang = "";

//Message events:
integer EVENT_START_TRANSLATOR          = 1001;
integer EVENT_END_TRANSLATOR            = 1002;
integer EVENT_NEW_TEXT_TO_TRANSLATE     = 1003;
integer EVENT_NEW_TRANSLATION_AVAILABLE = 1004;


//message handling
//It's possible we gt faster incoming messages the we can translate it
//then we save them and translate one after the other
list g_messages = [];
integer g_msgListHandle = 0;


// Functions
////////////////////////////////////////////////////////////

// DebugOut writes messages to the Owner of the object
// it the function is activated over the control 
// variable debug_output
DebugOut( string msg )
{
    if( debug_output == TRUE )
    {
        llOwnerSay(msg);
    }
}

handleList()
{
    g_msgListHandle += 2;
    if( g_msgListHandle >= llGetListLength(g_messages) )
    {
        g_messages = [];
        g_msgListHandle = 0;
        DebugOut("Reset list with messages");
    }
}


//translate the message into
translate()
{
    if( g_requestHandle != NULL_KEY )
    {
        DebugOut("could not translate... que is full: " + (string) g_requestHandle);
        return;
    } 

    string message = llList2String(g_messages,g_msgListHandle);
    g_msgListHandle += 1;
    key usr = llList2Key(g_messages,g_msgListHandle);

    //start the magic
    if( g_user == usr )
    {
        //use direction from
        string body = "{ \"src\": \""+ g_fromLang +"\", \"dest\": \""+ g_toLang +"\", \"text\": \""+ message +"\", \"email\":\"" + g_accountName + "\", \"password\":\""+ g_password +"\"}";
        DebugOut("body to send: " + body);

        g_requestHandle = llHTTPRequest("https://frengly.com/frengly/data/translateREST", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], body);
    }  else
    { 
        //use direction to
        string body = "{ \"src\": \""+ g_toLang +"\", \"dest\": \""+ g_fromLang +"\", \"text\": \""+ message +"\", \"email\":\"" + g_accountName + "\", \"password\": \""+ g_password +"\"}";
        DebugOut("body to send: " + body);

        g_requestHandle = llHTTPRequest("https://frengly.com/frengly/data/translateREST", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/json"], body);
    }

    DebugOut("requestHandle: " + (string)g_requestHandle);
}

//parse the translated result
string parseMessage(string msg)
{
    //get the message
    return llJsonGetValue(msg, ["translation"]);
}


//handle incoming messages
handleIncommingMessage(integer num, string msg, key id)
{
    if( num == EVENT_NEW_TEXT_TO_TRANSLATE )
    {
        //start translating the incoming message
        g_messages += msg; //save the message in the list
        g_messages += id;  //save the user who wrote the message also

        translate();
    }
    
}

readConfiguration()
{
    // Check the notecard exists, and has been saved
    DebugOut("search NC: " + g_notecardName);
    if (llGetInventoryKey(g_notecardName) == NULL_KEY)
    {
        DebugOut( "Notecard '" + g_notecardName + "' missing or unwritten");
        return;
    }
    g_notecardQueryId = llGetNotecardLine(g_notecardName, g_notecardLine);
    DebugOut("NC query id: " + (string)g_notecardQueryId);
}

parseNC_Line(string msg)
{
    list results = [];
    results = llParseString2List(msg, [":"],[]);

    if( llSubStringIndex(msg, "From:") != -1 )
    {
        g_fromLang = llList2String(results, 1);
        DebugOut("From language: " + g_fromLang);
    } else if( llSubStringIndex(msg, "To:") != -1 )
    {
        g_toLang = llList2String(results, 1);
        DebugOut("To language: " + g_toLang);
    } else if( llSubStringIndex(msg, "Account:") != -1 )
    {
        g_accountName = llList2String(results, 1);
        DebugOut("account name:" + g_accountName);
    } else if( llSubStringIndex(msg, "Password:") != -1 )
    {
        g_password = llList2String(results, 1);
        DebugOut("passowrd: " + g_password);
    }
}


// Program states
////////////////////////////////////////////////////////////
default
{
    state_entry()
    {
        //reste the global variables
        debug_output = FALSE; 
        g_user = NULL_KEY;
        g_requestHandle = NULL_KEY;
    }

    link_message( integer sender_num, integer num, string str, key id )
    {
        DebugOut("Translator: sender_num: " + (string)sender_num + " num: " + (string)num + " str:" + str + " id: " + (string)id);
        
        if( num == EVENT_START_TRANSLATOR )
        {
            //parse the message and get debug_output state
            if( str == "debug_on" ){
                debug_output = TRUE;
                DebugOut("Started debug output for translator engine");
            } 
            
            g_user = id;
            DebugOut("Start with the translation mode...");
            state translationMode;
        }
    }

   
}

state translationMode
{
     state_entry()
    {
        //read the configuration notecard
        readConfiguration();
    }
    
     dataserver( key queryid, string data )
    {
        DebugOut("dataserver query id: " + (string)queryid);
        if( g_notecardQueryId == queryid )
        {
            //read nc and parse the following
            if (data == EOF)
                DebugOut("Done reading notecard, read " + (string) g_notecardLine + " notecard lines.");
            else
            {
                // bump line number for reporting purposes and in preparation for reading next line
                DebugOut( "Line: " + (string) g_notecardLine + " " + data);
                parseNC_Line(data);
                
                ++g_notecardLine;
                g_notecardQueryId = llGetNotecardLine(g_notecardName, g_notecardLine);
            }
        }
    }
    
    
    link_message( integer sender_num, integer num, string str, key id )
    {
        DebugOut("Translator: sender_num: " + (string)sender_num + " num: " + (string)num + " str:" + str + " id: " + (string)id);
     
        if( num == EVENT_END_TRANSLATOR )
        {
            state default;
        }
        
        handleIncommingMessage(num, str, id);
    }

    http_response( key request_id, integer status, list metadata, string body )
    {
        DebugOut("http respnose incoming query id:" + (string)request_id);
        if( g_requestHandle == request_id )
        {
            DebugOut("Received http response: " + body);
            //get the user
            key user = llList2Key(g_messages, g_msgListHandle);
            g_requestHandle = NULL_KEY; //this is needed to start the next translation
            handleList();

            if( g_msgListHandle > 0 ) translate(); //start the next translation if the queue is not empty

            if( status == 200 ) 
            {
                //send the message back to the IO-Control.
                string translatedMsg = parseMessage(body);
                llMessageLinked(LINK_THIS, EVENT_NEW_TRANSLATION_AVAILABLE, translatedMsg, user);    
            } else
            {
                DebugOut("Translation reply state: " + (string)status);
                return;
            }
            
        } else
        {
            DebugOut("wrong message: reqId: " + (string)request_id + " status: " + (string)status + " metadata: " + llDumpList2String(metadata, ";")  + " body: " + body);
        }
    }
}