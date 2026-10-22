// Shared by the Settings hook (Tweak.x) and the slopkit pane (slopkitprefs).
//
// A "slopkit tweak" is any installed package whose id starts with com.mbucc9000. (except this
// one). Its Settings rows are the PreferenceLoader entry plists its dpkg .list file owns, so
// nothing has to be rebuilt or registered: install a tweak and it shows up under slopkit.

#import <Foundation/Foundation.h>

#define SK_PACKAGE_PREFIX @"com.mbucc9000."
#define SK_SELF_PACKAGE   @"com.mbucc9000.slopkit"
#define SK_PREFS_PATH     @"/var/mobile/Library/Preferences/com.mbucc9000.slopkit.plist"
#define SK_PL_DIR         @"/Library/PreferenceLoader/Preferences"
#define SK_OWN_ENTRY      @"/Library/PreferenceLoader/Preferences/SlopKit.plist"
#define SK_DPKG_INFO      @"/var/lib/dpkg/info"
#define SK_DPKG_STATUS    @"/var/lib/dpkg/status"
#define SK_LOG_PATH       @"/var/mobile/SlopKit.log"
#define SK_LOG_MAX        (128 * 1024)

static inline void SKLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attrs = [fm attributesOfItemAtPath:SK_LOG_PATH error:NULL];
    if ([attrs fileSize] > SK_LOG_MAX) {
        [fm removeItemAtPath:SK_LOG_PATH error:NULL];
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *line = [NSString stringWithFormat:@"%@ [%@] %@\n", [df stringFromDate:[NSDate date]],
                      [[NSProcessInfo processInfo] processName], msg];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:SK_LOG_PATH];
    if (!fh) {
        [line writeToFile:SK_LOG_PATH atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        return;
    }
    [fh seekToEndOfFile];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

// "Also Show in Settings": leave the tweaks' own rows on the main Settings page too.
static inline BOOL SKAlsoInSettings(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:SK_PREFS_PATH];
    return [[prefs objectForKey:@"alsoInSettings"] boolValue];
}

static inline void SKSetAlsoInSettings(BOOL on) {
    NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:SK_PREFS_PATH] mutableCopy];
    if (!prefs) {
        prefs = [NSMutableDictionary dictionary];
    }
    [prefs setObject:[NSNumber numberWithBool:on] forKey:@"alsoInSettings"];
    [prefs writeToFile:SK_PREFS_PATH atomically:YES];
}

// PreferenceLoader entry plists installed by slopkit packages: full plist path -> package id.
static inline NSDictionary *SKEntryPlists(void) {
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SK_DPKG_INFO error:NULL];
    NSString *prefix = [SK_PL_DIR stringByAppendingString:@"/"];
    for (NSString *file in files) {
        if (![file hasPrefix:SK_PACKAGE_PREFIX] || ![file hasSuffix:@".list"]) {
            continue;
        }
        NSString *package = [file stringByDeletingPathExtension];
        if ([package isEqualToString:SK_SELF_PACKAGE]) {
            continue;
        }
        NSString *list = [NSString stringWithContentsOfFile:[SK_DPKG_INFO stringByAppendingPathComponent:file]
                                                   encoding:NSUTF8StringEncoding error:NULL];
        for (NSString *line in [list componentsSeparatedByString:@"\n"]) {
            if ([line hasPrefix:prefix] && [line hasSuffix:@".plist"] &&
                [[NSFileManager defaultManager] fileExistsAtPath:line]) {
                [out setObject:package forKey:line];
            }
        }
    }
    return out;
}

// Apps (Encore, Venn, …) keep their settings inside the app, so the pane leaves them out.
// A package counts as an app when it installs anything under /Applications.
static inline BOOL SKPackageIsApp(NSString *package) {
    NSString *list = [NSString stringWithContentsOfFile:[SK_DPKG_INFO stringByAppendingPathComponent:
                                                         [package stringByAppendingString:@".list"]]
                                               encoding:NSUTF8StringEncoding error:NULL];
    return [list rangeOfString:@"\n/Applications/"].location != NSNotFound || [list hasPrefix:@"/Applications/"];
}

// Installed slopkit packages from dpkg's status file: package id -> its control fields.
static inline NSDictionary *SKInstalledPackages(void) {
    NSMutableDictionary *out = [NSMutableDictionary dictionary];
    NSString *status = [NSString stringWithContentsOfFile:SK_DPKG_STATUS encoding:NSUTF8StringEncoding error:NULL];
    if (!status) {
        status = [NSString stringWithContentsOfFile:SK_DPKG_STATUS encoding:NSISOLatin1StringEncoding error:NULL];
    }
    NSString *needle = [@"Package: " stringByAppendingString:SK_PACKAGE_PREFIX];
    NSUInteger length = [status length];
    NSRange search = NSMakeRange(0, length);
    while (search.length > 0) {
        NSRange hit = [status rangeOfString:needle options:0 range:search];
        if (hit.location == NSNotFound) {
            break;
        }
        NSRange end = [status rangeOfString:@"\n\n" options:0
                                      range:NSMakeRange(hit.location, length - hit.location)];
        NSUInteger stop = (end.location == NSNotFound) ? length : end.location;
        search = NSMakeRange(stop, length - stop);
        if (hit.location > 0 && [status characterAtIndex:hit.location - 1] != '\n') {
            continue;
        }
        NSString *para = [status substringWithRange:NSMakeRange(hit.location, stop - hit.location)];
        NSMutableDictionary *fields = [NSMutableDictionary dictionary];
        for (NSString *line in [para componentsSeparatedByString:@"\n"]) {
            if ([line length] == 0 || [line hasPrefix:@" "] || [line hasPrefix:@"\t"]) {
                continue;
            }
            NSRange colon = [line rangeOfString:@":"];
            if (colon.location == NSNotFound) {
                continue;
            }
            NSString *key = [line substringToIndex:colon.location];
            NSString *value = [[line substringFromIndex:colon.location + 1]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [fields setObject:value forKey:key];
        }
        NSString *package = [fields objectForKey:@"Package"];
        if (!package || [package isEqualToString:SK_SELF_PACKAGE]) {
            continue;
        }
        if (![[fields objectForKey:@"Status"] hasSuffix:@" installed"]) {
            continue;
        }
        [out setObject:fields forKey:package];
    }
    return out;
}
