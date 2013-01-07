//
//  NetServiceController.h
//  TestBed
//
//  Created by Apple User on 11/24/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProtocolFramework.h"

extern NSString *const NetServiceControllerReceivedResponse;
extern NSString *const NetServiceControllerConnected;
extern NSString *const NetServiceControllerDisconnected;

@protocol NetServiceView

- (void)showNetServiceConnected:(NSString *)netServiceName;
- (UIView *) getCurrentView;
- (UIToolbar *) getCurrentToolbar;

@end

@interface NetServiceController : NSObject <NSStreamDelegate, NSNetServiceBrowserDelegate, UIActionSheetDelegate>{
    id delegate;
    NSNetServiceBrowser * serviceBrowser;
    NSMutableArray * serviceList;
    NSInputStream * inputStream;
    NSOutputStream * outputStream;
    NSMutableData * dataBuffer;
    NSNetService *selectedService;
    NSString *serverLabel;
    id<NetServiceView> netServiceView;
@private
    UIActionSheet *_availableTestServices; 
    MessageBuffer _responseMessage;
    NSMutableArray *_messagePool;
}

- (id) initWithView: (id<NetServiceView>) netServiceView;
- (const MessageBuffer *) getReceivedMessage;
- (void) scheduleMessageToSend:(MessageBuffer *)message;
- (void) connectToService: (NSNetService *)netService;
- (void) disconnectFromService;
- (void) showAvailableTestServicesDialog;
- (BOOL) connectedToNetService;

- (id)delegate;
- (void)setDelegate:(id)value;

@property (nonatomic, readonly) NSArray *serviceList;

@end


@interface NetServiceController (NetServiceControllerDelegateMethods)

- (BOOL) doesNeedToDiscover;
- (void) setDiscoveryMode:(BOOL)mode;
- (void) discoverNextNetServiceFromList:(NSArray *)serviceList usingController:(NetServiceController *)netServiceController;
// if the delegate implements this method, it is called when the NetServiceController
// needs to know if the found net service wants to work directly with TestBed application
// on this device or simulator

@end

