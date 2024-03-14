#import "RNCarPlay.h"
#import <React/RCTConvert.h>
#import <React/RCTRootView.h>

@implementation RNCarPlay
{
    bool hasListeners;
}

@synthesize interfaceController;
@synthesize window;
@synthesize searchResultBlock;
@synthesize selectedResultBlock;
@synthesize isNowPlayingActive;

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

+ (NSDictionary *) getConnectedWindowInformation: (CPWindow *) window  API_AVAILABLE(ios(12.0)){
    return @{
        @"width": @(window.bounds.size.width),
        @"height": @(window.bounds.size.height),
        @"scale": @(window.screen.scale)
    };
}

+ (void) connectWithInterfaceController:(CPInterfaceController*)interfaceController window:(CPWindow*)window  API_AVAILABLE(ios(12.0)){
    RNCPStore * store = [RNCPStore sharedManager];
    store.interfaceController = interfaceController;
    store.window = window;
    [store setConnected:true];

    RNCarPlay *cp = [RNCarPlay allocWithZone:nil];
    if (cp.bridge) {
        [cp sendEventWithName:@"didConnect" body:[self getConnectedWindowInformation:window]];
    }
}

+ (void) disconnect {
    RNCarPlay *cp = [RNCarPlay allocWithZone:nil];
    RNCPStore *store = [RNCPStore sharedManager];
    [store setConnected:false];
    [[store.window subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (cp.bridge) {
        [cp sendEventWithName:@"didDisconnect" body:@{}];
    }
}

RCT_EXPORT_MODULE();

+ (id)allocWithZone:(NSZone *)zone {
    static RNCarPlay *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        @"didConnect",
        @"didDisconnect",
        // interface
        @"barButtonPressed",
        @"backButtonPressed",
        @"didAppear",
        @"didDisappear",
        @"willAppear",
        @"willDisappear",
        @"buttonPressed",
        // grid
        @"gridButtonPressed",
        // information
        @"actionButtonPressed",
        // list
        @"didSelectListItem",
        // search
        @"updatedSearchText",
        @"searchButtonPressed",
        @"selectedResult",
        // tabbar
        @"didSelectTemplate",
        // nowplaying
        @"upNextButtonPressed",
        @"albumArtistButtonPressed",
        // poi
        @"didSelectPointOfInterest",
        // map
        @"mapButtonPressed",
        @"didUpdatePanGestureWithTranslation",
        @"didEndPanGestureWithVelocity",
        @"panBeganWithDirection",
        @"panEndedWithDirection",
        @"panWithDirection",
        @"didBeginPanGesture",
        @"didDismissPanningInterface",
        @"willDismissPanningInterface",
        @"didShowPanningInterface",
        @"didDismissNavigationAlert",
        @"willDismissNavigationAlert",
        @"didShowNavigationAlert",
        @"willShowNavigationAlert",
        @"didCancelNavigation",
        @"alertActionPressed",
        @"selectedPreviewForTrip",
        @"startedTrip",
        @"didSelectRowItem"
    ];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}


-(UIImage *)imageWithTint:(UIImage *)image andTintColor:(UIColor *)tintColor {
    UIImage *imageNew = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imageNew];
    imageView.tintColor = tintColor;
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, 0.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

-(UIImage*)dynamicImageWithNormalImage:(UIImage*)normalImage darkImage:(UIImage*)darkImage {
  RNCPStore *store = [RNCPStore sharedManager];
    if (normalImage == nil || darkImage == nil) {
        return normalImage ? : darkImage;
    }
    if (@available(iOS 14.0, *)) {
      UIImageAsset* imageAsset = darkImage.imageAsset;

        // darkImage
        UITraitCollection* darkImageTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:
        @[[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark],
          [UITraitCollection traitCollectionWithDisplayScale:normalImage.scale]]];
        [imageAsset registerImage:normalImage withTraitCollection:darkImageTraitCollection];

        return [imageAsset imageWithTraitCollection: store.interfaceController.carTraitCollection];
    }
    else {
        return normalImage;
   }
}

- (UIImage *)imageWithSize:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

RCT_EXPORT_METHOD(checkForConnection) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        if ([store isConnected] && hasListeners) {
            [self sendEventWithName:@"didConnect" body:[RNCarPlay getConnectedWindowInformation: store.window]];
        }
    }
}

RCT_EXPORT_METHOD(createTemplate:(NSString *)templateId config:(NSDictionary*)config) {
    BOOL updatingTemplate = [RCTConvert BOOL:config[@"updatingTemplate"]];
    if (updatingTemplate) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self createTemplateMethod:templateId config:config];
        });
    } else {
        [self createTemplateMethod:templateId config:config];
    }
}

- (void)createTemplateMethod:(NSString *)templateId config:(NSDictionary*)config {
    if (@available(iOS 12.0, *)) {
        // Get the shared instance of the RNCPStore class
        RNCPStore *store = [RNCPStore sharedManager];
        
        // Extract values from the 'config' dictionary
        NSString *type = [RCTConvert NSString:config[@"type"]];
        NSString *title = [RCTConvert NSString:config[@"title"]];
        NSArray *leadingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"leadingNavigationBarButtons"]] templateId:templateId];
        NSArray *trailingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"trailingNavigationBarButtons"]] templateId:templateId];
        
        // Create a new CPTemplate object
        CPTemplate *carPlayTemplate = [[CPTemplate alloc] init];
        
        if ([type isEqualToString:@"search"]) {
            CPSearchTemplate *searchTemplate = [[CPSearchTemplate alloc] init];
            searchTemplate.delegate = self;
            carPlayTemplate = searchTemplate;
        }
        else if ([type isEqualToString:@"grid"]) {
            NSArray *buttons = [self parseGridButtons:[RCTConvert NSArray:config[@"buttons"]] templateId:templateId];
            CPGridTemplate *gridTemplate = [[CPGridTemplate alloc] initWithTitle:title gridButtons:buttons];
            [gridTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
            [gridTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
            carPlayTemplate = gridTemplate;
        }
        else if ([type isEqualToString:@"list"]) {
            if (@available(iOS 14, *)) {
                NSArray *sections = [self parseSections:[RCTConvert NSArray:config[@"sections"]] templateId:templateId];
                CPListTemplate *listTemplate;
                if (@available(iOS 15.0, *)) {
                    if ([config objectForKey:@"assistant"]) {
                        NSDictionary *assistant = [config objectForKey:@"assistant"];
                        BOOL _enabled = [assistant valueForKey:@"enabled"];
                        if (_enabled) {
                            CPAssistantCellConfiguration *conf = [[CPAssistantCellConfiguration alloc] initWithPosition:CPAssistantCellPositionTop visibility:CPAssistantCellVisibilityAlways assistantAction:CPAssistantCellActionTypePlayMedia];
                            listTemplate = [[CPListTemplate alloc] initWithTitle:title sections:sections assistantCellConfiguration:conf];
                        }
                    }
                }
                if (listTemplate == nil) {
                    // Fallback on earlier versions
                    listTemplate = [[CPListTemplate alloc] initWithTitle:title sections:sections];
                }
                [listTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
                [listTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
                if (![RCTConvert BOOL:config[@"backButtonHidden"]]) {
                    NSString *title = [RCTConvert NSString:config[@"backButtonTitle"]];
                    if (!title) {
                        title = @"Back";
                    }
                    title = [@" " stringByAppendingString:title];
                    CPBarButton *backButton = [[CPBarButton alloc] initWithTitle:title handler:^(CPBarButton * _Nonnull barButton) {
                        if (self->hasListeners) {
                            [self sendEventWithName:@"backButtonPressed" body:@{@"templateId":templateId}];
                        }
                        [self popTemplate:false];
                    }];
                    [listTemplate setBackButton:backButton];
                }
                if (config[@"emptyViewTitleVariants"]) {
                    listTemplate.emptyViewTitleVariants = [RCTConvert NSArray:config[@"emptyViewTitleVariants"]];
                }
                if (config[@"emptyViewSubtitleVariants"]) {
                    listTemplate.emptyViewSubtitleVariants = [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]];
                }
                listTemplate.delegate = self;
                carPlayTemplate = listTemplate;
            } else {
                NSArray *sections = [self parseSections:[RCTConvert NSArray:config[@"sections"]] templateId:templateId];
                CPListTemplate *listTemplate = [[CPListTemplate alloc] initWithTitle:title sections:sections];
                [listTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
                [listTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
                listTemplate.delegate = self;
                carPlayTemplate = listTemplate;
            }
        }
        else if ([type isEqualToString:@"map"]) {
            CPMapTemplate *mapTemplate = [[CPMapTemplate alloc] init];
            
            [self applyConfigForMapTemplate:mapTemplate templateId:templateId config:config];
            [mapTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
            [mapTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
            [mapTemplate setUserInfo:@{ @"templateId": templateId }];
            mapTemplate.mapDelegate = self;
            
            carPlayTemplate = mapTemplate;
        } else if ([type isEqualToString:@"voicecontrol"]) {
            CPVoiceControlTemplate *voiceTemplate = [[CPVoiceControlTemplate alloc] initWithVoiceControlStates: [self parseVoiceControlStates:config[@"voiceControlStates"]]];
            carPlayTemplate = voiceTemplate;
        } else if ([type isEqualToString:@"nowplaying"]) {
            if (@available(iOS 14, *)) {
                CPNowPlayingTemplate *nowPlayingTemplate = [CPNowPlayingTemplate sharedTemplate];
                [nowPlayingTemplate setAlbumArtistButtonEnabled:[RCTConvert BOOL:config[@"albumArtistButtonEnabled"]]];
                [nowPlayingTemplate setUpNextTitle:[RCTConvert NSString:config[@"upNextButtonTitle"]]];
                [nowPlayingTemplate setUpNextButtonEnabled:[RCTConvert BOOL:config[@"upNextButtonEnabled"]]];
                NSMutableArray<CPNowPlayingButton *> *buttons = [NSMutableArray new];
                NSArray<NSDictionary*> *_buttons = [RCTConvert NSDictionaryArray:config[@"buttons"]];
                
                NSDictionary *buttonImagesNamesMapping = @{
                    @"heart": @"HeartIcon",
                    @"heart-outlined": @"HeartOutlinedIcon",
                    @"clock": @"ClockNowIcon",
                    @"arrow-down-circle": @"ArrowDownCircleIcon",
                    @"md-close": @"CloseIcon",
                    @"repeat": @"RepeatIcon",
                    @"shuffle": @"ShuffleIcon"
                };
                
                for (NSDictionary *_button in _buttons) {
                    NSString *id = [RCTConvert NSString:_button[@"id"]];
                    NSString *imageName = [RCTConvert NSString:_button[@"imageName"]];
                    BOOL selected = [RCTConvert BOOL:_button[@"selected"]];
                    NSDictionary *body = @{@"templateId":templateId, @"id": id};
                    UIImage *buttonImage = [UIImage imageNamed:buttonImagesNamesMapping[imageName]];
                    if (buttonImage) {
                        CPNowPlayingButton *button = [CPNowPlayingImageButton.alloc initWithImage:buttonImage handler:^(CPNowPlayingImageButton *b) {
                            if (self->hasListeners) {
                                [self sendEventWithName:@"buttonPressed" body:body];
                            }
                        }];
                        button.selected = selected;
                        [buttons addObject:button];
                    }
                }
                [nowPlayingTemplate updateNowPlayingButtons:buttons];
                carPlayTemplate = nowPlayingTemplate;
            }
        } else if ([type isEqualToString:@"tabbar"]) {
            if (@available(iOS 14, *)) {
                CPTabBarTemplate *tabBarTemplate = [[CPTabBarTemplate alloc] initWithTemplates:[self parseTemplatesFrom:config]];
                tabBarTemplate.delegate = self;
                carPlayTemplate = tabBarTemplate;
            }
        } else if ([type isEqualToString:@"contact"]) {
            if (@available(iOS 14, *)) {
                NSString *nm = [RCTConvert NSString:config[@"name"]];
                UIImage *img = [RCTConvert UIImage:config[@"image"]];
                CPContact *contact = [[CPContact alloc] initWithName:nm image:img];
                [contact setSubtitle:config[@"subtitle"]];
                [contact setActions:[self parseButtons:config[@"actions"] templateId:templateId]];
                CPContactTemplate *contactTemplate = [[CPContactTemplate alloc] initWithContact:contact];
                carPlayTemplate = contactTemplate;
            }
        } else if ([type isEqualToString:@"actionsheet"]) {
            NSString *title = [RCTConvert NSString:config[@"title"]];
            NSString *message = [RCTConvert NSString:config[@"message"]];
            NSMutableArray<CPAlertAction *> *actions = [NSMutableArray new];
            NSArray<NSDictionary*> *_actions = [RCTConvert NSDictionaryArray:config[@"actions"]];
            for (NSDictionary *_action in _actions) {
                CPAlertAction *action = [[CPAlertAction alloc] initWithTitle:[RCTConvert NSString:_action[@"title"]] style:[RCTConvert CPAlertActionStyle:_action[@"style"]] handler:^(CPAlertAction *a) {
                    if (self->hasListeners) {
                        [self sendEventWithName:@"actionButtonPressed" body:@{@"templateId":templateId, @"id": _action[@"id"] }];
                    }
                }];
                [actions addObject:action];
            }
            CPActionSheetTemplate *actionSheetTemplate = [[CPActionSheetTemplate alloc] initWithTitle:title message:message actions:actions];
            carPlayTemplate = actionSheetTemplate;
        } else if ([type isEqualToString:@"alert"]) {
            NSMutableArray<CPAlertAction *> *actions = [NSMutableArray new];
            NSArray<NSDictionary*> *_actions = [RCTConvert NSDictionaryArray:config[@"actions"]];
            for (NSDictionary *_action in _actions) {
                CPAlertAction *action = [[CPAlertAction alloc] initWithTitle:[RCTConvert NSString:_action[@"title"]] style:[RCTConvert CPAlertActionStyle:_action[@"style"]] handler:^(CPAlertAction *a) {
                    if (self->hasListeners) {
                        [self sendEventWithName:@"actionButtonPressed" body:@{@"templateId":templateId, @"id": _action[@"id"] }];
                    }
                }];
                [actions addObject:action];
            }
            NSArray<NSString*>* titleVariants = [RCTConvert NSArray:config[@"titleVariants"]];
            CPAlertTemplate *alertTemplate = [[CPAlertTemplate alloc] initWithTitleVariants:titleVariants actions:actions];
            carPlayTemplate = alertTemplate;
        } else if ([type isEqualToString:@"poi"]) {
            if (@available(iOS 14, *)) {
                NSString *title = [RCTConvert NSString:config[@"title"]];
                NSMutableArray<__kindof CPPointOfInterest *> * items = [NSMutableArray new];
                NSUInteger selectedIndex = 0;
                
                NSArray<NSDictionary*> *_items = [RCTConvert NSDictionaryArray:config[@"items"]];
                for (NSDictionary *_item in _items) {
                    CPPointOfInterest *poi = [RCTConvert CPPointOfInterest:_item];
                    [poi setUserInfo:_item];
                    [items addObject:poi];
                }
                
                CPPointOfInterestTemplate *poiTemplate = [[CPPointOfInterestTemplate alloc] initWithTitle:title pointsOfInterest:items selectedIndex:selectedIndex];
                poiTemplate.pointOfInterestDelegate = self;
                carPlayTemplate = poiTemplate;
            }
        } else if ([type isEqualToString:@"information"]) {
            if (@available(iOS 14, *)) {
                NSString *title = [RCTConvert NSString:config[@"title"]];
                CPInformationTemplateLayout layout = [RCTConvert BOOL:config[@"leading"]] ? CPInformationTemplateLayoutLeading : CPInformationTemplateLayoutTwoColumn;
                NSMutableArray<__kindof CPInformationItem *> * items = [NSMutableArray new];
                NSMutableArray<__kindof CPTextButton *> * actions = [NSMutableArray new];
                
                NSArray<NSDictionary*> *_items = [RCTConvert NSDictionaryArray:config[@"items"]];
                for (NSDictionary *_item in _items) {
                    [items addObject:[[CPInformationItem alloc] initWithTitle:_item[@"title"] detail:_item[@"detail"]]];
                }
                
                NSArray<NSDictionary*> *_actions = [RCTConvert NSDictionaryArray:config[@"actions"]];
                for (NSDictionary *_action in _actions) {
                    CPTextButton *action = [[CPTextButton alloc] initWithTitle:_action[@"title"] textStyle:CPTextButtonStyleNormal handler:^(__kindof CPTextButton * _Nonnull contactButton) {
                        if (self->hasListeners) {
                            [self sendEventWithName:@"actionButtonPressed" body:@{@"templateId":templateId, @"id": _action[@"id"] }];
                        }
                    }];
                    [actions addObject:action];
                }
                
                CPInformationTemplate *informationTemplate = [[CPInformationTemplate alloc] initWithTitle:title layout:layout items:items actions:actions];
                carPlayTemplate = informationTemplate;
            }
        }
        
        if (@available(iOS 14, *)) {
            if (config[@"tabSystemItem"]) {
                carPlayTemplate.tabSystemItem = [RCTConvert NSInteger:config[@"tabSystemItem"]];
            }
            if (config[@"tabSystemImageName"]) {
                carPlayTemplate.tabImage = [UIImage systemImageNamed:[RCTConvert NSString:config[@"tabSystemImageName"]]];
            }
            if (config[@"tabImage"]) {
                carPlayTemplate.tabImage = [RCTConvert UIImage:config[@"tabImage"]];
            }
            if (config[@"tabImageName"]) {
                NSDictionary *tabImagesNamesMapping = @{
                    @"home": @"HomeIcon",
                    @"clock": @"ClockTabIcon",
                    @"search": @"SearchIcon",
                    @"music": @"MusicIcon",
                };
                NSString *imageName = [RCTConvert NSString:config[@"tabImageName"]];
                carPlayTemplate.tabImage = [UIImage imageNamed: tabImagesNamesMapping[imageName]];
            }
            if (config[@"tabTitle"]) {
                carPlayTemplate.tabTitle = [RCTConvert NSString:config[@"tabTitle"]];
            }
        }
        
        [carPlayTemplate setUserInfo:@{ @"templateId": templateId }];
        [store setTemplate:templateId template:carPlayTemplate];
    }
}

RCT_EXPORT_METHOD(createTrip:(NSString*)tripId config:(NSDictionary*)config) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTrip *trip = [self parseTrip:config];
        NSMutableDictionary *userInfo = trip.userInfo;
        if (!userInfo) {
            userInfo = [[NSMutableDictionary alloc] init];
            trip.userInfo = userInfo;
        }
        
        [userInfo setValue:tripId forKey:@"id"];
        [store setTrip:tripId trip:trip];
    }
}

RCT_EXPORT_METHOD(updateTravelEstimatesForTrip:(NSString*)templateId tripId:(NSString*)tripId travelEstimates:(NSDictionary*)travelEstimates timeRemainingColor:(NSUInteger*)timeRemainingColor) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            CPTrip *trip = [[RNCPStore sharedManager] findTripById:tripId];
            if (trip) {
                CPTravelEstimates *estimates = [self parseTravelEstimates:travelEstimates];
                [mapTemplate updateTravelEstimates:estimates forTrip:trip withTimeRemainingColor:(CPTimeRemainingColor) timeRemainingColor];
            }
        }
    }
}

RCT_REMAP_METHOD(startNavigationSession,
                 templateId:(NSString *)templateId
                 tripId:(NSString *)tripId
                 startNavigationSessionWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            CPTrip *trip = [[RNCPStore sharedManager] findTripById:tripId];
            if (trip) {
                CPNavigationSession *navigationSession = [mapTemplate startNavigationSessionForTrip:trip];
                [store setNavigationSession:tripId navigationSession:navigationSession];
                resolve(@{ @"tripId": tripId, @"navigationSessionId": tripId });
            }
        } else {
            reject(@"template_not_found", @"Template not found in store", nil);
        }
    }
}

RCT_EXPORT_METHOD(updateManeuversNavigationSession:(NSString*)navigationSessionId maneuvers:(NSArray*)maneuvers) {
    if (@available(iOS 12.0, *)) {
        CPNavigationSession* navigationSession = [[RNCPStore sharedManager] findNavigationSessionById:navigationSessionId];
        if (navigationSession) {
            NSMutableArray<CPManeuver*>* upcomingManeuvers = [NSMutableArray array];
            for (NSDictionary *maneuver in maneuvers) {
                [upcomingManeuvers addObject:[self parseManeuver:maneuver]];
            }
            [navigationSession setUpcomingManeuvers:upcomingManeuvers];
        }
    }
}

RCT_EXPORT_METHOD(updateTravelEstimatesNavigationSession:(NSString*)navigationSessionId maneuverIndex:(NSUInteger)maneuverIndex travelEstimates:(NSDictionary*)travelEstimates) {
    if (@available(iOS 12.0, *)) {
        CPNavigationSession* navigationSession = [[RNCPStore sharedManager] findNavigationSessionById:navigationSessionId];
        if (navigationSession) {
            CPManeuver *maneuver = [[navigationSession upcomingManeuvers] objectAtIndex:maneuverIndex];
            if (maneuver) {
                [navigationSession updateTravelEstimates:[self parseTravelEstimates:travelEstimates] forManeuver:maneuver];
            }
        }
    }
}

RCT_EXPORT_METHOD(pauseNavigationSession:(NSString*)navigationSessionId reason:(NSUInteger*)reason description:(NSString*)description) {
    if (@available(iOS 12.0, *)) {
        CPNavigationSession* navigationSession = [[RNCPStore sharedManager] findNavigationSessionById:navigationSessionId];
        if (navigationSession) {
            [navigationSession pauseTripForReason:(CPTripPauseReason) reason description:description];
        } else {
            NSLog(@"Could not find session");
        }
    }
}

RCT_EXPORT_METHOD(cancelNavigationSession:(NSString*)navigationSessionId) {
    if (@available(iOS 12.0, *)) {
        CPNavigationSession* navigationSession = [[RNCPStore sharedManager] findNavigationSessionById:navigationSessionId];
        if (navigationSession) {
            [navigationSession cancelTrip];
        } else {
            NSLog(@"Could not cancel. No session found.");
        }
    }
}

RCT_EXPORT_METHOD(finishNavigationSession:(NSString*)navigationSessionId) {
    if (@available(iOS 12.0, *)) {
        CPNavigationSession* navigationSession = [[RNCPStore sharedManager] findNavigationSessionById:navigationSessionId];
        if (navigationSession) {
            [navigationSession finishTrip];
        }
    }
}

RCT_EXPORT_METHOD(setRootTemplate:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        
        store.interfaceController.delegate = self;
        
        if (template) {
            if (@available(iOS 14, *)) {
                [store.interfaceController setRootTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
                    if (err) {
                        NSLog(@"error - setRootTemplate %@", err);
                    }
                }];
            } else {
                [store.interfaceController setRootTemplate:template animated:animated];
            }
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(pushTemplate:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            if (@available(iOS 14, *)) {
                [store.interfaceController pushTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
                    if (err) {
                        NSLog(@"error - pushTemplate %@", err);
                    }
                }];
            } else {
                [store.interfaceController pushTemplate:template animated:animated];
            }
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(popToTemplate:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            if (@available(iOS 14, *)) {
                [store.interfaceController popToTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
                    if (err) {
                        NSLog(@"error - popToTemplate %@", err);
                    }
                }];
            } else {
                [store.interfaceController popToTemplate:template animated:animated];
            }
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(popToRootTemplate:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        if (@available(iOS 14, *)) {
            [store.interfaceController popToRootTemplateAnimated:animated completion:^(BOOL done, NSError * _Nullable err) {
                if (err) {
                    NSLog(@"error - popToRootTemplate %@", err);
                }
            }];
        } else {
            [store.interfaceController popToRootTemplateAnimated:animated];
        }
    }
}

RCT_EXPORT_METHOD(popTemplate:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        if (@available(iOS 14, *)) {
            [store.interfaceController popTemplateAnimated:animated completion:^(BOOL done, NSError * _Nullable err) {
                if (err) {
                    NSLog(@"error - popTemplate %@", err);
                }
            }];
        } else {
            [store.interfaceController popTemplateAnimated:animated];
        }
    }
}

RCT_EXPORT_METHOD(presentTemplate:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            if (@available(iOS 14, *)) {
                [store.interfaceController presentTemplate:template animated:animated completion:^(BOOL done, NSError * _Nullable err) {
                    if (err) {
                        NSLog(@"error - presentTemplate %@", err);
                    }
                }];
            } else {
                [store.interfaceController presentTemplate:template animated:animated];
            }
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(dismissTemplate:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        [store.interfaceController dismissTemplateAnimated:animated];
    }
}

RCT_EXPORT_METHOD(updateListTemplate:(NSString*)templateId config:(NSDictionary*)config) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template && [template isKindOfClass:[CPListTemplate class]]) {
            CPListTemplate *listTemplate = (CPListTemplate *)template;
            if (config[@"leadingNavigationBarButtons"]) {
                NSArray *leadingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"leadingNavigationBarButtons"]] templateId:templateId];
                [listTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
            }
            if (config[@"trailingNavigationBarButtons"]) {
                NSArray *trailingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"trailingNavigationBarButtons"]] templateId:templateId];
                [listTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
            }
            if (config[@"emptyViewTitleVariants"]) {
                listTemplate.emptyViewTitleVariants = [RCTConvert NSArray:config[@"emptyViewTitleVariants"]];
            }
            if (config[@"emptyViewSubtitleVariants"]) {
                NSLog(@"%@", [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]]);
                listTemplate.emptyViewSubtitleVariants = [RCTConvert NSArray:config[@"emptyViewSubtitleVariants"]];
            }
        }
    }
}

RCT_EXPORT_METHOD(updateTabBarTemplates:(NSString *)templateId templates:(NSDictionary*)config) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPTabBarTemplate *tabBarTemplate = (CPTabBarTemplate*) template;
            [tabBarTemplate updateTemplates:[self parseTemplatesFrom:config]];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}


RCT_EXPORT_METHOD(updateListTemplateSections:(NSString *)templateId sections:(NSArray*)sections) {
    if (@available(iOS 12.0, *)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RNCPStore *store = [RNCPStore sharedManager];
            CPTemplate *template = [store findTemplateById:templateId];
            if (template) {
                CPListTemplate *listTemplate = (CPListTemplate*) template;
                [self parseSections:sections templateId:templateId completion:^(NSArray<CPListSection*> *parsedSections) {
                    [listTemplate updateSections:parsedSections];
                }];
            } else {
                NSLog(@"Failed to find template %@", template);
            }
        });
    }
}

RCT_EXPORT_METHOD(updateListTemplateItem:(NSString *)templateId config:(NSDictionary*)config) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPListTemplate *listTemplate = (CPListTemplate*) template;
            NSInteger sectionIndex = [RCTConvert NSInteger:config[@"sectionIndex"]];
            if (sectionIndex >= 0 && sectionIndex >= listTemplate.sections.count) {
                return;
            }
            CPListSection *section = listTemplate.sections[sectionIndex];
            NSInteger index = [RCTConvert NSInteger:config[@"itemIndex"]];
            if (index >= 0 && index >= section.items.count) {
                return;
            }
            CPListItem *item = (CPListItem *)section.items[index];
            if (item) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    RNCPStore *store = [RNCPStore sharedManager];
                    CPTemplate *template = [store findTemplateById:templateId];
                    if (template) {
                        CPListTemplate *listTemplate = (CPListTemplate*) template;
                        NSInteger sectionIndex = [RCTConvert NSInteger:config[@"sectionIndex"]];
                        if (sectionIndex >= 0 && sectionIndex >= listTemplate.sections.count) {
                            return;
                        }
                        CPListSection *section = listTemplate.sections[sectionIndex];
                        NSInteger index = [RCTConvert NSInteger:config[@"itemIndex"]];
                        if (index >= 0 && index >= section.items.count) {
                            return;
                        }
                        CPListItem *item = (CPListItem *)section.items[index];
                        if (item) {
                            NSString *imgUrl = [RCTConvert NSString:config[@"imgUrl"]];
                            if (imgUrl) {
                                NSURL *url = [NSURL URLWithString:imgUrl];
                                if (url) {
                                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                                    if (imageData) {
                                        UIImage *image = [[UIImage alloc] initWithData:imageData];
                                        if (image) {
                                            [item setImage:image];
                                        }
                                    }
                                }
                            }
                        }
                    }
                });
                if (config[@"image"]) {
                    [item setImage:[RCTConvert UIImage:config[@"image"]]];
                }
                if (config[@"text"]) {
                    [item setText:[RCTConvert NSString:config[@"text"]]];
                }
                if (config[@"detailText"]) {
                    [item setDetailText:[RCTConvert NSString:config[@"detailText"]]];
                }
                BOOL isPlaying = [RCTConvert BOOL:config[@"isPlaying"]];
                if (isPlaying) {
                    [item setPlayingIndicatorLocation:CPListItemPlayingIndicatorLocationTrailing];
                    [item setPlaying:YES];
                } else {
                    [item setPlaying:NO];
                }
            }
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(updateListTemplateRowItems:(NSString *)templateId config:(NSDictionary*)config) {
    if (@available(iOS 14, *)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RNCPStore *store = [RNCPStore sharedManager];
            CPTemplate *template = [store findTemplateById:templateId];
            if (template) {
                CPListTemplate *listTemplate = (CPListTemplate*) template;
                NSInteger sectionIndex = [RCTConvert NSInteger:config[@"sectionIndex"]];
                if (sectionIndex >= listTemplate.sections.count) {
                    return;
                }
                CPListSection *section = listTemplate.sections[sectionIndex];
                NSInteger index = [RCTConvert NSInteger:config[@"itemIndex"]];
                if (index >= section.items.count) {
                    return;
                }
                CPListImageRowItem *item = (CPListImageRowItem *)section.items[index];
                if (item) {
                    if(config[@"rowItems"]) {
                        UIImage *placeholder = [UIImage imageNamed: @"Placeholder"];
                        NSArray *_rowItems = [RCTConvert NSArray:config[@"rowItems"]];
                        NSMutableArray *loadedRowItemsImages = [[NSMutableArray alloc] init];
                        
                        for (id rowItem in _rowItems) {
                            if (rowItem[@"imgUrl"]) {
                                UIImage *image = nil;
                                NSString *imgUrl = rowItem[@"imgUrl"];
                                NSURL *url = [NSURL URLWithString:imgUrl];
                                if (url) {
                                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                                    if (imageData) {
                                        UIImage *imageCopy = [[UIImage alloc] initWithData:imageData];
                                        if (imageCopy) {
                                            image = imageCopy;
                                        }
                                    }
                                }
                                if (!image && placeholder) image = placeholder;
                                if ([rowItem[@"isArtist"] boolValue]) {
                                    image = [self imageWithRoundedCornersSize:100 usingImage:image];
                                }
                                if (image) {
                                    [loadedRowItemsImages addObject:image];
                                }
                            }
                        }
                        
                        while ([loadedRowItemsImages count] < 9) {
                            if (placeholder) [loadedRowItemsImages addObject:placeholder];
                        }
                        
                        [item updateImages:loadedRowItemsImages];
                    }
                }
            } else {
                NSLog(@"Failed to find template %@", template);
            }
        });
    }
}

RCT_EXPORT_METHOD(updateInformationTemplateItems:(NSString *)templateId items:(NSArray*)items) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPInformationTemplate *informationTemplate = (CPInformationTemplate*) template;
            informationTemplate.items = [self parseInformationItems:items];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(updateInformationTemplateActions:(NSString *)templateId items:(NSArray*)actions) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPInformationTemplate *informationTemplate = (CPInformationTemplate*) template;
            informationTemplate.actions = [self parseInformationActions:actions templateId:templateId];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(getMaximumListItemCount:(NSString *)templateId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPListTemplate *listTemplate = (CPListTemplate*) template;
            resolve(@(CPListTemplate.maximumItemCount));
        } else {
            NSLog(@"Failed to find template %@", template);
            reject(@"template_not_found", @"Template not found in store", nil);
        }
    }
}

RCT_EXPORT_METHOD(getMaximumListSectionCount:(NSString *)templateId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if (@available(iOS 14, *)) {
        RNCPStore *store = [RNCPStore sharedManager];
        CPTemplate *template = [store findTemplateById:templateId];
        if (template) {
            CPListTemplate *listTemplate = (CPListTemplate*) template;
            resolve(@(CPListTemplate.maximumSectionCount));
        } else {
            NSLog(@"Failed to find template %@", template);
            reject(@"template_not_found", @"Template not found in store", nil);
        }
    }
}

RCT_EXPORT_METHOD(updateMapTemplateConfig:(NSString *)templateId config:(NSDictionary*)config) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [self applyConfigForMapTemplate:mapTemplate templateId:templateId config:config];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(showPanningInterface:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate showPanningInterfaceAnimated:animated];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(dismissPanningInterface:(NSString *)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate dismissPanningInterfaceAnimated:animated];
        } else {
            NSLog(@"Failed to find template %@", template);
        }
    }
}

RCT_EXPORT_METHOD(enableNowPlaying:(BOOL)enable) {
    if (@available(iOS 14, *)) {
        if (enable && !isNowPlayingActive) {
            [CPNowPlayingTemplate.sharedTemplate addObserver:self];
        } else if (!enable && isNowPlayingActive) {
            [CPNowPlayingTemplate.sharedTemplate removeObserver:self];
        }
    }
}

RCT_EXPORT_METHOD(hideTripPreviews:(NSString*)templateId) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate hideTripPreviews];
        }
    }
}

RCT_EXPORT_METHOD(showTripPreviews:(NSString*)templateId tripIds:(NSArray*)tripIds tripConfiguration:(NSDictionary*)tripConfiguration) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        NSMutableArray *trips = [[NSMutableArray alloc] init];
        
        for (NSString *tripId in tripIds) {
            CPTrip *trip = [[RNCPStore sharedManager] findTripById:tripId];
            if (trip) {
                [trips addObject:trip];
            }
        }
        
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate showTripPreviews:trips textConfiguration:[self parseTripPreviewTextConfiguration:tripConfiguration]];
        }
    }
}

RCT_EXPORT_METHOD(showRouteChoicesPreviewForTrip:(NSString*)templateId tripId:(NSString*)tripId tripConfiguration:(NSDictionary*)tripConfiguration) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        CPTrip *trip = [[RNCPStore sharedManager] findTripById:tripId];
        
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate showRouteChoicesPreviewForTrip:trip textConfiguration:[self parseTripPreviewTextConfiguration:tripConfiguration]];
        }
    }
}

RCT_EXPORT_METHOD(presentNavigationAlert:(NSString*)templateId json:(NSDictionary*)json animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate presentNavigationAlert:[self parseNavigationAlert:json templateId:templateId] animated:animated];
        }
    }
}

RCT_EXPORT_METHOD(dismissNavigationAlert:(NSString*)templateId animated:(BOOL)animated) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            [mapTemplate dismissNavigationAlertAnimated:YES completion:^(BOOL completion) {
                [self sendTemplateEventWithName:template name:@"didDismissNavigationAlert"];
            }];
        }
    }
}

RCT_EXPORT_METHOD(activateVoiceControlState:(NSString*)templateId identifier:(NSString*)identifier) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPVoiceControlTemplate *voiceTemplate = (CPVoiceControlTemplate*) template;
            [voiceTemplate activateVoiceControlStateWithIdentifier:identifier];
        }
    }
}

RCT_EXPORT_METHOD(reactToUpdatedSearchText:(NSArray *)items) {
    if (@available(iOS 12.0, *)) {
        NSArray *sectionsItems = [self parseListItems:items startIndex:0 templateId:nil];
        
        if (self.searchResultBlock) {
            self.searchResultBlock(sectionsItems);
            self.searchResultBlock = nil;
        }
    }
}

RCT_EXPORT_METHOD(reactToSelectedResult:(BOOL)status) {
    if (self.selectedResultBlock) {
        self.selectedResultBlock();
        self.selectedResultBlock = nil;
    }
}

RCT_EXPORT_METHOD(updateMapTemplateMapButtons:(NSString*) templateId mapButtons:(NSArray*) mapButtonConfig) {
    if (@available(iOS 12.0, *)) {
        CPTemplate *template = [[RNCPStore sharedManager] findTemplateById:templateId];
        if (template) {
            CPMapTemplate *mapTemplate = (CPMapTemplate*) template;
            NSArray *mapButtons = [RCTConvert NSArray:mapButtonConfig];
            NSMutableArray *result = [NSMutableArray array];
            for (NSDictionary *mapButton in mapButtons) {
                NSString *_id = [mapButton objectForKey:@"id"];
                [result addObject:[RCTConvert CPMapButton:mapButton withHandler:^(CPMapButton * _Nonnull mapButton) {
                    [self sendTemplateEventWithName:mapTemplate name:@"mapButtonPressed" json:@{ @"id": _id }];
                }]];
            }
            [mapTemplate setMapButtons:result];
        }
    }
}

# pragma parsers

- (void) applyConfigForMapTemplate:(CPMapTemplate*)mapTemplate templateId:(NSString*)templateId config:(NSDictionary*)config API_AVAILABLE(ios(12.0)) {
    RNCPStore *store = [RNCPStore sharedManager];

    if ([config objectForKey:@"guidanceBackgroundColor"]) {
        [mapTemplate setGuidanceBackgroundColor:[RCTConvert UIColor:config[@"guidanceBackgroundColor"]]];
    } else if (@available(iOS 14, *)) {
      [mapTemplate setGuidanceBackgroundColor:UIColor.systemGray5Color];
    }
    
    if ([config objectForKey:@"tripEstimateStyle"]) {
        [mapTemplate setTripEstimateStyle:[RCTConvert CPTripEstimateStyle:config[@"tripEstimateStyle"]]];
    }
    else {
      [mapTemplate setTripEstimateStyle:CPTripEstimateStyleDark];
    }

    if ([config objectForKey:@"leadingNavigationBarButtons"]){
        NSArray *leadingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"leadingNavigationBarButtons"]] templateId:templateId];
        [mapTemplate setLeadingNavigationBarButtons:leadingNavigationBarButtons];
    }
  
    if ([config objectForKey:@"trailingNavigationBarButtons"]){
        NSArray *trailingNavigationBarButtons = [self parseBarButtons:[RCTConvert NSArray:config[@"trailingNavigationBarButtons"]] templateId:templateId];
        [mapTemplate setTrailingNavigationBarButtons:trailingNavigationBarButtons];
    }

    if ([config objectForKey:@"mapButtons"]) {
        NSArray *mapButtons = [RCTConvert NSArray:config[@"mapButtons"]];
        NSMutableArray *result = [NSMutableArray array];
        for (NSDictionary *mapButton in mapButtons) {
            NSString *_id = [mapButton objectForKey:@"id"];
            [result addObject:[RCTConvert CPMapButton:mapButton withHandler:^(CPMapButton * _Nonnull mapButton) {
                [self sendTemplateEventWithName:mapTemplate name:@"mapButtonPressed" json:@{ @"id": _id }];
            }]];
        }
        [mapTemplate setMapButtons:result];
    }

    if ([config objectForKey:@"automaticallyHidesNavigationBar"]) {
        [mapTemplate setAutomaticallyHidesNavigationBar:[RCTConvert BOOL:config[@"automaticallyHidesNavigationBar"]]];
    }

    if ([config objectForKey:@"hidesButtonsWithNavigationBar"]) {
        [mapTemplate setHidesButtonsWithNavigationBar:[RCTConvert BOOL:config[@"hidesButtonsWithNavigationBar"]]];
    }

    if ([config objectForKey:@"render"]) {
        RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:self.bridge moduleName:templateId initialProperties:@{}];
        [rootView setFrame:store.window.frame];
        [[store.window subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [store.window addSubview:rootView];
    }
}

- (NSArray<__kindof CPTemplate*>*) parseTemplatesFrom:(NSDictionary*)config API_AVAILABLE(ios(12.0)) {
    RNCPStore *store = [RNCPStore sharedManager];
    NSMutableArray<__kindof CPTemplate*> *templates = [NSMutableArray new];
    NSArray<NSDictionary*> *tpls = [RCTConvert NSDictionaryArray:config[@"templates"]];
    for (NSDictionary *tpl in tpls) {
        CPTemplate *templ = [store findTemplateById:tpl[@"id"]];
        // @todo UITabSystemItem
        [templates addObject:templ];
    }
    return templates;
}

- (NSArray<CPButton*>*) parseButtons:(NSArray*)buttons templateId:(NSString *)templateId  API_AVAILABLE(ios(14.0)) {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *button in buttons) {
        CPButton *_button;
        NSString *_id = [button objectForKey:@"id"];
        NSString *type = [button objectForKey:@"type"];
        if ([type isEqualToString:@"call"]) {
            _button = [[CPContactCallButton alloc] initWithHandler:^(__kindof CPButton * _Nonnull contactButton) {
                if (self->hasListeners) {
                    [self sendEventWithName:@"buttonPressed" body:@{@"id": _id, @"templateId":templateId}];
                }
            }];
        } else if ([type isEqualToString:@"message"]) {
            _button = [[CPContactMessageButton alloc] initWithPhoneOrEmail:[button objectForKey:@"phoneOrEmail"]];
        } else if ([type isEqualToString:@"directions"]) {
            _button = [[CPContactDirectionsButton alloc] initWithHandler:^(__kindof CPButton * _Nonnull contactButton) {
                if (self->hasListeners) {
                    [self sendEventWithName:@"buttonPressed" body:@{@"id": _id, @"templateId":templateId}];
                }
            }];
        }

        BOOL _disabled = [button objectForKey:@"disabled"];
        [_button setEnabled:!_disabled];

        NSString *_title = [button objectForKey:@"title"];
        [_button setTitle:_title];

        [result addObject:_button];
    }
    return result;
}

- (NSArray<CPBarButton*>*) parseBarButtons:(NSArray*)barButtons templateId:(NSString *)templateId API_AVAILABLE(ios(12.0)) {
    NSMutableArray *result = [NSMutableArray array];
    for (NSDictionary *barButton in barButtons) {
        CPBarButtonType _type;
        NSString *_id = [barButton objectForKey:@"id"];
        NSString *type = [barButton objectForKey:@"type"];
        if (type && [type isEqualToString:@"image"]) {
            _type = CPBarButtonTypeImage;
        } else {
            _type = CPBarButtonTypeText;
        }
        CPBarButton *_barButton = [[CPBarButton alloc] initWithType:_type handler:^(CPBarButton * _Nonnull barButton) {
            if (self->hasListeners) {
                [self sendEventWithName:@"barButtonPressed" body:@{@"id": _id, @"templateId":templateId}];
            }
        }];
        BOOL _disabled = [barButton objectForKey:@"disabled"];
        [_barButton setEnabled:!_disabled];

        if (_type == CPBarButtonTypeText) {
            NSString *_title = [barButton objectForKey:@"title"];
            [_barButton setTitle:_title];
        } else if (_type == CPBarButtonTypeImage) {
            UIImage *_image = [RCTConvert UIImage:[barButton objectForKey:@"image"]];
            [_barButton setImage:_image];
        }
        [result addObject:_barButton];
    }
    return result;
}

- (NSArray<CPListSection*>*)parseSections:(NSArray*)sections templateId:(NSString *)templateId API_AVAILABLE(ios(12.0)) {
    NSMutableArray *result = [NSMutableArray array];
    int index = 0;
    for (NSDictionary *section in sections) {
        NSArray *items = [section objectForKey:@"items"];
        NSString *_sectionIndexTitle = [section objectForKey:@"sectionIndexTitle"];
        NSString *_header = [section objectForKey:@"header"];
        NSArray *_items = [self parseListItems:items startIndex:index templateId:templateId];
        CPListSection *_section = [[CPListSection alloc] initWithItems:_items header:_header sectionIndexTitle:_sectionIndexTitle];
        [result addObject:_section];
        int count = (int) [items count];
        index = index + count;
    }
    return result;
}

- (void)parseSections:(NSArray*)sections
                templateId:(NSString *)templateId
               completion:(void (^)(NSArray<CPListSection*> *parsedSections))completion API_AVAILABLE(ios(12.0)) {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<CPListSection*> *parsedSections = [self parseSections:sections templateId:templateId];
        if (completion) {
            completion(parsedSections);
        }
    });
}


- (NSArray<CPListItem*>*)parseListItems:(NSArray*)items startIndex:(int)startIndex templateId:(NSString *)templateId API_AVAILABLE(ios(12.0)) {
    NSMutableArray *_items = [NSMutableArray array];
    int index = startIndex;
    UIImage *placeholder = [UIImage imageNamed: @"Placeholder"];
    for (NSDictionary *item in items) {
        NSString *_detailText = [RCTConvert NSString:item[@"detailText"]];
        NSString *_text = [RCTConvert NSString:item[@"text"]];
        UIImage *image = nil;
        NSArray *_rowItems = [item objectForKey:@"rowItems"];
        BOOL isPlaying = [RCTConvert BOOL:item[@"isPlaying"]];
        BOOL onlyText = [RCTConvert BOOL:item[@"onlyText"]];
        
        if(item[@"rowItems"] && templateId) {
            if (@available(iOS 14.0, *)) {
                
                NSMutableArray *loadedRowItems = [[NSMutableArray alloc] init];
                NSMutableArray *loadedRowItemsImages = [[NSMutableArray alloc] init];
                
                for (id rowItem in _rowItems) {
                    UIImage *image = nil;
                    if (rowItem[@"imgUrl"]) {
                        NSString *imgUrl = rowItem[@"imgUrl"];
                        NSURL *url = [NSURL URLWithString:imgUrl];
                        if (url) {
                            NSData *imageData = [NSData dataWithContentsOfURL:url];
                            if (imageData) {
                                UIImage *imageCopy = [[UIImage alloc] initWithData:imageData];
                                if (imageCopy) {
                                    image = imageCopy;
                                }
                            }
                        }
                        if (!image && placeholder) image = placeholder;
                        if ([rowItem[@"isArtist"] boolValue]) {
                            image = [self imageWithRoundedCornersSize:100 usingImage:image];
                        }
                        if (image) {
                            [loadedRowItems addObject:rowItem];
                            [loadedRowItemsImages addObject:image];
                        }
                    }
                }
                
                while ([loadedRowItemsImages count] < 9) {
                    if (placeholder) [loadedRowItemsImages addObject:placeholder];
                }
                
                CPListImageRowItem *_imageRowItem = [[CPListImageRowItem alloc] initWithText:_text images:loadedRowItemsImages];
                
                _imageRowItem.listImageRowHandler = ^(CPListImageRowItem *item, NSInteger index, dispatch_block_t completionBlock) {
                    NSMutableDictionary *bodyDictionary = [NSMutableDictionary dictionary];
                    
                    NSNumber *indexNumber = @(index);
                    
                    bodyDictionary[@"index"] = indexNumber;
                    
                    if (templateId) {
                        bodyDictionary[@"templateId"] = templateId;
                    }
                    
                    [self sendEventWithName:@"didSelectRowItem" body:bodyDictionary];
                    
                    if (completionBlock) {
                        completionBlock();
                    }
                };
                
                [_imageRowItem setUserInfo:@{ @"index": @(index) }];
                [_items addObject:_imageRowItem];
                index = index + 1;
                continue;
            }
        }
        
        if (item[@"imgUrl"]) {
            NSString *imgUrl = [RCTConvert NSString:item[@"imgUrl"]];
            if (imgUrl) {
                NSURL *url = [NSURL URLWithString:imgUrl];
                if (url) {
                    NSData *imageData = [NSData dataWithContentsOfURL:url];
                    if (imageData) {
                        UIImage *imageCopy = [[UIImage alloc] initWithData:imageData];
                        if (imageCopy) {
                            image = imageCopy;
                        }
                    }
                }
            }
        }
        
        NSDictionary *listItemsImagesNamesMapping = @{
            @"play-shuffle": @"PlayShuffleIcon"
        };
            
        if (item[@"imageName"]) {
            NSString *imageName = [RCTConvert NSString:item[@"imageName"]];
            if (imageName) {
                NSString *nativeImageName = listItemsImagesNamesMapping[imageName];
                if (nativeImageName) {
                    UIImage *imageCopy = [UIImage imageNamed:nativeImageName];
                    if (imageCopy) {
                        image = imageCopy;
                    }
                }
            }
        }
        
        if (!image && !onlyText && placeholder) image = placeholder;
        
        if ([item[@"isArtist"] boolValue]) {
            image = [self imageWithRoundedCornersSize:100 usingImage:image];
        }
        
        CPListItem *_item = [[CPListItem alloc] initWithText:_text detailText:_detailText image:image];
        if (@available(iOS 14, *)) {
            if (isPlaying) {
                [_item setPlayingIndicatorLocation:CPListItemPlayingIndicatorLocationTrailing];
                [_item setPlaying:isPlaying];
            }
            if ([item objectForKey:@"showsDisclosureIndicator"]) {
                BOOL showsDisclosureIndicator = [RCTConvert BOOL:[item objectForKey:@"showsDisclosureIndicator"]];
                if (showsDisclosureIndicator) {
                    [_item setAccessoryType:CPListItemAccessoryTypeDisclosureIndicator];
                }
            }
        }
        [_item setUserInfo:@{ @"index": @(index) }];
        [_items addObject:_item];
        index = index + 1;
    }
    return _items;
}

- (UIImage *)imageWithRoundedCornersSize:(float)cornerRadius usingImage:(UIImage *)original {
    CGSize imageSize = original.size;
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, imageSize.width, imageSize.height) cornerRadius:cornerRadius];
    [path addClip];
    [original drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedImage;
}


- (NSArray<CPInformationItem*>*)parseInformationItems:(NSArray*)items  API_AVAILABLE(ios(14.0)){
    NSMutableArray *_items = [NSMutableArray array];
    for (NSDictionary *item in items) {
        [_items addObject:[[CPInformationItem alloc] initWithTitle:item[@"title"] detail:item[@"detail"]]];
    }
    
    return _items;
}

- (NSArray<CPTextButton*>*)parseInformationActions:(NSArray*)actions templateId:(NSString *)templateId  API_AVAILABLE(ios(14.0)){
    NSMutableArray *_actions = [NSMutableArray array];
    for (NSDictionary *action in actions) {
        CPTextButton *_action = [[CPTextButton alloc] initWithTitle:action[@"title"] textStyle:CPTextButtonStyleNormal handler:^(__kindof CPTextButton * _Nonnull contactButton) {
            if (self->hasListeners) {
                [self sendEventWithName:@"actionButtonPressed" body:@{@"templateId":templateId, @"id": action[@"id"] }];
            }
        }];
        [_actions addObject:_action];
    }
    
    return _actions;
}

- (NSArray<CPGridButton*>*)parseGridButtons:(NSArray*)buttons templateId:(NSString*)templateId API_AVAILABLE(ios(12.0)) {
    NSMutableArray *result = [NSMutableArray array];
    int index = 0;
    for (NSDictionary *button in buttons) {
        NSString *_id = [button objectForKey:@"id"];
        NSArray<NSString*> *_titleVariants = [button objectForKey:@"titleVariants"];
        UIImage *_image = [RCTConvert UIImage:[button objectForKey:@"image"]];
        CPGridButton *_button = [[CPGridButton alloc] initWithTitleVariants:_titleVariants image:_image handler:^(CPGridButton * _Nonnull barButton) {
            if (self->hasListeners) {
                [self sendEventWithName:@"gridButtonPressed" body:@{@"id": _id, @"templateId":templateId, @"index": @(index) }];
            }
        }];
        BOOL _disabled = [button objectForKey:@"disabled"];
        [_button setEnabled:!_disabled];
        [result addObject:_button];
        index = index + 1;
    }
    return result;
}

- (CPTravelEstimates*)parseTravelEstimates: (NSDictionary*)json API_AVAILABLE(ios(12.0)) {
    NSString *units = [RCTConvert NSString:json[@"distanceUnits"]];
    double value = [RCTConvert double:json[@"distanceRemaining"]];

    NSUnit *unit = [NSUnitLength kilometers];
    if (units && [units isEqualToString: @"meters"]) {
        unit = [NSUnitLength meters];
    }
    else if (units && [units isEqualToString: @"miles"]) {
        unit = [NSUnitLength miles];
    }
    else if (units && [units isEqualToString: @"feet"]) {
        unit = [NSUnitLength feet];
    }
    else if (units && [units isEqualToString: @"yards"]) {
        unit = [NSUnitLength yards];
    }

    NSMeasurement *distance = [[NSMeasurement alloc] initWithDoubleValue:value unit:unit];
    double time = [RCTConvert double:json[@"timeRemaining"]];

    return [[CPTravelEstimates alloc] initWithDistanceRemaining:distance timeRemaining:time];
}

- (CPManeuver*)parseManeuver:(NSDictionary*)json API_AVAILABLE(ios(12.0)) {
    CPManeuver* maneuver = [[CPManeuver alloc] init];

    if ([json objectForKey:@"junctionImage"]) {
        UIImage *junctionImage = [RCTConvert UIImage:json[@"junctionImage"]];
        [maneuver setJunctionImage:[self imageWithTint:junctionImage andTintColor:[UIColor whiteColor]]];
    }

    if ([json objectForKey:@"initialTravelEstimates"]) {
        CPTravelEstimates* travelEstimates = [self parseTravelEstimates:json[@"initialTravelEstimates"]];
        [maneuver setInitialTravelEstimates:travelEstimates];
    }

    if ([json objectForKey:@"symbolImage"]) {
        UIImage *symbolImage = [RCTConvert UIImage:json[@"symbolImage"]];
      
        if ([json objectForKey:@"resizeSymbolImage"]) {
            NSString *resizeType = [RCTConvert NSString:json[@"resizeSymbolImage"]];
            if ([resizeType isEqualToString: @"primary"]) {
                symbolImage = [self imageWithSize:symbolImage convertToSize:CGSizeMake(100, 100)];
            }
            if ([resizeType isEqualToString: @"secondary"]) {
                symbolImage = [self imageWithSize:symbolImage convertToSize:CGSizeMake(50, 50)];
            }
        }

        BOOL shouldTint = [RCTConvert BOOL:json[@"tintSymbolImage"]];
        if ([json objectForKey:@"tintSymbolImage"]) {
            UIColor *tintColor = [RCTConvert UIColor:json[@"tintSymbolImage"]];
            UIImage *darkImage = symbolImage;
            UIImage *lightImage = [self imageWithTint:symbolImage andTintColor:tintColor];
            symbolImage = [self dynamicImageWithNormalImage:lightImage darkImage:darkImage];
        }


        [maneuver setSymbolImage:symbolImage];
    }

    if ([json objectForKey:@"instructionVariants"]) {
        [maneuver setInstructionVariants:[RCTConvert NSStringArray:json[@"instructionVariants"]]];
    }

    return maneuver;
}

- (CPTripPreviewTextConfiguration*)parseTripPreviewTextConfiguration:(NSDictionary*)json API_AVAILABLE(ios(12.0)) {
    return [[CPTripPreviewTextConfiguration alloc] initWithStartButtonTitle:[RCTConvert NSString:json[@"startButtonTitle"]] additionalRoutesButtonTitle:[RCTConvert NSString:json[@"additionalRoutesButtonTitle"]] overviewButtonTitle:[RCTConvert NSString:json[@"overviewButtonTitle"]]];
}

- (CPTrip*)parseTrip:(NSDictionary*)config API_AVAILABLE(ios(12.0)) {
    if ([config objectForKey:@"config"]) {
        config = [config objectForKey:@"config"];
    }
    MKMapItem *origin = [RCTConvert MKMapItem:config[@"origin"]];
    MKMapItem *destination = [RCTConvert MKMapItem:config[@"destination"]];
    NSMutableArray *routeChoices = [NSMutableArray array];
    if ([config objectForKey:@"routeChoices"]) {
        NSInteger index = 0;
        for (NSDictionary *routeChoice in [RCTConvert NSArray:config[@"routeChoices"]]) {
            CPRouteChoice *cpRouteChoice = [RCTConvert CPRouteChoice:routeChoice];
            NSMutableDictionary *userInfo = cpRouteChoice.userInfo;
            if (!userInfo) {
                userInfo = [[NSMutableDictionary alloc] init];
                cpRouteChoice.userInfo = userInfo;
            }
            [userInfo setValue:[NSNumber numberWithInteger:index] forKey:@"index"];
            [routeChoices addObject:cpRouteChoice];
            index++;
        }
    }
    return [[CPTrip alloc] initWithOrigin:origin destination:destination routeChoices:routeChoices];
}

- (CPNavigationAlert*)parseNavigationAlert:(NSDictionary*)json templateId:(NSString*)templateId API_AVAILABLE(ios(12.0)) {
    CPImageSet *imageSet;
    if ([json objectForKey:@"lightImage"] && [json objectForKey:@"darkImage"]) {
        imageSet = [[CPImageSet alloc] initWithLightContentImage:[RCTConvert UIImage:json[@"lightImage"]] darkContentImage:[RCTConvert UIImage:json[@"darkImage"]]];
    }
    CPAlertAction *secondaryAction = [json objectForKey:@"secondaryAction"] ? [self parseAlertAction:json[@"secondaryAction"] body:@{ @"templateId": templateId, @"secondary": @(YES) }] : nil;

    return [[CPNavigationAlert alloc] initWithTitleVariants:[RCTConvert NSStringArray:json[@"titleVariants"]] subtitleVariants:[RCTConvert NSStringArray:json[@"subtitleVariants"]] imageSet:imageSet primaryAction:[self parseAlertAction:json[@"primaryAction"] body:@{ @"templateId": templateId, @"primary": @(YES) }] secondaryAction:secondaryAction duration:[RCTConvert double:json[@"duration"]]];
}

- (CPAlertAction*)parseAlertAction:(NSDictionary*)json body:(NSDictionary*)body API_AVAILABLE(ios(12.0)) {
    return [[CPAlertAction alloc] initWithTitle:[RCTConvert NSString:json[@"title"]] style:(CPAlertActionStyle) [RCTConvert NSUInteger:json[@"style"]] handler:^(CPAlertAction * _Nonnull action) {
        if (self->hasListeners) {
            [self sendEventWithName:@"alertActionPressed" body:body];
        }
    }];
}

- (NSArray<CPVoiceControlState*>*)parseVoiceControlStates:(NSArray<NSDictionary*>*)items API_AVAILABLE(ios(12.0)) {
    NSMutableArray<CPVoiceControlState*>* res = [NSMutableArray array];
    for (NSDictionary *item in items) {
        [res addObject:[self parseVoiceControlState:item]];
    }
    return res;
}

- (CPVoiceControlState*)parseVoiceControlState:(NSDictionary*)json API_AVAILABLE(ios(12.0)) {
    return [[CPVoiceControlState alloc] initWithIdentifier:[RCTConvert NSString:json[@"identifier"]] titleVariants:[RCTConvert NSStringArray:json[@"titleVariants"]] image:[RCTConvert UIImage:json[@"image"]] repeats:[RCTConvert BOOL:json[@"repeats"]]];
}

- (NSString*)panDirectionToString:(CPPanDirection)panDirection API_AVAILABLE(ios(12.0)) {
    switch (panDirection) {
        case CPPanDirectionUp: return @"up";
        case CPPanDirectionRight: return @"right";
        case CPPanDirectionDown: return @"down";
        case CPPanDirectionLeft: return @"left";
        case CPPanDirectionNone: return @"none";
    }
}

- (NSDictionary*)navigationAlertToJson:(CPNavigationAlert*)navigationAlert dismissalContext:(CPNavigationAlertDismissalContext)dismissalContext API_AVAILABLE(ios(12.0)) {
    NSString *dismissalCtx = @"none";
    if (dismissalContext) {
        switch (dismissalContext) {
            case CPNavigationAlertDismissalContextTimeout:
                dismissalCtx = @"timeout";
                break;
            case CPNavigationAlertDismissalContextSystemDismissed:
                dismissalCtx = @"system";
                break;
            case CPNavigationAlertDismissalContextUserDismissed:
                dismissalCtx = @"user";
                break;
        }
    }

    return @{
        @"todo": @(YES),
        @"reason": dismissalCtx
    };
}
- (NSDictionary*)navigationAlertToJson:(CPNavigationAlert*)navigationAlert API_AVAILABLE(ios(12.0)) {
    return @{ @"todo": @(YES) };
    //    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
    //    return @{
    //                            };
}

- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString*)name API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:template name:name json:@{}];
}

- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString*)name json:(NSDictionary*)json API_AVAILABLE(ios(12.0)) {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] initWithDictionary:json];
    NSDictionary *userInfo = [template userInfo];
    [body setObject:[userInfo objectForKey:@"templateId"] forKey:@"templateId"];
    if (hasListeners) {
        [self sendEventWithName:name body:body];
    }
}


# pragma MapTemplate

- (void)mapTemplate:(CPMapTemplate *)mapTemplate selectedPreviewForTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice API_AVAILABLE(ios(12.0)) {
    NSDictionary *userInfo = trip.userInfo;
    NSString *tripId = [userInfo valueForKey:@"id"];

    NSDictionary *routeUserInfo = routeChoice.userInfo;
    NSString *routeIndex = [routeUserInfo valueForKey:@"index"];
    [self sendTemplateEventWithName:mapTemplate name:@"selectedPreviewForTrip" json:@{ @"tripId": tripId, @"routeIndex": routeIndex}];
}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate startedTrip:(CPTrip *)trip usingRouteChoice:(CPRouteChoice *)routeChoice API_AVAILABLE(ios(12.0)) {
    NSDictionary *userInfo = trip.userInfo;
    NSString *tripId = [userInfo valueForKey:@"id"];

    NSDictionary *routeUserInfo = routeChoice.userInfo;
    NSString *routeIndex = [routeUserInfo valueForKey:@"index"];

    [self sendTemplateEventWithName:mapTemplate name:@"startedTrip" json:@{ @"tripId": tripId, @"routeIndex": routeIndex}];
}

- (void)mapTemplateDidCancelNavigation:(CPMapTemplate *)mapTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didCancelNavigation"];
}

//- (BOOL)mapTemplate:(CPMapTemplate *)mapTemplate shouldShowNotificationForManeuver:(CPManeuver *)maneuver {
//    // @todo
//}
//- (BOOL)mapTemplate:(CPMapTemplate *)mapTemplate shouldUpdateNotificationForManeuver:(CPManeuver *)maneuver withTravelEstimates:(CPTravelEstimates *)travelEstimates {
//    // @todo
//}
//- (BOOL)mapTemplate:(CPMapTemplate *)mapTemplate shouldShowNotificationForNavigationAlert:(CPNavigationAlert *)navigationAlert {
//    // @todo
//}

- (void)mapTemplate:(CPMapTemplate *)mapTemplate willShowNavigationAlert:(CPNavigationAlert *)navigationAlert API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"willShowNavigationAlert" json:[self navigationAlertToJson:navigationAlert]];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate didShowNavigationAlert:(CPNavigationAlert *)navigationAlert API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didShowNavigationAlert" json:[self navigationAlertToJson:navigationAlert]];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate willDismissNavigationAlert:(CPNavigationAlert *)navigationAlert dismissalContext:(CPNavigationAlertDismissalContext)dismissalContext API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"willDismissNavigationAlert" json:[self navigationAlertToJson:navigationAlert dismissalContext:dismissalContext]];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate didDismissNavigationAlert:(CPNavigationAlert *)navigationAlert dismissalContext:(CPNavigationAlertDismissalContext)dismissalContext API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didDismissNavigationAlert" json:[self navigationAlertToJson:navigationAlert dismissalContext:dismissalContext]];
}

- (void)mapTemplateDidShowPanningInterface:(CPMapTemplate *)mapTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didShowPanningInterface"];
}
- (void)mapTemplateWillDismissPanningInterface:(CPMapTemplate *)mapTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"willDismissPanningInterface"];
}
- (void)mapTemplateDidDismissPanningInterface:(CPMapTemplate *)mapTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didDismissPanningInterface"];
}
- (void)mapTemplateDidBeginPanGesture:(CPMapTemplate *)mapTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didBeginPanGesture"];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate panWithDirection:(CPPanDirection)direction API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"panWithDirection" json:@{ @"direction": [self panDirectionToString:direction] }];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate panBeganWithDirection:(CPPanDirection)direction API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"panBeganWithDirection" json:@{ @"direction": [self panDirectionToString:direction] }];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate panEndedWithDirection:(CPPanDirection)direction API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"panEndedWithDirection" json:@{ @"direction": [self panDirectionToString:direction] }];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate didEndPanGestureWithVelocity:(CGPoint)velocity API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didEndPanGestureWithVelocity" json:@{ @"velocity": @{ @"x": @(velocity.x), @"y": @(velocity.y) }}];
}
- (void)mapTemplate:(CPMapTemplate *)mapTemplate didUpdatePanGestureWithTranslation:(CGPoint)translation velocity:(CGPoint)velocity API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:mapTemplate name:@"didUpdatePanGestureWithTranslation" json:@{ @"translation": @{ @"x": @(translation.x), @"y": @(translation.y) }, @"velocity": @{ @"x": @(velocity.x), @"y": @(velocity.y) }}];
}



# pragma SearchTemplate

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate selectedResult:(CPListItem *)item completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(12.0)) {
    NSNumber* index = [item.userInfo objectForKey:@"index"];
    [self sendTemplateEventWithName:searchTemplate name:@"selectedResult" json:@{ @"index": index }];
    self.selectedResultBlock = completionHandler;
}

- (void)searchTemplateSearchButtonPressed:(CPSearchTemplate *)searchTemplate API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:searchTemplate name:@"searchButtonPressed"];
}

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate updatedSearchText:(NSString *)searchText completionHandler:(void (^)(NSArray<CPListItem *> * _Nonnull))completionHandler API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:searchTemplate name:@"updatedSearchText" json:@{ @"searchText": searchText }];
    self.searchResultBlock = completionHandler;
}

# pragma ListTemplate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(12.0)) {
    if (listTemplate && item) {
        NSNumber* index = [item.userInfo objectForKey:@"index"];
        [self sendTemplateEventWithName:listTemplate name:@"didSelectListItem" json:@{ @"index": index }];
        self.selectedResultBlock = completionHandler;
    }
}

# pragma TabBarTemplate

- (void)tabBarTemplate:(CPTabBarTemplate *)tabBarTemplate didSelectTemplate:(__kindof CPTemplate *)selectedTemplate  API_AVAILABLE(ios(14.0)){
    if (tabBarTemplate && selectedTemplate) {
        NSString* selectedTemplateId = [[selectedTemplate userInfo] objectForKey:@"templateId"];
        [self sendTemplateEventWithName:tabBarTemplate name:@"didSelectTemplate" json:@{@"selectedTemplateId":selectedTemplateId}];
    }
}

# pragma PointOfInterest
-(void)pointOfInterestTemplate:(CPPointOfInterestTemplate *)pointOfInterestTemplate didChangeMapRegion:(MKCoordinateRegion)region  API_AVAILABLE(ios(14.0)){
    // noop
}

-(void)pointOfInterestTemplate:(CPPointOfInterestTemplate *)pointOfInterestTemplate didSelectPointOfInterest:(CPPointOfInterest *)pointOfInterest  API_AVAILABLE(ios(14.0)){
    [self sendTemplateEventWithName:pointOfInterestTemplate name:@"didSelectPointOfInterest" json:[pointOfInterest userInfo]];
}

# pragma InterfaceController

- (void)templateDidAppear:(CPTemplate *)aTemplate animated:(BOOL)animated API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:aTemplate name:@"didAppear" json:@{ @"animated": @(animated) }];
}

- (void)templateDidDisappear:(CPTemplate *)aTemplate animated:(BOOL)animated API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:aTemplate name:@"didDisappear" json:@{ @"animated": @(animated) }];
}

- (void)templateWillAppear:(CPTemplate *)aTemplate animated:(BOOL)animated API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:aTemplate name:@"willAppear" json:@{ @"animated": @(animated) }];
}

- (void)templateWillDisappear:(CPTemplate *)aTemplate animated:(BOOL)animated API_AVAILABLE(ios(12.0)) {
    [self sendTemplateEventWithName:aTemplate name:@"willDisappear" json:@{ @"animated": @(animated) }];
}

# pragma NowPlaying

- (void)nowPlayingTemplateUpNextButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate API_AVAILABLE(ios(14.0)){
    if (nowPlayingTemplate) {
        [self sendTemplateEventWithName:nowPlayingTemplate name:@"upNextButtonPressed"];
    }
}

- (void)nowPlayingTemplateAlbumArtistButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate API_AVAILABLE(ios(14.0)){
    if (nowPlayingTemplate) {
        [self sendTemplateEventWithName:nowPlayingTemplate name:@"albumArtistButtonPressed"];
    }
}

@end
