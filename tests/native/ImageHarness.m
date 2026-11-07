#import <Foundation/Foundation.h>
#define RCT_EXPORT_METHOD(method) - (void)method
#define RCTLogWarn(...) NSLog(__VA_ARGS__)
#define CHECK(test) do { if (!(test)) { NSLog(@"FAIL: %s", #test); exit(1); } } while (0)
#define CPMaximumNumberOfGridImages 8
typedef NSInteger CPListItemAccessoryType;
enum { CPListItemAccessoryTypeNone, CPListItemAccessoryTypeDisclosureIndicator };

@interface UIImage : NSObject @end
@implementation UIImage @end
static UIImage *validImage;
static NSUInteger imageConversions;
@interface RCTConvert : NSObject
+ (UIImage *)UIImage:(id)json;
+ (NSInteger)NSInteger:(id)json;
+ (NSString *)NSString:(id)json;
+ (BOOL)BOOL:(id)json;
+ (CGFloat)CGFloat:(id)json;
@end
@implementation RCTConvert
+ (UIImage *)UIImage:(id)json {
    imageConversions++;
    if (!json || json == [NSNull null]) return nil;
    id uri = [json isKindOfClass:NSDictionary.class] ? json[@"uri"] : json;
    if ([uri isEqual:@"other-exception"]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"not an image input error" userInfo:nil];
    }
    if ([uri isEqual:@"file:///missing-cover.jpg"] || [uri isEqual:@"file:///corrupt-cover.jpg"]) {
        NSURL *imageURL = [NSURL URLWithString:uri];
        // Exact RN RCTImageFromLocalBundleAssetURL expression after local decode fails.
        (void)[[[NSBundle mainBundle] bundleURL]
            URLByAppendingPathComponent:[imageURL.host stringByAppendingString:imageURL.path]];
    }
    return validImage;
}
+ (NSInteger)NSInteger:(id)json { return [json integerValue]; }
+ (NSString *)NSString:(id)json { return json == [NSNull null] ? nil : json; }
+ (BOOL)BOOL:(id)json { return [json boolValue]; }
+ (CGFloat)CGFloat:(id)json { return [json doubleValue]; }
@end
@interface RCTConvert (RNCPImageTests)
+ (UIImage *)RNCPUIImage:(id)json;
@end
@implementation RCTConvert (RNCPImageTests)
/* IMAGE_CONVERTER */
@end

@interface CPTemplate : NSObject @end
@implementation CPTemplate @end
@interface CPListItem : NSObject
@property(nonatomic) UIImage *image, *accessoryImage;
@property NSString *text, *detailText;
@property BOOL playing;
@property CGFloat playbackProgress;
@property id userInfo;
- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detail image:(UIImage *)image accessoryImage:(UIImage *)accessory accessoryType:(CPListItemAccessoryType)type;
- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detail image:(UIImage *)image showsDisclosureIndicator:(BOOL)indicator;
@end
@implementation CPListItem
- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detail image:(UIImage *)image accessoryImage:(UIImage *)accessory accessoryType:(CPListItemAccessoryType)type {
    if ((self = [super init])) { self.text = text; self.detailText = detail; self.image = image; self.accessoryImage = accessory; }
    return self;
}
- (instancetype)initWithText:(NSString *)text detailText:(NSString *)detail image:(UIImage *)image showsDisclosureIndicator:(BOOL)indicator {
    return [self initWithText:text detailText:detail image:image accessoryImage:nil accessoryType:0];
}
- (void)setImage:(UIImage *)image { CHECK(NSThread.isMainThread); _image = image; }
- (void)setAccessoryImage:(UIImage *)image { CHECK(NSThread.isMainThread); _accessoryImage = image; }
@end
@interface CPListImageRowItem : CPListItem
@property NSArray *images;
- (instancetype)initWithText:(NSString *)text images:(NSArray *)images;
- (void)setListImageRowHandler:(void (^)(CPListImageRowItem *, NSInteger, dispatch_block_t))handler;
@end
@implementation CPListImageRowItem
- (instancetype)initWithText:(NSString *)text images:(NSArray *)images {
    if ((self = [super init])) { self.text = text; self.images = images; }
    return self;
}
- (void)setListImageRowHandler:(void (^)(CPListImageRowItem *, NSInteger, dispatch_block_t))handler {}
@end
@interface CPListSection : NSObject
@property NSArray *items;
@end
@implementation CPListSection @end
@interface CPListTemplate : CPTemplate
@property NSArray *sections;
@end
@implementation CPListTemplate @end
@interface RNCPStore : NSObject
@property NSMutableDictionary *templates;
+ (instancetype)sharedManager;
- (CPTemplate *)findTemplateById:(NSString *)key;
@end
@implementation RNCPStore
+ (instancetype)sharedManager {
    static RNCPStore *store; static dispatch_once_t once;
    dispatch_once(&once, ^{ store = [RNCPStore new]; store.templates = [NSMutableDictionary new]; });
    return store;
}
- (CPTemplate *)findTemplateById:(NSString *)key { return self.templates[key]; }
@end
@interface RNCarPlay : NSObject
@property NSUInteger remoteLoads;
@end
@implementation RNCarPlay
- (void)updateItemImageWithURL:(CPListItem *)item imgUrl:(NSString *)url placeholderImage:(UIImage *)placeholder {
    if (placeholder) item.image = placeholder;
    self.remoteLoads++;
}
- (void)updateListRowItemImageWithURL:(CPListImageRowItem *)item imgUrl:(NSString *)url index:(NSInteger)index placeholderImage:(UIImage *)placeholder {
    self.remoteLoads++;
}
- (void)loadImageAsync:(id)source completion:(void (^)(UIImage *))completion { self.remoteLoads++; completion(validImage); }
- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString *)name json:(NSDictionary *)json {}
/* ACTUAL_METHODS */
@end

int main(void) { @autoreleasepool {
    validImage = [UIImage new];
    NSDictionary *missing = @{@"uri": @"file:///missing-cover.jpg"};
    NSDictionary *corrupt = @{@"uri": @"file:///corrupt-cover.jpg"};
    CHECK([RCTConvert RNCPUIImage:missing] == nil);
    CHECK([RCTConvert RNCPUIImage:corrupt] == nil);
    NSUInteger before = imageConversions;
    CHECK([RCTConvert RNCPUIImage:nil] == nil);
    CHECK([RCTConvert RNCPUIImage:NSNull.null] == nil);
    CHECK(imageConversions == before);
    for (id source in @[@{@"uri": @"file:///valid-cover.jpg", @"scale": @2}, @"bundle-icon", @{@"uri": @"data:image/png;base64,example"}]) {
        CHECK([RCTConvert RNCPUIImage:source] == validImage);
    }
    BOOL rethrown = NO;
    @try { [RCTConvert RNCPUIImage:@"other-exception"]; }
    @catch (NSException *exception) { rethrown = [exception.name isEqual:NSInternalInconsistencyException]; }
    CHECK(rethrown);

    RNCarPlay *cp = [RNCarPlay new];
    CPListItem *item = [CPListItem new];
    UIImage *placeholder = [UIImage new];
    item.image = placeholder; item.accessoryImage = placeholder;
    CPListSection *section = [CPListSection new]; section.items = @[item];
    CPListTemplate *template = [CPListTemplate new]; template.sections = @[section];
    [RNCPStore sharedManager].templates[@"library"] = template;
    [cp updateListTemplateItem:@"library" config:@{
        @"sectionIndex": @0, @"itemIndex": @0, @"image": missing, @"accessoryImage": corrupt,
        @"text": @"Playlists", @"detailText": @"Still usable", @"isPlaying": @YES, @"playbackProgress": @0.5
    }];
    CHECK(item.image == placeholder); CHECK(item.accessoryImage == placeholder);
    CHECK([item.text isEqual:@"Playlists"]); CHECK([item.detailText isEqual:@"Still usable"]);
    CHECK(item.playing); CHECK(item.playbackProgress == 0.5);
    [cp updateListTemplateItem:@"library" config:@{@"sectionIndex": @0, @"itemIndex": @0, @"image": @"valid", @"accessoryImage": @"valid"}];
    CHECK(item.image == validImage); CHECK(item.accessoryImage == validImage);
    [cp updateListTemplateItem:@"library" config:@{@"sectionIndex": @0, @"itemIndex": @0, @"image": @{@"uri": @"https://example.test/cover"}}];
    CHECK(cp.remoteLoads == 1);
    [cp updateListTemplateItem:@"library" config:@{@"sectionIndex": @0, @"itemIndex": @0, @"imgUrl": @"https://example.test/cover", @"placeholderImage": missing}];
    CHECK(cp.remoteLoads == 2);

    NSArray *rows = [cp parseListItems:@[
        @{@"text": @"Local", @"image": missing},
        @{@"text": @"Remote", @"imgUrl": @"https://example.test/cover", @"placeholderImage": missing},
        @{@"text": @"Row", @"images": @[missing, @"valid", corrupt]}
    ] startIndex:0 templateId:@"library"];
    CHECK(rows.count == 3); CHECK([rows[0] image] == nil);
    CHECK([rows[0] userInfo][@"index"] != nil);
    CPListImageRowItem *row = rows[2];
    CHECK(row.images.count == 3); CHECK(row.images[1] == validImage);
    CHECK([row.images[0] isKindOfClass:UIImage.class]); CHECK([row.images[2] isKindOfClass:UIImage.class]);
    NSLog(@"PASS: missing/corrupt local images, valid/data/bundle images, placeholders, updates, remote route, initial rows and stable image-row indices");
    return 0;
} }
