//
//  RNCPStore.m
//  RNCarPlay
//
//  Created by Birkir Gudjonsson on 3/25/19.
//  Copyright © 2019 SOLID Mobile. All rights reserved.
//

#import "RNCPStore.h"

@implementation RNCPStore {
    NSMutableDictionary* _templatesStore;
    NSMutableDictionary* _navigationSessionsStore;
    NSMutableDictionary* _tripsStore;
    Boolean _connected;
}

@synthesize window;
@synthesize interfaceController;

-(instancetype)init {
    if (self = [super init]) {
        _templatesStore = [[NSMutableDictionary alloc] init];
        _navigationSessionsStore = [[NSMutableDictionary alloc] init];
        _tripsStore = [[NSMutableDictionary alloc] init];
        _connected = false;
    }

    return self;
}

+ (RNCPStore*) sharedManager {
    static RNCPStore *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void) setConnected:(Boolean) isConnected {
    _connected = isConnected;
}

- (Boolean) isConnected {
    return _connected;
}

- (CPTemplate*) findTemplateById:(NSString*)templateId API_AVAILABLE(ios(12.0)){
    return [_templatesStore objectForKey:templateId];
}

- (NSString*) setTemplate:(NSString*)templateId template:(CPTemplate*)template API_AVAILABLE(ios(12.0)){
    [_templatesStore setObject:template forKey:templateId];
    return templateId;
}

- (CPTrip*) findTripById:(NSString*)tripId API_AVAILABLE(ios(12.0)){
    return [_tripsStore objectForKey:tripId];
}

- (NSString*) setTrip:(NSString*)tripId trip:(CPTrip*)trip API_AVAILABLE(ios(12.0)){
    [_tripsStore setObject:trip forKey:tripId];
    return tripId;
}

- (CPNavigationSession*) findNavigationSessionById:(NSString*)navigationSessionId API_AVAILABLE(ios(12.0)){
    return [_navigationSessionsStore objectForKey:navigationSessionId];
}

- (NSString*) setNavigationSession:(NSString*)navigationSessionId navigationSession:(CPNavigationSession*)navigationSession API_AVAILABLE(ios(12.0)){
    [_navigationSessionsStore setObject:navigationSession forKey:navigationSessionId];
    return navigationSessionId;
}

@end
