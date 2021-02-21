//
//  DCBBluetoothManager.m
//  TeleFocus
//
//  Created by Daniel Bradley on 21/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import "DCBBluetoothManager.h"

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreBluetooth/CoreBluetooth.h>

static DCBBluetoothManager *instance = nil;

@interface DCBBluetoothManager () <CBCentralManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;
@property (nonatomic) BOOL alertInView;

@end

@implementation DCBBluetoothManager

///////////////////////////////////////////////////////////////////////////////
#pragma mark - Intialisation
///////////////////////////////////////////////////////////////////////////////

+ (instancetype)sharedManager {
    
    if ( instance == nil ) {
        instance = [[self alloc] init];
    }

    return instance;
}

- (void)startBluetoothServices {
    
    if ( self.centralManager == nil ) {
        
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        [options setObject:@NO forKey:CBCentralManagerOptionShowPowerAlertKey];
        [options setObject:@"telefocus.cbcentralmanager" forKey:CBCentralManagerOptionRestoreIdentifierKey];
        
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:nil
                                                                 options:options];
        
    }
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - Methods
///////////////////////////////////////////////////////////////////////////////

- (void)startScan {
    
    CBManagerState state = self.centralManager.state;
    
    if ( state == CBManagerStatePoweredOn ) {
        
        NSLog(@"Bluetooth : starting scan");
        
        NSArray *services = [NSArray arrayWithObjects:kHM10UUID, nil];
        
        [self.centralManager scanForPeripheralsWithServices:services
                                                    options:nil];
        
    } else {
        //Bluetooth is OFF or in a state that can not start a scan
        [self presentAlertWithTitle:@"Bluetooth Error"
                            message:@"Unable to start scan. Please check Bluetooth is turned on."];
    }
    
}

- (void)stopScan {

    if ( self.centralManager ) {
        [self.centralManager stopScan];
    }
    
}

- (void)disconnectAll {
    
    if ( self.centralManager ) {
        
        [self.connectedPeripheral setNotifyValue:NO forCharacteristic:self.bleService.readWriteCharacteristic];
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        
        [self clearDevices];
    }
    
}

- (void)trashManager {
    
    if ( instance ) {
        self.centralManager = nil;
        instance = nil;
        
        [self clearDevices];
    }
    
}

- (void)clearDevices {
    
    self.bleService = nil;
    self.connectedPeripheral = nil;
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - Helpers
///////////////////////////////////////////////////////////////////////////////

- (BOOL)isScanning {
    
    if ( self.centralManager ) {
        
        BOOL isScanning = self.centralManager.isScanning;
        return isScanning;
        
    } else {
        return NO;
    }
    
}

- (BOOL)isConnected {
    
    if ( self.connectedPeripheral ) {
        return YES;
        
    } else {
        return NO;
    }
    
}

- (void)setBleService:(DCBHM10Service *)bleService {
    // Using a setter so the service will be properly started and reset
    if (_bleService) {
        
        [_bleService reset];
        _bleService = nil;
    }
    
    _bleService = bleService;
    
    if (_bleService) {
        [_bleService startDiscoveringServices];
    }
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications
///////////////////////////////////////////////////////////////////////////////

- (void)presentAlertWithTitle:(NSString *)title message:(NSString *)message {
    
    if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive ||
        [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive ) {
        
        if ( self.alertInView == NO ) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      self.alertInView = NO;
                                                                  }];
            
            [alert addAction:defaultAction];
            [self.parentViewcontroller presentViewController:alert animated:YES completion:^{
                self.alertInView = YES;
            }];
        }
    }
    
}

- (void)postNotificationWithMessage:(NSString *)message {
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:@"Alert - Bluetooth" arguments:nil];
    content.body  = [NSString localizedUserNotificationStringForKey:message arguments:nil];
    content.sound = [UNNotificationSound defaultSound];
    
    NSInteger badgeCount = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    content.badge = [NSNumber numberWithInteger:badgeCount +1];

    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5f repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"com.danielbradley.telefocus.bluetooth" content:content trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:nil];
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - CBCentralManager Delegates
///////////////////////////////////////////////////////////////////////////////

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    CBManagerState state = self.centralManager.state;
    
    switch ( state ) {
        case CBManagerStateUnknown:
            NSLog(@"Bluetooth : bluetooth unknown");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@"Bluetooth : bluetooth ON");
            [self startScan];
            break;
        case CBManagerStateResetting:
            NSLog(@"Bluetooth : bluetooth resetting");
            [self clearDevices];
            break;
        case CBManagerStatePoweredOff:
            [self presentAlertWithTitle:@"Bluetooth Error" message:@"Currently Bluetooth is turned off. Please turn Bluetooth on."];
            [self clearDevices];
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Bluetooth : bluetooth unsupported");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"Bluetooth : bluetooth unauthorized");
            break;
        default:
            break;
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    NSArray *advertisedDataServices = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
    
    BOOL hasValidService = NO;
    
    for ( CBUUID *uuid in advertisedDataServices ) {

        if ( [advertisedDataServices containsObject:uuid] ) {
            hasValidService = YES;
        }
    }
    
    //Try to connect to the discovered peripheral
    if ( hasValidService ) {
        
//        //Post Local Notification
//        NSString *message = [NSString stringWithFormat:@"Discovered peripheral %@", peripheral.name];
//        [self postNotificationWithMessage:message];
        
        // If not already connected to a peripheral, then connect to this one
        if (!self.connectedPeripheral || (self.connectedPeripheral.state == CBPeripheralStateDisconnected)) {
            // Retain the peripheral before trying to connect
            self.connectedPeripheral = peripheral;
            
            // Reset service
            self.bleService = nil;
            
            // Connect to peripheral
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
//    //Post Local Notification
//    NSString *message = [NSString stringWithFormat:@"Connected peripheral %@", peripheral.name];
//    [self postNotificationWithMessage:message];
    
    if (!peripheral) {
        return;
    }
    
    // Create new service class
    if (peripheral == self.connectedPeripheral) {
        self.bleService = [[DCBHM10Service alloc] initWithPeripheral:peripheral];
    }
    
    // Stop scanning for new devices
    [self.centralManager stopScan];
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    //Post Local Notification
    NSString *message = [NSString stringWithFormat:@"Failed to connect peripheral %@", peripheral.name];
    [self presentAlertWithTitle:@"Bluetooth Error" message:message];
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    //Post Local Notification
    NSString *message = [NSString stringWithFormat:@"Diconnected peripheral %@", peripheral.name];
    [self presentAlertWithTitle:@"Bluetooth Info" message:message];
    
    if (!peripheral) {
        return;
    }
    
    // See if it was our peripheral that disconnected
    if (peripheral == self.connectedPeripheral) {
        self.bleService = nil;
        self.connectedPeripheral = nil;
    }
    
    // Start scanning for new devices
    [self startScan];
    
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    
    for ( CBPeripheral *peripheral in peripherals ) {
        [central connectPeripheral:peripheral options:nil];
    }
    
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state {
    
}

@end
