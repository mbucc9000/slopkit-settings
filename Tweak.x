// slopkit Settings: takes the slopkit tweaks' own rows off the main Settings page, so they only
// appear under Settings > slopkit.
//
// PreferenceLoader builds the main list by calling libprefs'
// -[PSListController specifiersFromEntry:sourcePreferenceLoaderBundlePath:title:] once per entry
// plist, from PrefsListController, and skips any entry that returns nil. Returning nil there for
// our tweaks' plists hides them; the slopkit pane calls the same method from its own controller,
// so it still gets the real rows. Nothing is hidden when "Also Show in Settings" is on, when the
// slopkit row itself is missing, or when libprefs isn't there.

#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import "SKShared.h"

@interface PSListController : UIViewController
@end

static NSSet *gHidden;   // full paths of the entry plists that live under slopkit

%group SKHide
%hook PSListController

- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourcePath
                           title:(NSString *)title {
    Class root = objc_getClass("PrefsListController");
    if (root && [self isKindOfClass:root] && sourcePath && title) {
        NSString *plist = [[sourcePath stringByAppendingPathComponent:title] stringByAppendingPathExtension:@"plist"];
        if ([gHidden containsObject:plist]) {
            return nil;
        }
    }
    return %orig;
}

%end
%end

%ctor {
    @autoreleasepool {
        if (SKAlsoInSettings()) {
            SKLog(@"Also Show in Settings is on; main list left alone");
            return;
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:SK_OWN_ENTRY]) {
            SKLog(@"slopkit row missing; main list left alone");
            return;
        }
        NSDictionary *entries = SKEntryPlists();
        if ([entries count] == 0) {
            return;
        }
        dlopen("/usr/lib/libprefs.dylib", RTLD_LAZY);
        Class cls = objc_getClass("PSListController");
        SEL sel = @selector(specifiersFromEntry:sourcePreferenceLoaderBundlePath:title:);
        if (!cls || !class_getInstanceMethod(cls, sel)) {
            SKLog(@"libprefs not found; main list left alone");
            return;
        }
        gHidden = [NSSet setWithArray:[entries allKeys]];
        %init(SKHide);
        SKLog(@"moved %lu rows under slopkit: %@", (unsigned long)[gHidden count],
              [[[entries allKeys] valueForKey:@"lastPathComponent"] componentsJoinedByString:@", "]);
    }
}
