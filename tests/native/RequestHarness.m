#import <Foundation/Foundation.h>
#define RCT_EXPORT_METHOD(method) - (void)method
#define CHECK(test) do { if (!(test)) { NSLog(@"FAIL: %s", #test); exit(1); } } while (0)
typedef void(^SearchResultUpdateBlock)(NSArray *);
typedef void(^SelectedResultBlock)(void);
@interface CPTemplate : NSObject
@property NSDictionary *userInfo;
@end
@implementation CPTemplate @end
@interface CPSearchTemplate : CPTemplate @end
@implementation CPSearchTemplate @end
@interface CPListItem : NSObject
@property id userInfo;
@end
@implementation CPListItem @end
@interface CPListSection : NSObject
@property NSArray *items;
@end
@implementation CPListSection @end
@interface CPListTemplate : CPTemplate
@property NSArray<CPListSection *> *sections;
@end
@implementation CPListTemplate @end
@interface CPInterfaceController : NSObject
@property NSArray *templates;
@property CPTemplate *presentedTemplate;
@end
@implementation CPInterfaceController @end
@interface RNCPStore : NSObject
@property NSMutableDictionary *items;
@property CPInterfaceController *interfaceController;
+ (instancetype)sharedManager;
- (void)removeTemplate:(NSString *)templateId;
@end
@implementation RNCPStore
+ (instancetype)sharedManager { static RNCPStore *store; if (!store) { store=[RNCPStore new]; store.items=[NSMutableDictionary new]; store.interfaceController=[CPInterfaceController new]; } return store; }
- (void)removeTemplate:(NSString *)templateId { [self.items removeObjectForKey:templateId]; }
@end
@interface RNCarPlay : NSObject {
 @public BOOL hasListeners;
 NSUInteger _requestSequence;
 NSMutableDictionary *_searchRequests, *_selectionRequests;
 NSMutableSet *_searchTemplateIds;
}
@property(copy) SearchResultUpdateBlock searchResultBlock;
@property(copy) SelectedResultBlock selectedResultBlock;
@property NSMutableArray<NSDictionary *> *events;
@end
@implementation RNCarPlay
- (instancetype)init { if ((self=[super init])) { hasListeners=YES; _searchRequests=[NSMutableDictionary new]; _selectionRequests=[NSMutableDictionary new]; _searchTemplateIds=[NSMutableSet new]; self.events=[NSMutableArray new]; } return self; }
- (NSArray *)parseListItems:(NSArray *)items startIndex:(int)index templateId:(NSString *)templateId { return items; }
- (void)sendEventWithName:(NSString *)name body:(NSDictionary *)body { [self.events addObject:@{ @"name":name, @"body":body }]; }
- (void)sendTemplateEventWithName:(CPTemplate *)template name:(NSString *)name json:(NSDictionary *)json { NSMutableDictionary *body=[json mutableCopy]; body[@"templateId"]=template.userInfo[@"templateId"]; [self sendEventWithName:name body:body]; }
/* ACTUAL_METHODS */
@end
static CPSearchTemplate *search(NSString *key) { CPSearchTemplate *t=[CPSearchTemplate new]; t.userInfo=@{@"templateId":key}; return t; }
int main(void) { @autoreleasepool {
 RNCarPlay *cp=[RNCarPlay new]; CPSearchTemplate *a=search(@"a"), *b=search(@"b");
 __block int oldCount=0, newCount=0; __block NSArray *newRows=nil;
 [cp searchTemplate:a updatedSearchText:@"old" completionHandler:^(NSArray *rows){ oldCount++; CHECK(rows.count==0); }];
 NSString *oldId=cp.events.lastObject[@"body"][@"requestId"];
 [cp searchTemplate:a updatedSearchText:@"new" completionHandler:^(NSArray *rows){ newCount++; newRows=rows; }];
 NSString *newId=cp.events.lastObject[@"body"][@"requestId"];
 CHECK(oldCount==1); CHECK(![oldId isEqual:newId]);
 [cp reactToUpdatedSearchTextForRequest:@[@"stale"] templateId:@"a" requestId:oldId];
 [cp reactToUpdatedSearchTextForRequest:@[@"wrong owner"] templateId:@"b" requestId:newId]; CHECK(newCount==0);
 [cp reactToUpdatedSearchTextForRequest:@[@"new"] templateId:@"a" requestId:newId]; CHECK(newCount==1); CHECK([newRows[0] isEqual:@"new"]);
 [cp reactToUpdatedSearchTextForRequest:@[] templateId:@"a" requestId:newId]; CHECK(newCount==1);
 // Two templates retain independent native completion ownership.
 __block int first=0, second=0;
 [cp searchTemplate:a updatedSearchText:@"a" completionHandler:^(NSArray *rows){first++;}]; NSString *firstId=cp.events.lastObject[@"body"][@"requestId"];
 [cp searchTemplate:b updatedSearchText:@"b" completionHandler:^(NSArray *rows){second++;}]; NSString *secondId=cp.events.lastObject[@"body"][@"requestId"];
 [cp reactToUpdatedSearchTextForRequest:@[] templateId:@"a" requestId:firstId]; CHECK(first==1 && second==0);
 [cp reactToUpdatedSearchTextForRequest:@[] templateId:@"b" requestId:secondId]; CHECK(second==1);
 // Search/list selection tokens do not share a mutable completion slot.
 CPListItem *item=[CPListItem new]; item.userInfo=@{@"index":@0}; CPListTemplate *list=[CPListTemplate new]; list.userInfo=@{@"templateId":@"list"};
 __block int searchSelected=0, listSelected=0;
 [cp searchTemplate:a selectedResult:item completionHandler:^{searchSelected++;}]; NSString *searchId=cp.events.lastObject[@"body"][@"requestId"];
 [cp listTemplate:list didSelectListItem:item completionHandler:^{listSelected++;}]; NSString *listId=cp.events.lastObject[@"body"][@"requestId"];
 [cp reactToSelectedResultForRequest:@"a" requestId:searchId]; CHECK(searchSelected==1 && listSelected==0);
 [cp reactToSelectedResultForRequest:@"a" requestId:listId]; CHECK(listSelected==0);
 [cp cancelRequestsForTemplate:nil]; CHECK(listSelected==1);
 [cp reactToSelectedResultForRequest:@"list" requestId:listId]; CHECK(listSelected==1);
 // Hidden stack entries survive; popped searches are removed and signal JS.
 RNCPStore *store=[RNCPStore sharedManager]; store.items[@"a"]=a; [cp->_searchTemplateIds addObject:@"a"];
 store.interfaceController.templates=@[a]; [cp templateDidDisappear:a animated:NO]; CHECK(store.items[@"a"]==a);
 store.interfaceController.templates=@[]; [cp templateDidDisappear:a animated:NO]; CHECK(!store.items[@"a"]); CHECK([cp.events.lastObject[@"name"] isEqual:@"templateRemoved"]);
 CHECK(cp->_searchRequests.count==0 && cp->_selectionRequests.count==0);
 NSLog(@"PASS: request ownership, supersession, wrong owner, duplicate reply, independent templates, search/list selections, cancellation and search removal");
 return 0;
} }
