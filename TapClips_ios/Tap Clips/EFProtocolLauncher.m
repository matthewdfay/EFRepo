//
//  EFProtocolLauncher.m
//  TapClips
//
//  Created by Matthew Fay on 5/28/14.
//  Copyright (c) 2014 Elemental Foundry. All rights reserved.
//

#import "EFProtocolLauncher.h"
#import "EFProtocolAction.h"
#import "EFLaunchPageAction.h"
#import "EFReturnAction.h"
#import "EFLinkAction.h"
#import "EFExtensions.h"

static NSString * const EFProtocolScheme = @"tapclips";

@interface EFProtocolLauncher ()

@property (nonatomic, copy, readwrite) NSURL *protocol;
@property (nonatomic, copy, readwrite) NSString *scheme;
@property (nonatomic, copy, readwrite) NSString *action;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy, readwrite) NSDictionary *options;
@property (nonatomic, copy, readwrite) NSString *referringApplication;

@property (nonatomic, strong) NSMutableArray *errorsFromParsing;
@property (nonatomic, assign) BOOL isValidProtocol;

@end

@implementation EFProtocolLauncher

- (NSString *)EFFacebookScheme
{
    return [NSString stringWithFormat:@"fb%@", [UIApplication facebookAppId]];
}

- (BOOL)isValidProtocol
{
    return _isValidProtocol;
}

- (NSMutableArray *)errorsFromParsing
{
    if (!_errorsFromParsing) {
        _errorsFromParsing = [NSMutableArray array];
    }
    return _errorsFromParsing;
}

- (NSArray *)parseErrors
{
    return [self.errorsFromParsing copy];
}

- (id)initWithProtocol:(NSURL *)url
{
    return [self initWithProtocol:url referringApplication:nil];
}

- (id)initWithProtocol:(NSURL *)url referringApplication:(NSString *)referringApplication
{
    self = [super init];
    if (self) {
        if ([self parseProtocol:url]) {
            _protocol = [url copy];
            _isValidProtocol = YES;
        }
        _referringApplication = [referringApplication copy];
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark - Parsing
//////////////////////////////////////////////////////////////
- (BOOL)parseProtocol:(NSURL *)protocol
{
    BOOL validProtocol = YES;
    validProtocol &= [self parseScheme:protocol];
    validProtocol &= [self parseAction:protocol];
    
    if (validProtocol && [self.scheme isEqualToString:EFProtocolScheme]) {
        [self parsePathFromEFProtocol:protocol];
        [self parseOptionsFromProtocol:protocol.query];
    } else if (validProtocol && [self.scheme isEqualToString:[self EFFacebookScheme]]) {
        validProtocol = [self parseFacebookProtocol:protocol];
    }
    
    return validProtocol;
}

- (BOOL)parseScheme:(NSURL *)protocol
{
    self.scheme = protocol.scheme;
    BOOL validScheme = [self.scheme isEqualToString:EFProtocolScheme];
    validScheme |= [self.scheme isEqualToString:[self EFFacebookScheme]];
    if (!validScheme) {
        [self appendErrorWithMessage:[NSString stringWithFormat:@"Scheme <%@> is not a known scheme.", protocol.scheme]];
    }
    return validScheme;
}

- (BOOL)parseAction:(NSURL *)protocol
{
    BOOL validAction = NO;
    self.action = [self actionFromString:protocol.host];
    
    if (self.action.length > 0)
        validAction = YES;
    else
        [self appendErrorWithMessage:@"Could not find valid action."];
    
    return validAction;
}

- (void)parseOptionsFromProtocol:(NSString *)protocol
{
    NSArray *components = [protocol componentsSeparatedByString:@"&"];
    NSMutableDictionary *queryOptions = [NSMutableDictionary dictionaryWithCapacity:components.count];
    
    for (NSString *component in components) {
        [self appendOption:component toDictionary:queryOptions];
    }
    
    self.options = [queryOptions copy];
}

- (NSString *)actionFromString:(NSString *)string
{
    NSString *action = nil;
    if (string.length > 0) {
        if ([self.scheme isEqualToString:EFProtocolScheme]) {
            action = [self actionFromEFString:string];
        } else if ([self.scheme isEqualToString:[self EFFacebookScheme]]) {
            action = [self actionFromFacebookString:string];
        }
    }
    return action;
}

- (void)appendOption:(NSString *)option toDictionary:(NSMutableDictionary *)dictionary
{
    NSArray *components = [option componentsSeparatedByString:@"="];
    NSString *key = [self valueFromArray:components atIndex:0];
    NSString *value = [self valueFromArray:components atIndex:1];
    NSString *decodedValue = [value urlDecode];
    
    if (key.length && decodedValue.length) {
        [dictionary setObject:decodedValue forKey:key];
    }
}

- (id)valueFromArray:(NSArray *)array atIndex:(NSInteger)index
{
    if (array.count >= (index + 1))
        return [array objectAtIndex:index];
    else
        return nil;
}

//////////////////////////////////////////////////////////////
#pragma mark - EFParsing
//////////////////////////////////////////////////////////////
- (NSString *)actionFromEFString:(NSString *)string
{
    NSString *action = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"action\\.(.*)" options:0 error:nil];
    NSTextCheckingResult *result = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    NSInteger ranges = [result numberOfRanges];
    if (ranges > 0)
        action = [string substringWithRange:[result rangeAtIndex:1]];
    return action;
}

- (void)parsePathFromEFProtocol:(NSURL *)protocol
{
    self.path = protocol.path;
}

//////////////////////////////////////////////////////////////
#pragma mark - Facebook Parsing
//////////////////////////////////////////////////////////////
- (NSString *)actionFromFacebookString:(NSString *)string
{
    return @"launch";
}

- (BOOL)parseFacebookProtocol:(NSURL *)protocol
{
    BOOL validProtocol = YES;
    [self parseOptionsFromProtocol:protocol.fragment];
    NSString *target = [self.options objectForKey:@"target_url"];
    if (target.length) {
        NSURL *targetURL = [NSURL URLWithString:target];
        
        NSString *path = targetURL.path;
        if ([path hasPrefix:@"/"] && [path length] > 1) {
            path = [path substringFromIndex:1];
        }
        NSArray *split = [path componentsSeparatedByString:@"/"];
        
        if ([split count] > 1) {
            self.path = [NSString stringWithFormat:@"/%@", [split objectAtIndex:0]];
            NSString * key = [self keyForEFPath];
            if (key.length) {
                self.options = @{key: [split objectAtIndex:1]?:@""};
            }
        }
    } else {
        validProtocol = NO;
    }
    return validProtocol;
}

- (NSString *)keyForEFPath
{
    NSString *key = nil;
    if ([self.path isEqualToString:@"/explore"]) {
        key = @"url";
    } else if ([self.path isEqualToString:@"/web"]) {
        key = @"url";
    }
    return key;
}

//////////////////////////////////////////////////////////////
#pragma mark - Errors
//////////////////////////////////////////////////////////////
- (void)appendErrorWithMessage:(NSString *)message
{
    [self.errorsFromParsing addObject:[self parseErrorWithMessage:message]];
}

- (NSError *)parseErrorWithMessage:(NSString *)message
{
    return [NSError errorWithDomain:@"com.tapclips.ios.protocolParserDomain" code:101 userInfo:@{NSLocalizedDescriptionKey: message ?: @""}];
}

//////////////////////////////////////////////////////////////
#pragma mark - Actions
//////////////////////////////////////////////////////////////
- (void)performProtocolAction
{
    Class actionClass = [self launchActionClassForActionName:self.action];
    if ([actionClass allowsActionFromReferringApplication:self.referringApplication]) {
        EFProtocolAction *action = [[actionClass alloc] initWithPath:self.path options:self.options];
        [action perform];
    }
}

- (Class)launchActionClassForActionName:(NSString *)action
{
    if (!action) return nil;
    
    static NSDictionary *lookupTable = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lookupTable = @{
                        @"launch": [EFLaunchPageAction class],
                        @"return": [EFReturnAction class],
                        @"link": [EFLinkAction class]
                        };
    });
    
    return lookupTable[action];
}

@end
