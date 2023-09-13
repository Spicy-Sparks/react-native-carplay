#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <CarPlay/CarPlay.h>
#import <React/RCTConvert.h>

API_AVAILABLE(ios(12.0))
@interface RCTConvert (RNCarPlay)

+ (CPTripEstimateStyle)CPTripEstimateStyle:(id)json;
+ (CPPanDirection)CPPanDirection:(id)json;
+ (CPAssistantCellPosition)CPAssistantCellPosition:(id)json API_AVAILABLE(ios(15.0));
+ (CPAssistantCellVisibility)CPAssistantCellVisibility:(id)json API_AVAILABLE(ios(15.0));
+ (CPAssistantCellActionType)CPAssistantCellActionType:(id)json API_AVAILABLE(ios(15.0));
+ (CPMapButton *)CPMapButton:(id)json withHandler:(void (^)(CPMapButton *_Nonnull mapButton))handler;
+ (CPRouteChoice *)CPRouteChoice:(id)json;
+ (MKMapItem *)MKMapItem:(id)json;
+ (CPPointOfInterest *)CPPointOfInterest:(id)json API_AVAILABLE(ios(14.0));
+ (CPAlertActionStyle)CPAlertActionStyle:(id)json;
@end
