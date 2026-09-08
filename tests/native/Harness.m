#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#define RCT_EXPORT_METHOD(method) - (void)method
#define RCTLogWarn(...) NSLog(__VA_ARGS__)
#define CHECK(test) do { if (!(test)) { NSLog(@"FAIL: %s", #test); exit(1); } } while (0)
@interface UIImage : NSObject @end
@implementation UIImage @end
@interface CPTemplate : NSObject @end
@implementation CPTemplate @end
@interface CPInterfaceController : NSObject
@property NSMutableArray *templates;
@property BOOL delayed, failPop;
@property(copy) void (^pending)(void);
@property NSUInteger maximumObserved;
- (void)pushTemplate:(CPTemplate*)item animated:(BOOL)animated completion:(void(^)(BOOL,NSError*))completion;
- (void)popTemplateAnimated:(BOOL)animated completion:(void(^)(BOOL,NSError*))completion;
@end
@implementation CPInterfaceController
- (void)pushTemplate:(CPTemplate*)item animated:(BOOL)animated completion:(void(^)(BOOL,NSError*))completion {
 CHECK(self.templates.count < 5); [self.templates addObject:item];
 self.maximumObserved=MAX(self.maximumObserved,self.templates.count);
 if (self.delayed) self.pending=^{ completion(YES,nil); }; else completion(YES,nil);
}
- (void)popTemplateAnimated:(BOOL)animated completion:(void(^)(BOOL,NSError*))completion {
 void(^work)(void)=^{ if (!self.failPop) [self.templates removeLastObject]; completion(!self.failPop,nil); };
 if (self.delayed) self.pending=work; else work();
}
@end
@interface RNCPStore : NSObject
@property CPInterfaceController *interfaceController;
@property BOOL connected;
@property NSMutableDictionary *items;
+ (instancetype)sharedManager;
- (id)findTemplateById:(NSString*)key;
- (BOOL)isConnected;
@end
@implementation RNCPStore
+ (instancetype)sharedManager { static RNCPStore *s; static dispatch_once_t once; dispatch_once(&once,^{s=[RNCPStore new];s.items=[NSMutableDictionary new];}); return s; }
- (id)findTemplateById:(NSString*)key {return self.items[key];}
- (BOOL)isConnected {return self.connected;}
@end
@interface CPListItem : NSObject
@property(nonatomic) UIImage *image;
@end
@implementation CPListItem
- (void)setImage:(UIImage*)image {CHECK(NSThread.isMainThread);_image=image;}
@end
@interface CPListImageRowItem : NSObject
@property NSArray *gridImages;
- (void)updateImages:(NSArray*)images;
@end
@implementation CPListImageRowItem
- (void)updateImages:(NSArray*)images {CHECK(NSThread.isMainThread);self.gridImages=images;}
@end
@interface RCTImageLoader : NSObject
- (void)loadImageWithURLRequest:(NSURLRequest*)request callback:(void(^)(NSError*,UIImage*))callback;
@end
@implementation RCTImageLoader
- (void)loadImageWithURLRequest:(NSURLRequest*)request callback:(void(^)(NSError*,UIImage*))callback {
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{callback(nil,[UIImage new]);});
}
@end
@interface RNCarPlay : NSObject {
 @public NSCache *_imageCache; BOOL _templatePushInFlight; NSUInteger _navigationGeneration;
}
@end
@implementation RNCarPlay
- (instancetype)init {if ((self=[super init])) _imageCache=[NSCache new];return self;}
- (RCTImageLoader*)rncpImageLoader {return [RCTImageLoader new];}
/* ACTUAL_METHODS */
@end
int main(void) { @autoreleasepool {
 RNCPStore *store=[RNCPStore sharedManager]; store.connected=YES;
 CPInterfaceController *controller=[CPInterfaceController new]; store.interfaceController=controller;
 controller.templates=[NSMutableArray arrayWithObject:[CPTemplate new]];
 RNCarPlay *cp=[RNCarPlay new];
 for (int i=0;i<30;i++) {NSString *key=[NSString stringWithFormat:@"%d",i];store.items[key]=[CPTemplate new];[cp pushTemplate:key animated:NO];}
 CHECK(controller.templates.count==5); CHECK(controller.maximumObserved==5);
 CHECK(controller.templates.lastObject==store.items[@"29"]);
 for (int i=30;i<34;i++) store.items[[NSString stringWithFormat:@"%d",i]]=[CPTemplate new];
 controller.delayed=YES;
 [cp pushTemplate:@"30" animated:NO]; // pop in flight
 [cp pushTemplate:@"31" animated:NO]; CHECK(controller.templates.count==5);
 void(^pending)(void)=controller.pending;controller.pending=nil;pending();
 CHECK(controller.templates.lastObject==store.items[@"30"]);
 pending=controller.pending;controller.pending=nil;pending();
 controller.delayed=NO;controller.failPop=YES;
 [cp pushTemplate:@"31" animated:NO]; CHECK(!cp->_templatePushInFlight);CHECK(controller.templates.lastObject==store.items[@"30"]);
 controller.failPop=NO; controller.delayed=YES;
 [cp pushTemplate:@"31" animated:NO];
 cp->_navigationGeneration++;cp->_templatePushInFlight=NO;store.connected=NO;
 pending=controller.pending;controller.pending=nil;pending();
 CHECK(controller.templates.lastObject!=store.items[@"31"]);
 store.connected=YES;controller.delayed=NO;
 [cp pushTemplate:@"32" animated:NO]; CHECK(controller.templates.lastObject==store.items[@"32"]);
 CPListItem *item=[CPListItem new];CPListImageRowItem *row=[CPListImageRowItem new];row.gridImages=@[[UIImage new]];
 UIImage *old=row.gridImages[0];
 [cp updateItemImageWithURL:item imgUrl:@"https://example.test/cover" placeholderImage:nil];
 [cp updateListRowItemImageWithURL:row imgUrl:@"https://example.test/row" index:0 placeholderImage:nil];
 NSDate *end=[NSDate dateWithTimeIntervalSinceNow:5];
 while ((!item.image || row.gridImages[0]==old) && [end timeIntervalSinceNow]>0) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
 CHECK(item.image);CHECK(row.gridImages[0]!=old);
 NSLog(@"PASS: 30 navigation levels, rapid taps, failed pop, disconnect/reconnect, background cover and row-image completion");
 return 0;
}}
