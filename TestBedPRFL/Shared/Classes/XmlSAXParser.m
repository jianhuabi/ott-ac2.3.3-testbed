//
//  XmlSAXParser.m
//  TestBed
//
//  Created by Apple User on 5/19/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "XmlSAXParser.h"

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
static BOOL compareStrings(const char* left, const char* right) {
    return (left == NULL && right == NULL) || (left != NULL && right != NULL && strcmp(left, right) == 0);
}

@implementation XmlSAXParser

@synthesize parsingStatus = _parsingStatus;
@synthesize currentNodeInfo = _currentNodeInfo;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) init {
    self = [super init];
    if (self != nil) {
        self->_currentNodeInfo = NULL;
        self->_freePoolOfNodeInfo = NULL;
        [self reset];
    }
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    moveAllNodeInfoInstancesToFreePool(&self->_currentNodeInfo, &self->_freePoolOfNodeInfo);
    cleanFreePool(&self->_freePoolOfNodeInfo);
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)reset {
    self->_parsingStatus = statusType_Ok;
    moveAllNodeInfoInstancesToFreePool(&self->_currentNodeInfo, &self->_freePoolOfNodeInfo);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) addNode:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)uri {
    ParsingNodeInfo *newInfo = getNewNodeInfo(&self->_freePoolOfNodeInfo);
    
    if (newInfo != NULL) {
        newInfo->parentNode = self->_currentNodeInfo;
        newInfo->localname = localname;
        newInfo->prefix = prefix;
        newInfo->URI = uri;
        self->_currentNodeInfo = newInfo;
    }
    // fprintf(stderr, "RequestParsingContext: addNode:%s withPrefix:%s andUri:%s\n", localname, prefix, uri);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) currentNodeIsEqualTo:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)uri {
    BOOL isEqual = NO;
    if (self->_currentNodeInfo != NULL) {
        isEqual = compareStrings(localname, self->_currentNodeInfo->localname);
        if (isEqual) {
            isEqual = compareStrings(prefix, self->_currentNodeInfo->prefix);
        }
        if (isEqual) {
            isEqual = compareStrings(uri, self->_currentNodeInfo->URI);
        }
    }
    // fprintf(stderr, "RequestParsingContext: currentNodeIsEqualTo:%s withPrefix:%s andUri:%s\n", localname, prefix, uri);
    return isEqual;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) removeCurrentNode {
    // fprintf(stderr, "RequestParsingContext: removeCurrentNode:%s withPrefix:%s andUri:%s\n", self->_currentNodeInfo->localname, self->_currentNodeInfo->prefix, self->_currentNodeInfo->URI);
    moveNodeInfoInstanceToFreePool(&self->_currentNodeInfo, &self->_freePoolOfNodeInfo);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (StatusType) verifyParentLocalName:(const char*)localname {
    StatusType isCorrect = statusType_Error;
    if (self->_currentNodeInfo != NULL
        && compareStrings(localname, self->_currentNodeInfo->localname)) {
        isCorrect = statusType_Ok;
    } else if (localname == NULL) {
        // the node does not have parent
        isCorrect = statusType_Ok;
    }
    return isCorrect;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) setParsingStatus:(StatusType)status {
    if (self->_parsingStatus == statusType_Unknown || self->_parsingStatus == statusType_Ok) {
        self->_parsingStatus = status; 
    }
}

@end
