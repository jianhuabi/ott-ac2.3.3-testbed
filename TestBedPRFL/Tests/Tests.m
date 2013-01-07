#import "Tests.h"

@interface Tests() 

@property (readonly, retain) id<TestLog> logger;

@end


@implementation Tests

@synthesize logger = _logger;
@synthesize parentTestGroup;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)Log:(NSString *)message {
    if (![NSThread isMainThread]) {
        [(NSObject *)self->_logger performSelectorOnMainThread:@selector(addLog:) withObject:(NSObject *)message waitUntilDone:YES];
    }
    else {
        [self.logger addLog:message];
    }

}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithLogger:(id<TestLog>) testLogger andParentTestGroup:(TestGroup *)testGroup {
    [super init];
    self->_logger = testLogger;
    self.parentTestGroup = testGroup;
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [parentTestGroup release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(id)SampleTestRules:(OperationId)operation withView:(DetailViewController*)view {
    id result = nil;
    
    switch (operation) {
        default:
            // raise an exception 
            break;
        case opid_getName:
            result = @"Sample Test Rules";
            break;
        case opid_getDescription:
            result = @"A sample test.";
            break;
        case opid_getTestType:
            result = [NSNumber numberWithShort:TestType_Automatic];
            break;
        case opid_runTest: {
            BOOL ret = YES;
            
            [self Log:@"Sample test rules!\n"];
            
            result = [NSNumber numberWithBool:ret];
        }
            break;
    }
    
    return result;
}

@end
