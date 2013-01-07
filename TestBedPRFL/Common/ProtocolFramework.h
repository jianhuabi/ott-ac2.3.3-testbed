//
//  ProtocolFramework.h
//  TestBoss
//
//  Created by Apple User on 12/7/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

// Protocol between TestBed and TestBoss.
//
// TestBed and TestBoss communicates in a request-response mode.
// TestBoss is a server. 
// TestBed is a client.
// 
// Protocol uses an XML format.
// Root node for a client's message is <request>...</request>.
// Root node for a server's message is <response>...</response>.
// Both nodes nodes has an attribute 'type', which is in most cases is mandatory.
// There are 4 major groups of request-response message formats.
//     - ping-pong
//     - hello
//     - cmd (command)
//     - report
//
// Group 'ping-pong'
// =================
// This group contains two singular types of messages. Theses messsages are to
// verify that connection does exist and is alive.
//     (1) <request/>  <=> <response/>
//     (2) <request type="ping" /> 
//         <=> 
//         <response type="pong">
//           <deviceList>
//             <deviceName>name1</deviceName>
//             <deviceName>name2</deviceName>
//             <deviceName>name3</deviceName>
//           </deviceList>
//         </response>
//
// Group 'hello'
// =============
// This is a group of communication initiation messages. The client introduces itself
// to the server and checks that it communicates with the right instance of the 
// server. The server confirms the proper inception of the contact and 
// returns its credentials.
//
//    (1) <request type="hello" [from_id="TestBed callsign"] [to_id="TestBoss callsign"]>
//          <deviceInfo>
//            <uniqueId>3b4901142577651f6d66d120519abaa45fa6d578</uniqueId>
//            <name>Someone Name's iPad</name>
//            <systemName>iPhone OS</systemName>
//            <systemVersion>4.2.1</systemVersion>
//            <model>iPad</model>
//            <localizedModel>iPad</localizedModel>
//            <userInterfaceIdiom>pad</userInterfaceIdiom>
//          </deviceInfo>
//        </request>
//
//        <=>
//       
//        <response type="hello" [from_id="TestBoss callsign"] [to_id="TestBed callsign"]>
//
// Group 'cmd' (or 'command')
// ==========================
// This is a group of command messages. TestBed asks TestBoss what to do next sending
// "next-cmd" request type. TestBoss responds with a command that TestBed should perform.
// Some commands can have parameters.
//
//    (1) <request type="next-cmd" previous="command-name" 
//           [from_id="TestBed callsign"] [to_id="TestBoss callsign"]/>
//
//        <=>
//
//        <response type="cmd" cmd="command-name" >
//          <parameters>
//            ...
//          </parameters>
//        <response>
// 
//        Where 'command-name' := ("do-manual"; "do-automatic"; "do-exit";
//                                 "get-test-list"; "get-status";
//                                 "run-all"; "run-selected"; )
//        do-manual      - TestBed should switch to listen to User UI events and 
//                         report about all testing activities as soon as they 
//                         happened
//        do-automatic   - TesBed should actively work with TestBoss asking it what 
//                         to do until it receives either 'do-manual' or 'do-exit'
//                         command
//        do-exit        - TestBed should complete the work and exit
//        get-test-list  - TestBed should return a list of all test cases with 
//                         a 'report' type of request message, kind="list"
//        get-status     - TestBed should return full status of test cases with
//                         a 'report' type of request message, kind="status"
//        run-all        - TestBed should run all test cases
//        run-selected   - TestBed should run test cases passed as a parameters in the 
//                         response.
// Group 'report'
// ==============
//    (1) <request type="report" kind="report-type" [on_cmd="command-name"]>
//          <log>...</log>
//          <status>...</status>
//          <list>...</list>
//        </request>
//
//        <=>
//
//        <response type="report" kind="report-type" status="[ok; repeat; error]"/>
//        Where 'report-type' := ("log"; "status"; "list")
//

#include <string.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <stdint.h>


#ifndef BOOL
typedef signed char		BOOL; 
#endif

#ifndef YES
#define YES             (BOOL)1
#endif

#ifndef NO
#define NO              (BOOL)0
#endif

/**
 * use this macro to declare constant string char*
 */
#define DECLARE_STRING(id, string) \
const char id[] = string; \
enum { id##Length = ((sizeof(id) - 1)/sizeof(char)) }; \
const long id##_Length = ((sizeof(id) - 1)/sizeof(char));

#define DECLARE_NSSTRING(id, string) \
NSString *const id = @string;

#define USES_STRING(id) \
extern const char id[]; \
extern const long id##_Length;

#define ARRAYSIZE(range) (sizeof(range)/sizeof((range)[0]))

typedef struct _MessageBuffer {
    uint8_t *buffer; // a pointer to buffer
    uint16_t capacity; // capacity of the buffer
    uint16_t length; // length of the message
} MessageBuffer;

typedef struct _ParsingNodeInfo
{
    struct _ParsingNodeInfo *parentNode;
    const char *localname;
    const char *prefix;
    const char *URI;
    MessageBuffer nodeValue;
} ParsingNodeInfo;

typedef enum
{
    msgType_Unknown = 0,
    msgType_Empty,
    msgType_Ping,
    msgType_Pong,
    msgType_Hello,
    msgType_NextCmd,
    msgType_Cmd,     
    msgType_Report,
} RequestResponseMessageType;

typedef enum
{
    reportType_Unknown = 0,
    reportType_Log,
    reportType_Status,
    reportType_List,
} ReportType;

typedef enum
{
    cmdType_Unknown = 0,
    cmdType_DoManual,
    cmdType_DoAutomatic,
    cmdType_DoExit,
    cmdType_GetTestList,
    cmdType_GetStatus,
    cmdType_RunAll,
    cmdType_RunSelected,
} CmdType;

typedef enum
{
    statusType_Unknown = 0,
    statusType_Ok,
    statusType_Error,
    statusType_Repeat
} StatusType;

typedef enum
{
    linkType_Available = 0,
    linkType_Primary,
    linkType_Busy,
} LinkType;

void initMessageBuffer(MessageBuffer *message);
void freeMessageBuffer(MessageBuffer *message);
void extendMessageBuffer(MessageBuffer *message, uint16_t delta);
void appendMessageBuffer(MessageBuffer *message, const uint8_t *data, uint16_t dataLength);
void appendMessageBufferWithFormat(MessageBuffer *message, const char *template, ...);
void resetMessageBuffer(MessageBuffer *message);

char *escapeCString(const char *source, int length);
char *unescapeCString(const char *source, int length);

void moveNodeInfoInstanceToFreePool(ParsingNodeInfo **list, ParsingNodeInfo** freePool);
void moveAllNodeInfoInstancesToFreePool(ParsingNodeInfo **list, ParsingNodeInfo** freePool);
void cleanFreePool(ParsingNodeInfo **freePool);
void initNodeInfo(ParsingNodeInfo *info);
ParsingNodeInfo *getNewNodeInfo (ParsingNodeInfo **freePool);
                    

typedef struct _ValueProperties {
    const char* valName;
    int         valNameSize;
    int         context;
} ValueProperties;

typedef struct _AttributeRequirements {
    const char *attrName;
    int attrNameSize;
    BOOL checkForExpectedValues;
    BOOL checkForExistense;
    ValueProperties *expectedValues;
    int expectedValuesSize;
} AttributeRequirements;

BOOL analyzeAttributes (const xmlChar **attributes,
                        int nb_attributes,
                        const AttributeRequirements *attrRequirements,
                        int *context,
                        const char **value,
                        int *valueSize);
