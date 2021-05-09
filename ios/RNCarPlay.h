//
//  RNCarPlay.h
//  RNCarPlay
//
//  Created by Birkir Gudjonsson on 3/25/19.
//  Copyright © 2019 SOLID Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "RCTConvert+RNCarPlay.h"
#import "RNCPStore.h"

API_AVAILABLE(ios(12.0))
typedef void(^SearchResultUpdateBlock)(NSArray<CPListItem *> * _Nonnull);
typedef void(^SelectedResultBlock)(void);

API_AVAILABLE(ios(12.0))
@interface RNCarPlay : RCTEventEmitter<RCTBridgeModule, CPInterfaceControllerDelegate, CPSearchTemplateDelegate, CPListTemplateDelegate, CPMapTemplateDelegate,  CPTabBarTemplateDelegate, CPPointOfInterestTemplateDelegate> {
    CPInterfaceController *interfaceController;
    CPWindow *window;
    SearchResultUpdateBlock searchResultBlock;
    SelectedResultBlock selectedResultBlock;
}

@property (nonatomic, retain) CPInterfaceController *interfaceController API_AVAILABLE(ios(12.0));
@property (nonatomic, retain) CPWindow *window API_AVAILABLE(ios(12.0));
@property (nonatomic, copy) SearchResultUpdateBlock searchResultBlock API_AVAILABLE(ios(12.0));
@property (nonatomic, copy) SelectedResultBlock selectedResultBlock API_AVAILABLE(ios(12.0));

+ (void) connectWithInterfaceController:(CPInterfaceController*)interfaceController API_AVAILABLE(ios(12.0));
+ (void) disconnect;
- (NSArray<CPListSection*>*) parseSections:(NSArray*)sections API_AVAILABLE(ios(12.0));

@end
