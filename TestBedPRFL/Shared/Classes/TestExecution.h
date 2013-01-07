//
//  TestExecution.h
//  TestBed
//
//  Created by Apple User on 11/28/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Test.h"
#import "TestGroup.h"

@interface TestExecution : NSOperation {
    Test *_test;
    TestGroup *_testGroup;
    NSIndexPath *_indexPath;
    id _controller;
    id<TestLog> _logger;
}

- (id)initWithTest:(Test *)test
         testGroup:(TestGroup *)parentTestGroup
        controller:(id)controller
            logger:(id<TestLog>)logger
      andIndexPath:(NSIndexPath *)indexPath;

@property (copy, readonly) Test *test;
@property (copy, readonly) NSIndexPath *indexPath;

@end
