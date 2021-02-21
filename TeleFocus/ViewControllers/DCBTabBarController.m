//
//  DCBTabBarController.m
//  TeleFocus
//
//  Created by Daniel Bradley on 21/10/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import "DCBTabBarController.h"

@interface DCBTabBarController ()

@end

@implementation DCBTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UITabBar appearance].tintColor = [UIColor whiteColor];
    [UITabBar appearance].barTintColor = [UIColor blackColor];
    [UITabBar appearance].backgroundColor = [UIColor blackColor];
    
    [self styleTabBar];
    [self setupTabBarItems];
    
}

- (void)styleTabBar {
    
}

- (void)setupTabBarItems {
    
    NSMutableArray *viewController = [[NSMutableArray alloc] init];
    //Dashboard
    [viewController addObject:[self viewControllerWithStoryboardName:@"main"
                                                      withIdentifier:@"focusNavSBID"
                                                               title:@"Focus"
                                                           imageName:@"focusTabBar"
                                                                 tag:0]];
    
//    [viewController addObject:[self viewControllerWithStoryboardName:@"main"
//                                                      withIdentifier:@"settingsNavSBID"
//                                                               title:@"Settings"
//                                                           imageName:nil
//                                                                 tag:1]];

    //Set ViewControllers
    [self setViewControllers:viewController animated:YES];
    
}

- (UIViewController *)viewControllerWithStoryboardName:(NSString *)storyboardName withIdentifier:(NSString *)identifier title:(NSString *)title imageName:(NSString *)imageName tag:(int)tag {
    
    UIViewController *vc = [[UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:identifier];
    [vc setTabBarItem:[self tabBarItemWithTitle:title imageNamed:imageName tag:tag]];
    
    return vc;
    
}

- (UITabBarItem *)tabBarItemWithTitle:(NSString *)title imageNamed:(NSString *)imageName tag:(int)tag {
    
    UITabBarItem *item = [[UITabBarItem alloc] init];
    [item setTitle:title];
    [item setTag:tag];
    
    if ( imageName.length > 0 ) {
        NSString *unselectedString = [NSString stringWithFormat:@"%@.png", imageName];
        NSString *selectedString = [NSString stringWithFormat:@"%@_selected.png", imageName];
        
        UIImage *unselectedImage = [UIImage imageNamed:unselectedString];
        UIImage *selectedImage = [UIImage imageNamed:selectedString];
        [item setImage:[unselectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [item setSelectedImage:[selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }
    
    return item;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
