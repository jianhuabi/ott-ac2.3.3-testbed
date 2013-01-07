//
//  DetailViewController.h
//  TestBed
//
//  Created by Apple User on 11/15/10.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActiveCloakAgent.h"

/* Singleton implementation of a provisioning Class */

@interface ProvisionController : NSObject
{
    
}

@property (nonatomic, retain) ActiveCloakAgent * m_activeCloakAgent;

/* This method retrieves the shared ProvisionController instance.
 * If the shared instance does not exist, it will be instantiated.
 */
+ (ProvisionController *)getProvisionController:(ActiveCloakAgent *)activeCloakAgent;

/* Invoked to start the provisioning process.
 *
 * The provisioning process will be done asynchronously so it will be 
 * necessary to check the log to see the status of the provisioning
 * process.
 */
- (void) provision;

/* Checks the provisioning status of the current device.
 *
 * @return YES if provisioned and NO otherwise.
 */
- (BOOL) isProvisioned;

/* ProvisionRequestor Delegate methods */
- (void) secureStoreReceived:(NSData *)data;
- (void) secureStoreRequestFailed:(NSError *)error;

/* Checks to see if the provisioning process has started.
 *
 * @return YES if provisioned and NO otherwise.
 */
+ (BOOL) provisionInProgress;

@end

