//
//  TestGroup.h
//  TestBed
//
//  Created by Apple User on 11/16/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TestObject.h"
#import "Test.h"
#import "TestLog.h"
#import "Tests.h"


typedef enum {
    SectionType_GroupSection = 0,
    SectionType_TestSection = 1
} TestSectionType;

typedef enum {
    SortType_Default = 0,   // alphabetic descending order by test names
    SortType_UserDefined    // sorting with usage of test serial numbers defined by user
} TestSortType;

@interface TestSection : NSObject
{
    NSMutableArray *listOfTests;
    NSString *sectionName;
    TestSectionType sectionType;
    BOOL hasTestGenerator;  // if the flag is YES, it means that the section has a test case
                            // that produces a set of test cases
    NSString *sectionIconName;
    UIImage *sectionIcon;
@private
    BOOL _modified; // if the flag is YES, it means that the section has been modified recently
                    // to clean the flag up, call public 'synchronized' method
}

- (id) initWithSectionType:(TestSectionType)type andSectionName:(NSString *)name;
- (id) objectAtIndex:(NSUInteger)index;
- (TestObject *) testObjectAtIndex:(NSUInteger)index;
- (Test*) getTestById:(NSString *)testId;
- (NSInteger)getTestIndexById:(NSString *)testId;
- (BOOL) doesContainTest:(Test*)childTest;
- (TestGroup *) getSubgroup: (NSString *) targetName;
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount;
- (NSString *) getListReportString;
- (NSUInteger) count;
- (void) addTestObject:(TestObject *)testObject;
- (void) removeTestObject:(TestObject *)testObject;
- (void) sortTests:(TestSortType)sortType;
- (BOOL) hasBeenModified;
- (void) synchronized;

@property (nonatomic, retain) NSMutableArray *listOfTests;
@property (nonatomic, retain) NSString *sectionName;
@property (nonatomic, readwrite) TestSectionType sectionType;
@property (assign) BOOL hasTestGenerator;
@property (nonatomic, retain) UIImage *sectionIcon;
@property (nonatomic, retain) NSString *sectionIconName;

@end


@interface TestGroup : TestObject {
    NSMutableArray *listOfSections;
    Tests *_testsObject;
    BOOL hasTestGenerator;  // if the flag is YES, it means that the group has a test case
                            // that produces a set of test cases
@private
    BOOL _modified; // if the flag is YES, it means that the test group has been modified recently
                    // to clean the flag up, call the public 'synchronized' method
}

- (id) initWithName:(NSString *)groupName andParent:(TestGroup *)parentGroup;
- (NSUInteger) count;
- (NSIndexPath *) getIndexPathByConsecutiveIndex:(NSUInteger)index;
- (NSUInteger) getConsecutiveIndexByIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger) numberOfSections;
- (NSInteger) numberOfTestsInSection:(NSInteger)section;
- (id) objectAtIndexPath:(NSIndexPath *)indexPath;
- (TestGroup *) getSubgroup: (NSString *) groupName;
- (TestGroup *) establishTestGroupWithName: (NSString *)groupName;
- (void) removeTestGroup: (TestGroup *) testGroup;
- (void) establishTestSectionWithName: (NSString *)sectionName;
- (BOOL) deleteTestSectionWithName: (NSString *)sectionName;
- (void) addTest:(Test *)test toSection:(NSString *)sectionName;
- (TestObject *)getTestObject:(NSIndexPath *)indexPath;
- (TestObject *)getTestObjectByConsecutiveIndex:(NSUInteger)index;
- (Test*)getTestById:(NSString *)testId;
- (NSIndexPath *)getTestIndexById:(NSString *)testId;
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount;
- (NSString *) getListReportString;
- (NSString *) getFullParentName;
- (NSString *) getSectionName:(NSUInteger)index;
- (NSString *) getParentSectionName:(Test *)childTest;
- (void) sortTestsInSections:(TestSortType)sortType;
- (void) removeEmptySections;
- (void) removeEmptySubgroups;
- (BOOL) hasBeenModified;
- (void) synchronized;
- (NSInteger) hasSectionBeenModified:(NSInteger)section;

@property (nonatomic, retain) NSMutableArray *listOfSections;
@property (nonatomic, retain) Tests *testsObject; // an object that contains test functions related to the group
@property (assign) BOOL hasTestGenerator; 

@end
