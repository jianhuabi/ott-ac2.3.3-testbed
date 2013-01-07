//
//  IconDownloader.m
//  TestBed
//
//  Created by Apple User on 5/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//
//  This file is based on the similar component from
//  the Apple sample - TopPaid

#import "IconDownloader.h"

#define kAppIconHeight 36

@implementation IconDownloader

@synthesize testRecord;
@synthesize indexPathInTableView;
@synthesize delegate;
@synthesize activeDownload;
@synthesize imageConnection;

#pragma mark

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc
{
    [testRecord release];
    [indexPathInTableView release];
    
    [activeDownload release];
    
    [imageConnection cancel];
    [imageConnection release];
    
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)startDownload
{
    self.activeDownload = [NSMutableData data];
    // alloc+init and start an NSURLConnection; release on completion/failure
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:
                             [NSURLRequest requestWithURL:
                              [NSURL URLWithString:testRecord.iconName]] delegate:self];
    self.imageConnection = conn;
    [conn release];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)cancelDownload
{
    [self.imageConnection cancel];
    self.imageConnection = nil;
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
	// Clear the activeDownload property to allow later attempts
    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.imageConnection = nil;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Set appIcon and clear temporary data/image
    UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
    
    if (image.size.width != kAppIconHeight && image.size.height != kAppIconHeight)
	{
        CGSize itemSize = CGSizeMake(kAppIconHeight, kAppIconHeight);
		UIGraphicsBeginImageContext(itemSize);
		CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
		[image drawInRect:imageRect];
		self.testRecord.testIcon = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
    }
    else
    {
        self.testRecord.testIcon = image;
    }
    
    self.activeDownload = nil;
    [image release];
    
    // Release the connection now that it's finished
    self.imageConnection = nil;
    
    // call our delegate and tell it that our icon is ready for display
    [delegate appImageDidLoad:self.indexPathInTableView];
}

@end

