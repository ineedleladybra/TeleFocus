//
//  DCBBluetoothManager.h
//  TeleFocus
//
//  Created by Daniel Bradley on 21/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DCBHM10Service.h"

@interface DCBBluetoothManager : NSObject

@property (assign, nonatomic) UIViewController *parentViewcontroller;
@property (nonatomic, strong) DCBHM10Service *bleService;

+ (instancetype)sharedManager;
- (void)startBluetoothServices;
- (void)startScan;
- (void)stopScan;
- (void)clearDevices;
- (void)disconnectAll;
- (void)trashManager;

- (BOOL)isScanning;
- (BOOL)isConnected;

@end
