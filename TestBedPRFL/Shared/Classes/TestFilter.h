//
//  TestFilter.h
//  ActiveCloak
//  Created by Apple User on 2/17/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tests.h"

//
// TestOption_Empty            - means no options defined
//
// TestOption_UseSections      - means the TestBed should ask every unit test, which section it belongs,
//                               using opid_getTestSection operation ID. If unit test returns a section name,
//                               TestBed will put test case into the corresponding section. If section
//                               does not exist, it will create it.
//                               If unit test does not return a section name, TestBed will put the unit test 
//                               into the default "Tests" section.
//                               TestBed also will try to call (NSArray *)getSectionOrder method from the test
//                               object instance for order of the sections in the group table. Otherwise, 
//                               it will create sections in an arbitrary order.
//
// TestOption_UseIcons         - means the TestBed should use special icon images to mark to put into the table
//                               cell related to the unit test case. It should ask every unit test about the
//                               icon using opid_getTestIcon operation id.
//
// TestOption_UserDefinedOrder - means the TestBed should sort test cases in the group sections by asking
//                               for serial numbers from unit tests using opid_getSerialNumber operation id.
//
// TestOption_UnsortedOrder    - means keep test cases in the group sections in arbitrary ordere. By default
//                               TestBed sorts test case in alphabetical descending order.
//
// TestOption_HideTopRunButton - directs the root view controller to hide top Run button in the navigation view.
// 
// TestOption_ExecuteTestGenerators - means to run the test cases, which are marked with a TestFlag_TestProducer flag
//                                    and automatically generate a set of test cases using either the content 
//                                    discovery or some other mechanism. These test cases will be executed during 
//                                    the application load time. It will allow to prepare the dynamically created 
//                                    test cases in advance, which is important for Demo mode
//

typedef enum {
    TestOption_Empty                 = 0x00000000,
    TestOption_UseSections           = 0x40000000,
    TestOption_UseIcons              = 0x20000000,
    TestOption_UserDefinedOrder      = 0x10000000, 
    TestOption_UnsortedOrder         = 0x08000000, // it is sorted by default
    TestOption_HideTopRunButton      = 0x04000000,
    TestOption_ExecuteTestGenerators = 0x02000000,
} TestOptions;

@interface TestFilter : NSObject {
    
@private
    NSArray *_groupNames;
    TestOptions _testOptions;
    TestFlags _testFlags;
}

- (id) initWithOptions:(TestOptions)options withGroupNames:(NSArray *)groupNames andWithTestFlags:(TestFlags)flags;
- (BOOL) individualGroups;
- (BOOL) multipleGroups;
- (BOOL) isGroupNameAllowed: (NSString *)groupName;
- (BOOL) isTestFlagsEmpty;
- (BOOL) verifyTestFlagsExist:(TestFlags)flags;
- (BOOL) isOptionTurnedOn:(TestOptions)option;

@property (nonatomic, readonly) NSArray *groupNames;

@end
