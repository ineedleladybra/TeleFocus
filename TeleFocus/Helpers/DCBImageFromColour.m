//
//  DCBImageFromColour.m
//  TeleFocus
//
//  Created by Daniel Bradley on 01/11/2016.
//  Copyright © 2016 Daniel Bradley. All rights reserved.
//

#import "DCBImageFromColour.h"

@implementation DCBImageFromColour

+ (UIImage *)imageFromColor:(UIColor *)color {
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
