//
//  NSDate+EFExtensions.h
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (EFExtensions)

+ (NSInteger)currentYear;
/**
 ie 4pm on Wednesday, July 3
 */
- (NSString *)longReadableDate;

/**
 ie Jul 3
 */
- (NSString *)shortDate;
- (NSString *)longDate;

/**
 ie Monday, Friday...
 */
- (NSString *)weekday;

/**
 ie Thu Aug 12 @ 6:25pm
 */
- (NSString *)shortDateWithTime;

/**
 ie 4:00pm
 */
- (NSString *)time;
- (NSString *)timeWithTimeZone;

/**
 ie 2013
 */
- (NSInteger)year;

/**
 will give the time between now and this date.
 ie 42 seconds ago, 8 minutes ago, 1 year ago
 */
- (NSString *)timeSinceDate;

/**
 Returns the date without time set.
 */
- (NSDate *)dateWithoutTime;

/**
 Advance Dates
 */
+ (NSDate *)oneDayFromNow;
+ (NSDate *)oneWeekFromNow;
+ (NSDate *)oneYearFromNow;

/**
 Date comparisons
 */
- (BOOL)isToday;
- (BOOL)isFuture;
- (BOOL)isPast;

/**
 Date Adjustment
 */
- (NSDate *)addHours:(NSInteger)hours;

/**
 API Date
 */
- (NSTimeInterval)timeIntervalSince1970InMS;
+ (NSDate *)dateWithTimeIntervalSince1970InMS:(NSTimeInterval)milisec;

@end
