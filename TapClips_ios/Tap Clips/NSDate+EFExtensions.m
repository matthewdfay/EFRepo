//
//  NSDate+EFExtensions.m
//  Tap Clips
//
//  Created by Matthew Fay on 3/20/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "NSDate+EFExtensions.h"

static NSTimeInterval const EFMinute = 60;
static NSTimeInterval const EFHour = 3600;
static NSTimeInterval const EFDay = 86400;
static NSTimeInterval const EFWeek = 604800;
static NSTimeInterval const EFMonth = 2629800;
static NSTimeInterval const EFYear = 31557600;

@implementation NSDate (EFExtensions)

+ (NSInteger)currentYear
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [cal setTimeZone:timeZone];
    
    NSDateComponents *components = [cal components:NSYearCalendarUnit fromDate:[NSDate date]];
    return [components year];
}

- (NSString *)longReadableDate
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"ha 'on' EEEE, MMMM d";
        formatter.AMSymbol = @"am";
        formatter.PMSymbol = @"pm";
        formatterQueue = dispatch_queue_create("com.dateformatter.longReadableDate", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
        string = [string stringByAppendingString:[self endingForDay:string]];
    });
    
    return string;
}

- (NSString *)endingForDay:(NSString *)day
{
    if ([day hasSuffix:@"1"]) {
        return @"st";
    } else if ([day hasSuffix:@"2"]) {
        return @"nd";
    } else if ([day hasSuffix:@"3"]) {
        return @"rd";
    }
    return @"th";
}

- (NSString *)shortDate
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MMM d";
        formatterQueue = dispatch_queue_create("com.dateformatter.shortDate", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSString *)longDate
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MMMM d";
        formatterQueue = dispatch_queue_create("com.dateformatter.longDate", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSString *)weekday
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"EEEE";
        formatterQueue = dispatch_queue_create("com.dateformatter.weekday", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSString *)shortDateWithTime
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"EEE MMM d @ h:mm a";
        formatterQueue = dispatch_queue_create("com.dateformatter.shortDate", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSString *)time
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"h:mma";
        formatter.AMSymbol = @"am";
        formatter.PMSymbol = @"pm";
        formatterQueue = dispatch_queue_create("com.dateformatter.time", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSString *)timeWithTimeZone
{
    static NSDateFormatter *formatter;
    static dispatch_queue_t formatterQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"h:mma z";
        formatter.AMSymbol = @"am";
        formatter.PMSymbol = @"pm";
        formatterQueue = dispatch_queue_create("com.dateformatter.timeWithZone", 0);
    });
    
    __block NSString *string = nil;
    dispatch_sync(formatterQueue, ^{
        string = [formatter stringFromDate:self];
    });
    
    return string;
}

- (NSInteger)year
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [cal setTimeZone:timeZone];
    
    NSDateComponents *components = [cal components:NSYearCalendarUnit fromDate:self];
    return [components year];
}

- (NSString *)timeSinceDate
{
    NSString *timeString = nil;
    NSTimeInterval seconds = abs([self timeIntervalSinceNow]);
    if (seconds < 10) {
        timeString = @"just now";
    } else if (seconds < EFMinute) {
        timeString = [NSString stringWithFormat:@"%ld second%@ ago", (long)seconds, seconds == 1 ? @"" : @"s"];
    } else if (seconds < EFHour) {
        NSInteger minutes = floor(seconds / EFMinute);
        timeString = [NSString stringWithFormat:@"%ld minute%@ ago", (long)minutes, minutes == 1 ? @"" : @"s"];
    } else if (seconds < EFDay) {
        NSInteger hours = floor(seconds / EFHour);
        timeString = [NSString stringWithFormat:@"%ld hour%@ ago", (long)hours, hours == 1 ? @"" : @"s"];
    } else if (seconds < EFWeek) {
        NSInteger days = floor(seconds / EFDay);
        timeString = [NSString stringWithFormat:@"%ld day%@ ago", (long)days, days == 1 ? @"" : @"s"];
    } else if (seconds < EFMonth) {
        NSInteger weeks = floor(seconds / EFWeek);
        timeString = [NSString stringWithFormat:@"%ld week%@ ago", (long)weeks, weeks == 1 ? @"" : @"s"];
    } else if (seconds < EFYear) {
        NSInteger months = floor(seconds / EFMonth);
        timeString = [NSString stringWithFormat:@"%ld month%@ ago", (long)months, months == 1 ? @"" : @"s"];
    } else {
        NSInteger years = floor(seconds / EFYear);
        timeString = [NSString stringWithFormat:@"%ld year%@ ago", (long)years, years == 1 ? @"" : @"s"];
    }
    
    return timeString;
}

- (NSDate *)dateWithoutTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
    
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    return [calendar dateFromComponents:dateComps];
}

//////////////////////////////////////////////////////////////
#pragma mark - Future Dates
//////////////////////////////////////////////////////////////
+ (NSDate *)oneDayFromNow
{
    return [NSDate dateWithTimeIntervalSinceNow:EFDay];
}

+ (NSDate *)oneWeekFromNow
{
    return [NSDate dateWithTimeIntervalSinceNow:EFWeek];
}

+ (NSDate *)oneYearFromNow
{
    return [NSDate dateWithTimeIntervalSinceNow:EFYear];
}

//////////////////////////////////////////////////////////////
#pragma mark - Date Comparisons
//////////////////////////////////////////////////////////////
- (BOOL)isToday
{
    return ([[[NSDate date] dateWithoutTime] compare:[self dateWithoutTime]] == NSOrderedSame);
}

- (BOOL)isFuture
{
    return ([[NSDate date] compare:self] == NSOrderedAscending);
}

- (BOOL)isPast
{
    return ([[NSDate date] compare:self] == NSOrderedDescending ||
            [[NSDate date] compare:self] == NSOrderedSame);
}

//////////////////////////////////////////////////////////////
#pragma mark - Modify Date
//////////////////////////////////////////////////////////////
- (NSDate *)addHours:(NSInteger)hours
{
    NSInteger newInterval = ((hours * EFHour) + self.timeIntervalSince1970);
    return [NSDate dateWithTimeIntervalSince1970:newInterval];
}

//////////////////////////////////////////////////////////////
#pragma mark - API Convert Date
//////////////////////////////////////////////////////////////
- (NSTimeInterval)timeIntervalSince1970InMS
{
    return ([self timeIntervalSince1970] * 1000.0);
}

+ (NSDate *)dateWithTimeIntervalSince1970InMS:(NSTimeInterval)milisec
{
    return [NSDate dateWithTimeIntervalSince1970:(milisec/1000.0)];
}

@end
