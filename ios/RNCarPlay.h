#import <Foundation/Foundation.h>
#import <CarPlay/CarPlay.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "RCTConvert+RNCarPlay.h"
#import "RNCPStore.h"

API_AVAILABLE(ios(12.0))
typedef void (^SearchResultUpdateBlock)(NSArray<CPListItem *> *_Nonnull);
typedef void (^SelectedResultBlock)(void);

API_AVAILABLE(ios(12.0))
@interface RNCarPlay : RCTEventEmitter <RCTBridgeModule, CPInterfaceControllerDelegate, CPSearchTemplateDelegate, CPListTemplateDelegate, CPMapTemplateDelegate, CPTabBarTemplateDelegate, CPPointOfInterestTemplateDelegate, CPNowPlayingTemplateObserver>
{
    CPInterfaceController *interfaceController;
    CPWindow *window;
    SearchResultUpdateBlock searchResultBlock;
    SelectedResultBlock selectedResultBlock;
    BOOL isNowPlayingActive;
}

@property(nonatomic, retain) CPInterfaceController * _Nonnull interfaceController;
@property(nonatomic, retain) CPWindow * _Nonnull window;
@property(nonatomic, copy) SearchResultUpdateBlock _Nullable searchResultBlock;
@property(nonatomic, copy) SelectedResultBlock _Nullable selectedResultBlock;
@property(nonatomic) BOOL isNowPlayingActive;
@property(nullable, nonatomic, copy) void (^listImageRowHandler)(CPListImageRowItem * _Nonnull item, NSInteger index, dispatch_block_t _Nonnull completionBlock) API_AVAILABLE(ios(14.0));

+ (void)connectWithInterfaceController:(CPInterfaceController *_Nonnull)interfaceController window:(CPWindow *_Nonnull)window;
+ (void)disconnect;

@end
