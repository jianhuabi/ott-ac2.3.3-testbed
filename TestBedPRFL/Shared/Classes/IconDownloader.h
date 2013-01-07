//
//  IconDownloader.h
//  TestBed
//
//  Created by Apple User on 5/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//
//  This file is based on the similar component from
//  the Apple sample - TopPaid

#import <Foundation/Foundation.h>
#import "Test.h"

@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject
{
    Test *testRecord;
    NSIndexPath *indexPathInTableView;
    id <IconDownloaderDelegate> delegate;
    
    NSMutableData *activeDownload;
    NSURLConnection *imageConnection;
}

@property (nonatomic, retain) Test *testRecord;
@property (nonatomic, retain) NSIndexPath *indexPathInTableView;
@property (nonatomic, retain) id <IconDownloaderDelegate> delegate;

@property (nonatomic, retain) NSMutableData *activeDownload;
@property (nonatomic, retain) NSURLConnection *imageConnection;

- (void)startDownload;
- (void)cancelDownload;

@end

@protocol IconDownloaderDelegate 

- (void)appImageDidLoad:(NSIndexPath *)indexPath;

@end

