//
//  DataDownloadController.h
//  TestBed
//
//  Created by Apple User on 5/24/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tests.h"

@interface DataDownloadController : NSObject {

    NSMutableData *receivedData;
    NSURLConnection *currentUrlConnection;
    NSString *currentUrl;
    Tests *testsInstance;
    NSError *errorInfo;
@private
    BOOL _downloadCompleted;
    BOOL _downloadCompletedWithError;
}

- (id) init;
- (id) initWithTestHost:(Tests *)testsInstance;
- (NSData *) downloadDataFromUrl:(NSString *)targetUrl;

@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *currentUrlConnection;
@property (nonatomic, retain) NSString * currentUrl;
@property (nonatomic, retain) Tests * testsInstance;
@property (nonatomic, retain) NSError *errorInfo;

@end
