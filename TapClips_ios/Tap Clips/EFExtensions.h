//
//  EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#ifndef Tap_Clips_EFExtensions_h
#define Tap_Clips_EFExtensions_h

#import "UIApplication+EFExtensions.h"
#import "NSDate+EFExtensions.h"
#import "NSFileManager+EFExtensions.h"
#import "NSString+EFExtensions.h"
#import "NSData+EFExtensions.h"
#import "UIStoryboard+EFExtensions.h"
#import "NSDictionary+EFExtensions.h"
#import "UIAlertView+EFExtensions.h"
#import "UIViewController+EFExtensions.h"
#import "UIColor+EFExtensions.h"
#import "UIImage+EFExtensions.h"
#import "NSRegularExpression+EFExtension.h"

#define EF_IS_IOS7 ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#define EF_IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define EF_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#endif
