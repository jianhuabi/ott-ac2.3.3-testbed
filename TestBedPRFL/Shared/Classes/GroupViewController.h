//
//  GroupViewController.h
//  TestBed
//
//  Created by Apple User on 11/19/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TestGroup.h"
#import "TestExecution.h"
#import "IconDownloader.h"

@class DetailViewController;
@class RootViewController;

@interface GroupViewController : UITableViewController <UIScrollViewDelegate, IconDownloaderDelegate> {

    TestGroup *currentTestGroup; // a hosting test group that possesses the view
    DetailViewController *detailViewController; // an environment the test use to visualize the testing (video, audio, and etc.) 
    RootViewController *rootViewController; // a logger
    TestExecution *_testExecution; // the current test executor, an object that executes a unit test asynchronously
    NSOperationQueue *_queue; // a queue to execute unit tests
    UITableViewStyle _tableStyle;
    NSMutableDictionary *imageDownloadsInProgress;  // the set of IconDownloader objects for each app
    
    // Execution parameters
    NSRange _executionRange; // a range of unit test in the current test group under testing 
    NSUInteger _execIndex; // an index of the next test to be executed from the range above
    BOOL _isExecuting; // a flag for executing state
    BOOL _isAppeared; // a flag for appearing state
    BOOL _isFinished; // a flag for test execution completed state
    BOOL _topMostExecuted;
    BOOL _executeTestGenerators;
}

- (id) initWithStyle:(UITableViewStyle)style; 
- (void)runGroupOfTestsAction:(id)sender; // an action for the navigation bar Run button
- (void)runSingleTestAction:(id)sender event:(id)event; // an action for the the table view cell Run button
- (void)runTestGenerators; // this method run only test generators from the entire test group including the subgroups
- (void)initiateTestGeneratorExecution; // this method will initiate test genrator execution fro teh entire test 
                                        // collection starting from root

- (void)enableProgressBar:(BOOL)enable atIndexPath:(NSIndexPath *)indexPath withProgress:(float)progressValue;
- (void)updateProgressBarAtIndexPath:(NSIndexPath *)indexPath withProgress:(float)progressValue;

@property (nonatomic, retain) TestGroup *currentTestGroup;
@property (nonatomic, retain) DetailViewController *detailViewController;
@property (nonatomic, retain) RootViewController *rootViewController;
@property (nonatomic, assign, readonly) UITableViewStyle tableStyle;
@property (nonatomic, assign, readonly) BOOL isExecuting;
@property (nonatomic, assign, readonly) BOOL isAppeared;
@property (nonatomic, assign, readonly) BOOL isFinished;
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;

@end
