/////////////////////////////////////////////////////////////
//
// Author: CLAENG
// Date: 21.02.2021
//
// Description v1.0:
// - Read new mesage from the nearby chat and send them to the translator engine.
// - Write received translations to the nearby chat
//
////////////////////////////////////////////////////////////

// Variables and constants
////////////////////////////////////////////////////////////

integer debug_output    = TRUE;  //Start and stop debug output

// listener variables
integer listener_handle = 0;
integer chat_channel    = 0;


//main user
key g_user = NULL_KEY;

//Message events:
integer EVENT_START_TRANSLATOR          = 1001;
integer EVENT_END_TRANSLATOR            = 1002;
integer EVENT_NEW_TEXT_TO_TRANSLATE     = 1003;
integer EVENT_NEW_TRANSLATION_AVAILABLE = 1004;


//Range constants
integer RANGE_WHISPER   = 0;
integer RANGE_SAY       = 1;
integer RANGE_SHOUT     = 2;
integer RANGE_REGION    = 3;
integer RANGE_IM        = 4;
integer RANGE_INIT      = -1;

//At the moment we initialise this over a variable, later it's a nc or hud config
integer g_talking_range   = RANGE_INIT; //0 = whisper, 1 = say, 2 = shout, 3 = RegionSay, (4 = IM future feature), -1 uninitialised


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

// A first hello with range information after
// the translator started
SendTranslatorInformation(integer talking_range)
{
    if( talking_range == RANGE_WHISPER )
    {
        llWhisper(0, "Translator is in whisper range");
    } else if( talking_range == RANGE_SAY ) {
        llSay(0,"Translator is in talking range");
    } else if( talking_range == RANGE_SHOUT ) {
        llShout(0, "Translator is in shouting range");
    } else if( talking_range == RANGE_REGION ) {
        llShout(0, "Translator is in region range");
    } else if( talking_range == RANGE_IM ) {
        llWhisper(0, "Translation for IM's are not implemented yet");
    }
}

//handle the incoming messages
//output the results depending on the range settings
handleIncommingMessage(integer event_num, string message, key id)
{
    if( EVENT_NEW_TRANSLATION_AVAILABLE == event_num )
    {
        string result = llGetDisplayName(id) + ": "+ message;
        if( getTalkingRange() == RANGE_WHISPER )
        {
            llWhisper(0, result);
        } else if ( getTalkingRange() == RANGE_SAY ) {
            llSay(0, result);
        } else if ( getTalkingRange() == RANGE_SHOUT ) {
            llShout(0, result);
        } else if (getTalkingRange() == RANGE_IM ) {
            //This functionality will be imlementd in a newer version
            DebugOut("Not Implemented yet");
        } else if (getTalkingRange() == RANGE_REGION)
        {
            llRegionSay(0, result);
        }
    }
}

//Send an inital message to the translator engine
//this message also activates the debug output if it's activated initially
StartTranslatorEngine()
{
    string msgToTranslator = "debug_off";
    if( debug_output == TRUE ) msgToTranslator = "debug_on";
    
    llMessageLinked(LINK_THIS, EVENT_START_TRANSLATOR, msgToTranslator, g_user);
}

//
integer getTalkingRange()
{
    //TODO in the next version for now it's a constant
    if( g_talking_range == RANGE_INIT )
    {
        g_talking_range = RANGE_SAY;
    }

    return g_talking_range;
}


// Program states
////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llSay(0, "To start translation please attache the translator");
    }

    attach(key id)
    {
        if( id != NULL_KEY ) //attache
        {
            g_user = id;  //save the user id for later controlling the translation direction

            //inform the translator script
            StartTranslatorEngine();

            //init talking and translation range
            integer talking_range = getTalkingRange();

            //start a listener on channel 0
            listener_handle = llListen( chat_channel, "", "", "");

            // inform communication partners
            SendTranslatorInformation(talking_range);        

        } else //detach
        {
            //inform the translator engine
            llMessageLinked(LINK_THIS, EVENT_END_TRANSLATOR, "", NULL_KEY);

            // inform communication partners
            llSay(0,"End translation of messages");
        }
    }

    link_message( integer sender_num, integer num, string str, key id )
    {
        //handle only new translated 
        if( num == EVENT_NEW_TRANSLATION_AVAILABLE )
        {
            DebugOut("IOHandler: sender: " + (string)sender_num + " num: " + (string)num + " str: " + str + " id: " + (string)id);

            handleIncommingMessage(num, str, id);
        }
    }

    listen( integer channel, string name, key id, string message )
    {
        DebugOut("New msg to translate: " + message + " id: " + (string)id + " name: " + name);
        llMessageLinked(LINK_THIS, EVENT_NEW_TEXT_TO_TRANSLATE, message, id);
    }
}