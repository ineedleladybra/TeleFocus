//
//  DCBHM10Service.h
//  TeleFocus
//
//  Created by Daniel Bradley on 22/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

static NSString* const RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION = @"kBLEServiceChangedStatusNotification";

#define kHM10Identifier [CBUUID UUIDWithString:@"2A1714A7-895A-429B-9A45-24007F2EDC8B"]
#define kHM10UUID [CBUUID UUIDWithString:@"FFE0"]
#define kReadWriteUUID [CBUUID UUIDWithString:@"FFE1"]

@interface DCBHM10Service : NSObject <CBPeripheralDelegate>

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBCharacteristic *readWriteCharacteristic;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;
- (void)reset;
- (void)startDiscoveringServices;

- (void)writeCommand:(UInt8)value;

@end
