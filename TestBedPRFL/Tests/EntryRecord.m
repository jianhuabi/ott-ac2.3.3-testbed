//
//  EntryRecord.m
//  TestBed
//
//  Created by Apple User on 5/18/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "EntryRecord.h"
#import "ActiveCloakMediaPlayer.h"


@implementation EntryRecord

@synthesize link;
@synthesize title;
@synthesize entryId;
@synthesize summary;
@synthesize updated;
@synthesize licenseAcquisitionUrl;
@synthesize urltype;
@synthesize serialNumber;
@synthesize imageUrl;
@synthesize imageHeight;
@synthesize imageWidth;
@synthesize contentSize;
@synthesize downloadToFile;
@synthesize sectionName;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) init {
    [super init];
    self.link = nil;
    self.title = nil;
    self.entryId = nil;
    self.summary = nil;
    self.updated = nil;
    self.licenseAcquisitionUrl = nil;
    self.downloadToFile = nil;
    self.sectionName = nil;
    self.urltype = ACURLTypeHLS;
    self.serialNumber = 0;
    self.imageUrl = nil;
    self.imageHeight = -1;
    self.imageWidth = -1;
    self.contentSize = -1;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
-(void)dealloc {
    [link release];
    [title release];
    [entryId release];
    [summary release];
    [updated release];
    [licenseAcquisitionUrl release];
    [downloadToFile release];
    [sectionName release];
    [super dealloc];
}

@end
