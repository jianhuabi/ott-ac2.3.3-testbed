//
//  ProvisionRequestor.m
//  TestBed
//
//  Created by Apple User on 5/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//
//  This file is based on the similar component from
//  the Apple sample - TopPaid

#import "ProvisionRequestor.h"
#import "CFNetwork/CFNetworkErrors.h"

@interface ProvisionRequestor()

/* The timeout value. */
@property (nonatomic, assign) NSTimeInterval connectionTimeout;

/* The secure store received from the Proxy. */
@property (nonatomic, retain) NSMutableData *activeDownload;

/* The Proxy connection object. */
@property (nonatomic, retain) NSURLConnection *provisionConnection; 

/* A manually created timer to make sure that the
 * NSURLConnection times out when we expect it to.
 */
@property (nonatomic, retain) NSTimer * connectionTimer;
 
- (void)onTimerEvent:(id)userInfo;
- (void)startTimer;
- (void)stopTimer;

/* Creates an NSURLConnection to the Proxy on the main thread.
 * 
 * @param[in] aRequest The request to make to the Proxy.
 */
- (void)initiateURLRequest:(NSURLRequest *) aRequest;

/* NSURLConnectionDelegate methods */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@implementation ProvisionRequestor

@synthesize delegate = _delegate;
@synthesize activeDownload = _activeDownload;
@synthesize provisionConnection = _provisionConnection;
@synthesize connectionTimer = _connectionTimer;
@synthesize connectionTimeout = _connectionTimeout;

#pragma mark

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithDelegate:(id)aDelegate
{
    [super init];
    self.delegate = aDelegate;
    return self;
}

- (void)dealloc
{
    [self stopTimer];
    [self.provisionConnection cancel];
    
    self.delegate = nil;
    self.activeDownload = nil;
    self.provisionConnection = nil;
    self.connectionTimer = nil;
    
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)startRequestFromNSURLRequest:(NSURLRequest *) aRequest withTimeOut:(NSTimeInterval)interval
{
    self.activeDownload = [[NSMutableData alloc ] init];
    NSLog(@"Requesting secure store from URL: %@\n", aRequest.URL.absoluteString);

    self.connectionTimeout = interval;
    [self startTimer];
    [self initiateURLRequest:aRequest];
}

-(void)initiateURLRequest: (NSURLRequest *) aRequest
{
    if ([NSThread isMainThread])
    {
        self.provisionConnection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
    }
    else
    {
        [self performSelectorOnMainThread:@selector(initiateURLRequest:) withObject:aRequest waitUntilDone:YES];
    }
    
    
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)cancelRequest
{
    [self stopTimer];
    [self.provisionConnection cancel];
    self.connectionTimer = nil;
    self.provisionConnection = nil;
    self.activeDownload = nil;
}


#pragma mark -
#pragma mark Download support (NSURLConnectionDelegate)

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.activeDownload appendData:data];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self stopTimer];
    
	// Clear the activeDownload property to allow later attempts
    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.provisionConnection = nil;
    
    if ([self.delegate respondsToSelector:@selector(secureStoreRequestFailed:)])
	{
		[self.delegate secureStoreRequestFailed:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSInteger status = [(NSHTTPURLResponse*)response statusCode];
    
    /* We always look for 200 only thus scenarios such as redirect are ignored. In a production
     * environment this should be more robust. */
    if (status != 200)
    {
        [self cancelRequest];
        if ([self.delegate respondsToSelector:@selector(secureStoreRequestFailed:)])
        {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat: @"Received unexpected response from Proxy. Status code: %d\n", status] 
                         forKey:NSLocalizedDescriptionKey];
            [self.delegate secureStoreRequestFailed:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorBadServerResponse userInfo: errorDetail]];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    [self stopTimer];
    
    // Release the connection now that it's finished
    self.provisionConnection = nil;
    
    // call our delegate and give it the secure store
    if ([self.delegate respondsToSelector:@selector(secureStoreReceived:)])
	{
		 [self.delegate secureStoreReceived:self.activeDownload];
	}
    
    self.activeDownload = nil;
}

- (void)onTimerEvent:(id)userInfo
{
    [self cancelRequest];
    
    if ([self.delegate respondsToSelector:@selector(secureStoreRequestFailed:)])
	{
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Connection timed out and cancelled by application" forKey:NSLocalizedDescriptionKey];
		[self.delegate secureStoreRequestFailed:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorTimedOut userInfo: errorDetail]];
	}
}

-(void)startTimer
{
    if ([NSThread isMainThread])
    {
        self.connectionTimer = [NSTimer scheduledTimerWithTimeInterval:self.connectionTimeout
                                                                target:self
                                                              selector:@selector(onTimerEvent:)
                                                              userInfo:nil
                                                               repeats:NO]; 
    }
    else
    {
        [self performSelectorOnMainThread:@selector(startTimer) withObject:nil waitUntilDone:YES];
    }
}

-(void)stopTimer
{
    if (self.connectionTimer != nil)
    {
        [self.connectionTimer invalidate];
    }
}

- (NSURLRequest *) prepareProvisioningUrlRequestForHost: (NSString *)host 
                                               withBody: (NSString *)data 
                                           withDeviceId: (NSString *)deviceId
                                            withTimeout: (NSTimeInterval)interval
                                            withServlet: (NSString *)servlet
{
	NSURL *url = nil;
	NSMutableURLRequest * request = nil;
    NSString * path = [NSMutableString stringWithFormat:@"/%@/%@", servlet, deviceId];
	
	url = [[NSURL alloc] initWithScheme:@"http" host:host path:path];
    
	request = [NSMutableURLRequest requestWithURL:url 
                                      cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
                                  timeoutInterval:interval];
    
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[data dataUsingEncoding: NSASCIIStringEncoding]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	
	return request;
}

@end

