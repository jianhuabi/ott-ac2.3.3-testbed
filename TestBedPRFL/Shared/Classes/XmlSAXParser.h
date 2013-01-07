//
//  XmlSAXParser.h
//  TestBed
//
//  Created by Apple User on 5/19/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProtocolFramework.h"

@interface XmlSAXParser : NSObject
{
    StatusType _parsingStatus; // status of the parsing
@private
    ParsingNodeInfo *_currentNodeInfo; // a stack of embedded XML nodes in process
    ParsingNodeInfo *_freePoolOfNodeInfo; //  a pool of free ParsingNodeInfo structures used during the parsing
}

@property (nonatomic, assign) StatusType parsingStatus;
@property (nonatomic, assign) ParsingNodeInfo *currentNodeInfo;

- (id) init;
- (void)reset;
- (void) addNode:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)uri;
- (void) setParsingStatus:(StatusType)status;
- (StatusType) verifyParentLocalName:(const char*)localname;
- (BOOL) currentNodeIsEqualTo:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)uri;
- (void) removeCurrentNode;

@end
