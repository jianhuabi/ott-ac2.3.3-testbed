//
//  RequestParsingContext.h
//  TestBoss
//
//  Created by Apple User on 12/9/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XmlSAXParser.h"

///////////////////////////////////////////////////////////////////////////////
// ResponseContext
//
// This object performs TestBoss response parsing and collects information 
// from the TestBoss response content. 
//
@interface ResponseContext: XmlSAXParser {
    RequestResponseMessageType _responseType; // response type
    ReportType _reportType; // a report type if the response type is msgType_Report 
    StatusType _responseStatus; // type of the response
    CmdType _cmdType; // type of the command sent in the msgType_Cmd response
    NSMutableArray *_deviceNameList;
    NSString *responseId; // response ID
}

- (id) init;
- (void)reset;
- (void)parseResponse:(const MessageBuffer *)response;

@property (nonatomic, assign) RequestResponseMessageType responseType;
@property (nonatomic, assign) ReportType reportType;
@property (nonatomic, assign) StatusType responseStatus;
@property (nonatomic, assign) CmdType cmdType;
@property (nonatomic, retain) NSMutableArray *deviceNameList;
@property (nonatomic, retain) NSString *responseId;

@end
