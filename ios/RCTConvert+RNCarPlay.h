#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <CarPlay/CarPlay.h>
#import <React/RCTConvert.h>

@interface RCTConvert (RNCarPlay)

+ (CPTripEstimateStyle)CPTripEstimateStyle:(id)json;
+ (CPPanDirection)CPPanDirection:(id)json;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 150000
+ (CPAssistantCellPosition)CPAssistantCellPosition:(id)json;
+ (CPAssistantCellVisibility)CPAssistantCellVisibility:(id)json;
+ (CPAssistantCellActionType)CPAssistantCellActionType:(id)json;
#endif
+ (CPMapButton*)CPMapButton:(id)json withHandler:(void (^)(CPMapButton * _Nonnull mapButton))handler;
+ (CPRouteChoice*)CPRouteChoice:(id)json;
+ (MKMapItem*)MKMapItem:(id)json;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 140000
+ (CPPointOfInterest*)CPPointOfInterest:(id)json;
#endif
+ (CPAlertActionStyle)CPAlertActionStyle:(id)json;
@end
