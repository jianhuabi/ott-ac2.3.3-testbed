//
//  TestGroup.m
//  TestBed
//
//  Created by Apple User on 11/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestGroup.h"
#import "ProtocolFramework.h"
#import "GroupViewController.h"

DECLARE_NSSTRING(tagStart_testGroupResuls, "<testGroupResults name=\"%s\" type=\"group\" >")
DECLARE_NSSTRING(tagEnd_testGroupResults, "</testGroupResults>")

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
NSComparisonResult compareTests(TestObject * left, TestObject * right, void * context)
{
	return ([left.name caseInsensitiveCompare:right.name]);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
NSComparisonResult compareTestsForUserDefinedOrder(Test * left, Test * right, void * context)
{
    NSComparisonResult result = NSOrderedDescending;
    
    if (left.serialNumber == right.serialNumber) {
        result = [left.name caseInsensitiveCompare:right.name];
    } else if (left.serialNumber < right.serialNumber) {
        result = NSOrderedAscending;
    } else {
        result = NSOrderedDescending;
    }
    
    return result;
}

@implementation TestSection

@synthesize listOfTests;
@synthesize sectionName;
@synthesize sectionType;
@synthesize hasTestGenerator;
@synthesize sectionIcon;
@synthesize sectionIconName;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithSectionType:(TestSectionType)type andSectionName:(NSString *)name {
    [super init];
    listOfTests = [[NSMutableArray alloc] initWithCapacity:5];
    sectionName = name == nil ? nil : [[NSString alloc] initWithString:name];
    sectionType = type;
    self->_modified = YES;
    self.hasTestGenerator = NO;
    sectionIconName = nil;
    sectionIcon = nil;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) dealloc {
    [listOfTests release];
    [sectionName release];
    [sectionIconName release];
    [sectionIcon release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)objectAtIndex:(NSUInteger)index {
    id resultObject = nil;

    resultObject = [listOfTests objectAtIndex:index];
    
    return resultObject;
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestObject *) testObjectAtIndex:(NSUInteger)index {
    
    return (TestObject *)[self objectAtIndex:index];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (Test*)getTestById:(NSString *)testId {
    Test* targetTest = nil;
    if (sectionType == SectionType_TestSection) {
        for (Test* test in listOfTests) {            
            if ([test.testId isEqualToString:testId]) {
                targetTest = test;
                break;
            }
        }
    }
    return targetTest;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSInteger)getTestIndexById:(NSString *)testId {
    NSInteger targetIndex = -1;
    
    if (sectionType == SectionType_TestSection) {
        NSInteger index = 0;
        for (Test* test in listOfTests) {
            if ([test.testId isEqualToString:testId]) {
                targetIndex = index;
                break;
            }
            index++;
        }
    }
    
    return targetIndex;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) doesContainTest:(Test*)childTest {
    
    BOOL doesContain = NO;
    if (sectionType == SectionType_TestSection) {
        for (Test* test in listOfTests) {            
            if ([test.testId isEqualToString:childTest.testId]) {
                doesContain = YES;
                break;
            }
        }
    }
    return doesContain;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) addTestObject:(TestObject *)testObject {
    [listOfTests addObject:testObject];
    if (testObject.testObjectType == type_TestInstance) {
        hasTestGenerator = hasTestGenerator || ((Test *)testObject).testGenerator;
    }
    self->_modified = YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) removeTestObject:(TestObject *)testObject {
    [listOfTests removeObject:testObject];
    self->_modified = YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *) getSubgroup: (NSString *) targetName {
    TestGroup *testGroup = nil;
    if (sectionType == SectionType_GroupSection) {
        for (int index = 0; index < [listOfTests count]; index++) {
            testGroup = [listOfTests objectAtIndex:index];
            if ([testGroup.name isEqualToString: targetName])
                break;
            testGroup = nil;
        }
    }
    return testGroup;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount {
    NSMutableString *statusReport = [NSMutableString stringWithCapacity:1024];
    
    for (int index = 0; index < [listOfTests count]; index++) {
        [statusReport appendString:[[listOfTests objectAtIndex:index] getStatusReportStringAndCollect:totalCount successful:successfulCount failed:failedCount]];
    }
    
    return statusReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getListReportString {
    NSMutableString *listReport = [NSMutableString stringWithCapacity:1024];
    
    for (int index = 0; index < [listOfTests count]; index++) {
        [listReport appendString:[[listOfTests objectAtIndex:index] getListReportString]];
    }
    
    return listReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSUInteger) count {
    return [listOfTests count];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) sortTests:(TestSortType)sortType {
    if (sortType == SortType_Default) {
        [listOfTests sortUsingFunction:compareTests context:nil];
    } else if (sortType == SortType_UserDefined) {
        [listOfTests sortUsingFunction:compareTestsForUserDefinedOrder context:nil];
    }
    self->_modified = YES;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) hasBeenModified {
    return self->_modified;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) synchronized {
    self->_modified = NO;
}

@end


@interface TestGroup ()

- (TestSection *) findSectionWithName:(NSString *)sectionName;

@end

@implementation TestGroup

@synthesize listOfSections;
@synthesize testsObject = _testsObject;
@synthesize hasTestGenerator;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) init {
    listOfSections = [[NSMutableArray alloc] initWithCapacity:2];
    self.testObjectType = type_TestGroup;
    self->_modified = YES;
    self.hasTestGenerator = NO;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithName:(NSString *)groupName andParent:(TestGroup *)parentGroup {
    [self init];
    self.name = groupName;
    self.parent = parentGroup;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [self.testsObject release];
    [listOfSections release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *)getFullParentName {
    if (parent != nil) {
        return [[NSString alloc] initWithFormat:@"%@/%@", [parent getFullParentName], name];
    } else {
        return [[NSString alloc] initWithString:name];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSUInteger) count {
    NSUInteger resultCount = 0;
    for (TestSection *section in listOfSections) {
        resultCount += [section count];
    }
    return resultCount;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSIndexPath *) getIndexPathByConsecutiveIndex:(NSUInteger)index {
    NSIndexPath *path = nil;
    NSUInteger sectionIndex = 0;
    NSUInteger size = 0;
    NSUInteger rowIndex = index;
    
    for (TestSection *section in listOfSections) {
        size = [section count];
        if (size > rowIndex) {
            break;
        }
        rowIndex -= size;
        sectionIndex++;
    }
    
    path = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    
    return path;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSUInteger) getConsecutiveIndexByIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger consecutiveIndex = 0;
    
    for (NSUInteger index = 0;  index < indexPath.section; index++) {
        if (index < [listOfSections count]) {
            consecutiveIndex += [[listOfSections objectAtIndex:index] count];
        } else {
            break;
        }

    }
    consecutiveIndex += indexPath.row;
    
    return consecutiveIndex;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSUInteger) numberOfSections {
    return [listOfSections count];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSInteger) numberOfTestsInSection:(NSInteger)section {
    return [[listOfSections objectAtIndex:section] count];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    id resultObject = nil;

    resultObject = [[listOfSections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    return resultObject;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestObject *)getTestObject:(NSIndexPath *) indexPath {
    return (TestObject *)[self objectAtIndexPath:indexPath];
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestObject *)getTestObjectByConsecutiveIndex:(NSUInteger)index {
    return [self getTestObject:[self getIndexPathByConsecutiveIndex:index]];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (Test*)getTestById:(NSString *)testId {
    
    Test* targetTest = nil;
    
    for (TestSection* section in listOfSections) {
        targetTest = [section getTestById:testId];
        if (targetTest != nil)
            break;
    }
    
    return targetTest;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSIndexPath *)getTestIndexById:(NSString *)testId {
    
    NSIndexPath *path = nil;
    NSUInteger sectionIndex = 0;
    
    for (TestSection* section in listOfSections) {
        NSInteger rowIndex = [section getTestIndexById:testId];
        if (rowIndex >= 0) {
            path = [NSIndexPath indexPathForRow:(NSUInteger)rowIndex inSection:sectionIndex];
            break;
        }
        sectionIndex++;
    }
    
    return path;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *) getSubgroup: (NSString *) targetName {
    TestGroup *testGroup = nil;
    if ([listOfSections count] > 0) {
        testGroup = [[listOfSections objectAtIndex:0] getSubgroup:targetName];
    }
    return testGroup;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestGroup *) establishTestGroupWithName: (NSString *) groupName {
    TestGroup *newGroup = [[TestGroup alloc] initWithName:groupName andParent:self];
    TestSection *groupSection = nil;
    if ([listOfSections count] <= 0 || [[listOfSections objectAtIndex:0] sectionType] != SectionType_GroupSection) {
        groupSection = [[TestSection alloc] initWithSectionType:SectionType_GroupSection andSectionName:@"Groups"];
        [listOfSections insertObject:groupSection atIndex:0];
        self->_modified = YES;
    } else {
        groupSection = [listOfSections objectAtIndex:0];
    }

    [groupSection addTestObject:newGroup];
    return newGroup;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) deleteTestSectionWithName: (NSString *)sectionName {
    BOOL success = NO;
    TestSection *sectionToDelete = [self findSectionWithName:sectionName];
    if (sectionToDelete != nil) {
        [listOfSections removeObject:sectionToDelete];
        success = YES;
        self->_modified = YES;
    }
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) removeTestGroup: (TestGroup *) testGroup {
    if ([listOfSections count] > 0 && [[listOfSections objectAtIndex:0] sectionType] == SectionType_GroupSection) {
        TestSection *groupSection = [listOfSections objectAtIndex:0];
        [groupSection removeTestObject:testGroup];
        self->_modified = YES;
    } else {
        // we should probably raise an exception
    }

}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) removeEmptySubgroups {
    
    if ([listOfSections count] > 0 && [[listOfSections objectAtIndex:0] sectionType] == SectionType_GroupSection) {
        NSMutableArray *listOfEmptyGroups = [[NSMutableArray alloc] initWithCapacity:1];
        TestSection *groupSection = [listOfSections objectAtIndex:0];
        for (int index = 0; index < groupSection.count; index++) {
            TestGroup *childGroup = (TestGroup *)[groupSection testObjectAtIndex:index];
            [childGroup removeEmptySubgroups];
            if (childGroup.count <= 0) {
                [listOfEmptyGroups addObject:childGroup];
            }
        }
        for (TestGroup *emptyGroup in listOfEmptyGroups) {
            [groupSection removeTestObject:emptyGroup];
            self->_modified = YES;
        }
        [listOfEmptyGroups release];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestSection *) createTestSectionWithName: (NSString *)sectionName {
    TestSection *testSection = [[TestSection alloc] initWithSectionType:SectionType_TestSection andSectionName:sectionName];
    [listOfSections addObject:testSection];
    self->_modified = YES;
    return testSection;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) establishTestSectionWithName: (NSString *)sectionName {
    [self createTestSectionWithName:sectionName];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (TestSection *) findSectionWithName:(NSString *)sectionName {
    TestSection *targetSection = nil;
    if (sectionName != nil) {
        for (TestSection *section in listOfSections) {
            if ([section.sectionName isEqualToString:sectionName]) {
                targetSection = section;
            }
        }
    }
    
    return targetSection;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) addTest:(Test *)test toSection:(NSString *)sectionName {
    
    TestSection *testSection = nil;
    
    if (sectionName != nil) {
        testSection = [self findSectionWithName:sectionName];
    }
    
    if (testSection == nil) {
        testSection = [self createTestSectionWithName:(sectionName == nil ? @"Tests" : sectionName)];
    }
    
    // update value of the hasTestGenerator flag for 
    // this group and for its parents if it is changed
    BOOL currentHasTestGeneratorValue = hasTestGenerator;
    hasTestGenerator = hasTestGenerator || test.testGenerator;
    if (currentHasTestGeneratorValue != hasTestGenerator) {
        // propogate the flag value to all parent groups;
        TestGroup *parentGroup = self.parent;
        while (parentGroup != nil) {
            parentGroup.hasTestGenerator = self.hasTestGenerator;
            parentGroup = parentGroup.parent;
        }
    }
    
    [testSection addTestObject:test];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getStatusReportStringAndCollect:(NSUInteger *)totalCount successful:(NSUInteger *)successfulCount failed:(NSUInteger *)failedCount {
    NSMutableString *statusReport = [NSMutableString stringWithCapacity:1024];
    const char *unescapedName = [self.name cStringUsingEncoding:NSUTF8StringEncoding];
    int size = strlen(unescapedName);
    char *escapedName = escapeCString(unescapedName, size);
    NSString *startTag = [NSString stringWithFormat:tagStart_testGroupResuls, escapedName];
    [statusReport appendString:startTag];
    free(escapedName);
    
    for (TestSection *section in listOfSections) {
        [statusReport appendString:[section getStatusReportStringAndCollect:totalCount successful:successfulCount failed:failedCount]];
    }
    
    [statusReport appendString:tagEnd_testGroupResults];
    return statusReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getListReportString {
    NSMutableString *listReport = [NSMutableString stringWithCapacity:1024];
    const char *unescapedName = [self.name cStringUsingEncoding:NSUTF8StringEncoding];
    int size = strlen(unescapedName);
    char *escapedName = escapeCString(unescapedName, size);
    NSString *startTag = [NSString stringWithFormat:@"<testGroup name=\"%s\" >", escapedName];
    free(escapedName);
    
    [listReport appendString:startTag];
    
    for (TestSection *section in listOfSections) {
        [listReport appendString:[section getListReportString]];
    }
    
    [listReport appendString:@"</testGroup>"];
    return listReport;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getSectionName:(NSUInteger)index {
    NSString *sectionName = nil;
    if (index < [listOfSections count]) {
        sectionName = [[listOfSections objectAtIndex:index] sectionName];
    }
    return sectionName;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSString *) getParentSectionName:(Test *)childTest {
    NSString *parentSectionName = nil;
    for (TestSection *section in listOfSections) {
        if ([section doesContainTest:childTest]) {
            parentSectionName = section.sectionName;
            break;
        }
    }
    return parentSectionName;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) sortTestsInSections:(TestSortType)sortType {
    for (TestSection *section in listOfSections) {
        [section sortTests:sortType];
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) removeEmptySections {
    NSMutableArray *listOfEmptySections = [[NSMutableArray alloc] initWithCapacity:1];
    
    // collect emtpy sections in a separate array
    for (TestSection* section in listOfSections) {
        if ([section count] == 0) {
            [listOfEmptySections addObject:section];
        }
    }
    
    // if there are empty sections, remove them
    if (listOfEmptySections.count > 0) {
        for (TestSection *section in listOfEmptySections) {
            [listOfSections removeObject:section];
        }
        self->_modified = YES;
    }
    
    [listOfEmptySections release];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) hasBeenModified {

    BOOL modified = self->_modified;

    if (!modified) {
        // verify if some section has been modified
        for (TestSection* section in listOfSections) {
            modified = [section hasBeenModified];
            if (modified)
                break;
        }
    }
    
    return modified;
}

/*-----------------------------------------------------------------------------
    This method should be called by some GUI after it has synchronized its
    state with the test group;
 ----------------------------------------------------------------------------*/
- (void) synchronized {
    // marks every section in the group as synchronized
    for (TestSection* section in listOfSections) {
        [section synchronized];
    }
    self->_modified = NO;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (NSInteger) hasSectionBeenModified:(NSInteger)section {
    return [[listOfSections objectAtIndex:section] hasBeenModified];
}

@end
