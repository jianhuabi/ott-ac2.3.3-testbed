//
//  EntryRecord.h
//  TestBed
//
//  Created by Apple User on 5/18/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>

///////////////////////////////////////////////////////////////////////////////
// EntryRecord
//
// This class describes a single entry record obtained from Atom Syndication 
// Format file acquired from a test server
@interface EntryRecord : NSObject {
    NSString *link; // this is a test content URL to stream and play
    NSString *title; // this is a title of the content is used as a test name
    NSString *entryId; // this is a test id (mandatory), it is used to distinguish test cases
    NSString *summary; // this is a description of the test case
    NSString *updated; // this is a date
    NSString *licenseAcquisitionUrl; // this is license acquisition URL
    NSString *downloadToFile;
    NSString *sectionName;
    NSUInteger urltype; // this is a URL type, it is currently equal to either URLTYPE_HLS or URLTYPE_IIS 
    NSInteger serialNumber; // this is a serial number of the test case in a test section to keep predefined order of test cases
    NSString *imageUrl; // this is a URL of an icon that can be used as representation of the corresponding test case
    NSInteger imageHeight; // height of the icon in pixels (non-mandatory)
    NSInteger imageWidth; // width of the icon in pixels (non-mandatory)
    NSInteger contentSize; // size of content described in the entry, if < 0, the size is not defined.
}

@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *entryId;
@property (nonatomic, retain) NSString *summary;
@property (nonatomic, retain) NSString *updated;
@property (nonatomic, retain) NSString *licenseAcquisitionUrl;
@property (nonatomic, retain) NSString *imageUrl;
@property (nonatomic, retain) NSString *downloadToFile;
@property (nonatomic, retain) NSString *sectionName;
@property (nonatomic, readwrite) NSUInteger urltype;
@property (nonatomic, readwrite) NSInteger serialNumber;
@property (nonatomic, readwrite) NSInteger imageHeight;
@property (nonatomic, readwrite) NSInteger imageWidth;
@property (nonatomic, readwrite) NSInteger contentSize;

@end
