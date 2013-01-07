#import "RootViewController.h"
#import "DetailViewController.h"
#import "GroupViewController.h"
#import "Test.h"
#import "TestBedTests.h"

@implementation RootViewController

@synthesize testRepository;
@synthesize currentGroupView = _currentGroupView;
@synthesize tabBarController = _tabBarController;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
+(RootViewController*) currentView:(RootViewController*)update;
{
	static RootViewController * ret = nil;
	if (update != nil)
	{
		ret = update;
	}
    //fprintf(stderr, "RootViewController.currentView: ret = 0x%08x\n", (NSUInteger)ret);
	return ret;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void NativeToObjC(char * name, NativeTestFunc * func)
{
	// Create a auto release pool since this code is called before
	// the main objective C runtime is started
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	Test * test = [Test alloc];
	
	test.methodName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
	test.name = test.methodName;
	test.method = nil;
	test.nativeFunc = func;
    test.testObjectType = type_TestInstance;
	
	[[TestRepository nativeTests] addObject:test];
	
	[pool release];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void TestLog(char * log, ...)
{
	char buffer[1024];
	va_list args;
	va_start(args, log);
	vsprintf(buffer, log, args);
	va_end(args);

	// Since this is likely run on a non-ObjC thread, create a 
	// autorelease pool to catch the NSString object, even though
	// performSelectorOnMainThread will retain it
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString * nss = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
	RootViewController * temp = [RootViewController currentView:nil];
	[temp performSelectorOnMainThread:@selector(addLog:) withObject:nss waitUntilDone:NO];
	
	[pool drain];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
+(void)resetLog
{
	UITextView * tv = [[[RootViewController currentView:nil] detailViewController] outputTextView];
	tv.text = @"Log has been Reset!\n";
	[tv setText:[tv text]];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
+(void)addLog:(NSString*)log
{
    NSLog(@"%@", log);
    DetailViewController *detailController = [[RootViewController currentView:nil] detailViewController];
	UITextView * tv = [detailController outputTextView];
	[tv setText:[[tv text] stringByAppendingString:(log != nil ? log : @"(null)")]];
	
    // scroll to end of textview
	[tv scrollRangeToVisible:NSMakeRange(tv.text.length - 1, 0)];

    if (detailController.testEventController != nil && [detailController.testEventController connectedToNetService]) {
        [detailController.testEventController sendReportMessage:log withReportType:reportType_Log];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)addLog:(NSString*)log
{
    NSLog(@"%@", log);
    DetailViewController *detailController = [[RootViewController currentView:nil] detailViewController];
	UITextView * tv = [detailController outputTextView];
	[tv setText:[[tv text] stringByAppendingString:(log != nil ? log : @"(null)")]];

	// scroll to end of textview
	[tv scrollRangeToVisible:NSMakeRange(tv.text.length - 1, 0)];
    
    if (detailController.testEventController != nil && [detailController.testEventController connectedToNetService]) {
        [detailController.testEventController sendReportMessage:log withReportType:reportType_Log];
    }
}

/*-----------------------------------------------------------------------------
    This functions sends a log message directly to the TestBoss server
    without writing it to the log text view.
    It is needed for sending specific log separtors for reporting purposes.
 ----------------------------------------------------------------------------*/
-(void) sendLog:(NSString*)log {
    DetailViewController *detailController = [[RootViewController currentView:nil] detailViewController];
    if (detailController.testEventController != nil && [detailController.testEventController connectedToNetService]) {
        [detailController.testEventController sendReportMessage:log withReportType:reportType_Log];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithStyle:(UITableViewStyle)style {

    return [self initWithStyle:style andTestFilter:nil];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithStyle:(UITableViewStyle)style andTestFilter:(TestFilter *)filter{
    
    [super initWithStyle:style];
    
    if (filter != nil) {
        self.testRepository = [[TestRepository alloc] initWithLogger:self andTestFilter:filter];
    }
    else {
        self.testRepository = [[TestRepository alloc] initWithLogger:self];
    }
    self.currentTestGroup = self.testRepository.rootTestGroup;
    self.rootViewController = self; // need it because RootViewController is inherited from GroupViewController;
    self->_testGeneratorsAlreadyExecuted = NO;
    
    return self;
}

/*-----------------------------------------------------------------------------
    This function should be called only in the iPhone version of TestBed
 ----------------------------------------------------------------------------*/
-(id) initWithStyle:(UITableViewStyle)style andTabBarController:(UITabBarController *)tabBarController {

    return [self initWithStyle:style testFilter:nil andTabBarController:tabBarController];
}

/*-----------------------------------------------------------------------------
    This function should be called only in the iPhone version of TestBed
 ----------------------------------------------------------------------------*/
-(id) initWithStyle:(UITableViewStyle)style testFilter:(TestFilter *)filter andTabBarController:(UITabBarController *)tabBarController {
    assert(IS_IPHONE);
    [super initWithStyle:style];
    
    if (filter != nil) {
        self.testRepository = [[TestRepository alloc] initWithLogger:self andTestFilter:filter];
    }
    else {
        self.testRepository = [[TestRepository alloc] initWithLogger:self];
    }
    self.currentTestGroup = self.testRepository.rootTestGroup;
    self.rootViewController = self; // need it because RootViewController is inherited from GroupViewController;
    self->_tabBarController = tabBarController; // this a weak reference to allow deallocation at the shutting down
    self->_testGeneratorsAlreadyExecuted = NO;
    
    // In the iPhone mode we should setup TabBarItem attributes like and image and title
    // to show it correctly in the GUI
    self.tabBarItem.image = [UIImage imageNamed:@"test-black.png"];
    self.title = @"Test Group";
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidLoad 
{
    [super viewDidLoad];
	[RootViewController currentView:self];
	if (IS_IPHONE)
	{
        // In iPhone mode we need to select the second tab bar item in order to initialize DetailViewController.
        if (detailViewController.testEventController == nil) {
            self->_tabBarController.selectedViewController = [self->_tabBarController.viewControllers objectAtIndex:1];
        }
    }
#ifdef ACTIVECLOAKDEMO    
    else {        
        // run test generators if the option exists
        // The option means that we are forcing to run 
        // the content discovery tests in automatic mode
        TestFilter *testFilter = testRepository.testFilter;
        if (testFilter != nil 
            && [testFilter isOptionTurnedOn:TestOption_ExecuteTestGenerators] 
            && !self->_testGeneratorsAlreadyExecuted) {
            
            [self initiateTestGeneratorExecution];
            [self.detailViewController showRootView];
            self->_testGeneratorsAlreadyExecuted = YES;
        }

    }
#endif
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc 
{
	[testRepository release];
    [super dealloc];
}

@end

