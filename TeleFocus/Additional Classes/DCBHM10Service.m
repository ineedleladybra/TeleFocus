//
//  DCBHM10Service.m
//  TeleFocus
//
//  Created by Daniel Bradley on 22/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import "DCBHM10Service.h"

@implementation DCBHM10Service

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    
    self = [super init];
    
    if ( self ) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
    }
    return self;
    
}

- (void)dealloc {
    [self reset];
}

- (void)reset {
    
    if ( self.peripheral ) {
        self.peripheral = nil;
    }
    
    // Send notification
    [self sendBTServiceNotificationWithIsBluetoothConnected:NO];
    
}

- (void)startDiscoveringServices {
    
    [self.peripheral discoverServices:@[kHM10UUID]];
    
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    if ( peripheral != self.peripheral ) {
        NSLog(@"Wrong peripheral.\n");
        return;
    }
    
    if ( error != nil ) {
        NSLog(@"Error %@\n", error);
        return;
    }
    
    NSArray *uuidsForBTService = @[kReadWriteUUID];
    NSArray *services = [peripheral services];
    
    if ( !services || ![services count] ) {
        NSLog(@"No services found");
        return;
    }
    
    for (CBService *service in services) {
        
        if ( [service.UUID isEqual:kHM10UUID] ) {
            //NSLog(@"Service found %@", service.UUID);
            [peripheral discoverCharacteristics:uuidsForBTService forService:service];
            
        } else {
            NSLog(@"UNKNOWN service found %@", service.UUID);
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    NSArray *characteristics = [service characteristics];
    
    if ( peripheral != self.peripheral ) {
        NSLog(@"Wrong peripheral.\n");
        return;
    }
    
    if ( error != nil ) {
        NSLog(@"Error %@\n", error);
        return;
    }
    
    for ( CBCharacteristic *characteristic in characteristics ) {
        
        if ( [characteristic.UUID isEqual:kReadWriteUUID] ) {
            
            //NSLog(@"Discovered characteristic %@", characteristic.UUID);
            
            //Allow notify
            [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            self.readWriteCharacteristic = characteristic;
            
            // Send notification
            [self sendBTServiceNotificationWithIsBluetoothConnected:YES];
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    //NSLog(@"didUpdateValueForCharacteristic %@", characteristic.UUID);
    
}

#pragma mark - Communication to BLE device

- (void)writeCommand:(UInt8)value {
    
    if ( !self.readWriteCharacteristic ) {
        return;
    }
    
    NSData *data = nil;
    data = [NSData dataWithBytes:&value length:sizeof(value)];
    //NSLog(@"writingCommand %i \n%@", value, data);
    
    [self.peripheral writeValue:data
              forCharacteristic:self.readWriteCharacteristic
                           type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark - Notification

- (void)sendBTServiceNotificationWithIsBluetoothConnected:(BOOL)isBluetoothConnected {
    
    NSDictionary *connectionDetails = @{@"isConnected": @(isBluetoothConnected)};
    [[NSNotificationCenter defaultCenter] postNotificationName:RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION
                                                        object:self
                                                      userInfo:connectionDetails];
    
}

@end
