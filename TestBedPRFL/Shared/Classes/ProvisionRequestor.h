//
//  ProvisionRequestor.h
//  TestBed
//
//  Created by Apple User on 5/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//
//  This file is based on the similar component from
//  the Apple sample - TopPaid

#import <Foundation/Foundation.h>

@protocol ProvisionRequestorDelegate <NSObject>
@optional
/* Called when the provisioned secure store.
 * is received from the Proxy.
 * 
 * @param[in] data The secure store.
 */
- (void)secureStoreReceived:(NSData *)data;

/* Called when the provisioning process completes with
 * an error.
 * 
 * @param[in] error The error.
 */
- (void)secureStoreRequestFailed:(NSError *)error;

@end

@interface ProvisionRequestor : NSObject
{
    id <ProvisionRequestorDelegate> delegate;
}

@property (nonatomic, retain) id <ProvisionRequestorDelegate> delegate;
/* Makes a request to the proxy for a secure store.
 *
 * The request itself is asynchronous thus it will be necessary to implement the delegate
 * to actually check the status or receive the provisioned secure store.
 *
 * @param[in] aRequest The request that will be sent to the Proxy.
 *
 * @param[in] interval The maximum wait time for the connection.
 */
- (void)startRequestFromNSURLRequest:(NSURLRequest *) aRequest withTimeOut:(NSTimeInterval)interval;

/* Cancels the request if there is one in progress.*/
- (void)cancelRequest;

/* Prepares a valid NSURLRequest object that can be used to request
 * a secure store from the Proxy.
 * 
 * @param[in] host The proxy address.
 * @param[in] data The fingerprint data that will be sent to the proxy.
 * @param[in] deviceId The device id of the current device.
 * @param[in] interval The timeout period for the Request.
 * @param[in] servlet The name of the application to invoke on the Proxy.
 */
- (NSURLRequest *) prepareProvisioningUrlRequestForHost: (NSString *)host 
                                               withBody: (NSString *)data 
                                           withDeviceId: (NSString *)deviceId
                                            withTimeout: (NSTimeInterval)interval
                                            withServlet: (NSString *)servlet;

- (id)initWithDelegate:(id)aDelegate;

@end



