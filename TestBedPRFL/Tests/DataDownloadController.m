//
//  DataDownloadController.m
//  TestBed
//
//  Created by Apple User on 5/24/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "DataDownloadController.h"

@interface DataDownloadController ()

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end

@implementation DataDownloadController

@synthesize receivedData;
@synthesize currentUrlConnection;
@synthesize currentUrl;
@synthesize testsInstance;
@synthesize errorInfo;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)init {
    [super init];

    self.receivedData = nil;
    self.currentUrlConnection = nil;
    self.currentUrl = nil;
    self.errorInfo = nil;
    
    self->_downloadCompleted = NO;
    self->_downloadCompletedWithError = NO;
   
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) initWithTestHost:(Tests *)tests {
    [self init];
    self.testsInstance = tests;
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [self.receivedData release];
    [self.currentUrlConnection release];
    [self.currentUrl release];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)initiateDownloadProcessFromUrl {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.currentUrl]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
    self.currentUrlConnection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
}    

/*-----------------------------------------------------------------------------

 ----------------------------------------------------------------------------*/
- (NSData *) downloadDataFromUrl:(NSString *)targetUrl {
    assert(![NSThread isMainThread]); // this function should not be called in the main thread
                                        // because it runs synchronously and should not block 
                                        // the main thread
    
    self.currentUrl = [NSString stringWithString:targetUrl];
    self->_downloadCompleted = NO;
    self->_downloadCompletedWithError = NO;
    
	[self performSelectorOnMainThread:@selector(initiateDownloadProcessFromUrl) withObject:nil waitUntilDone:YES];

    if (self.currentUrlConnection != nil) {
        fprintf(stderr, "Connection initiated\n");
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        while (!self->_downloadCompleted && !self->_downloadCompletedWithError) {
            [NSThread sleepForTimeInterval:(NSTimeInterval)1.0]; 
        }
    }
    else if (testsInstance != nil) {
        fprintf(stderr, "Connection failed\n");
        [testsInstance Log:[NSString stringWithFormat:@"Could not instantiate connection for the '%@' URL", self.currentUrl]]; 
    }

    return self.receivedData;
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)handleError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Download Data"
														message:errorMessage
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

// The following are delegate methods for NSURLConnection. See NSURLConnection.h 
// These functions are usually called from a different thread

/*-----------------------------------------------------------------------------
    connection:didReceiveResponse:response
 ----------------------------------------------------------------------------*/
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    fprintf(stderr, "connection:didReceiveResponse:response\n");
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger rc = [httpResponse statusCode];
        if (rc != 200) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Server responed with code = %d", rc]
                                                                 forKey:NSLocalizedDescriptionKey];
            NSError *badResponseError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                             code:kCFFTPErrorUnexpectedStatusCode
                                                         userInfo:userInfo];
            
            [self connection:connection didFailWithError:badResponseError];
        }
    }
    
    if (self.receivedData == nil) {
        self.receivedData = [NSMutableData data];    // start off with new data
    }
    else {
        [self.receivedData setLength:0];
    }

}

/*-----------------------------------------------------------------------------
    connection:didReceiveData:data
 ----------------------------------------------------------------------------*/
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    fprintf(stderr, "connection:didReceiveData:data - data.length = %d\n", data.length);
    [self.receivedData appendData:data];  // append incoming data
}

/*-----------------------------------------------------------------------------
    connection:didFailWithError:error
 ----------------------------------------------------------------------------*/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    fprintf(stderr, "connection:didFailWithError:error\n");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([error code] == kCFURLErrorNotConnectedToInternet)
	{
        // if we can identify the error, we can present a more precise message to the user.
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No Connection Error"
															 forKey:NSLocalizedDescriptionKey];
        NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
														 code:kCFURLErrorNotConnectedToInternet
													 userInfo:userInfo];
        [self handleError:noConnectionError];
        self.errorInfo = noConnectionError;
    }
	else
	{
        // otherwise handle the error generically
        [self handleError:error];
        self.errorInfo = error;
    }
    
    self.currentUrlConnection = nil;   // release our connection
    self->_downloadCompletedWithError = YES;
}

/*-----------------------------------------------------------------------------
    connectionDidFinishLoading:connection
 ----------------------------------------------------------------------------*/
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    fprintf(stderr, "connectionDidFinishLoading:connection\n");
    self.currentUrlConnection = nil;   // release our connection
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
    NSString *receivedBytes = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"receivedData = %@", receivedBytes);
    
    self->_downloadCompleted = YES;
}

@end
