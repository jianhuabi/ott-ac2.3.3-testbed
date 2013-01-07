//
//  TestRepository.m
//  TestBed
//
//  Created by Apple User on 11/18/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "TestRepository.h"
#import "ProtocolFramework.h"
#import <objc/runtime.h>
#import <objc/message.h>

DECLARE_NSSTRING(c_xmlDeclaration, "<?xml version=\"1.0\" encoding=\"utf-8\" ?>")
DECLARE_NSSTRING(c_xmlStylesheet, "<?xml-stylesheet type=\"text/xsl\" href=\"TestResultView.xslt\"?>")
DECLARE_NSSTRING(tagStart_testAutomationResults, "<testAutomationResults dateTime=\"%@\">")
DECLARE_NSSTRING(tagEnd_testAutomationResults, "</testAutomationResults>")
DECLARE_NSSTRING(tagStart_listOfTestCaseResults, "<listOfTestCaseResults>")
DECLARE_NSSTRING(tagEnd_listOfTestCaseResults, "</listOfTestCaseResults>")
DECLARE_NSSTRING(tag_statistic, "<statistic numberOfTestCases=\"%d\" successful=\"%d\" failed=\"%d\" skipped=\"%d\"/>")

@interface TestRepository ()

- (BOOL) processMethod:(Method)method
                withId:(NSString *)testId
     fromTestsInstance:(Tests *)testsObject
             withClass:(Class)testClass
           inTestGroup:(TestGroup *)testGroup
           dynamicType:(BOOL)isDynamic
           withEntryId:(NSString *)entryId
             inSection:(NSString *)parentSection;
    
@end


@implementation TestRepository

@synthesize rootTestGroup;
@synthesize testFilter = _testFilter;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
+(NSMutableArray*)nativeTests
{
	static NSMutableArray * ret = nil;
	if (ret == nil)
	{
		ret = [[NSMutableArray alloc] init];
	}
	return ret;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithLogger:(id<TestLog>)logger {
    self = [super init];
    self->_testFilter = nil;
    if (self != nil) {
        self->_logger = logger;
        [self createTestCollectionTestsClasses];
        return self;
    }
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithLogger:(id<TestLog>)logger andTestFilter:(TestFilter *)filter{
    self = [super init];
    self->_testFilter = filter;
    [self->_testFilter retain];
    if (self != nil) {
        self->_logger = logger;
        [self createTestCollectionTestsClasses];
        return self;
    }
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) dealloc {
    [rootTestGroup release];
    [self->_testFilter release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) createTestCollectionTestsClasses {

    if (rootTestGroup == NULL)
    {
        // run through all classes of the application
        // and process the classes that were derived from Tests class
        int numClasses;
        Class *classes = NULL;
        Class testsClass = NSClassFromString(@"Tests");
    
        numClasses = objc_getClassList(NULL, 0);
    
        if (numClasses > 0) {
            classes = malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
        
            if (classes != NULL) {
                const char* className = NULL;
                const char* primeClassName = NULL; 
            
                for (int index = 0; index < numClasses; index++) {
                    Class primeClass = classes[index];
                    Class superClass = class_getSuperclass(primeClass);
                    while (superClass != Nil) {
                        if (superClass == testsClass) {
                            primeClassName = class_getName(primeClass);
                            className = class_getName(superClass);
                            
                            // if a test filter exists and requires to register individual groups,
                            // verify if the group is allowed to register.
                            if (self->_testFilter != nil && [self->_testFilter individualGroups]) {
                                NSString *targetGroupName = [NSString stringWithCString:primeClassName encoding:NSUTF8StringEncoding];
                                if ([self->_testFilter isGroupNameAllowed:targetGroupName]) {
                                    NSLog(@"primeClass = %s only", primeClassName);
                                    // create a root test group ahead if there are several groups in the filter
                                    if (self.rootTestGroup == nil && [self->_testFilter multipleGroups]) {
                                        self.rootTestGroup = [[TestGroup alloc] initWithName:@"Tests" andParent:nil];
                                    }
                                    
                                    [self registerTestFunctionsOf:primeClass fromParentGroup:self.rootTestGroup];
                                }
                                
                            } else {
                                // Otherwise register the entier branch
                                NSLog(@"primeClass = %s, superClass = %s", primeClassName, className);
                                [self registerTestClassesFrom:primeClass tillSuperclass:testsClass];
                            }
                            break;
                        }
                        superClass = class_getSuperclass(superClass);
                    }
                }
            }
        
            free(classes);
        }
        
        if (self->_testFilter == nil || ![self->_testFilter individualGroups] || [self->_testFilter isGroupNameAllowed:@"Native Tests"]) {
            // Create a test group for Native Tests
            TestGroup *nativeTestGroup = [rootTestGroup establishTestGroupWithName:@"Native Tests"];
	
            for (Test * native in [TestRepository nativeTests]) {
                [nativeTestGroup addTest:native toSection:@"Tests"];
            }
        }
        
        [self.rootTestGroup removeEmptySubgroups];
    }
}   

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *)registerTestClassesFrom: (Class)primeClass tillSuperclass:(Class)baseClass{
    TestGroup *parentGroup = NULL;
    
    if (primeClass != baseClass) {
        parentGroup = [self registerTestClassesFrom:class_getSuperclass(primeClass) tillSuperclass:baseClass];
    }

    return [self registerTestFunctionsOf:primeClass fromParentGroup:parentGroup];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *)registerTestFunctionsOf:(Class)testClass fromParentGroup:(TestGroup *)parentGroup {

    TestGroup *testGroup = NULL;
    const char* testClassName = class_getName(testClass);
    NSString *targetTestGroupName = [NSString stringWithCString:testClassName encoding:NSUTF8StringEncoding];
    if (parentGroup != nil) {
        testGroup = [parentGroup getSubgroup:targetTestGroupName];
    }
    else {
        testGroup = self.rootTestGroup;
    }

    if (testGroup == nil) {
        
        Method *methods;
        unsigned int methodCount = 0;
        
        // create a test object and initialize it with a logger
        // we need the object to communicate with it's test functions.
        id testsObject = [TestObject createObjectFromClass:testClass];
        
        if (testsObject != nil) {
            SEL selInitWithLoggerAndParentTestGroup = sel_getUid("initWithLogger:andParentTestGroup:");

            // establish a test group for the test class.
            if (parentGroup != nil) {
                testGroup = [parentGroup establishTestGroupWithName:targetTestGroupName];
            }
            else {
                // create the root group
                self.rootTestGroup = [[TestGroup alloc] initWithName:targetTestGroupName andParent:nil];
                testGroup = self.rootTestGroup;
            }
            
            // initialize the test object with logger and parent test group
            testsObject = objc_msgSend(testsObject, selInitWithLoggerAndParentTestGroup, self->_logger, testGroup);

            // save the pre-created testsObject to the test group
            // it will be used during test runs
            testGroup.testsObject = testsObject;
            
            // Create predefined sections in the group if it is required
            // by the TestOption_UseSections option turned on.
            if ([self->_testFilter isOptionTurnedOn:TestOption_UseSections]) {
                SEL selGetSectionOrder = sel_getUid("getSectionOrder");
                if (class_respondsToSelector(testClass, selGetSectionOrder)) {
                    id sectionOrderInstance = objc_msgSend(testsObject, selGetSectionOrder);
                    if (sectionOrderInstance != nil && [sectionOrderInstance isKindOfClass:[NSArray class]]) {
                        NSArray *sectionOrder = (NSArray *)sectionOrderInstance;
                        for (NSString *sectionName in sectionOrder) {
                            [testGroup establishTestSectionWithName:sectionName];
                        }
                    }
                }
            }
            
            methods = class_copyMethodList(testClass, &methodCount);
            
            for (int i = 0; i < methodCount; i ++)
            {
                [self processMethod:methods[i]
                             withId:nil
                  fromTestsInstance:testsObject
                          withClass:testClass
                        inTestGroup:testGroup
                        dynamicType:NO
                        withEntryId:nil
                          inSection:nil];
            }
            
            free(methods);
            
            [testGroup removeEmptySections];
            
            if ([self->_testFilter isOptionTurnedOn:TestOption_UserDefinedOrder]) {
                [testGroup sortTestsInSections:SortType_UserDefined];
            }
            else if (![self->_testFilter isOptionTurnedOn:TestOption_UnsortedOrder]) {
                [testGroup sortTestsInSections:SortType_Default];
            }
            
        }
    }
    
    return testGroup;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) processMethod:(Method)method
                withId:(NSString *)testId
     fromTestsInstance:(Tests *)testsObject
             withClass:(Class)testClass
           inTestGroup:(TestGroup *)testGroup
           dynamicType:(BOOL)isDynamic
           withEntryId:(NSString *)entryId
             inSection:(NSString *)parentSectionName {
    BOOL success = YES;
    SEL methodSelector = method_getName(method);
    const char* method_name = sel_getName(methodSelector);
    unsigned nargs = method_getNumberOfArguments(method);
    const char* typeEncoding = method_getTypeEncoding(method);
    const char* typeExpected = isDynamic ? "@28@0:4@8i12@16@20@24" : "@16@0:4i8@12";
    int nargsExpected = isDynamic ? 7 : 4;
    
    // register methods that have type is equal either to 
    //   -(id)testfunction:(NSString *)testId usingOperation:(OperationId)operation underView:(DetailViewController*)view
    // or 
    //   -(id)testfunction:(OperationId)operation withView:(DetailViewController*)view
    if (nargs == nargsExpected && strcmp(typeEncoding, typeExpected) == 0) {
        // ask unit test for its name
        NSString *testName = [Test callTestFunction:methodSelector
                                       fromInstance:testsObject
                                         withTestId:testId
                                     usingOperation:opid_getName
                                             inView:nil
                                        dynamicType:isDynamic
                                        withEntryId:entryId
                                     andSectionName:parentSectionName];
        
        // if test does not have name, ignore it
        if (testName != nil) {
            BOOL registerTest = NO;
            TestFlags testFlags = TestFlag_Empty;
            id testFlagsObject = [Test callTestFunction:methodSelector
                                           fromInstance:testsObject
                                             withTestId:testId
                                         usingOperation:opid_getTestFlags
                                                 inView:nil
                                            dynamicType:isDynamic
                                            withEntryId:entryId
                                         andSectionName:parentSectionName];
            if (testFlagsObject != nil && [testFlagsObject isKindOfClass:[NSNumber class]]) {
                testFlags = [testFlagsObject unsignedLongValue];
            }
            
            if (self->_testFilter != nil && ![self->_testFilter isTestFlagsEmpty]) {
                // if testFilter exists and has not empty test flags,
                // verify that the unit test owns the particular flag.
                // If it is true, register the method. Otherwise, ignore it.
                registerTest = [self->_testFilter verifyTestFlagsExist:testFlags];
            } else {
                registerTest = YES;
            }
            
            if (registerTest) {
                Test * test = [[Test alloc] initWithName:testName andParentGroup:testGroup];
                test.methodName = [NSString stringWithCString:method_name encoding:NSUTF8StringEncoding];
                test.method = method;
                test.nativeFunc = nil;
                test.testClass = testClass;
                test.variableName = testFlags & TestFlag_VariableName ? YES : NO;
                test.dynamicUnitTest = isDynamic;
                test.entryId = entryId;
                test.testId = testId != nil ? [NSString stringWithString:testId] : [NSString stringWithString:testName];
                test.iconNeedsToBeDownloaded = testFlags & TestFlag_IconNeedsToBeDownloaded ? YES : NO;
                test.testGenerator = testFlags & TestFlag_TestProducer ? YES : NO;
                
                if (test.testGenerator) {
                    NSLog(@"TestRepository::prosessMethod: found a test generator = %s", method_name);
                }
                
                // if the TestOption_UseSections option turned on, 
                // add the test to the default "Tests" section 
                // or to the section with the name obtained from 
                // the test directly using opid_getTestSection operation id.
                NSString *sectionName = @"Tests";
                if ([self->_testFilter isOptionTurnedOn:TestOption_UseSections]) {
                    id sectionNameInstance = [Test callTestFunction:methodSelector
                                                       fromInstance:testsObject
                                                         withTestId:testId
                                                     usingOperation:opid_getTestSection
                                                             inView:nil
                                                        dynamicType:isDynamic
                                                        withEntryId:entryId
                                                     andSectionName:parentSectionName];
                    if (sectionNameInstance != nil && [sectionNameInstance isKindOfClass:[NSString class]]) {
                        sectionName = (NSString *)sectionNameInstance;
                    }
                }
                
                // if the TestOption_UseIcons option turned on, 
                // try to obtain image file name from the unit test
                // using opid_getTestIcon operation id.
                if ([self->_testFilter isOptionTurnedOn:TestOption_UseIcons]) {
                    id iconNameInstance = [Test callTestFunction:methodSelector
                                                    fromInstance:testsObject
                                                      withTestId:testId
                                                  usingOperation:opid_getTestIcon
                                                          inView:nil
                                                     dynamicType:isDynamic
                                                     withEntryId:entryId
                                                  andSectionName:parentSectionName];
                    if (iconNameInstance != nil && [iconNameInstance isKindOfClass:[NSString class]]) {
                        NSString *iconName = (NSString *)iconNameInstance;
                        
                        test.iconName = iconName;
                    }
                }
                
                // if the TestOption_UserDefinedOrder option turned on, 
                // try to obtain serial number from the unit test
                // using opid_getSerialNumber operation id
                if ([self->_testFilter isOptionTurnedOn:TestOption_UserDefinedOrder]) {
                    id serialNumberInstance = [Test callTestFunction:methodSelector
                                                        fromInstance:testsObject
                                                          withTestId:testId
                                                      usingOperation:opid_getSerialNumber
                                                              inView:nil
                                                         dynamicType:YES
                                                         withEntryId:entryId
                                                      andSectionName:parentSectionName];
                    if (serialNumberInstance != nil && [serialNumberInstance isKindOfClass:[NSNumber class]]) {
                        NSInteger serialNumber = [serialNumberInstance integerValue];
                        test.serialNumber = serialNumber;
                    }
                }
                
                [testGroup addTest:test toSection:sectionName]; 

                if (isDynamic && [self->_testFilter isOptionTurnedOn:TestOption_UserDefinedOrder]) {
                    [testGroup sortTestsInSections:SortType_UserDefined];
                }
                else if (isDynamic && ![self->_testFilter isOptionTurnedOn:TestOption_UnsortedOrder]) {
                    [testGroup sortTestsInSections:SortType_Default];
                }
                
            }
        }
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getStatusReportString {
    
    NSMutableString *statusReport = [NSMutableString stringWithCapacity:1024];
    NSUInteger numberOfTestCases = 0;
    NSUInteger numberOfSuccessful = 0;
    NSUInteger numberOfFailed = 0;
    
    [statusReport appendString:c_xmlDeclaration];
    [statusReport appendString:c_xmlStylesheet];
    [statusReport appendString:[NSString stringWithFormat:tagStart_testAutomationResults, [[NSDate date] description]]];
    [statusReport appendString:tagStart_listOfTestCaseResults];
  
    if (rootTestGroup != nil) {
        [statusReport appendString:[rootTestGroup getStatusReportStringAndCollect:&numberOfTestCases successful:&numberOfSuccessful failed:&numberOfFailed]];
    }
    
    [statusReport appendString:tagEnd_listOfTestCaseResults];
    [statusReport appendString:[NSString stringWithFormat:tag_statistic,
                                numberOfTestCases,
                                numberOfSuccessful,
                                numberOfFailed,
                                numberOfTestCases - numberOfSuccessful - numberOfFailed]];
    [statusReport appendString:tagEnd_testAutomationResults];
    return statusReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getListReportString {
    NSMutableString *listReport = [NSMutableString stringWithCapacity:1024];
    NSString *startTag = [NSString stringWithFormat:@"<testList>"];
    [listReport appendString:startTag];
    
    if (rootTestGroup != nil) {
        [listReport appendString:[rootTestGroup getListReportString]];
    }
    
    [listReport appendString:@"</testList>"];
    return listReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *) getTestGroupForClass:(Class)targetClass {
    TestGroup * resultTestGroup = nil;
    Class baseTestsClass = NSClassFromString(@"Tests");

    // if a test filter exists and requires to register individual group,
    // verify if the class is allowed to register.
    if (self->_testFilter != nil && [self->_testFilter individualGroups]) {
        const char* targetClassName = class_getName(targetClass);
        NSString *targetGroupName = [NSString stringWithCString:targetClassName encoding:NSUTF8StringEncoding];
        if ([self->_testFilter isGroupNameAllowed:targetGroupName]) {
            
            if ([targetGroupName isEqualToString:self.rootTestGroup.name]) {
                // if we registered only one individual group, 
                // the root test group should be the target one
                resultTestGroup = self.rootTestGroup;
            }
            else {
                // if we registered several individual groups, the root test group
                // should contain the target one.
                resultTestGroup = [self.rootTestGroup getSubgroup:targetGroupName];
            }
        }
        
    } else {
        if (targetClass == baseTestsClass) {
            resultTestGroup = rootTestGroup;
        }
        else {
            Class superClass = class_getSuperclass(targetClass);
            TestGroup *superGroup = [self getTestGroupForClass:superClass];
            const char* targetClassName = class_getName(targetClass);
            NSString *targetGroupName = [NSString stringWithCString:targetClassName encoding:NSUTF8StringEncoding];
            resultTestGroup = [superGroup getSubgroup:targetGroupName];
            //[targetGroupName release];
        }
    }

    return resultTestGroup;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) registerUnitTestWithId:(NSString *)testId
              fromTestsInstance:(Tests *)testsInstance
                      withClass:(Class)testClass
                    usingMethod:(Method)testMethod
                    withEntryId:(NSString *)entryId
                      inSection:(NSString *)parentSectionName {
    BOOL success = YES;
    TestGroup *parentTestGroup = [self getTestGroupForClass:testClass];
    
    success = [self processMethod:testMethod
                           withId:testId
                fromTestsInstance:testsInstance
                        withClass:testClass
                      inTestGroup:parentTestGroup
                      dynamicType:YES
                      withEntryId:entryId
                        inSection:parentSectionName];
    
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) removeTestSectionByName:(NSString *)sectionName inClass:(Class)testClass {
    BOOL success = NO;
    TestGroup *parentTestGroup = [self getTestGroupForClass:testClass];
    
    if (parentTestGroup != nil) {
        success = [parentTestGroup deleteTestSectionWithName:sectionName];
    }
    
    return success;
}



@end
