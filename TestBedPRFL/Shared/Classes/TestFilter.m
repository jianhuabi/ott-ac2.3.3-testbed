//
//  TestFilter.m
//  ActiveCloak
//
//  Created by Apple User on 2/17/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "TestFilter.h"
#import "Tests.h"

@implementation TestFilter

@synthesize groupNames = _groupNames;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithOptions:(TestOptions)options withGroupNames:(NSArray *)groupNames andWithTestFlags:(TestFlags)flags {
    [super init];
    self->_groupNames = groupNames != nil ? [[NSArray alloc] initWithArray:groupNames] : nil;
    self->_testOptions = options;
    self->_testFlags = flags;
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) isGroupNameAllowed: (NSString *)groupName {
    BOOL allowed = NO;
    
    if (self->_groupNames != nil) {
        for (NSString *name in self->_groupNames) {
            if ([groupName isEqualToString:name]) {
                allowed = YES;
                break;
            }
        }
    } else {
        allowed = YES;
    }
    
    return allowed;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) individualGroups {
    return self->_groupNames != nil;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) multipleGroups {
    return self->_groupNames == nil || [self->_groupNames count] > 1;
}
   
/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) dealloc {
    [self->_groupNames release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) isTestFlagsEmpty {
    return self->_testFlags == TestFlag_Empty;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) verifyTestFlagsExist:(TestFlags)flags {
    return (self->_testFlags & flags) != TestFlag_Empty;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) isOptionTurnedOn:(TestOptions)option {
    return (self->_testOptions & option) != TestOption_Empty;
}

@end
