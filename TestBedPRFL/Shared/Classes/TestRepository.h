//
//  TestRepository.h
//  TestBed
//
//  Created by Apple User on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Test.h"
#import "Tests.h"
#import "TestObject.h"
#import "TestGroup.h"
#import "TestLog.h"
#import "TestFilter.h"


@interface TestRepository : NSObject {

    TestGroup *rootTestGroup;
    TestFilter *_testFilter;
    id<TestLog> _logger;
}

+ (NSMutableArray*) nativeTests;

- (id) initWithLogger:(id<TestLog>)logger;
- (id) initWithLogger:(id<TestLog>)logger andTestFilter:(TestFilter *)filter;
- (void) createTestCollectionTestsClasses;
- (TestGroup *) registerTestClassesFrom: (Class)primeClass tillSuperclass:(Class)baseClass;
- (TestGroup *) registerTestFunctionsOf:(Class)testClass fromParentGroup:(TestGroup *)parentGroup;
- (NSString *) getStatusReportString;
- (NSString *) getListReportString;
- (BOOL) registerUnitTestWithId:(NSString *)testId
              fromTestsInstance:(Tests *)testsInstance
                      withClass:(Class)testClass
                    usingMethod:(Method)testMethod
                    withEntryId:(NSString *)entryId
                      inSection:(NSString *)parentSectionName;
- (BOOL) removeTestSectionByName:(NSString *)sectionName inClass:(Class)testClass;
- (TestGroup *) getTestGroupForClass:(Class)targetClass;


@property (nonatomic, retain) TestGroup *rootTestGroup;
@property (nonatomic, readonly) TestFilter* testFilter;
           
@end
