//
//  DuetDesktopCaptureServiceDelegate.m
//  DuetCoreService
//
//  Created by Peter Huszak on 2023. 07. 31..
//

#import "DuetDesktopCapturerServiceDelegate.h"
#import "DuetDesktopCapturerService.h"
#import "DuetDesktopCapturerClientProtocol.h"


@implementation DuetDesktopCapturerServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
	// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
	NSLog(@"DuetService incoming connection %@", newConnection);

	// Configure the connection.
	// First, set the interface that the exported object implements.
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DuetDesktopCapturerServiceProtocol)];
	newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DuetDesktopCapturerClientProtocol)];
	// Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
	DuetDesktopCapturerService *exportedObject = [DuetDesktopCapturerService new];
	newConnection.exportedObject = exportedObject;
	
	// Resuming the connection allows the system to deliver more incoming messages.
	[newConnection resume];
	
	typeof(self) __weak weakSelf = self;

	// Validate the connection
	id<DuetDesktopCapturerClientProtocol> remoteProxy = [newConnection remoteObjectProxyWithErrorHandler:^(NSError *error) {
		typeof(self) self = weakSelf;
		// This block will be called if the connection is interrupted or disconnected.
	}];
	[remoteProxy getVersionWithCompletion:^(NSString *version, NSError *error) {
		NSLog(@"Desktop Capture Manager responded to getVersion: %@ error: %@", version, error);
	}];

	[remoteProxy startScreenCaptureWithCompletion:^(BOOL success, NSError *error) {
		NSLog(@"Start screencapture success: %d, error: %@", success, error);
	}];

	// Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
	return YES;
}

@end
