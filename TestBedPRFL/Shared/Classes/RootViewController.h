#import <UIKit/UIKit.h>
#import "TestRepository.h"
#import "GroupViewController.h"

@class DetailViewController;

@interface RootViewController : GroupViewController <TestLog>
{
    TestRepository *testRepository;
    GroupViewController *_currentGroupView;
    UITabBarController *_tabBarController;   // reference to the main TabBarController is needed 
                                            // to perform automatic switching between tabs in iPhone
    BOOL _testGeneratorsAlreadyExecuted;
}

+(RootViewController*) currentView:(RootViewController*)update;
+(void) resetLog;
+(void) addLog:(NSString*)log;
-(void) addLog:(NSString*)log;
-(void) sendLog:(NSString*)log;
-(id) initWithStyle:(UITableViewStyle)style; // initialization for iPad
-(id) initWithStyle:(UITableViewStyle)style andTestFilter:(TestFilter *)filter;
-(id) initWithStyle:(UITableViewStyle)style andTabBarController:(UITabBarController *)tabBarController; // initialization for iPhone
-(id) initWithStyle:(UITableViewStyle)style testFilter:(TestFilter *)filter andTabBarController:(UITabBarController *)tabBarController; // initialization for iPhone

@property (nonatomic, retain) TestRepository *testRepository;
@property (nonatomic, assign) GroupViewController *currentGroupView;
@property (nonatomic, readonly) UITabBarController *tabBarController;

@end
