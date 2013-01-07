//
//  TestObject.m
//  TestBed
//
//  Created by Apple User on 11/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestObject.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation TestObject

@synthesize name;
@synthesize parent;
@synthesize testObjectType;
@synthesize variableName;

- (id) init {
    [super init];
    self.variableName = NO;
    return self;
}

- (void) dealloc {
	[name release];
    [parent release];
    [super dealloc];
}

+ (id) createObjectFromClass: (Class)primeClass {
    const char* primeClassName = class_getName(primeClass);
	id primeClassId = objc_lookUpClass(primeClassName);
	SEL selAlloc = sel_getUid("alloc");
	SEL selInit = sel_getUid("init");
	id primeClassObjectId = (id)objc_msgSend(primeClassId, selAlloc);
	primeClassObjectId = (id)objc_msgSend(primeClassObjectId, selInit);
    return primeClassObjectId;
}

+ (void) releaseObjectFromId: (id)object {
	SEL selRelease = sel_getUid("release");
    objc_msgSend(object, selRelease);
}

@end
