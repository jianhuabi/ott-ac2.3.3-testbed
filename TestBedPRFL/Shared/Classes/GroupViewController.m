//
//  GroupViewController.m
//  TestBed
//
//  Created by Apple User on 11/19/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "GroupViewController.h"
#import "RootViewController.h"
#import "DetailViewController.h"

#define kProgressBarViewTag				4		// for tagging the UIProgressView control in a table view cell to update and recycle it
#define kTitleLabelViewTag              2       // for tagging the UILabel control in a table view cell to update and recycle it

extern TestStatusAttributeValue g_statusAttributeValues [];

@interface GroupViewController () 

@property (nonatomic, retain, readonly) NSOperationQueue *queue;
@property (nonatomic, retain) TestExecution *testExecution;

- (void) executeNextTestObject;
- (void) runEntireTestGroup;
- (void) setExecutionFlagTo:(BOOL)value;
- (void) setFinishedFlagTo:(BOOL)value;
- (void) setAppearedFlagTo:(BOOL)value;
- (BOOL) canTestBeRunAutomatically:(Test *)atomicTest;
- (void) initiateTestExecution:(Test *)atomicTest;
- (void) testExecutionDone:(TestExecution *)executor;
- (GroupViewController *)establishNewGroupViewController:(TestGroup *)hostTestGroup animated:(BOOL)animated; // 
- (void) addObserverOnAppearence; 
- (void) runTestsInRange:(NSRange *)testRange startingFromIndex:(NSUInteger)index;
- (void) synchronizeTableViewWithTestGroup;
- (void) startIconDownload:(Test *)testRecord forIndexPath:(NSIndexPath *)indexPath;

@end


@implementation GroupViewController

@synthesize currentTestGroup;
@synthesize detailViewController;
@synthesize rootViewController;
@synthesize imageDownloadsInProgress;
@synthesize tableStyle = _tableStyle;
@synthesize queue = _queue;
@synthesize isFinished = _isFinished;
@synthesize isAppeared = _isAppeared;
@synthesize isExecuting = _isExecuting;
@synthesize testExecution = _testExecution;

#pragma mark -
#pragma mark Initialization

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithStyle:(UITableViewStyle)style {

    // Customization that is not appropriate for viewDidLoad.
    
    if ((self = [super initWithStyle:style])) {
        // create and initialize and operation queue
        self->_tableStyle = style;
        self->_queue = [[NSOperationQueue alloc] init];
        assert(self->_queue != nil);
        self->_isFinished = NO;
        self->_isAppeared = NO;
        self->_isExecuting = NO;
        self->_executionRange.location = 0;
        self->_executionRange.length = 0;
        self->_execIndex = 0;
        self->_executeTestGenerators = NO;
        self->_topMostExecuted = NO;
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(currentTestGroup.name, @"Test group view navigation title");
    
    TestFilter *testFilter = self.rootViewController.testRepository.testFilter;
    if (testFilter == nil || ![testFilter isOptionTurnedOn:TestOption_HideTopRunButton]) {
        // display an Run button in the navigation bar for this view controller.
        UIBarButtonItem *runButtonItem = [[[UIBarButtonItem alloc]
                                           initWithTitle:NSLocalizedString(@"Run", @"")
                                           style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(runGroupOfTestsAction:)]
                                          autorelease];
        
        self.navigationItem.rightBarButtonItem = runButtonItem;
    }
    
    // make the pop over control with the table view shorter 
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(340, 750); 
    
    // mark the hosting test group that is was synchronized with GUI
    [currentTestGroup synchronized];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)runGroupOfTestsAction:(id)sender {
    if (!self->_isExecuting) {
        // run tests only if we are not in an 'isExecuting' state.
        self->_topMostExecuted = YES;
        [self runEntireTestGroup];
        [self executeNextTestObject];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)initiateTestGeneratorExecution {
    if (!self->_isExecuting) {
        // initiate tests only if we are not in an 'isExecuting' state.
        self->_topMostExecuted = YES;
        [self runTestGenerators];
        [self executeNextTestObject];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)runTestGenerators {
    if (!self->_isExecuting) {
        // run test generators only if we are not in an 'isExecuting' state.
        self->_executeTestGenerators = YES;
        [self runEntireTestGroup];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) runEntireTestGroup {
    NSRange range;
    range.location = 0;
    range.length = self.currentTestGroup.count;
    [self runTestsInRange:&range startingFromIndex:0];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) runTestsInRange:(NSRange *)testRange startingFromIndex:(NSUInteger)index {
    self->_executionRange.location = testRange->location;
    self->_executionRange.length = testRange->length;
    self->_execIndex = index;
    self->_isExecuting = YES; // do not need to notify
    self->_isFinished = NO; // do not need to notify

    self.navigationItem.hidesBackButton = YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) executeNextTestObject {
    BOOL nextIsExecuted = NO; 
    BOOL finished = NO;

    // running loop through all test objects in the group until we found 
    // either a subgroup of tests or an atomic test that can be run 
    // in the automatic mode or the execution of the group is finished
    while (!nextIsExecuted && !finished) {

        // if the execution index is still in the execution range
        // run test by the index
        // otherwise, finish execution of the group
       
        if (self->_isExecuting
            && self->_executionRange.location <= self->_execIndex
            && self->_execIndex < self->_executionRange.location + self->_executionRange.length) {
            
            TestObject *testObject = [currentTestGroup getTestObjectByConsecutiveIndex:self->_execIndex];
            
            if (testObject != nil && testObject.testObjectType == type_TestGroup) {
                
                TestGroup *childGroup = (TestGroup *)testObject;
                // run test cases in the child group only if the _executeTestGenerators 
                // is not ON or the group contains a test generator
                if (!self->_executeTestGenerators || [childGroup hasTestGenerator]) {

                    // need to perform test from a test sub-group
                    // create next GroupViewController and put it into executable mode
                
                    //fprintf(stderr, "executeNextTestObject: test group with name = %s\n", [childGroup.name cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]);
                    //NSLog(@"executeNextTestObject: test group with name = %s\n", [childGroup.name cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]);
                    GroupViewController *childGroupView = [self establishNewGroupViewController:childGroup animated:NO];
                    
                    // execute test cases from the child group
                    // depending on the _executeTestGenerators flag
                    if (self->_executeTestGenerators) {
                        [childGroupView runTestGenerators];
                    }
                    else {
                        [childGroupView runEntireTestGroup];
                    }
                    [childGroupView addObserverOnAppearence];
                    [childGroupView addObserver:self forKeyPath:@"isFinished" options:0 context:&self->_execIndex];
                    [childGroupView release];
                    nextIsExecuted = YES;
                }
            }
            else if (testObject != nil && testObject.testObjectType == type_TestInstance) {
                
                // need to perform an atomic unit test
                // create TestExecution object 
                Test *atomicTest = (Test *)testObject;
                    
                // run the child atomic test case only if the _executeTestGenerators
                // is not ON or the test case is a test generator
                if (!self->_executeTestGenerators || [atomicTest testGenerator]) {
                    
                    //fprintf(stderr, "executeNextTestObject: atomic test with name = %s\n", [atomicTest.name cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]);
                    //NSLog(@"executeNextTestObject: atomic test with name = %s\n", [atomicTest.name cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]);
                    // run a test case if either we are not in automatic mode or the test can be run in the automatic mode
                    // otherwise, the test will be skipped
                    if (!detailViewController.testEventController.runOnlyAutomatic || [self canTestBeRunAutomatically:atomicTest]) {
                        [self initiateTestExecution:atomicTest];
                        nextIsExecuted = YES;
                    }
                }
            }
            
            self->_execIndex++;
        }
        else {
            if (!self->_isFinished && self->_isExecuting && self->_topMostExecuted) {
                // the app just finished to run unit tests.
                [detailViewController.testEventController dispatchTestEvent:te_FinishedTesting];
                self->_topMostExecuted = NO;
            }
            [self setExecutionFlagTo:NO];
            [self setFinishedFlagTo:YES];
            
            if (self->_executeTestGenerators && self == [RootViewController currentView:nil]) {
                // close popover in the portrait view after we have finished automatic test 
                // generation
                [detailViewController hideRootView];
            }
            self->_executeTestGenerators = NO;
            
            self.navigationItem.hidesBackButton = NO;
            finished = YES;
        }
    }
}
        
/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) setExecutionFlagTo:(BOOL)value {
    if (self.isExecuting != value) {
        [self willChangeValueForKey:@"isExecuting"];
        self->_isExecuting = value;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) setFinishedFlagTo:(BOOL)value {
    if (self.isFinished != value) {
        [self willChangeValueForKey:@"isFinished"];
        self->_isFinished = value;
        [self didChangeValueForKey:@"isFinished"];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) setAppearedFlagTo:(BOOL)value {
    if (self.isAppeared != value) {
        [self willChangeValueForKey:@"isAppeared"];
        self->_isAppeared = value;
        [self didChangeValueForKey:@"isAppeared"];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) addObserverOnAppearence {
    [self addObserver:self forKeyPath:@"isAppeared" options:0 context:&self->_isAppeared];
    [detailViewController showRootView];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"GroupViewController::observeValueForKeyPath: enter with KeyPath = %@", keyPath);
    if (context == &self->_execIndex) {
        
        // the child group has finished testing execution
        GroupViewController *childGroupView;
        
        // validate correct obeserver behavior
        assert([keyPath isEqual:@"isFinished"]);
        childGroupView = (GroupViewController *) object;
        assert([childGroupView isKindOfClass:[GroupViewController class]]);
        assert([childGroupView isFinished]);
        
        [childGroupView removeObserver:self forKeyPath:@"isFinished"];

        [[self navigationController] popViewControllerAnimated:NO];
        [self addObserverOnAppearence];
        
        //fprintf(stderr, "childGroupView finished testing\n");
        
    } else if (context == &self->_isAppeared) {
        
        // the current GroupViewController appeared.
        GroupViewController *myself = nil;

        // validate correct obeserver behavior
        assert([keyPath isEqual:@"isAppeared"]);
        myself = (GroupViewController *) object;
        assert([myself isKindOfClass:[GroupViewController class]]);
        assert([myself isAppeared]);

        //fprintf(stderr, "view appeared - %s\n", [self.currentTestGroup.name cStringUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding]);
        
        [myself removeObserver:self forKeyPath:@"isAppeared"];
        [myself executeNextTestObject];
        
    } else if (context == &self->_queue) {
        // an atomic unit test has started or finished an execution of the test
        // We observe -isExecuting purely for logging purposes.
        TestExecution *testExecutor;
    
        // can be running on any thread
        assert([keyPath isEqual:@"isExecuting"]);
        testExecutor = (TestExecution *) object;
        assert([testExecutor isKindOfClass:[TestExecution class]]);
        // if ([testExecutor isExecuting]) {
        //     fprintf(stderr, "test executing\n");
        // } else {
        //     fprintf(stderr, "test stopped\n");
        // }
    } else if (context == &self->_testExecution) {
        TestExecution *testExecutor;
        
        // if the operation has finished, call testExecutionDone: on the main thread to deal 
        // with the results.
        
        // can be running on any thread
        assert([keyPath isEqual:@"isFinished"]);
        testExecutor = (TestExecution *) object;
        assert([testExecutor isKindOfClass:[TestExecution class]]);
        assert([testExecutor isFinished]);

        [self performSelectorOnMainThread:@selector(testExecutionDone:) withObject:testExecutor waitUntilDone:NO];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) canTestBeRunAutomatically:(Test *)atomicTest {
    BOOL canBeRun = NO;
    
    if (atomicTest != nil && atomicTest.nativeFunc == nil && atomicTest.method != nil) {
        id testInstance = [currentTestGroup testsObject];
    
        if (testInstance != nil) {
        
            // run the unit test
            id testType = [atomicTest performTestOperation:opid_getTestType fromInstance:testInstance inView:self.detailViewController];

            if ([testType isKindOfClass:[NSNumber class]]){
                canBeRun = [testType shortValue] == TestType_Automatic;
            }
        }
    }
    return canBeRun;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) initiateTestExecution:(Test *)atomicTest {

    // need to perform an atomic unit test
    // create TestExecution object 
    
    NSIndexPath *indexPath = [currentTestGroup getIndexPathByConsecutiveIndex:self->_execIndex];
    self.testExecution = [[TestExecution alloc] initWithTest:atomicTest
                                                    testGroup:currentTestGroup
                                                   controller:self.detailViewController
                                                       logger:self.rootViewController
                                                 andIndexPath:indexPath];
    assert(self.testExecution != nil);
    
    // set up two observers for the test execution
    [self.testExecution addObserver:self forKeyPath:@"isFinished"  options:0 context:&self->_testExecution];
    [self.testExecution addObserver:self forKeyPath:@"isExecuting" options:0 context:&self->_queue];
    
    //fprintf(stderr, "test queuing\n");
    [self.queue addOperation:self.testExecution];
    
    // notify testEventController that a test has been started
    [detailViewController.testEventController dispatchTestEvent:te_StartedUnitTest];

    // the user interface is adjusted by a KVO observer on executing.
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];

}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)testExecutionDone:(TestExecution *)executor {
    assert([NSThread isMainThread]);
    assert([executor isKindOfClass:[TestExecution class]]);
    
    assert(![executor isExecuting]);
    
    // notify testEventController that a test has been completed
    [detailViewController.testEventController dispatchTestEvent:te_CompletedUnitTest];
    
    // Always remove our observer, regardless of whether we care about 
    // the results of this operation.
    
    //fprintf(stderr, "test done\n");
    [executor removeObserver:self forKeyPath:@"isFinished"];
    [executor removeObserver:self forKeyPath:@"isExecuting"];
    
    // Check to see whether these are the test execution we're looking for. 
    // If not, we just discard it because it is probably canceled.
    
    if (executor == self.testExecution) {
        assert( ! [executor isCancelled] );

        // Clear out our record of the operation.  The user interface is adjusted 
        // by a KVO observer on recalculating.
        Test *currentTest = (Test *)[self.currentTestGroup objectAtIndexPath:executor.indexPath];
        
        currentTest.testStatus = executor.test.testStatus;
        currentTest.numberTestRuns = executor.test.numberTestRuns;
        currentTest.numberPasses = executor.test.numberPasses;
        currentTest.numberFailures = executor.test.numberFailures;

        [self.testExecution release];
        self.testExecution = nil;
        
        [self synchronizeTableViewWithTestGroup];
        
        // update the table view cell 
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:executor.indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
        //fprintf(stderr, "test view commit\n");
        
    } else {
        //fprintf(stderr, "test discard\n");
    }
    [self executeNextTestObject];
}

/*-----------------------------------------------------------------------------
    This method synchronizes the table view with the current state of the 
    hosting test group after a test execution.
    It asks the test group if it has been modified. It it is true, it recreates 
    every modified section in the view and deletes excessive or inserts 
    additional necessary sections at the end of the table.
    It also verifies that number of rows in the table sections is equal to the 
    number of test cases in the corresponding sections. It it is not the same,
    it will recreate these sections as well.
 ----------------------------------------------------------------------------*/
- (void) synchronizeTableViewWithTestGroup {
    BOOL needToUpdateSections = [currentTestGroup hasBeenModified];
    UITableView *tableView = (UITableView *)self.view;
    NSUInteger currentSectionNumber = [tableView numberOfSections];
    NSUInteger numberOfSectionsInGroup = [currentTestGroup numberOfSections];
    NSUInteger minSectionNumber = currentSectionNumber < numberOfSectionsInGroup ? currentSectionNumber : numberOfSectionsInGroup;
    
    for (NSUInteger sectionNumber = 0; sectionNumber < minSectionNumber && !needToUpdateSections; sectionNumber++) {
        NSInteger numberOfTestsInSection = [currentTestGroup numberOfTestsInSection:sectionNumber];
        NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:sectionNumber];
        if (numberOfRowsInSection != numberOfTestsInSection) {
            needToUpdateSections = YES;
            break;
        }
    }
    
    if (needToUpdateSections || currentSectionNumber != numberOfSectionsInGroup) {
        [tableView beginUpdates];

        for (NSUInteger sectionNumber = 0; sectionNumber < minSectionNumber; sectionNumber++) {
            NSInteger numberOfTestsInSection = [currentTestGroup numberOfTestsInSection:sectionNumber];
            NSInteger numberOfRowsInSection = [tableView numberOfRowsInSection:sectionNumber];
            BOOL sectionModified = [currentTestGroup hasSectionBeenModified:sectionNumber];
            // if the test section has been modified or it has number of test cases different from
            // the number of rows in the corresponding table view section, the table view section
            // should be recreated
            if (sectionModified || numberOfRowsInSection != numberOfTestsInSection) {
                NSIndexSet *sectionIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(sectionNumber, 1)];
                [tableView deleteSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
                [tableView insertSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        
        if (currentSectionNumber < numberOfSectionsInGroup) {
            // insert new section(s)
            NSRange sectionRange = NSMakeRange(currentSectionNumber, numberOfSectionsInGroup - currentSectionNumber);
            NSIndexSet *sectionIndexSet = [NSIndexSet indexSetWithIndexesInRange:sectionRange];
            [tableView insertSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
        }
        else if (currentSectionNumber > numberOfSectionsInGroup) {
            // delete obsolete section(s)
            NSRange sectionRange = NSMakeRange(numberOfSectionsInGroup, currentSectionNumber - numberOfSectionsInGroup);
            NSIndexSet *sectionIndexSet = [NSIndexSet indexSetWithIndexesInRange:sectionRange];
            [tableView deleteSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationNone];
        }
        
        [tableView endUpdates];
    }
    
    [currentTestGroup synchronized];
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewWillAppear:(BOOL)animated {
    //NSLog(@"GroupViewController::viewWillAppear");
    [super viewWillAppear:animated];
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.rootViewController.currentGroupView = self;
    //NSLog(@"GroupViewController::viewDidAppear");
    [self setAppearedFlagTo:YES];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
// Notifies when rotation begins, reaches halfway point and ends.
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //NSLog(@"GroupViewController::willRotateToInterfaceOrientation");
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //NSLog(@"GroupViewController::didRotateFromInterfaceOrientation");
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [currentTestGroup numberOfSections];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [currentTestGroup numberOfTestsInSection:section];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)runSingleTestAction:(id)sender event:(id)event
{
    if (!self->_isExecuting) {
        NSSet *touches = [event allTouches];
        UITouch *touch = [touches anyObject];
        CGPoint currentTouchPosition = [touch locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
        if (indexPath != nil)
        {
            TestObject *testObject = [currentTestGroup getTestObject:indexPath];
            if (testObject.testObjectType == type_TestInstance) {
                NSRange range;
                range.location = [currentTestGroup getConsecutiveIndexByIndexPath:indexPath];
                range.length = 1;
                [self runTestsInRange:&range startingFromIndex:range.location];
                [self executeNextTestObject];
            }
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIButton *)createRunButton {
    UIButton *runButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    runButton.backgroundColor = [UIColor clearColor];
    runButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [runButton setTitle:@"Run" forState:UIControlStateNormal];
    [runButton addTarget:self action:@selector(runSingleTestAction:event:) forControlEvents:UIControlEventTouchUpInside];
    // Work out required size
    CGSize fontSize = [runButton.titleLabel.text sizeWithFont:runButton.titleLabel.font];
    CGFloat xOffset = 0.0;
    CGRect buttonFrame = CGRectMake(xOffset, 15, fontSize.width + 20.0, 24);
    [runButton setFrame:buttonFrame];
    return runButton;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIImageView *)createStatusIconView {
    UIImageView *statusIconView = [[[UIImageView alloc] initWithFrame:CGRectMake(9.0, 12.0, 20.0, 21.0)] autorelease];
    statusIconView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    return statusIconView;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UILabel *)createTitleLabelView {
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(45.0, 0.0, 250.0, 43.0)] autorelease];
    titleLabel.font = [UIFont systemFontOfSize: 18.0];
    titleLabel.textAlignment = UITextAlignmentLeft;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    titleLabel.tag = kTitleLabelViewTag;
    return titleLabel;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UILabel *)makeTitleLabelNarrow:(UILabel *)titleLabel {
    CGRect frame = CGRectMake(45.0, 0.0, 250.0, 21.0);
    titleLabel.font = [UIFont systemFontOfSize: 11.0];
    titleLabel.frame = frame;
    return titleLabel;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UILabel *)makeTitleLabelRegular:(UILabel *)titleLabel {
    CGRect frame = CGRectMake(45.0, 0.0, 250.0, 43.0);
    titleLabel.font = [UIFont systemFontOfSize: 18.0];
    titleLabel.frame = frame;
    return titleLabel;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIProgressView *)createProgressBarView:(float)currentValue {
    CGRect frame = CGRectMake(45.0, 25.0, 200.0, 18.0);
    UIProgressView *progressBar = [[UIProgressView alloc] initWithFrame:frame];
    progressBar.progressViewStyle = UIProgressViewStyleDefault;
    progressBar.progress = currentValue;
    
    progressBar.tag = kProgressBarViewTag;	// tag this view for later so we can remove it from recycled table cells
    return progressBar;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIActivityIndicatorView *)createActivityIndicatorView {
    UIActivityIndicatorView *activityView = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(9.0, 12.0, 20.0, 20.0)] autorelease];
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    activityView.hidesWhenStopped = YES;
    return activityView;
}
    
/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
//- (NSString *)tableView:(UITableView *)atableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *sectionName = [currentTestGroup getSectionName:section];
//	
//	return sectionName;
//}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString *sectionName = [currentTestGroup getSectionName:section];
	// create the parent view
	UIView * customSectionView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -5, self.tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
	//customSectionView.backgroundColor = [[UIColor colorWithRed:0.306 green:0.161 blue:0.047 alpha:1.000] colorWithAlphaComponent:0.9];
    customSectionView.backgroundColor = tableView.backgroundColor;
	
	// create the label
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, customSectionView.frame.size.height)];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor brownColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont fontWithName:@"Arial" size:16];
	headerLabel.text = sectionName;
	
	// package and return
	[customSectionView addSubview:headerLabel];
	[headerLabel release];
	return [customSectionView autorelease];
	
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	
	return 40.0;
}

/*-----------------------------------------------------------------------------
    Customize the appearance of table view cells.
 ----------------------------------------------------------------------------*/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellIdentifier";
    UIActivityIndicatorView *activityView = nil;
    UILabel *titleLabel = nil;
    UIImageView *statusIcon = nil;
    UIButton *runButtonView = nil;
    
    // NSLog(@"GrouplViewController::tableView:cellForRowAtIndexPath: enter");
    
    // obtain a table cell from the reusable pool
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // if the reusable pool is empty, create a new cell
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } 
    else {
        // try to reuse this cell components as many as possible
        int numberOfSubviews = [cell.contentView.subviews count];
        // fprintf(stderr, "found number of subviews = %d\n", numberOfSubviews);
        for (int index = 0; index < numberOfSubviews; index++) {
            UIView *subview = [cell.contentView.subviews objectAtIndex:index];
            if ([subview isKindOfClass:[UIActivityIndicatorView class]]) {
                // assign for reuse
                activityView = (UIActivityIndicatorView *)subview;
                // found an alive activity view
                if ([activityView isAnimating]) {
                    // disable the alive activity view
                    [activityView stopAnimating];
                }
            } else if ([subview isKindOfClass:[UILabel class]]) {
                // reuse title label
                titleLabel = (UILabel *)subview;
                [self makeTitleLabelRegular:titleLabel];
            } else if ([subview isKindOfClass:[UIImageView class]]) {
                // reuse the image view
                statusIcon = (UIImageView *)subview;
            } else if ([subview isKindOfClass:[UIProgressView class]]) {
                // do not need to remove the progress view here
                // it will be removed in the next statement
            }
        }
        // remove controls from the cell, which we will reuse later
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        if (cell.accessoryView != nil && [cell.accessoryView isKindOfClass:[UIButton class]]) {
            // reuse Riun button
            runButtonView = (UIButton *)cell.accessoryView;
        }
    }

    
    TestObject *testObject = [currentTestGroup getTestObject:indexPath];
    
    if (titleLabel == nil) {
        titleLabel = [self createTitleLabelView];
    }
    
    if (IS_IPAD) {
        titleLabel.backgroundColor = tableView.backgroundColor;
    }
    
    if (testObject.testObjectType == type_TestGroup) {
        titleLabel.text = testObject.name;
        if (statusIcon == nil) {
            statusIcon = [self createStatusIconView];
        }
        statusIcon.image = [UIImage imageNamed:@"folder.png"];
        [cell.contentView addSubview:statusIcon];
        [cell.contentView addSubview:titleLabel];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        Test *test = (Test *)testObject;
        
        if (test.showProgressBar) {
            [self makeTitleLabelNarrow:titleLabel];
        }

        // setup title label of the cell
        if (test.variableName ) {
            id testInstance = [currentTestGroup testsObject];
            id testNameInstance = [test performTestOperation:opid_getName fromInstance:testInstance inView:detailViewController];
            if (testNameInstance != nil && [testNameInstance isKindOfClass:[NSString class]]) {
                titleLabel.text = (NSString *)testNameInstance;
            }
            else {
                titleLabel.text = test.name;
            }

        }
        else {
            titleLabel.text = test.name;
        }
        
        
        if (self.testExecution != nil
            && self.testExecution.indexPath.section == indexPath.section
            && self.testExecution.indexPath.row == indexPath.row) {
            // if the test is in execution state, start activity view icon
            if (activityView == nil) {
                activityView = [self createActivityIndicatorView];
            }
            assert(activityView != nil);
            
            [activityView startAnimating];
            [cell.contentView addSubview:activityView];
            
        }
        else if (test.iconName != nil) {
            // establish a UI image view to put the test icon
            if (statusIcon == nil) {
                statusIcon = [[[UIImageView alloc] initWithFrame:CGRectMake(3.0, 5.0, 36.0, 36.0)] autorelease];
                statusIcon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
            }
            else {
                statusIcon.frame = CGRectMake(3.0, 5.0, 36.0, 36.0);
            }

            if (test.iconNeedsToBeDownloaded) {
                // Only load cached images; defer new downloads until scrolling ends
                if (test.testIcon == nil)
                {
                    if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
                    {
                        [self startIconDownload:test forIndexPath:indexPath];
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    statusIcon.image = [UIImage imageNamed:@"Content.png"];                
                }
                else
                {
                    statusIcon.image = test.testIcon;
                }
            }
            else {
                statusIcon.image = [UIImage imageNamed:test.iconName];
            }
            
            [cell.contentView addSubview:statusIcon];
        } 
        else {
            if (statusIcon == nil) {
                statusIcon = [self createStatusIconView];
            }
            else {
                statusIcon.frame = CGRectMake(9.0, 12.0, 20.0, 21.0);
            }
            statusIcon.image = [UIImage imageNamed:g_statusAttributeValues[test.testStatus].imageName];
            [cell.contentView addSubview:statusIcon];
        }
       
        [cell.contentView addSubview:titleLabel];

        if (test.showProgressBar) {
            [cell.contentView addSubview:[self createProgressBarView:test.progressValue]];
        }

        if (runButtonView == nil) {
            runButtonView = [self createRunButton];
        }
        cell.accessoryView = runButtonView;

    }
    
    // set accessability properties for UI Automation
    cell.isAccessibilityElement = YES;
    cell.accessibilityLabel = testObject.name;
    
	return cell;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"GroupViewController::tableView:heightForRowAtIndexPath: enter, row=%d, section=%d", indexPath.row, indexPath.section);
	
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	return cell.frame.size.height;
}



#pragma mark -
#pragma mark Table cell icon support

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)startIconDownload:(Test *)testRecord forIndexPath:(NSIndexPath *)indexPath {
    IconDownloader *iconDownloader = imageDownloadsInProgress == nil ? nil : [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil) 
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.testRecord = testRecord;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        if (imageDownloadsInProgress == nil) {
            imageDownloadsInProgress = [[NSMutableDictionary alloc] initWithCapacity:20];
        }
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
        [iconDownloader release];   
    }
}

/*-----------------------------------------------------------------------------
    this method is used in case the user scrolled into a set of cells that 
    don't have their test icons yet
 ----------------------------------------------------------------------------*/
- (void)loadImagesForOnscreenRows {
    if ([self.currentTestGroup count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            TestObject *testObject = [self.currentTestGroup getTestObject:indexPath];
            
            if (testObject.testObjectType == type_TestInstance) // avoid the app icon download if the app already has an icon
            {
                Test *testInstance = (Test *)testObject;
                if (testInstance.iconNeedsToBeDownloaded && !testInstance.testIcon) {
                    [self startIconDownload:testInstance forIndexPath:indexPath];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark IconDownloaderDelegate callback functions

/*-----------------------------------------------------------------------------
    appImageDidLoad:
 
    called by our ImageDownloader when an icon is ready to be displayed
 ----------------------------------------------------------------------------*/
- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        UIImageView *statusIcon = (UIImageView *)[cell.contentView.subviews objectAtIndex:0];
        statusIcon.image = iconDownloader.testRecord.testIcon;
        [imageDownloadsInProgress removeObjectForKey:indexPath];
    }
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

/*-----------------------------------------------------------------------------
    Load images for all onscreen rows when scrolling is finished
 ----------------------------------------------------------------------------*/
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

/*-----------------------------------------------------------------------------

 ----------------------------------------------------------------------------*/
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

#pragma mark -
#pragma mark Update progress bar 

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)enableProgressBar:(BOOL)enable atIndexPath:(NSIndexPath *)indexPath withProgress:(float)progressValue {
    
    if (indexPath != nil) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil) {
            UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:kTitleLabelViewTag];
            UIProgressView *progressBarView = (UIProgressView *)[cell.contentView viewWithTag:kProgressBarViewTag];
            if (enable && progressBarView == nil) {
                [self makeTitleLabelNarrow:titleLabel];
                UIProgressView *progressBarView = [self createProgressBarView:progressValue];
                [cell.contentView addSubview:progressBarView];
                //NSLog(@"GroupViewController::enableProgressBar:atIndexPath:withProgress: ENABLE progress bar, row=%d, section=%d", indexPath.row, indexPath.section);
                //CGRect frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height + 10);
                //[cell setFrame:frame];
            } else if (!enable && progressBarView != nil) {
                [self makeTitleLabelRegular:titleLabel];
                if (progressBarView != nil) {
                    [progressBarView removeFromSuperview];
                    //NSLog(@"GroupViewController::enableProgressBar:atIndexPath:withProgress: DISABLE progress bar, row=%d, section=%d", indexPath.row, indexPath.section);
                    //CGRect frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height - 10);
                    //[cell setFrame:frame];
                }
            }
        }
    }
}

/*-----------------------------------------------------------------------------

 ----------------------------------------------------------------------------*/
- (void)updateProgressBarAtIndexPath:(NSIndexPath *)indexPath withProgress:(float)progressValue {
    if (indexPath != nil) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell != nil) {
            UIProgressView *progressBarView = (UIProgressView *)[cell.contentView viewWithTag:kProgressBarViewTag];
            if (progressBarView != nil) {
                progressBarView.progress = progressValue;
            }
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (GroupViewController *)establishNewGroupViewController:(TestGroup *)hostTestGroup animated:(BOOL)animated{
    GroupViewController *groupViewController = [[GroupViewController alloc] initWithStyle:self->_tableStyle];
    
    groupViewController.currentTestGroup = hostTestGroup;
    groupViewController.detailViewController = self.detailViewController;
    groupViewController.rootViewController = self.rootViewController;
    
    // Push the detail view controller
    // We need to use navigation controller from the detail view controller. This is the real one.
    UINavigationController *navigator = [self.detailViewController navigationController];
    if (navigator != nil) {
        [navigator pushViewController:groupViewController animated:animated];
    }
    // change the appearance flag to NO, because we pushed the new one.
    self->_isAppeared = NO;
    
    return groupViewController;
}

#pragma mark -
#pragma mark Table view delegate

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TestObject *testObject = [currentTestGroup getTestObject:indexPath];

    if (testObject.testObjectType == type_TestGroup) {
        GroupViewController *groupViewController = [self establishNewGroupViewController:(TestGroup *)testObject animated:YES];
        
        [groupViewController release];
    }
}


#pragma mark -
#pragma mark Memory management

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
   
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [currentTestGroup release];
    [detailViewController release];
    [rootViewController release];
    [imageDownloadsInProgress release];
    [super dealloc];
}

@end

