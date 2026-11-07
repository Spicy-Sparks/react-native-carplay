#import "RCTConvert+RNCarPlay.h"
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTLog.h>
#import <Availability.h>

@implementation RCTConvert (RNCarPlay)

+ (UIImage *)RNCPUIImage:(id)json {
    if (json == nil || json == [NSNull null]) {
        return nil;
    }
    @try {
        return [self UIImage:json];
    } @catch (NSException *exception) {
        if (![exception.name isEqualToString:NSInvalidArgumentException]) {
            @throw;
        }
        // Optional cache/OTA artwork may disappear. RN's local-file fallback can
        // raise URLByAppendingPathComponent:nil for a hostless file:/// URL;
        // contain image conversion errors here, not the whole template update.
        RCTLogWarn(@"CarPlay could not load optional artwork (%@)", exception.name);
        return nil;
    }
}

RCT_ENUM_CONVERTER(CPTripEstimateStyle, (@{
                                           @"light": @(CPTripEstimateStyleLight),
                                           @"dark": @(CPTripEstimateStyleDark)
                                           }),
                                         CPTripEstimateStyleDark,
                                         integerValue)

RCT_ENUM_CONVERTER(CPPanDirection, (@{
                                      @"up": @(CPPanDirectionUp),
                                      @"right": @(CPPanDirectionRight),
                                      @"bottom": @(CPPanDirectionDown),
                                      @"left": @(CPPanDirectionLeft),
                                      @"none": @(CPPanDirectionNone)
                                      }), CPPanDirectionNone, integerValue)

RCT_ENUM_CONVERTER(CPAssistantCellPosition, (@{
                                      @"top": @(CPAssistantCellPositionTop),
                                      @"bottom": @(CPAssistantCellPositionBottom)
                                      }), CPAssistantCellPositionTop, integerValue)

RCT_ENUM_CONVERTER(CPAssistantCellVisibility, (@{
                                      @"off": @(CPAssistantCellVisibilityOff),
                                      @"always": @(CPAssistantCellVisibilityAlways),
                                      @"limited": @(CPAssistantCellVisibilityWhileLimitedUIActive)
                                      }), CPAssistantCellVisibilityOff, integerValue)

RCT_ENUM_CONVERTER(CPAssistantCellActionType, (@{
                                      @"playMedia": @(CPAssistantCellActionTypePlayMedia),
                                      @"startCall": @(CPAssistantCellActionTypeStartCall)
                                      }), CPAssistantCellActionTypePlayMedia, integerValue)


+ (CPMapButton*)CPMapButton:(id)json withHandler:(void (^)(CPMapButton * _Nonnull mapButton))handler {
    CPMapButton *mapButton = [[CPMapButton alloc] initWithHandler:handler];

    if ([json objectForKey:@"image"]) {
        UIImage *image = [RCTConvert RNCPUIImage:json[@"image"]];
        if (image) [mapButton setImage:image];
    }

    if ([json objectForKey:@"focusedImage"]) {
        UIImage *image = [RCTConvert RNCPUIImage:json[@"focusedImage"]];
        if (image) [mapButton setFocusedImage:image];
    }

    if ([json objectForKey:@"disabled"]) {
        [mapButton setEnabled:![RCTConvert BOOL:json[@"disabled"]]];
    }

    if ([json objectForKey:@"hidden"]) {
        [mapButton setHidden:[RCTConvert BOOL:json[@"hidden"]]];
    }

    return mapButton;
}

+ (MKMapItem*)MKMapItem:(id)json {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([RCTConvert double:json[@"latitude"]], [RCTConvert double:json[@"longitude"]]);
    NSString *name = [RCTConvert NSString:json[@"name"]];
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = name;
    return mapItem;
}

+ (CPRouteChoice*)CPRouteChoice:(id)json {
    return [[CPRouteChoice alloc] initWithSummaryVariants:[RCTConvert NSStringArray:json[@"additionalInformationVariants"]] additionalInformationVariants:[RCTConvert NSStringArray:json[@"selectionSummaryVariants"]] selectionSummaryVariants:[RCTConvert NSStringArray:json[@"summaryVariants"]]];
}

+ (CPPointOfInterest*)CPPointOfInterest:(id)json {
    MKMapItem *location = [RCTConvert MKMapItem:json[@"location"]];
    NSString *title = [RCTConvert NSString:json[@"title"]];
    NSString *subtitle = [RCTConvert NSString:json[@"subtitle"]];
    NSString *summary = [RCTConvert NSString:json[@"summary"]];
    NSString *detailTitle = [RCTConvert NSString:json[@"detailTitle"]];
    NSString *detailSubtitle = [RCTConvert NSString:json[@"detailSubtitle"]];
    NSString *detailSummary = [RCTConvert NSString:json[@"detailSummary"]];

    CPPointOfInterest *poi = [[CPPointOfInterest alloc] initWithLocation:location title:title subtitle:subtitle summary:summary detailTitle:detailTitle detailSubtitle:detailSubtitle detailSummary:detailSummary pinImage:nil];
    return poi;
}

+ (CPAlertActionStyle)CPAlertActionStyle:(NSString*) json {
    if ([json isEqualToString:@"cancel"]) {
        return CPAlertActionStyleCancel;
    } else if ([json isEqualToString:@"destructive"]) {
        return CPAlertActionStyleDestructive;
    }
    return CPAlertActionStyleDefault;
}

@end
