//
//  Test.h
//  TestBed
//
//  Created by Apple User on 11/18/10.
//  Copyright 2010 Irdeto. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "TestBedTests.h"
#import "TestObject.h"
#import "TestLog.h"
#import "Tests.h"

typedef enum {
    TestPassNonYetStarted           = 0,
    TestPassInProcess               = 1,
    TestPassFinishedWithFailure     = 2,
    TestPassFinishedSuccessfully    = 3,
    TestSkipped                     = 4,
} TestPassStateType;

typedef struct _testStateAttributeValue
{
    TestPassStateType testState;
    char *valueName;
    NSString *imageName;
} TestStatusAttributeValue;

@interface Test : TestObject 
{
    Class testClass;
	NSString *methodName;
    NSString *testId;
    NSString *iconName;
    NSString *entryId; // this is an entry Id for dynamic tests

	Method method;
	NativeTestFunc *nativeFunc;
    BOOL dynamicUnitTest;   // if the flag is true, it means that the test was generated 
                            // dynamically and it requires additional parameters like testId, entryId, 
                            // and section name.
    
    NSInteger numberTestRuns;
    NSInteger numberPasses;
    NSInteger numberFailures;
    NSInteger serialNumber;
    TestPassStateType   testStatus;
    BOOL iconNeedsToBeDownloaded;
    UIImage *testIcon;
    BOOL showProgressBar;   // id the field is YES, it means that the test makes deal
                            // with a progress bar that should be shown in the view.
    float progressValue;    // this is the last progress value for the progress bar bound to the test
    BOOL testGenerator;     // if the flag is true, it means that the test case generates a set of 
                            // test cases and it can executed in advance to prepare the set of test cases
                            // on background during the application load. Although it is not necessary.
}

+ (id) callTestFunction:(SEL)methodSelector
           fromInstance:(id)testInstance
             withTestId:(NSString *)theTestId
         usingOperation:(OperationId)operation
                 inView:(DetailViewController*)view
            dynamicType:(BOOL)isDynamic
            withEntryId:(NSString *)entryId
         andSectionName:(NSString *)sectionName;

- (id) initWithName: (NSString *)testName andParentGroup:(TestGroup *)parentGroup;
- (id)copy;
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount;
- (NSString *) getListReportString;
- (id) performTestOperation:(OperationId)operation fromInstance:(id)testInstance inView:(DetailViewController*)view;

@property (nonatomic, retain) NSString *methodName;
@property (nonatomic, retain) NSString *testId;
@property (nonatomic) Method method;
@property (nonatomic) NativeTestFunc * nativeFunc;
@property (assign) Class testClass;
@property (assign) NSInteger numberTestRuns;
@property (assign) NSInteger numberPasses;
@property (assign) NSInteger numberFailures;
@property (assign) TestPassStateType testStatus;
@property (nonatomic, retain) NSString *iconName;
@property (nonatomic, retain) UIImage *testIcon;
@property (assign) NSInteger serialNumber;
@property (assign) BOOL dynamicUnitTest;
@property (assign) BOOL iconNeedsToBeDownloaded;
@property (nonatomic, retain) NSString *entryId;
@property (assign) BOOL showProgressBar;
@property (assign) float progressValue;
@property (assign) BOOL testGenerator;

@end
