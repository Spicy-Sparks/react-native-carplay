#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>

API_AVAILABLE(ios(12.0))
@interface RNCPStore : NSObject {
    CPInterfaceController *interfaceController;
    CPWindow *window;
}

@property (nonatomic, retain) CPInterfaceController *interfaceController;
@property (nonatomic, retain) CPWindow *window;

+ (id)sharedManager;
- (CPTemplate*) findTemplateById: (NSString*)templateId API_AVAILABLE(ios(12.0));
- (NSString*) setTemplate:(NSString*)templateId template:(CPTemplate*)template API_AVAILABLE(ios(12.0));
- (CPTrip*) findTripById: (NSString*)tripId;
- (NSString*) setTrip:(NSString*)tripId trip:(CPTrip*)trip API_AVAILABLE(ios(12.0));
- (CPNavigationSession*) findNavigationSessionById:(NSString*)navigationSessionId API_AVAILABLE(ios(12.0));
- (NSString*) setNavigationSession:(NSString*)navigationSessionId navigationSession:(CPNavigationSession*)navigationSession API_AVAILABLE(ios(12.0));
- (Boolean) isConnected;
- (void) setConnected:(Boolean) isConnected;

@end
