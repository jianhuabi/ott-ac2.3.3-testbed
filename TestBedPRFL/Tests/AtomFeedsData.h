//
//  AtomFeedsParser.h
//  TestBed
//
//  Created by Apple User on 5/18/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XmlSAXParser.h"
#import "EntryRecord.h"

@class EntryRecord;

///////////////////////////////////////////////////////////////////////////////
// AtomFeedsData
//
// This class is intended to collect information from the standard Atom 
// Syndication Format (http://www.w3.org/2005/Atom) 
// extended with specific XMLSchema - urn:atom.testbed.cloakware.irdeto.com
// This schema describes additional XML nodes and attributes that give 
// necessary information about testing content located on the test server

@interface AtomFeedsData : XmlSAXParser {

    NSString *link; // this is a URL of the atom feeds 
    NSString *title; // this is a name of a test server that exposes the atom feed 
    NSString *feedId; // just a feed ID
    NSString *updated; // time of the last update of the atom feed
    NSString *author; // this is a name of auther of the atom feed
    
    EntryRecord *currentEntryRecord; // inforamtion of the current parsed <entry> node
    NSMutableDictionary *entryRecordList; // list of atom feed entries

@private
    
    NSInteger _serialNumber; // this is a serial number of the next atom feed entry
    
}

@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *feedId;
@property (nonatomic, retain) NSString *updated;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, retain) EntryRecord *currentEntryRecord;
@property (nonatomic, retain) NSMutableDictionary *entryRecordList;
@property (nonatomic, readonly) NSInteger serialNumber;

- (id) init;
- (void)reset;
- (void)parseAtomFeeds:(const MessageBuffer *)response; // method parses an atom feed passed as a parameter
- (void)incrementEntriesSerialNumber;

@end


