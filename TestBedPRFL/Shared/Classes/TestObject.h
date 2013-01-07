//
//  TestObject.h
//  TestBed
//
//  Created by Apple User on 11/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TestGroup;

typedef enum {
    type_Unknown        = 0,
    type_TestInstance   = 1,
    type_TestGroup      = 2,
} TestObjectType;

@interface TestObject : NSObject {
	NSString *name;
    TestGroup *parent;
    TestObjectType  testObjectType;
    BOOL variableName;
}

+ (id) createObjectFromClass: (Class)primeClass;
+ (void) releaseObjectFromId: (id)object;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) TestGroup *parent;
@property TestObjectType testObjectType;
@property (assign) BOOL variableName;

@end

