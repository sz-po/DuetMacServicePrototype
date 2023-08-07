//
//  DuetCoreDesktopCaptureManagerClient.m
//  DuetDesktopCaptureManager
//
//  Created by Peter Huszak on 2023. 08. 06..
//

#import "DuetCoreDesktopCaptureManagerClient.h"

@interface DuetCoreDesktopCaptureManagerClient ()

@property (nonatomic, strong) NSXPCConnection *connectionToService;
@property (nonatomic, weak) DuetDesktopCaptureManagerModel *appModel;

@end

@implementation DuetCoreDesktopCaptureManagerClient

- (instancetype)initWithAppModel:(DuetDesktopCaptureManagerModel *)model {
	self = [super self];
	if (self != nil) {
		self.appModel = model;
	}
	return self;
}

- (id<DuetDesktopCapturerDaemonProtocol>)remoteProxy {
	typeof(self) __weak weakSelf = self;
	id<DuetDesktopCapturerDaemonProtocol> remoteProxy = [self.connectionToService remoteObjectProxyWithErrorHandler:^(NSError *error) {
		typeof(self) self = weakSelf;
		NSLog(@"Connection to the Daemon is terminated. Error: %@.", error);
		self.connectionToService = nil;
	}];

	return remoteProxy;
}

- (BOOL)isConnected {
	return (self.connectionToService != nil);
}

- (void)sendDataToAgent:(NSData *)data withReply:(void (^)(NSString *))reply {
	// TODO: process data coming from the daemon
	NSLog(@"Daemon called sendDataToAgent: %@", data);
//	[self logMessage:[NSString stringWithFormat:@"Daemon called sendDataToAgent: %@", data]];

	reply(@"xpc client received sendDataToAgent");
}

- (void)getVersionWithCompletion:(void (^)(NSString *, NSError *))completion {
	//TODO: add version handling
	completion(@"1.0", nil);
}

- (void)startScreenCaptureWithCompletion:(void (^)(BOOL, NSError *))completion {
	[self.appModel startScreenCapture];
	completion(YES, nil);
}


- (void)connect {
	if (self.isConnected) {
		NSLog(@"Already connected to DuetCoreService.");
		return;
	}
	self.connectionToService = [[NSXPCConnection alloc] initWithMachServiceName:@"com.kairos.DuetDesktopCapturerService" options:NSXPCConnectionPrivileged];
//	_connectionToService = [[NSXPCConnection alloc] initWithMachServiceName:@"com.kairos.DuetService" options:0];
	self.connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DuetDesktopCapturerDaemonProtocol)];
	self.connectionToService.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(DuetDesktopCapturerClientProtocol)];
	self.connectionToService.exportedObject = self;
	
	typeof(self) __weak weakSelf = self;
	self.connectionToService.interruptionHandler = ^{
		typeof(self) self = weakSelf;
		NSLog(@"Connection to the Daemon is interrupted.");
		self.connectionToService = nil;
	};
	self.connectionToService.invalidationHandler = ^{
		typeof(self) self = weakSelf;
		NSLog(@"Connection to the Daemon is invalidated.");
		self.connectionToService = nil;
	};
	
	[self.connectionToService resume];
	
	
	[self.remoteProxy getVersionWithCompletion:^(NSString *version, NSError *error) {
		typeof(self) self = weakSelf;
		NSLog(@"Daemon responded to getVersion: %@ error: %@", version, error);
//		[self logMessage:[NSString stringWithFormat:@"Daemon responded to getVersion: %@ error: %@", version, error]];
	}];
}

- (void)disconnect {
	[self.connectionToService invalidate];
	self.connectionToService = nil;
}

- (void)setConnectionToService:(NSXPCConnection *)connectionToService {
	if (_connectionToService == connectionToService) {
		return;
	}
	_connectionToService = connectionToService;
	[self.delegate clientConnectionStateDidChange:self];
	
}

@end
