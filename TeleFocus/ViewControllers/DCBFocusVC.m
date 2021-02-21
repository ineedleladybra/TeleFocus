//
//  DCBFocusVC.m
//  TeleFocus
//
//  Created by Daniel Bradley on 21/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import "DCBFocusVC.h"

#import "DCBImageFromColour.h"
#import "DCBBluetoothManager.h"

#import <AVFoundation/AVFoundation.h>

typedef enum DCBAudioType {
    DCBAudioType_BLE_Connected = 0,
    DCBAudioType_BLE_Disconnected,
    DCBAudioType_Button,
} DCBAudioType;

@interface DCBFocusVC () <AVAudioPlayerDelegate>

@property (nonatomic) BOOL isInitialCommand;

@property (nonatomic, assign) IBOutlet UIButton *statusButton;
@property (nonatomic, assign) IBOutlet UILabel *statusLabel;

@property (nonatomic, assign) IBOutlet UIButton *buttonA;
@property (nonatomic, assign) IBOutlet UIButton *buttonB;
@property (nonatomic, assign) IBOutlet UISlider *speedSlider;
@property (nonatomic, assign) IBOutlet UILabel *speedSliderLabel;

//@property (nonatomic, strong) UISelectionFeedbackGenerator *hapticFeedback;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation DCBFocusVC

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isInitialCommand = YES;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjects:@[[UIColor whiteColor]]
                                                           forKeys:@[NSForegroundColorAttributeName]];
    
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    
    self.title = @"TeleFocus";
    self.view.backgroundColor = [UIColor blackColor];
    
    self.speedSliderLabel.textColor = [UIColor whiteColor];
    self.statusLabel.textColor = [UIColor whiteColor];
    
    // Watch Bluetooth connection
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionChanged:)
                                                 name:RWT_BLE_SERVICE_CHANGED_STATUS_NOTIFICATION
                                               object:nil];
    
    [[DCBBluetoothManager sharedManager] startBluetoothServices];
    [[DCBBluetoothManager sharedManager] setParentViewcontroller:self];
    
    [self setupSlider];
    [self setupButtons];
    //[self setupHapticFeedback];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - SETUP
///////////////////////////////////////////////////////////////////////////////

- (void)setupHapticFeedback {
        
    //self.hapticFeedback = [[UISelectionFeedbackGenerator alloc] init];
    //[self.hapticFeedback prepare];
    
}

- (void)setupSlider {
        
    self.speedSlider.minimumValue = 1;
    self.speedSlider.maximumValue = 40;
    self.speedSlider.value = 20;
    self.speedSlider.maximumTrackTintColor = [UIColor magentaColor];
    self.speedSlider.minimumTrackTintColor = [UIColor cyanColor];
    self.speedSliderLabel.text = [NSString stringWithFormat:@"Speed : %.f", self.speedSlider.value];
    [self.speedSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
}

- (void)setupButtons {

    [self.buttonA setTitle:@"CW inf." forState:UIControlStateNormal];
    [self.buttonB setTitle:@"CCW" forState:UIControlStateNormal];
    
    [self.buttonA setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buttonB setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.buttonA setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self.buttonB setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    
    [self.buttonA setBackgroundImage:[DCBImageFromColour imageFromColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
    [self.buttonB setBackgroundImage:[DCBImageFromColour imageFromColor:[UIColor darkGrayColor]] forState:UIControlStateNormal];
    [self.buttonA setBackgroundImage:[DCBImageFromColour imageFromColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    [self.buttonB setBackgroundImage:[DCBImageFromColour imageFromColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    
    self.buttonA.layer.cornerRadius = 10;
    self.buttonA.clipsToBounds = YES;
    self.buttonB.layer.cornerRadius = 10;
    self.buttonB.clipsToBounds = YES;
    
    [self.buttonA addTarget:self action:@selector(buttonAPressed:) forControlEvents:UIControlEventTouchDown];
    [self.buttonB addTarget:self action:@selector(buttonBPressed:) forControlEvents:UIControlEventTouchDown];
    [self.buttonA addTarget:self action:@selector(buttonAReleased:) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonB addTarget:self action:@selector(buttonBReleased:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.statusButton addTarget:self action:@selector(statusButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.statusButton.backgroundColor = [UIColor redColor];
    self.statusButton.layer.cornerRadius = 20;
    self.statusButton.clipsToBounds = YES;
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - SLIDER
///////////////////////////////////////////////////////////////////////////////

- (void)sliderValueChanged:(UISlider *)slider {
    
    //Update Slider Label
    self.speedSliderLabel.text = [NSString stringWithFormat:@"Speed : %.f", slider.value];
    [self sendCommand:(uint8_t)slider.value];
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - AUDIO / HAPTICS
///////////////////////////////////////////////////////////////////////////////

- (void)playAudioForType:(DCBAudioType)type {
    
    NSString *resourcePath;
    
    switch ( type ) {
        case DCBAudioType_BLE_Connected:
            resourcePath = [NSString stringWithFormat:@"%@/ble_connected.wav", [[NSBundle mainBundle] resourcePath]];
            break;
        case DCBAudioType_BLE_Disconnected:
            resourcePath = [NSString stringWithFormat:@"%@/ble_disconnected.wav", [[NSBundle mainBundle] resourcePath]];
            break;
        case DCBAudioType_Button:
            resourcePath = [NSString stringWithFormat:@"%@/select.wav", [[NSBundle mainBundle] resourcePath]];
            break;
        default:
            break;
    }
    
    if ( resourcePath.length > 0 ) {
        
        NSURL *resourceURL = [NSURL fileURLWithPath:resourcePath];
        
        NSError *error = nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:resourceURL
                                                                  error:&error];
        [self.audioPlayer setDelegate:self];
        [self.audioPlayer setNumberOfLoops:0];
        [self.audioPlayer prepareToPlay];
        
        if ( error == nil ) {
            [self.audioPlayer play];
        }
    }
    
}

- (void)triggerHapticFeedback {
    
    //[self.hapticFeedback selectionChanged];
    //[self.hapticFeedback prepare];
    //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - BUTTONS ACTIONS
///////////////////////////////////////////////////////////////////////////////

- (void)statusButtonPressed:(UIButton *)button {
    
    if ( [DCBBluetoothManager sharedManager].bleService ) {
        
        [[DCBBluetoothManager sharedManager] disconnectAll];
        
    } else {
        [[DCBBluetoothManager sharedManager] startScan];
    }
    
}

- (void)buttonAPressed:(UIButton *)button {

    self.buttonB.userInteractionEnabled = NO;
    [self sendCommand:44];
    
    [self playAudioForType:DCBAudioType_Button];
    [self triggerHapticFeedback];
    
}

- (void)buttonBPressed:(UIButton *)button {

    self.buttonA.userInteractionEnabled = NO;
    [self sendCommand:45];
    
    [self playAudioForType:DCBAudioType_Button];
    [self triggerHapticFeedback];
    
}

- (void)buttonAReleased:(UIButton *)button {

    self.buttonB.userInteractionEnabled = YES;
    [self sendCommand:46];
    
}

- (void)buttonBReleased:(UIButton *)button {

    self.buttonA.userInteractionEnabled = YES;
    [self sendCommand:47];
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - BLE CONNECTION
///////////////////////////////////////////////////////////////////////////////

- (void)connectionChanged:(NSNotification *)notification {
    // Connection status changed. Indicate on GUI.
    BOOL isConnected = [(NSNumber *) (notification.userInfo)[@"isConnected"] boolValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Set image based on connection status
        self.statusButton.backgroundColor = isConnected ? [UIColor greenColor] : [UIColor redColor];
        
        if ( isConnected ) {
            [self playAudioForType:DCBAudioType_BLE_Connected];
            
        } else {
            [self playAudioForType:DCBAudioType_BLE_Disconnected];
            self.isInitialCommand = YES;
        }
    });
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - SEND COMMAND
///////////////////////////////////////////////////////////////////////////////

- (void)sendCommand:(uint8_t)value {

    BOOL isConnected = [DCBBluetoothManager sharedManager].isConnected;
    // Send position to BLE (if service exists and is connected)
    if ( [DCBBluetoothManager sharedManager].bleService && isConnected ) {
        
        //If this the first command, send the slider value first
        if ( self.isInitialCommand ) {
            self.isInitialCommand = NO;
            [[DCBBluetoothManager sharedManager].bleService writeCommand:self.speedSlider.value];
        }
        
        //NSLog(@"sendingCommand %i", value);
        [[DCBBluetoothManager sharedManager].bleService writeCommand:value];
        
    } else {
        NSLog(@"sendPosition failed -> no bleService || not connected");
    }
    
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark - ENVIRONMENT
///////////////////////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
