//
//  Test.m
//  TestBed
//
//  Created by Apple User on 11/18/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "Test.h"
#import "ProtocolFramework.h"
#import "TestGroup.h"
#import <objc/message.h>

DECLARE_NSSTRING(tagStart_testCaseResult, "<testCaseResult name=\"%s\" id=\"%s\" number=\"%d\" status=\"%s\" runs=\"%d\" passes=\"%d\" failures=\"%d\"%@>")
DECLARE_NSSTRING(tagEnd_testCaseResult, "</testCaseResult>")
DECLARE_NSSTRING(tagStart_testData, "<testData>")
DECLARE_NSSTRING(tagEnd_testData, "</testData>")
DECLARE_NSSTRING(tagStart_dataRecord, "<dataRecord name=\"%@\">")
DECLARE_NSSTRING(tagEnd_dataRecord, "</dataRecord>")
DECLARE_NSSTRING(tagStart_resultInfo, "<resultInfo>")
DECLARE_NSSTRING(tagEnd_resultInfo, "</resultInfo>")
DECLARE_NSSTRING(tagStart_listOfResults, "<listOfResults>")
DECLARE_NSSTRING(tagEnd_listOfResults, "</listOfResults>")
DECLARE_NSSTRING(tagStart_listOfErrors, "<listOfErrors>")
DECLARE_NSSTRING(tagEnd_listOfErrors, "</listOfErrors>")
DECLARE_NSSTRING(tagStart_resultText, "<resultText>")
DECLARE_NSSTRING(tagEnd_resultText, "</resultText>")
DECLARE_NSSTRING(tagStart_errorText, "<errorText>")
DECLARE_NSSTRING(tagEnd_errorText, "</errorText>")

TestStatusAttributeValue g_statusAttributeValues [] =
{
    {TestPassNonYetStarted, "not-started", @"grey-checked.png"},
    {TestPassInProcess, "in-process", @"grey-checked.png"},
    {TestPassFinishedWithFailure, "failed", @"red-crossed.png"},
    {TestPassFinishedSuccessfully, "succeeded", @"green-checked.png"},
    {TestSkipped, "skipped", @"grey-checked.png"}                
};

@implementation Test

@synthesize method;
@synthesize methodName;
@synthesize nativeFunc;
@synthesize testClass;
@synthesize numberTestRuns;
@synthesize numberPasses;
@synthesize numberFailures;
@synthesize testStatus;
@synthesize testId;
@synthesize iconName;
@synthesize serialNumber;
@synthesize dynamicUnitTest;
@synthesize iconNeedsToBeDownloaded;
@synthesize testIcon;
@synthesize entryId;
@synthesize showProgressBar;
@synthesize progressValue;
@synthesize testGenerator;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithName: (NSString *)testName andParentGroup:(TestGroup *)parentGroup {
    self.name = testName;
    self.parent = parentGroup;
    self.testObjectType = type_TestInstance;
    self.testStatus = TestPassNonYetStarted;
    self.testId = nil;
    self.iconName = nil;
    self.serialNumber = NSIntegerMax;
    self.iconNeedsToBeDownloaded = NO;
    self.testIcon = nil;
    self.showProgressBar = NO;
    self.progressValue = 0.0;
    self.testGenerator = NO;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)copy {
    Test *testCopy = [[Test alloc] initWithName:self.name andParentGroup:self.parent];
    testCopy.method = self.method;
    testCopy.methodName = [self.methodName copy];
    testCopy.nativeFunc = self.nativeFunc;
    testCopy.testClass = self.testClass;
    testCopy.numberTestRuns = self.numberTestRuns;
    testCopy.numberPasses = self.numberPasses;
    testCopy.numberFailures = self.numberFailures;
    testCopy.testStatus = self.testStatus;
    testCopy.iconName = [self.iconName copy];
    testCopy.serialNumber = self.serialNumber;
    testCopy.variableName = self.variableName;
    testCopy.dynamicUnitTest = self.dynamicUnitTest;
    testCopy.testId = [self.testId copy];
    testCopy.iconNeedsToBeDownloaded = self.iconNeedsToBeDownloaded;
    testCopy.testIcon = self.testIcon;
    testCopy.entryId = [self.entryId copy];
    testCopy.showProgressBar = self.showProgressBar;
    testCopy.testGenerator = self.testGenerator;
    return testCopy;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount {
    NSMutableString *statusReport = [NSMutableString stringWithCapacity:1024];
    *totalCount += 1;
    if (self.testStatus == TestPassFinishedSuccessfully) {
        *successfulCount += 1;
    }
    else if (self.testStatus == TestPassFinishedWithFailure) {
        *failedCount += 1;
    }
    const char *unescapedName = [self.name cStringUsingEncoding:NSUTF8StringEncoding];
    int size = strlen(unescapedName);
    char *escapedName = escapeCString(unescapedName, size);
    
    [statusReport appendString:[NSString stringWithFormat:tagStart_testCaseResult,
                                escapedName,
                                (self.testId == nil ? escapedName : [self.testId cStringUsingEncoding:NSUTF8StringEncoding]),
                                *totalCount,
                                g_statusAttributeValues[self.testStatus].valueName,
                                self.numberTestRuns,
                                self.numberPasses,
                                self.numberFailures,
                                @""]];
    free(escapedName);

    [statusReport appendString:tagStart_testData];
    [statusReport appendString:tagEnd_testData];

    [statusReport appendString:tagStart_resultInfo];
    [statusReport appendString:tagEnd_resultInfo];

    [statusReport appendString:tagEnd_testCaseResult];
    return statusReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getListReportString {
    const char *unescapedName = [self.name cStringUsingEncoding:NSUTF8StringEncoding];
    int size = strlen(unescapedName);
    char *escapedName = escapeCString(unescapedName, size);
    NSString *reportLine = [NSString stringWithFormat:@"<unitTest name=\"%s\"/>", escapedName];
    free(escapedName);
    return reportLine;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) dealloc {
    [methodName release];
    [iconName release];
    [testId release];
    [entryId release];
    [testIcon release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
+ (id) callTestFunction:(SEL)methodSelector
           fromInstance:(id)testInstance
             withTestId:(NSString *)theTestId
         usingOperation:(OperationId)operation
                 inView:(DetailViewController*)view
            dynamicType:(BOOL)isDynamic
            withEntryId:(NSString *)entryId
         andSectionName:(NSString *)sectionName {
    id result = isDynamic
        ? objc_msgSend(testInstance, methodSelector, theTestId, operation, view, entryId, sectionName) 
        : objc_msgSend(testInstance, methodSelector, operation, view); 
    return result;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) performTestOperation:(OperationId)operation fromInstance:(id)testInstance inView:(DetailViewController*)view {
    return [Test callTestFunction:method_getName(self.method)
                     fromInstance:testInstance
                       withTestId:self.testId
                   usingOperation:operation
                           inView:view
                      dynamicType:self.dynamicUnitTest
                      withEntryId:self.entryId
                   andSectionName:[self.parent getParentSectionName:self]];
}

@end
