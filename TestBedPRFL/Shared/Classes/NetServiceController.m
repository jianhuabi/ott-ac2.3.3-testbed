//
//  NetServiceController.m
//  TestBed
//
//  Created by Apple User on 11/24/10.
//  Copyright 2010 Irdeto. All rights reserved.
//


#define FRAGMENT_SIZE 2048

#import "NetServiceController.h"

NSString *const NetServiceControllerReceivedResponse = @"NetServiceControllerReceivedResponse";
NSString *const NetServiceControllerConnected = @"NetServiceControllerConnected";
NSString *const NetServiceControllerDisconnected = @"NetServiceControllerDisconnected";

static char CharForCurrentThread(void)
// Returns 'M' if we're running on the main thread, or 'S' otherwies.
{
    return [NSThread isMainThread] ? 'M' : 'S';
}

@interface NetServiceController ()

@property (nonatomic, retain) id<NetServiceView> netServiceView;

- (void)openStreams;
- (void)closeStreams;
- (void)sendMessage:(NSData *)message;

@end


@implementation NetServiceController

@synthesize netServiceView;
@synthesize serviceList;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id)initWithView:(id<NetServiceView>)aNetServiceView {
    
    [super init];
    
    if (aNetServiceView != nil) {
        netServiceView = aNetServiceView;
        [(NSObject *) netServiceView retain];
    }
    
    initMessageBuffer(&self->_responseMessage);
    self->_messagePool = [[NSMutableArray alloc] init];
    
    serviceBrowser = [[NSNetServiceBrowser alloc] init];
    serviceList = [[NSMutableArray alloc] init];
    [serviceBrowser setDelegate:self];
    
    [serviceBrowser searchForServicesOfType:@"_testboss._tcp." inDomain:@""];
    
    self->_availableTestServices = nil;
    
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [(NSObject *)netServiceView release];
    [serviceList release];
    [serviceBrowser release];
    [self->_messagePool release];
    freeMessageBuffer(&self->_responseMessage);
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
- (id)delegate {
    return delegate;
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
- (void)setDelegate:(id)value {
    delegate = value;
}

/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)sendMessage:(NSData *)message {
    fprintf(stderr, "Sending message: length = %d\n", [message length]);
    if (outputStream) {
        int remainingToWrite = [message length];
        const void *marker = [message bytes];
        while (0 < remainingToWrite) {
            int actuallyWritten = 0;
            actuallyWritten = [outputStream write:marker maxLength:remainingToWrite];
            remainingToWrite -= actuallyWritten;
            marker += actuallyWritten;
        }
    }
}

/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)processMessagePool {
    if ([self->_messagePool count] > 0) {
        [self sendMessage:[self->_messagePool lastObject]];
    }
}

/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)scheduleMessageToSend:(MessageBuffer *)message {
    if (outputStream) {
        NSData *dataToSend = [[NSData alloc] initWithBytes:message->buffer length:message->length];
        [self->_messagePool insertObject:dataToSend atIndex:0];
        if ([self->_messagePool count] == 1) {
            [self processMessagePool];
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (const MessageBuffer *)getReceivedMessage {
    return &self->_responseMessage;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) showAvailableTestServicesDialog {
    
    if ([serviceList count] > 0) {
        self->_availableTestServices = [[UIActionSheet alloc] initWithTitle:@"Available Test Services:"
                                                                   delegate:self 
                                                          cancelButtonTitle:nil
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:nil];
        
        for (NSNetService *netService in serviceList) {
            [self->_availableTestServices addButtonWithTitle:netService.name];
        }
    
        if (IS_IPHONE) {
            [self->_availableTestServices addButtonWithTitle:@"Cancel"];
            self->_availableTestServices.cancelButtonIndex = serviceList.count;
        }
        
        // use the same style as the nav bar
        self->_availableTestServices.actionSheetStyle = UIActionSheetStyleAutomatic;
        
        // [self->_availableTestServices showInView:[netServiceView getCurrentView]];
        [self->_availableTestServices showFromToolbar:[netServiceView getCurrentToolbar]];
        [self->_availableTestServices release];
    }
    
}

#pragma mark -
#pragma mark UIActionSheetDelegate delegate methods

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)actionSheet:(UIActionSheet *)menuBarView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (0 <= buttonIndex && buttonIndex < serviceList.count) {
        [self connectToService:[serviceList objectAtIndex:buttonIndex]]; 
    }
}

/*-----------------------------------------------------------------------------
    Called when we cancel a view (eg. the user clicks the Home button). 
    This is not called when the user clicks the cancel button.
    If not defined in the delegate, a click in the cancel button is simulated
 ----------------------------------------------------------------------------*/
- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    if (delegate && [delegate respondsToSelector:@selector(setDiscoveryMode:)]) { 
        [delegate setDiscoveryMode:YES];
    }
}

/*-----------------------------------------------------------------------------
    before animation and showing view
 ----------------------------------------------------------------------------*/
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
}

/*-----------------------------------------------------------------------------
    after animation
 ----------------------------------------------------------------------------*/
- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
}

/*-----------------------------------------------------------------------------
    before animation and hiding view
 ----------------------------------------------------------------------------*/
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
}

/*-----------------------------------------------------------------------------
    after animation
 ----------------------------------------------------------------------------*/
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex < 0 && delegate && [delegate respondsToSelector:@selector(setDiscoveryMode:)]) { 
        [delegate setDiscoveryMode:YES];
    }
    self->_availableTestServices = nil;
}

#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    fprintf(stderr, "netServiceBrowser:didFindService: started\n");
    if (self->_availableTestServices != nil) {
        [self->_availableTestServices dismissWithClickedButtonIndex:-1 animated:NO];
    }
    // first, we add the new found service to the serviceList collection
    // and if 'moreComing' is YES, we continue to wait for other upcoming services to arrive
    if (![serviceList containsObject:aNetService]) {
        [self willChangeValueForKey:@"serviceList"];
        [serviceList addObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
    }
    
    // if 'moreComing' is NO, we, at first, will check if there is a service 
    // that needs to work directly with this device. If there is no such 
    // service, we will show a dialog to the user that he or she selects 
    // the right service (or just ignore it)
    if (selectedService == nil && serviceList.count > 0 && !moreComing) {
        if (delegate && [delegate respondsToSelector:@selector(doesNeedToDiscover)] && [delegate doesNeedToDiscover]) { 
            [delegate discoverNextNetServiceFromList:serviceList usingController:self];
        } else {
            [self showAvailableTestServicesDialog];
        }
    }
    fprintf(stderr, "netServiceBrowser:didFindService: finished\n");
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    
    if (self->_availableTestServices != nil) {
        [self->_availableTestServices dismissWithClickedButtonIndex:-1 animated:NO];
    }

    if ([serviceList containsObject:aNetService]) {
        // if TestBed is connected to the service, diconnect it from the one.
        if ([aNetService isEqual:selectedService]) {
            [self disconnectFromService];
        }
        [self willChangeValueForKey:@"serviceList"];
        [serviceList removeObject:aNetService];
        [self didChangeValueForKey:@"serviceList"];
        
        // check if we have other services to connect and ask for
        // connection if it is exist
        if (selectedService == nil && serviceList.count > 0) {
            if (delegate && [delegate respondsToSelector:@selector(doesNeedToDiscover)] && [delegate doesNeedToDiscover]) { 
                [delegate discoverNextNetServiceFromList:serviceList usingController:self];
            } else {
                [self showAvailableTestServicesDialog];
            }
        }
    }
}

#pragma mark -
#pragma mark Stream methods

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    NSInputStream * istream;
    switch(streamEvent) {
        case NSStreamEventHasBytesAvailable:;
            istream = (NSInputStream *)aStream;
            fprintf(stderr, "received streamEvent - NSStreamEventHasBytesAvailable\n");
            
            resetMessageBuffer(&self->_responseMessage);
            uint8_t fragment[FRAGMENT_SIZE];
            while (YES) {
                int actuallyRead = [istream read:(uint8_t *)fragment maxLength:FRAGMENT_SIZE];
                if (actuallyRead > 0) {
                    appendMessageBuffer(&self->_responseMessage, fragment, actuallyRead);
                }
                if (actuallyRead < FRAGMENT_SIZE) {
                    if ([self->_messagePool count] > 0 && actuallyRead > 0) {
                        // received a response on some existent request located in the messagePool
                        // process it and remove if it is ok.
                        // Handle the next message in the pool.
                        // need to supply a message handler (testEventController) with the received data

                        [[NSNotificationCenter defaultCenter] postNotificationName:NetServiceControllerReceivedResponse object:self];

                        NSData *lastSentMessage = [self->_messagePool lastObject];
                        [self->_messagePool removeLastObject];
                        [lastSentMessage release];
                        [self processMessagePool];
                    }
                    break;
                }
            }
            break;
        case NSStreamEventEndEncountered:;
            fprintf(stderr, "received streamEvent - NSStreamEventEndEncountered\n");
            [self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
        case NSStreamEventErrorOccurred:
        case NSStreamEventOpenCompleted:
        case NSStreamEventNone:
        default:
            break;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) connectToService: (NSNetService *)netService {
    
    if (selectedService == nil) {
        selectedService = netService;
        if ([selectedService getInputStream:&inputStream outputStream:&outputStream]) {
            [self openStreams];
            serverLabel = [selectedService name];
            if (netServiceView != nil) {
                [netServiceView showNetServiceConnected:[selectedService name]];
            }
        }
	}
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void) disconnectFromService {
    fprintf(stderr, "disconnectFromService - started in %c\n", CharForCurrentThread());
    [netServiceView showNetServiceConnected:nil];
    serverLabel = nil;
    selectedService = nil;
    if (inputStream != nil && outputStream != nil) {
        [self closeStreams];
    }
    fprintf(stderr, "disconnectFromService - finished in %c\n", CharForCurrentThread());
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)openStreams {
    fprintf(stderr, "openStreams - started in %c\n", CharForCurrentThread());
    if ([self->_messagePool count] > 0) {
        [self->_messagePool removeAllObjects]; 
    }
    [inputStream retain];
    [outputStream retain];
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
    fprintf(stderr, "openStreams - finished in %c\n", CharForCurrentThread());
    [[NSNotificationCenter defaultCenter] postNotificationName:NetServiceControllerConnected object:self];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)closeStreams {
    fprintf(stderr, "closeStreams - started in %c\n", CharForCurrentThread());
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    [inputStream release];
    [outputStream release];
    inputStream = nil;
    outputStream = nil;
    fprintf(stderr, "closeStreams - finished in %c\n", CharForCurrentThread());
    [[NSNotificationCenter defaultCenter] postNotificationName:NetServiceControllerDisconnected object:self];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (BOOL) connectedToNetService {
    
    return inputStream != nil && outputStream != nil;
}

@end
