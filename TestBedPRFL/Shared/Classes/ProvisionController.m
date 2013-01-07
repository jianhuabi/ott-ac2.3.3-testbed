//
//  ProvisionController.m
//  TestBed
//
//  Copyright 2012 Irdeto. All rights reserved.
//

#import "RootViewController.h"
#import "ProvisionRequestor.h"
#import "ProvisionController.h"

@interface ProvisionController()

@property (nonatomic, retain) NSString  * host;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSString * servletName;

- (void) handleError:(NSError *)error;
- (void) logText:(NSString *)text;
- (void) loadUrlProperties;
- (id) initWithActiveCloakAgent:(ActiveCloakAgent *)activeCloakAgent;

@end

static int g_provisionInProgress = 0;

@implementation ProvisionController

static ProvisionController *sharedProvisionController = nil;

@synthesize m_activeCloakAgent = _m_activeCloakAgent;
@synthesize host = _host;
@synthesize port = _port;
@synthesize servletName = _servletName;

ProvisionRequestor *m_provisionRequestor;


- (id) initWithActiveCloakAgent:(ActiveCloakAgent *)activeCloakAgent
{
    [super init];
    self.m_activeCloakAgent = activeCloakAgent;
    [self loadUrlProperties];
    m_provisionRequestor = [[ProvisionRequestor alloc] initWithDelegate:self];
    return self;
}

+ (ProvisionController *)getProvisionController:(ActiveCloakAgent *)activeCloakAgent
{
    @synchronized(self)
    {
        if (sharedProvisionController == nil)
        {
            sharedProvisionController = [super allocWithZone:NULL];
            sharedProvisionController = [sharedProvisionController initWithActiveCloakAgent: activeCloakAgent];
        }
        return sharedProvisionController;
    }
}

- (void) dealloc
{
    self.host = nil;
    self.port = nil;
    self.servletName = nil;
    self.m_activeCloakAgent = nil;
    [super dealloc];
}

- (void) provision
{
	NSString *provisioningData = nil;
	NSURLRequest *urlRequest = nil;
	NSTimeInterval interval = 30.0;
    NSString *deviceID = [self.m_activeCloakAgent deviceID];
	
    @synchronized(self)
    {
        if (![ProvisionController provisionInProgress])
        {
            if (![self isProvisioned])
            {
                g_provisionInProgress = 1;
	
                [self logText:@"The provisioning process has started. Check the log for status updates.\n"];
     
                provisioningData = [ActiveCloakAgent getProvisioningData];
    
                urlRequest = [m_provisionRequestor prepareProvisioningUrlRequestForHost: self.host 
                                                                               withBody: provisioningData 
                                                                           withDeviceId: deviceID
                                                                            withTimeout: interval
                                                                            withServlet: self.servletName];
	
                [m_provisionRequestor startRequestFromNSURLRequest:urlRequest withTimeOut:interval];
            }
            else 
            {
                [self logText:@"This device is already provisioned.\n"];
            }
        }
        else
        {
            [self logText:@"The provisioning process has already been started.\n"];
        }
    }
}

- (BOOL) isProvisioned
{
    return [ActiveCloakAgent isProvisioned];
}

- (void) secureStoreReceived:(NSData *)data
{
	[ActiveCloakAgent provision: data];
    [self logText:@"Provisioning Completed sucessfully.\n"];
	g_provisionInProgress = 0;
}

- (void) secureStoreRequestFailed:(NSError *)error
{
	[self handleError:error];
}

- (void) handleError:(NSError *)error
{
    [self logText:[NSString stringWithFormat:@"Error provisioning device. Error: %@\n", [error localizedDescription]]];
	g_provisionInProgress = 0;
}

- (void) logText:(NSString *)text
{
    if ([NSThread isMainThread])
    {
        TestLog((char *)[text UTF8String]);
        NSLog(@"%@", text);
    }
    else
    {
        [self performSelectorOnMainThread:@selector(logText:) withObject:text waitUntilDone:YES];
    }
}

- (void) loadUrlProperties
{
    if (self) {
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
           NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"proxyserver.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            plistPath = [[NSBundle mainBundle] pathForResource:@"proxyserver" ofType:@"plist"];
        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
            propertyListFromData:plistXML
            mutabilityOption:NSPropertyListMutableContainersAndLeaves
            format:&format
            errorDescription:&errorDesc];
        NSString *tmpHost = [temp objectForKey:@"host"];
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		NSNumber *tmpPort = [f numberFromString:[temp objectForKey:@"port"]];
		[f release];
        self.host = [NSMutableString stringWithFormat:@"%@:%@", tmpHost, tmpPort];
        self.servletName = [temp objectForKey:@"proxy_servlet_name"];
    }
}

+ (BOOL) provisionInProgress
{
    BOOL isProvisionInProgress = NO;
    
    if (g_provisionInProgress)
    {
        isProvisionInProgress = YES;
    }
    
    return isProvisionInProgress;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self getProvisionController: nil] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}
    
@end
