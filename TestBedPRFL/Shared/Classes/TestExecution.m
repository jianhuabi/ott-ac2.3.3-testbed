//
//  TestExecution.m
//  TestBed
//
//  Created by Apple User on 11/28/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "TestExecution.h"


@implementation TestExecution

@synthesize test = _test;
@synthesize indexPath = _indexPath;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithTest:(Test *)test
         testGroup:(TestGroup *)parentTestGroup
        controller:(id)controller
            logger:(id<TestLog>)logger
      andIndexPath:(NSIndexPath *)indexPath {
    
    // make the init method a thread safe one
    self = [super init];
    if (self != nil) {

        self->_test = [test copy];
        self->_testGroup = parentTestGroup;
        self->_controller = controller;
        self->_logger = logger;
        self->_indexPath = [indexPath copy];
    }
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc
{
    // can be called on any thread
    
    [self.test release];
    [self.indexPath release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)addRecordToLog:(NSString *)record {
    if (self->_logger != nil) {    
        [(NSObject *)self->_logger performSelectorOnMainThread:@selector(addLog:) withObject:(NSObject *)record waitUntilDone:NO];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendRecordToLog:(NSString *)record {
    if (self->_logger != nil) {    
        [(NSObject *)self->_logger performSelectorOnMainThread:@selector(sendLog:) withObject:(NSObject *)record waitUntilDone:YES];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)main
{
    
    NSNumber * result = NULL;
    
    NSString *testName = self.test.name;
    [self sendRecordToLog:[NSString stringWithFormat:@"<testLog name=\"%@\" group=\"%@\"><![CDATA[\n", testName, [self->_testGroup getFullParentName]]];
    [self addRecordToLog:[NSString stringWithFormat:@">>>>>> Started test '%@'\n", testName]];
    
    // update test run counter
    self.test.numberTestRuns++;
    
    if (self.test.nativeFunc != nil) {
        // Run a native unit test 
        BOOL success = YES;
        if (!self.test.nativeFunc()) {
            success = NO;
        }
        result = [NSNumber numberWithBool:success];
    }
    else {
        // Run an Objective-C unit test
        // Use a test object from the bound Objective-C test class.
        id testInstance = [self->_testGroup testsObject];
        
        if (testInstance != nil) {
            
            // run the unit test
            self.test.testStatus = TestPassInProcess;
            @try
            {
                result = [self.test performTestOperation:opid_runTest fromInstance:testInstance inView:self->_controller]; 
            }
            @catch (NSException *exception) 
            {
                [self addRecordToLog:[NSString stringWithFormat:@"!!!!!! Exception raised from test: %@: %@\n", 
                                      [exception name], [exception reason]]];
                result = NULL;
            }
        }
    }
    
    // analyze the test result
    if (result == NULL || !result.boolValue) {
        //[self addRecordToLog:@"Test failed!\n"];
        self.test.testStatus = TestPassFinishedWithFailure;
        self.test.numberFailures++;
    }
    else {
        self.test.testStatus = TestPassFinishedSuccessfully;
        self.test.numberPasses++;
    }
    [self addRecordToLog:[NSString stringWithFormat:@"<<<<<< Finished test '%@' with %@.\n", testName,
                          (self.test.testStatus == TestPassFinishedSuccessfully) ? @"SUCCESS" : @"FAILURE"]];
    [self sendRecordToLog:[NSString stringWithFormat:@"]]></testLog>\n", testName]];
}


@end
