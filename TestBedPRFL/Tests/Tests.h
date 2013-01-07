#import <Foundation/Foundation.h>
#import "TestLog.h"
#import "TestObject.h"

@class DetailViewController;

void TestLog(char *, ...);

@interface Tests : NSObject
{
    id<TestLog> _logger;
    TestGroup*  parentTestGroup;
}

- (id)initWithLogger:(id<TestLog>) testLogger andParentTestGroup:(TestGroup *)testGroup;
- (void)Log:(NSString *)message;

@property (nonatomic, retain) TestGroup* parentTestGroup;

@end

typedef enum {
    opid_None               = 0,
    opid_getName,
    opid_getDescription,
    opid_getTestType,
    opid_getTestFlags,
    opid_getTestSection,
    opid_getTestIcon,
    opid_getSerialNumber,
    opid_runTest,
} OperationId;

typedef enum {
    TestType_Unknown    = 0,
    TestType_Manual     = 1,
    TestType_Automatic  = 2
} TestType;

typedef enum {
    TestFlag_Empty                   = 0x00000000,  
    TestFlag_DemoTest                = 0x40000000,  // A test with this flag should be used in the demo mode
    TestFlag_VariableName            = 0x00000001,  // A test with this flag has a variable name and the
                                                    // engine should ask for the test name every time it 
                                                    // needs to update it in UI
    TestFlag_IconNeedsToBeDownloaded = 0x00000002,  // The test has an icon that should be downloaded 
                                                    // from a remote server using the specified URL
    TestFlag_TestProducer            = 0x00000004,  // this flag means that the corresponding unit test
                                                    // is intended to create a set of unit tests
                                                    // based on either a content discovery functionality 
                                                    // or some other mechanism
} TestFlags;

#define TEST_DECLARATION(testfunction) \
-(id)testfunction:(OperationId)operation withView:(DetailViewController*)view

#define AUTO_TEST_START(testfunction, testname, description) \
-(id)testfunction:(OperationId)operation withView:(DetailViewController*)view \
{ \
    id __result = nil; \
    const char *__testname = testname; \
    const char *__description = description; \
\
    switch (operation) { \
    default: \
            break; \
    case opid_getName: \
        __result = __testname == NULL ? nil : [NSString stringWithCString:__testname encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getDescription: \
        __result = __description == NULL ? nil : [NSString stringWithCString:__description encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestType: \
        __result = [NSNumber numberWithShort:TestType_Automatic]; \
        break; \
    case opid_runTest: \
    { \
        BOOL __ret = YES; \

#define MANUAL_TEST_START(testfunction, testname, description) \
-(id)testfunction:(OperationId)operation withView:(DetailViewController*)view \
{ \
    id __result = nil; \
    const char *__testname = testname; \
    const char *__description = description; \
\
    switch (operation) { \
    default: \
        break; \
    case opid_getName: \
        __result = __testname == NULL ? nil : [NSString stringWithCString:__testname encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getDescription: \
        __result = __description == NULL ? nil : [NSString stringWithCString:__description encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestType: \
        __result = [NSNumber numberWithShort:TestType_Manual]; \
        break; \
    case opid_runTest: \
        { \
            BOOL __ret = YES; \

#define AUTO_TEST_START_EXT(testfunction, testname, description, number, flags, section, icon) \
-(id)testfunction:(OperationId)operation withView:(DetailViewController*)view \
{ \
    id __result = nil; \
    const char *__testname = testname; \
    const char *__description = description; \
    const char *__sectionName = section; \
    const char *__iconPath = icon; \
    TestFlags __testFlags = flags; \
    NSInteger __serialNumber = number; \
\
    switch (operation) { \
    default: \
        break; \
    case opid_getName: \
        __result = __testname == NULL ? nil : [NSString stringWithCString:__testname encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getDescription: \
        __result = __description == NULL ? nil : [NSString stringWithCString:__description encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestType: \
        __result = [NSNumber numberWithShort:TestType_Automatic]; \
        break; \
    case opid_getTestFlags: \
        __result = [NSNumber numberWithUnsignedLong:__testFlags]; \
        break; \
    case opid_getSerialNumber: \
        __result = [NSNumber numberWithInteger:__serialNumber]; \
        break; \
    case opid_getTestSection: \
        __result = __sectionName == NULL ? nil : [NSString stringWithCString:__sectionName encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestIcon: \
        __result = __iconPath == NULL ? nil : [NSString stringWithCString:__iconPath encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_runTest: \
        { \
            BOOL __ret = YES; \

#define MANUAL_TEST_START_EXT(testfunction, testname, description, number, flags, section, icon) \
-(id)testfunction:(OperationId)operation withView:(DetailViewController*)view \
{ \
    id __result = nil; \
    const char *__testname = testname; \
    const char *__description = description; \
    const char *__sectionName = section; \
    const char *__iconPath = icon; \
    TestFlags __testFlags = flags; \
    NSInteger __serialNumber = number; \
\
    switch (operation) { \
    default: \
        break; \
    case opid_getName: \
        __result = __testname == NULL ? nil : [NSString stringWithCString:__testname encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getDescription: \
        __result = __description == NULL ? nil : [NSString stringWithCString:__description encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestType: \
        __result = [NSNumber numberWithShort:TestType_Manual]; \
        break; \
    case opid_getTestFlags: \
        __result = [NSNumber numberWithUnsignedLong:__testFlags]; \
        break; \
    case opid_getSerialNumber: \
        __result = [NSNumber numberWithInteger:__serialNumber]; \
        break; \
    case opid_getTestSection: \
        __result = __sectionName == NULL ? nil : [NSString stringWithCString:__sectionName encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_getTestIcon: \
        __result = __iconPath == NULL ? nil : [NSString stringWithCString:__iconPath encoding:NSUTF8StringEncoding]; \
        break; \
    case opid_runTest: \
        { \
            BOOL __ret = YES; \

#define TEST_END \
            __result = [NSNumber numberWithBool:__ret]; \
        } \
        break; \
    } \
\
    return __result; \
} \



