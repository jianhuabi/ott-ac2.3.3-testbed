//
//  TestEventController.m
//  TestBed
//
//  Created by Apple User on 11/27/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "RootViewController.h"
#import "TestEventController.h"
#import "ProtocolFramework.h"
#import "DetailViewController.h"
#import "IPAddress.h"

typedef struct _reportTypeAttributeValue {
    ReportType  reportType;
    char *      valueName;
} ReportTypeAttributeValue;

ReportTypeAttributeValue g_reportTypeAttributeValues [] = 
{
    {reportType_Unknown, "unknown"},
    {reportType_Log, "log"},
    {reportType_Status, "status"},
    {reportType_List, "list"}
};

typedef struct _cmdTypeToProcessState {
    CmdType cmdType;
    TestProcessState processState;
} CmdTypeToProcessState;

static CmdTypeToProcessState g_cmdToState [] = 
{
    {cmdType_Unknown, ts_Unknown},
    {cmdType_DoManual, ts_DoManual},
    {cmdType_DoAutomatic, ts_DoAutomatic},
    {cmdType_DoExit, ts_DoExit},
    {cmdType_GetTestList, ts_DoGetTestList},
    {cmdType_GetStatus, ts_DoGetStatus},
    {cmdType_RunAll, ts_DoRunAll},
    {cmdType_RunSelected, ts_DoRunSelected},
};

static const char* g_testEventNames [] = 
{
    "te_ApplicationLaunched",
    "te_ConnectedToServer",
    "te_DisconnectedFromServer",
    "te_SentRequest",
    "te_ReceivedResponse",
    "te_StartedUnitTest",
    "te_CompletedUnitTest",
    "te_FinishedTesting",
};

static const char* g_testStateNames [] = 
{
    "ts_AnalyzeCmd",
    "ts_Exit",
    "ts_Unexpected",
    "ts_Unknown",
    "ts_Start",
    "ts_WaitForServer",
    "ts_SendHello",
    "ts_WaitHello",
    "ts_SendGetNextCmd",
    "ts_WaitNextCmd",
    "ts_DoManual",
    "ts_DoAutomatic",
    "ts_DoExit",
    "ts_DoRunAll",
    "ts_DoRunSelected",
    "ts_DoGetTestList",
    "ts_DoGetStatus",
    "ts_Stop",
    "ts_PrepareNextTest",
    "ts_TestExecuting",
    "ts_SendTestList",
    "ts_SendStatus",
    "ts_WaitConfirmation",
    "ts_GUIControlled",
    "ts_count",
};

static TestProcessState testAutomata[te_count][ts_count] = 
{
    //                                  | ts_Start         | ts_WaitForServer  | ts_SendHello     | ts_WaitHello     | ts_SendGetNextCmd | ts_WaitNextCmd  | ts_DoManual     | ts_DoAutomatic    | ts_DoExit       | ts_DoRunAll       | ts_DoRunSelected  | ts_DoGetTestList  | ts_DoGetStatus    | ts_Stop         | ts_PrepareNextTest | ts_TestExecuting  | ts_SendTestList    | ts_SendStatus      | ts_WaitConfirmation | ts_GUIControlled |
    //                                  +------------------+-------------------+------------------+------------------+-------------------+-----------------+-----------------+-------------------+-----------------+-------------------+-------------------+-------------------+-------------------+-----------------+--------------------+-------------------+--------------------+--------------------+---------------------+------------------+
    /* te_ApplicationLaunched       */  {ts_WaitForServer,  ts_Unexpected,      ts_Unexpected,     ts_Unexpected,     ts_Unexpected,      ts_Unexpected,    ts_Unexpected,    ts_Unexpected,      ts_Unexpected,    ts_Unexpected,      ts_Unexpected,      ts_Unexpected,      ts_Unexpected,      ts_Unexpected,    ts_Unexpected,      ts_Unexpected,      ts_Unexpected,       ts_Unexpected,       ts_Unexpected,        ts_Unexpected    },
    /* te_ConnectedToServer         */  {ts_Unexpected,     ts_SendHello,       ts_SendHello,      ts_SendHello,      ts_SendHello,       ts_SendHello,     ts_SendHello,     ts_SendHello,       ts_SendHello,     ts_SendHello,       ts_SendHello,       ts_SendHello,       ts_SendHello,       ts_SendHello,     ts_SendHello,       ts_SendHello,       ts_SendHello,        ts_SendHello,        ts_SendHello,         ts_SendHello     },
    /* te_DisconnectedFromServer    */  {ts_Unexpected,     ts_WaitForServer,   ts_WaitForServer,  ts_WaitForServer,  ts_WaitForServer,   ts_WaitForServer, ts_WaitForServer, ts_WaitForServer,   ts_WaitForServer, ts_WaitForServer,   ts_WaitForServer,   ts_WaitForServer,   ts_WaitForServer,   ts_WaitForServer, ts_PrepareNextTest, ts_TestExecuting,   ts_WaitForServer,    ts_WaitForServer,    ts_WaitForServer,     ts_GUIControlled },
    /* te_SentRequest               */  {ts_Unexpected,     ts_Unexpected,      ts_WaitHello,      ts_Unexpected,     ts_WaitNextCmd,     ts_Unexpected,    ts_Unexpected,    ts_Unexpected,      ts_Unexpected,    ts_Unexpected,      ts_Unexpected,      ts_Unexpected,      ts_Unexpected,      ts_WaitForServer, ts_PrepareNextTest, ts_TestExecuting,   ts_WaitConfirmation, ts_WaitConfirmation, ts_WaitConfirmation,  ts_GUIControlled },
    /* te_ReceivedResponse          */  {ts_Unexpected,     ts_Unexpected,      ts_Unexpected,     ts_AnalyzeCmd,     ts_AnalyzeCmd,      ts_AnalyzeCmd,    ts_GUIControlled, ts_SendGetNextCmd,  ts_Stop,          ts_PrepareNextTest, ts_PrepareNextTest, ts_SendTestList,    ts_SendStatus,      ts_WaitForServer, ts_PrepareNextTest, ts_TestExecuting,   ts_WaitConfirmation, ts_WaitConfirmation, ts_SendGetNextCmd,    ts_GUIControlled },
    /* te_StartedUnitTest           */  {ts_Unexpected,     ts_WaitForServer,   ts_SendHello,      ts_WaitHello,      ts_TestExecuting,   ts_WaitNextCmd,   ts_DoManual,      ts_TestExecuting,   ts_Stop,          ts_TestExecuting,   ts_TestExecuting,   ts_TestExecuting,   ts_TestExecuting,   ts_WaitForServer, ts_TestExecuting,   ts_TestExecuting,   ts_TestExecuting,    ts_TestExecuting,    ts_TestExecuting,     ts_GUIControlled },
    /* te_CompletedUnitTest         */  {ts_Unexpected,     ts_WaitForServer,   ts_SendHello,      ts_WaitHello,      ts_PrepareNextTest, ts_WaitNextCmd,   ts_DoManual,      ts_PrepareNextTest, ts_Stop,          ts_PrepareNextTest, ts_PrepareNextTest, ts_PrepareNextTest, ts_PrepareNextTest, ts_WaitForServer, ts_PrepareNextTest, ts_PrepareNextTest, ts_PrepareNextTest,  ts_PrepareNextTest,  ts_PrepareNextTest,   ts_GUIControlled },
    /* te_FinishedTesting           */  {ts_Unexpected,     ts_WaitForServer,   ts_SendHello,      ts_WaitHello,      ts_SendGetNextCmd,  ts_WaitNextCmd,   ts_DoManual,      ts_SendGetNextCmd,  ts_Stop,          ts_SendGetNextCmd,  ts_SendGetNextCmd,  ts_SendGetNextCmd,  ts_SendGetNextCmd,  ts_WaitForServer, ts_SendGetNextCmd,  ts_SendGetNextCmd,  ts_SendGetNextCmd,   ts_SendGetNextCmd,   ts_SendGetNextCmd,    ts_GUIControlled },
    
};

const char *getTestStateName(TestProcessState testState)
{
    return g_testStateNames[testState - ts_first - 1];
}

const char *getTestEventName(TestEvent testEvent)
{
    return g_testEventNames[testEvent];
}


@interface TestEventController ()

@property (assign) TestProcessState currentState;
@property (assign) TestProcessState previousState;
@property (nonatomic, retain) NSString *deviceUniqueId;

- (void) receivedResponseFromTestServer:(NSNotification*)notification;
- (void) prepareAndSendHelloMessage;
- (void) sendHelloMessage:(NSString *)helloBody;
- (void) sendGetNextCmdMessage;
- (NSArray *) getIpAddressesForInterfaceName:(const char*)interfaceName;
- (void) initDeviceName;

@end


@implementation TestEventController

@synthesize currentState = _currentState;
@synthesize previousState = _previousState;
@synthesize responseContext = _responseContext;
@synthesize deviceName = _deviceName;
@synthesize deviceUniqueId;
@synthesize runOnlyAutomatic;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithDetailViewController:(DetailViewController *)detailViewController
                         NetService:(NetServiceController *)controller {
    [super init];
    
    self->_detailViewController = detailViewController; // keep a soft link to the detailViewController
    self->_netServiceController = controller;
    [self->_netServiceController retain];
    deviceUniqueId = [[NSString alloc] initWithString:[[UIDevice currentDevice] uniqueIdentifier]];
    self->_deviceName = nil;
    [self initDeviceName];
    self->_responseContext = [[ResponseContext alloc] init];
    initMessageBuffer(&self->_requestMessage);
    runOnlyAutomatic = NO;
    self->_discoveryMode = YES;
    self->_serviceIndex = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedResponseFromTestServer:)
                                                 name:NetServiceControllerReceivedResponse
                                               object:self->_netServiceController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectedToTestServer:)
                                                 name:NetServiceControllerConnected
                                               object:self->_netServiceController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disconnectedFromTestServer:)
                                                 name:NetServiceControllerDisconnected
                                               object:self->_netServiceController];
    // setup the test event state machine
    self->_previousState = ts_Unknown;
    self->_currentState = ts_Start;
    [self dispatchTestEvent:te_ApplicationLaunched];
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void) dealloc {
    [self->_netServiceController release];
    freeMessageBuffer(&self->_requestMessage);
    [self->_responseContext release];
    [deviceUniqueId release];
    [super dealloc];
}


/*-----------------------------------------------------------------------------
    This functions returns IP addresses for the particular network adapters 
    with name started with characters in the 'interfaceName' parameter.
 ----------------------------------------------------------------------------*/
- (NSArray *) getIpAddressesForInterfaceName:(const char*)interfaceName {
    NSMutableArray *resultList = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
    if (interfaceName != NULL) {
        int interfaceNameLength = strlen(interfaceName);
        char *if_names[MAXADDRS];
        char *ip_names[MAXADDRS];
        char *hw_addrs[MAXADDRS];
        unsigned long ip_addrs[MAXADDRS];
        GetAddresses(if_names, ip_names, hw_addrs, ip_addrs, MAXADDRS);
        
        for (int i = 0; i < MAXADDRS; i++) {
            static unsigned long localHost = 0x7F000001;            // 127.0.0.1
            unsigned long theAddr;
            
            theAddr = ip_addrs[i];
            
            if (theAddr == 0) break;
            if (theAddr == localHost) continue;
            
            // verify if is the desirable interface
            if (strncmp(if_names[i], interfaceName, interfaceNameLength) == 0)
            {
                [resultList addObject:[NSString stringWithFormat:@"%s", ip_names[i]]];
            }
        }
        
        FreeNameArray(if_names, MAXADDRS);
        FreeNameArray(ip_names, MAXADDRS);
        FreeNameArray(hw_addrs, MAXADDRS);
        
    }
    
    return resultList;
}

/*-----------------------------------------------------------------------------
    This function create a device name.
    If it is a device, we just reuse the current device name as it is.
    If it is a simulator, it obtaina IP addresses of the hosting machine and 
    creates a device name by merging the first IP address and the simulator's 
    name similar to the following sample - "10.0.1.30/iPhone Simulator".
 ----------------------------------------------------------------------------*/
-(void) initDeviceName {
    if (self->_deviceName == nil) {
        NSString *name = [[UIDevice currentDevice] name];
        NSString *model = [[UIDevice currentDevice] model];
        // look for Simulator word in the model name
        NSRange range = [model rangeOfString:@"Simulator" options:NSLiteralSearch | NSBackwardsSearch];
        if (range.location != NSNotFound && model.length == range.location + range.length) {
            // obtain list of Ethernet IP addresses
            NSArray *ipAddresses = [self getIpAddressesForInterfaceName:"en"];
            if (ipAddresses.count > 0) {
                self->_deviceName = [[NSString alloc] initWithFormat:@"%@/%@", [ipAddresses objectAtIndex:0], name];
            }
        }
        if (self->_deviceName == nil) {
            self->_deviceName = [[NSString alloc] initWithString:name];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) dispatchTestEvent: (TestEvent)testEvent {
    self->_previousState = self->_currentState;
    BOOL success = YES;

    switch (self->_previousState) {
        case ts_AnalyzeCmd:;
            break;
        case ts_Exit:;
            break;
        case ts_Unexpected:;
            break;
        case ts_Unknown:;
            break;
        case ts_Start:;
            break;
        case ts_WaitForServer:;
            break;
        case ts_SendHello:;
            break;
        case ts_WaitHello:;
            if (te_ReceivedResponse && (self->_responseContext.parsingStatus != statusType_Ok || self->_responseContext.responseStatus != statusType_Ok)) {
                success = FALSE;
            }
            break;
        case ts_SendGetNextCmd:;
            break;
        case ts_WaitNextCmd:;
            break;
        case ts_DoManual:;
            break;
        case ts_DoAutomatic:;
            break;
        case ts_DoExit:;
            break;
        case ts_DoRunAll:;
            break;
        case ts_DoRunSelected:;
            break;
        case ts_DoGetTestList:;
            break;
        case ts_DoGetStatus:;
            break;
        case ts_Stop:;
            break;
        case ts_PrepareNextTest:;
            break;
        case ts_TestExecuting:;
            break;
        case ts_SendTestList:;
            break;
        case ts_SendStatus:;
            break;
        case ts_WaitConfirmation:;
            break;
        case ts_GUIControlled:;
            break;
        default:;
            break;
    }
    
    if (success && testEvent >= 0 && self->_previousState >= 0) {
        self->_currentState = testAutomata[testEvent][self->_previousState];
    }
    fprintf(stderr, "TestEventController::dispatchTestEvent: (1) current state = %s (%d), event = %s, previous state = %s\n", 
            getTestStateName(self->_currentState), 
            self->_currentState, 
            getTestEventName(testEvent),
            getTestStateName(self->_previousState));
    
    // process first either a multiple decision event like 
    // a received response or an error
    if (self->_currentState <= ts_Unknown) {
        switch (self->_currentState) {
            case ts_AnalyzeCmd:;
                if (testEvent == te_ReceivedResponse 
                    && self->_responseContext.responseType == msgType_Cmd
                    && self->_responseContext.responseStatus == statusType_Ok) {
                    self->_currentState = g_cmdToState[self->_responseContext.cmdType].processState;
                } else if (testEvent == te_ReceivedResponse
                           && self->_responseContext.responseType == msgType_Hello
                           && self->_responseContext.responseStatus == statusType_Ok) {
                    self->_previousState = self->_currentState;
                    self->_currentState = ts_SendGetNextCmd;
                }
                break;
            case ts_Exit:;
                break;
            case ts_Unexpected:;
                break;
            case ts_Unknown:;
                break;
            default:;
                break;
        }
        
        fprintf(stderr, "TestEventController::dispatchTestEvent: (2) current state = %s (%d), event = %s, previous state = %s\n", 
                getTestStateName(self->_currentState), 
                self->_currentState, 
                getTestEventName(testEvent),
                getTestStateName(self->_previousState));
    }
    
    switch (self->_currentState) {
        case ts_Start:;
            break;
        case ts_WaitForServer:;
            break;
        case ts_SendHello:;
            [self dispatchTestEvent:te_SentRequest];
            [self prepareAndSendHelloMessage];
            break;
        case ts_WaitHello:;
            break;
        case ts_SendGetNextCmd:;
            if (testEvent == te_FinishedTesting) {
                runOnlyAutomatic = NO;
            }
            [self dispatchTestEvent:te_SentRequest];
            [self sendGetNextCmdMessage];
            break;
        case ts_WaitNextCmd:;
            break;
        case ts_DoManual:;
        case ts_DoAutomatic:;
        case ts_DoExit:;
            [self dispatchTestEvent:te_ReceivedResponse];
            break;
        case ts_DoRunAll:;
            runOnlyAutomatic = YES;
            // prepare a list of test cases that can be run
            GroupViewController *rootViewController = [RootViewController currentView:nil];
            [rootViewController runGroupOfTestsAction:nil];
            [self->_detailViewController showRootView];
            [self dispatchTestEvent:te_ReceivedResponse];
            break;
        case ts_DoRunSelected:;
            // create a list of selected test cases
            // [self createListOfSelectedTestCases];
            // [[RootViewController currentView:nil] runGroupOfTestsAction:nil];
            [self dispatchTestEvent:te_ReceivedResponse];
            break;
        case ts_DoGetTestList:;
        case ts_DoGetStatus:;
            [self dispatchTestEvent:te_ReceivedResponse];
            break;
        case ts_Stop:;
            break;
        case ts_PrepareNextTest:;
            break;
        case ts_TestExecuting:;
            break;
        case ts_SendTestList:;
            // Send a TestList request
            NSString *listReport = [[RootViewController currentView:nil].testRepository getListReportString];
            [self sendReportMessage:listReport withReportType:reportType_List];
            [self dispatchTestEvent:te_SentRequest];
            break;
        case ts_SendStatus:;
            NSString *statusReport = [[RootViewController currentView:nil].testRepository getStatusReportString];
            [self sendReportMessage:statusReport withReportType:reportType_Status];
            [self dispatchTestEvent:te_SentRequest];
            break;
        case ts_WaitConfirmation:;
            break;
        case ts_GUIControlled:;
            break;
        default:;
            break;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) receivedResponseFromTestServer:(NSNotification*)notification
{
    fprintf(stderr, "receivedResponseFromTestServer: started\n");
    const MessageBuffer *response = [self->_netServiceController getReceivedMessage];

    if (response != nil) {
        fprintf(stderr, "received a response: length = %d message = %s%s", response->length, response->buffer, response->length == 0 ? "\n" : "");
    }
    
    [self->_responseContext parseResponse:response];

    if (self->_discoveryMode) {
        // check that we recieved 'pong' type of the Response
        // iterate through the device list if it exists
        // if we have found our name, switch to generic mode and dispatch te_ConnectedToServer event
        // it means that we have connected to our "direct report" TestBoss
        assert(self->_responseContext.responseType == msgType_Pong);
        if ([self->_responseContext.deviceNameList count] > 0) {
            for (NSString *deviceName in self->_responseContext.deviceNameList) {
                if ([self->_deviceName isEqualToString:deviceName]) {
                    self->_discoveryMode = NO;
                    self->_serviceIndex = 0;
                    [self dispatchTestEvent:(TestEvent)te_ConnectedToServer];
                    break;
                }
            }
        }
        if (self->_discoveryMode) {
            [self->_netServiceController disconnectFromService];
        }
    } else {
        [self dispatchTestEvent:te_ReceivedResponse];
    }
    fprintf(stderr, "receivedResponseFromTestServer: finished\n");
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)prepareAndSendHelloMessage {
    NSMutableString *deviceInfo = [[NSMutableString alloc] initWithCapacity:1024];
    
    [deviceInfo appendString:@"<deviceInfo>"];
    [deviceInfo appendFormat:@"<uniqueId>%@</uniqueId>", [[UIDevice currentDevice] uniqueIdentifier]];
    [deviceInfo appendFormat:@"<name>%@</name>", self->_deviceName];
    [deviceInfo appendFormat:@"<systemName>%@</systemName>", [[UIDevice currentDevice] systemName]];
    [deviceInfo appendFormat:@"<systemVersion>%@</systemVersion>", [[UIDevice currentDevice] systemVersion]];
    [deviceInfo appendFormat:@"<model>%@</model>", [[UIDevice currentDevice] model]];
    [deviceInfo appendFormat:@"<localizedModel>%@</localizedModel>", [[UIDevice currentDevice] localizedModel]];
    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    char *idiomId = (idiom == UIUserInterfaceIdiomPhone ? "phone" : idiom == UIUserInterfaceIdiomPad ? "pad" : "unknown");
    [deviceInfo appendFormat:@"<userInterfaceIdiom>%s</userInterfaceIdiom>",  idiomId];
    [deviceInfo appendString:@"</deviceInfo>"];

    [self sendHelloMessage:deviceInfo];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendHelloMessage:(NSString *)helloBody {
    const char* helloRequestInfo = [helloBody cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
    resetMessageBuffer(&self->_requestMessage);
    appendMessageBufferWithFormat(&self->_requestMessage, "<request type=\"hello\">%s</request>\n",
                                  helloRequestInfo);
    [self->_netServiceController scheduleMessageToSend:&self->_requestMessage];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendPingMessage {
    resetMessageBuffer(&self->_requestMessage);
    appendMessageBufferWithFormat(&self->_requestMessage, "<request type=\"ping\"></request>\n");
    [self->_netServiceController scheduleMessageToSend:&self->_requestMessage];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendGetNextCmdMessage {
    resetMessageBuffer(&self->_requestMessage);
    appendMessageBufferWithFormat(&self->_requestMessage, "<request type=\"next-cmd\"></request>\n");
    [self->_netServiceController scheduleMessageToSend:&self->_requestMessage];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendReportMessage:(NSString *)reportBody withReportType:(ReportType)reportType {
    // send a report message only if we are connected to some test service
    if ([self connectedToNetService])
    {
        char *reportTypeName = g_reportTypeAttributeValues[reportType].valueName;
        resetMessageBuffer(&self->_requestMessage);
        const char *unescapedBody = [reportBody cStringUsingEncoding:NSUTF8StringEncoding];
        int size = strlen(unescapedBody);
        char *escapedBody = escapeCString(unescapedBody, size);
        appendMessageBufferWithFormat(&self->_requestMessage, "<request type=\"report\" kind=\"%s\" id=\"%s\"><%s>%s</%s></request>\n",
                                      reportTypeName,
                                      [deviceUniqueId cStringUsingEncoding:NSUTF8StringEncoding],
                                      reportTypeName,
                                      escapedBody,
                                      reportTypeName);
        [self->_netServiceController scheduleMessageToSend:&self->_requestMessage];
        free(escapedBody);
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) connectedToTestServer:(NSNotification*)notification
{
    if (self->_discoveryMode) {
        [self sendPingMessage];
    } else {
        [self dispatchTestEvent:(TestEvent)te_ConnectedToServer];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) disconnectedFromTestServer:(NSNotification*)notification
{
    if (self->_discoveryMode) {
        [self discoverNextNetServiceFromList:self->_netServiceController.serviceList usingController:self->_netServiceController];
    } else {
        [self dispatchTestEvent:(TestEvent)te_DisconnectedFromServer];
        self->_discoveryMode = YES;
        self->_serviceIndex = 0;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) doesNeedToDiscover {
    return self->_discoveryMode;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) setDiscoveryMode:(BOOL)mode {
    self->_discoveryMode = mode;
    self->_serviceIndex = 0;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)delayedConnection:(NSTimer*)theTimer {
    if (self->_discoveryMode && 0 <= self->_serviceIndex && self->_serviceIndex < [self->_netServiceController.serviceList count]) {
        int currentIndex = self->_serviceIndex;
        self->_serviceIndex++;
        [self->_netServiceController connectToService:[self->_netServiceController.serviceList objectAtIndex:currentIndex]];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) discoverNextNetServiceFromList:(NSArray *)serviceList usingController:(NetServiceController *)netServiceController {
    if (self->_discoveryMode && 0 <= self->_serviceIndex && self->_serviceIndex < [serviceList count]) {
        [NSTimer scheduledTimerWithTimeInterval:0.5
                                         target:self
                                       selector:@selector(delayedConnection:)
                                       userInfo:nil
                                        repeats:NO];
        // int currentIndex = self->_serviceIndex;
        // self->_serviceIndex++;
        // [netServiceController connectToService:[serviceList objectAtIndex:currentIndex]];
    } else {
        self->_discoveryMode = NO;
        self->_serviceIndex = 0;
        [netServiceController showAvailableTestServicesDialog];
    }

}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) connectedToNetService {
    
    return self->_netServiceController != nil && [self->_netServiceController connectedToNetService];
}

@end
