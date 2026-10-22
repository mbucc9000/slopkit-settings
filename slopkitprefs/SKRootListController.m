// slopkit Settings pane: Settings > slopkit.
//
// Installed: every installed slopkit tweak, one row each, opening its page: icon, name, tagline and How to
//   Use. Tweaks with their own settings get a Settings row there: exactly the row PreferenceLoader would
//   have put on the main page (built by libprefs' own -specifiersFromEntry:..., so bundle panes and
//   plist-only panes both open as before). Tweaks without settings say so. Apps are left out.
// Get More: slopkit packages from the repo catalog (Catalog.plist, written by build_slopkit.py)
//   that aren't installed; their info page links to Cydia.
// Then the Also Show in Settings switch and links to the repo.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../SKShared.h"

@interface PSSpecifier : NSObject
+ (id)preferenceSpecifierNamed:(NSString *)name target:(id)target set:(SEL)set get:(SEL)get
                        detail:(Class)detail cell:(int)cell edit:(Class)edit;
+ (id)groupSpecifierWithName:(NSString *)name;
+ (id)emptyGroupSpecifier;
+ (BOOL)environmentPassesPreferenceLoaderFilter:(NSDictionary *)filter;
- (NSString *)name;
- (void)setName:(NSString *)name;
- (void)removePropertyForKey:(NSString *)key;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
@end

@interface PSViewController : UIViewController
- (PSSpecifier *)specifier;
@end

@interface PSListController : PSViewController {
    NSArray *_specifiers;
}
- (UITableView *)table;
- (int)indexForIndexPath:(NSIndexPath *)indexPath;
- (PSSpecifier *)specifierAtIndex:(int)index;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
// Added by PreferenceLoader's libprefs.
- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath
                           title:(NSString *)title;
@end

@interface PSTableCell : UITableViewCell
+ (int)cellTypeFromString:(NSString *)string;
@end

#define SK_VERSION @"1.0.1"

static int SKCell(NSString *name) {
    return [NSClassFromString(@"PSTableCell") cellTypeFromString:name];
}

static NSBundle *SKBundle(void) {
    return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/SlopKitPrefs.bundle"];
}

// Loads name.png, preferring name@2x.png on Retina screens.
static UIImage *SKImage(NSString *path) {
    if (!path) {
        return nil;
    }
    NSString *base = [path stringByDeletingPathExtension];
    if ([[UIScreen mainScreen] scale] > 1) {
        NSString *retina = [base stringByAppendingString:@"@2x.png"];
        UIImage *img = [UIImage imageWithContentsOfFile:retina];
        if (img) {
            return [UIImage imageWithCGImage:[img CGImage] scale:2 orientation:UIImageOrientationUp];
        }
    }
    return [UIImage imageWithContentsOfFile:[base stringByAppendingString:@".png"]];
}

static UIImage *SKCatalogIcon(NSString *package) {
    NSString *dir = [[SKBundle() resourcePath] stringByAppendingPathComponent:@"catalog"];
    return SKImage([dir stringByAppendingPathComponent:[package stringByAppendingString:@".png"]]);
}

// An app's own home screen icon (Icon.png / Icon@2x.png in its .app), with rounded corners.
static UIImage *SKAppIcon(NSString *package) {
    NSString *list = [NSString stringWithContentsOfFile:[SK_DPKG_INFO stringByAppendingPathComponent:
                                                         [package stringByAppendingString:@".list"]]
                                               encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [list componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"/Applications/"] || ![line hasSuffix:@".app"]) {
            continue;
        }
        UIImage *img = SKImage([line stringByAppendingPathComponent:@"Icon.png"]);
        if (!img) {
            return nil;
        }
        CGRect r = CGRectMake(0, 0, img.size.width, img.size.height);
        UIGraphicsBeginImageContextWithOptions(r.size, NO, img.scale);
        [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:r.size.width * 0.175f] addClip];
        [img drawInRect:r];
        UIImage *rounded = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return rounded;
    }
    return nil;
}

static UIImage *SKDefaultIcon(void) {
    return SKImage([[SKBundle() resourcePath] stringByAppendingPathComponent:@"icon.png"]);
}

static NSDictionary *SKCatalog(void) {
    return [NSDictionary dictionaryWithContentsOfFile:[SKBundle() pathForResource:@"Catalog" ofType:@"plist"]];
}

// Icon, name and tagline centred above the first group, like the repo page's top card.
static UIView *SKHeader(CGFloat width, UIImage *icon, NSString *title, NSString *subtitle) {
    UIColor *ink = [UIColor colorWithRed:76 / 255.0 green:86 / 255.0 blue:108 / 255.0 alpha:1];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, subtitle ? 146 : 124)];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIImageView *iv = [[UIImageView alloc] initWithImage:icon];
    iv.frame = CGRectMake(floorf((width - 57) / 2), 18, 57, 57);
    iv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    iv.layer.shadowColor = [UIColor blackColor].CGColor;
    iv.layer.shadowOffset = CGSizeMake(0, 1);
    iv.layer.shadowOpacity = 0.35f;
    iv.layer.shadowRadius = 1.5f;
    [view addSubview:iv];

    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(10, 82, width - 20, 28)];
    name.text = title;
    name.font = [UIFont boldSystemFontOfSize:22];
    [view addSubview:name];

    UILabel *sub = nil;
    if (subtitle) {
        sub = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, width - 40, 20)];
        sub.text = subtitle;
        sub.font = [UIFont systemFontOfSize:14];
        sub.adjustsFontSizeToFitWidth = YES;
        sub.minimumScaleFactor = 0.75f;
        [view addSubview:sub];
    }
    for (UILabel *label in [NSArray arrayWithObjects:name, sub, nil]) {
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = ink;
        label.shadowColor = [UIColor whiteColor];
        label.shadowOffset = CGSizeMake(0, 1);
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return view;
}

static void SKInstallHeader(PSListController *controller, UIImage *icon, NSString *title, NSString *subtitle) {
    UITableView *table = [controller respondsToSelector:@selector(table)] ? [controller table] : nil;
    if (![table isKindOfClass:[UITableView class]] || table.tableHeaderView) {
        return;
    }
    table.tableHeaderView = SKHeader(table.bounds.size.width, icon, title, subtitle);
}

static UILabel *SKTextLabel(NSString *text, UIFont *font, UIColor *color, CGFloat x, CGFloat y, CGFloat width) {
    CGSize size = [text sizeWithFont:font constrainedToSize:CGSizeMake(width, 4000)
                       lineBreakMode:NSLineBreakByWordWrapping];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, ceilf(size.height))];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    return label;
}

// The info page's header: icon, name and tagline, then a white card with the note
// ("There are no settings to configure.") and the numbered How to Use steps.
static UIView *SKInfoHeader(CGFloat width, UIImage *icon, NSString *title, NSString *subtitle, NSString *note,
                            NSArray *steps) {
    UIView *top = SKHeader(width, icon, title, subtitle);
    if (!note && [steps count] == 0) {
        return top;
    }
    CGFloat pad = 12, cardW = width - 20, textW = cardW - 2 * pad, y = pad - 2;
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 8;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithWhite:0.66f alpha:1].CGColor;
    card.layer.shadowColor = [UIColor whiteColor].CGColor;
    card.layer.shadowOffset = CGSizeMake(0, 1);
    card.layer.shadowOpacity = 0.8f;
    card.layer.shadowRadius = 0;

    UIColor *ink = [UIColor colorWithRed:76 / 255.0 green:86 / 255.0 blue:108 / 255.0 alpha:1];
    if (note) {
        UILabel *label = SKTextLabel(note, [UIFont systemFontOfSize:15], ink, pad, y, textW);
        [card addSubview:label];
        y = CGRectGetMaxY(label.frame);
    }
    if ([steps count]) {
        if (note) {
            y += 12;
        }
        UILabel *head = SKTextLabel(@"How to Use", [UIFont boldSystemFontOfSize:16], [UIColor blackColor], pad, y,
                                    textW);
        [card addSubview:head];
        y = CGRectGetMaxY(head.frame) + 5;
        UIFont *font = [UIFont systemFontOfSize:15];
        NSUInteger i = 0;
        for (NSString *step in steps) {
            NSString *num = [NSString stringWithFormat:@"%lu.", (unsigned long)++i];
            [card addSubview:SKTextLabel(num, font, ink, pad, y, 20)];
            UILabel *text = SKTextLabel(step, font, [UIColor blackColor], pad + 20, y, textW - 20);
            [card addSubview:text];
            y = CGRectGetMaxY(text.frame) + 6;
        }
        y -= 6;
    }
    card.frame = CGRectMake(10, top.frame.size.height, cardW, y + pad);
    card.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [top addSubview:card];
    top.frame = CGRectMake(0, 0, width, CGRectGetMaxY(card.frame) + 4);
    return top;
}

static void SKOpenURL(NSString *url) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

#pragma mark - Settings rows

// Exactly the row(s) PreferenceLoader would add to the main Settings page for this entry plist, made for
// (and pushed from) `controller`. libprefs' own -specifiersFromEntry:... builds them, so bundle panes and
// plist-only panes (SMS Relay) open as they always did.
static NSArray *SKFallbackRows(PSListController *controller, NSDictionary *entry, NSString *title);

static NSArray *SKRowsForEntryPlist(PSListController *controller, NSString *path) {
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
    NSDictionary *entry = [plist objectForKey:@"entry"];
    if (![entry isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    Class spec = NSClassFromString(@"PSSpecifier");
    if ([spec respondsToSelector:@selector(environmentPassesPreferenceLoaderFilter:)]) {
        NSDictionary *filter = [plist objectForKey:@"filter"] ?: [plist objectForKey:@"pl_filter"];
        if (![spec environmentPassesPreferenceLoaderFilter:filter] ||
            ![spec environmentPassesPreferenceLoaderFilter:[entry objectForKey:@"pl_filter"]]) {
            return nil;
        }
    }
    NSString *title = [[path lastPathComponent] stringByDeletingPathExtension];
    if ([controller respondsToSelector:@selector(specifiersFromEntry:sourcePreferenceLoaderBundlePath:title:)]) {
        return [controller specifiersFromEntry:entry
              sourcePreferenceLoaderBundlePath:[path stringByDeletingLastPathComponent]
                                         title:title];
    }
    return SKFallbackRows(controller, entry, title);
}

// Without libprefs: bundle panes only (what older PreferenceLoaders could do).
static NSArray *SKFallbackRows(PSListController *controller, NSDictionary *entry, NSString *title) {
    NSString *bundleName = [entry objectForKey:@"bundle"];
    if (!bundleName) {
        return nil;
    }
    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle",
                                                                           bundleName]];
    if (![bundle load] || ![bundle principalClass]) {
        return nil;
    }
    PSSpecifier *row = [PSSpecifier preferenceSpecifierNamed:[entry objectForKey:@"label"] ?: title target:controller
                                                         set:NULL get:NULL detail:[bundle principalClass]
                                                        cell:SKCell(@"PSLinkCell") edit:Nil];
    NSString *icon = [entry objectForKey:@"icon"];
    if (icon) {
        UIImage *img = SKImage([[bundle resourcePath] stringByAppendingPathComponent:icon]);
        if (img) {
            [row setProperty:img forKey:@"iconImage"];
        }
    }
    return [NSArray arrayWithObject:row];
}

#pragma mark - Tweak page

// Every tweak's page: icon, name and tagline, a card with How to Use (and "There are no settings to
// configure." when it has none), a Settings row that opens the tweak's own settings when it has them,
// the version, and a Cydia link when the public repo has it.
@interface SKInfoListController : PSListController
@end

@implementation SKInfoListController

- (NSDictionary *)info {
    return [[self specifier] propertyForKey:@"skInfo"];
}

- (PSSpecifier *)valueRow:(NSString *)label value:(NSString *)value {
    PSSpecifier *row = [PSSpecifier preferenceSpecifierNamed:label target:self set:NULL get:@selector(rowValue:)
                                                      detail:Nil cell:SKCell(@"PSTitleValueCell") edit:Nil];
    [row setProperty:value ?: @"" forKey:@"skValue"];
    return row;
}

- (id)rowValue:(PSSpecifier *)row {
    return [row propertyForKey:@"skValue"];
}

- (id)specifiers {
    if (!_specifiers) {
        NSDictionary *info = [self info];
        BOOL installed = [[info objectForKey:@"installed"] boolValue];
        NSMutableArray *specs = [NSMutableArray array];

        // An installed app: just its header, which says it's installed.
        if (installed && [[info objectForKey:@"app"] boolValue]) {
            _specifiers = specs;
            return _specifiers;
        }

        // The tweak's own settings, one row per Settings entry (just "Settings" when there's one).
        NSArray *panes = [info objectForKey:@"panes"];
        NSMutableArray *rows = [NSMutableArray array];
        for (NSString *path in panes) {
            [rows addObjectsFromArray:SKRowsForEntryPlist(self, path) ?: [NSArray array]];
        }
        if ([rows count]) {
            [specs addObject:[PSSpecifier emptyGroupSpecifier]];
            for (PSSpecifier *row in rows) {
                if ([rows count] == 1) {
                    [row setName:@"Settings"];
                }
                [row removePropertyForKey:@"iconImage"];
                [specs addObject:row];
            }
        }

        [specs addObject:[PSSpecifier emptyGroupSpecifier]];
        [specs addObject:[self valueRow:@"Version" value:[info objectForKey:@"version"]]];
        if (!installed) {
            [specs addObject:[self valueRow:@"Status" value:@"Not Installed"]];
        }

        // Only offer Cydia for packages the public repo actually has.
        if ([[info objectForKey:@"public"] boolValue]) {
            PSSpecifier *links = [PSSpecifier emptyGroupSpecifier];
            if (!installed) {
                [links setProperty:@"Opens this package in Cydia, where you can install it." forKey:@"footerText"];
            }
            [specs addObject:links];
            PSSpecifier *cydia = [PSSpecifier preferenceSpecifierNamed:installed ? @"View in Cydia" : @"Get It in Cydia"
                                                                target:self set:NULL get:NULL detail:Nil
                                                                  cell:SKCell(@"PSLinkCell") edit:Nil];
            [cydia setProperty:[@"cydia://package/" stringByAppendingString:[info objectForKey:@"id"]]
                        forKey:@"skURL"];
            [specs addObject:cydia];
        }
        _specifiers = specs;
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSDictionary *info = [self info];
    self.title = [info objectForKey:@"name"];
    UITableView *table = [self respondsToSelector:@selector(table)] ? [self table] : nil;
    if (![table isKindOfClass:[UITableView class]] || table.tableHeaderView) {
        return;
    }
    BOOL installed = [[info objectForKey:@"installed"] boolValue];
    BOOL hasSettings = [[info objectForKey:@"panes"] count] > 0;
    NSArray *steps = [info objectForKey:@"howto"];
    NSString *about = [info objectForKey:@"about"];
    // The note: "no settings" for installed tweaks without any; what it does when it isn't installed
    // (Get More) or when there are no How to Use steps.
    NSString *note = nil;
    if (installed && [[info objectForKey:@"app"] boolValue]) {
        note = @"This app is installed. Open it from your home screen.";
        if (about) {
            note = [NSString stringWithFormat:@"%@\n\n%@", note, about];
        }
        steps = nil;
    } else if (installed && !hasSettings) {
        note = @"There are no settings to configure.";
        if ([steps count] == 0 && about) {
            note = [NSString stringWithFormat:@"%@\n\n%@", note, about];
        }
    } else if (!installed || [steps count] == 0) {
        note = about;
    }
    UIImage *icon = [info objectForKey:@"iconImage"] ?: SKCatalogIcon([info objectForKey:@"id"]) ?: SKDefaultIcon();
    table.tableHeaderView = SKInfoHeader(table.bounds.size.width, icon, [info objectForKey:@"name"],
                                         [info objectForKey:@"tagline"], note, steps);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PSSpecifier *spec = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
    NSString *url = [spec propertyForKey:@"skURL"];
    if (url) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SKOpenURL(url);
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end

#pragma mark - Root

@interface SKRootListController : PSListController
@end

@implementation SKRootListController

- (PSSpecifier *)infoRow:(NSDictionary *)info {
    PSSpecifier *row = [PSSpecifier preferenceSpecifierNamed:[info objectForKey:@"name"] target:self set:NULL
                                                         get:NULL detail:[SKInfoListController class]
                                                        cell:SKCell(@"PSLinkCell") edit:Nil];
    [row setProperty:info forKey:@"skInfo"];
    UIImage *icon = [info objectForKey:@"iconImage"] ?: SKCatalogIcon([info objectForKey:@"id"]) ?: SKDefaultIcon();
    if (icon) {
        [row setProperty:icon forKey:@"iconImage"];
    }
    return row;
}

- (id)specifiers {
    if (!_specifiers) {
        NSDictionary *catalog = SKCatalog();
        NSMutableDictionary *known = [NSMutableDictionary dictionary];
        for (NSDictionary *item in [catalog objectForKey:@"packages"]) {
            [known setObject:item forKey:[item objectForKey:@"id"]];
        }
        NSDictionary *installed = SKInstalledPackages();
        NSDictionary *entries = SKEntryPlists();

        // Which installed tweaks have their own Settings entries (checked by building their rows once).
        NSMutableDictionary *panes = [NSMutableDictionary dictionary];   // package -> entry plist paths
        NSMutableDictionary *paneIcons = [NSMutableDictionary dictionary];
        for (NSString *path in [[entries allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
            NSArray *rows = SKRowsForEntryPlist(self, path);
            NSString *package = [entries objectForKey:path];
            if (![rows count]) {
                SKLog(@"no row for %@", path);
                continue;
            }
            NSMutableArray *list = [panes objectForKey:package] ?: [NSMutableArray array];
            [list addObject:path];
            [panes setObject:list forKey:package];
            UIImage *icon = [[rows objectAtIndex:0] propertyForKey:@"iconImage"];
            if (icon && ![paneIcons objectForKey:package]) {
                [paneIcons setObject:icon forKey:package];
            }
        }

        // Every installed tweak gets one row that opens its page. Apps (anything installed under
        // /Applications, with no Settings entry) go under Apps, each with its name and description.
        NSMutableArray *mine = [NSMutableArray array];
        NSMutableArray *apps = [NSMutableArray array];
        for (NSString *package in installed) {
            NSDictionary *item = [known objectForKey:package];
            NSArray *paths = [panes objectForKey:package];
            BOOL isApp = ![paths count] && ([[item objectForKey:@"app"] boolValue] || SKPackageIsApp(package));
            NSDictionary *fields = [installed objectForKey:package];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setObject:package forKey:@"id"];
            [info setObject:[item objectForKey:@"name"] ?: [fields objectForKey:@"Name"] ?: package forKey:@"name"];
            [info setObject:[fields objectForKey:@"Version"] ?: @"" forKey:@"version"];
            NSString *about = [item objectForKey:@"about"] ?: [fields objectForKey:@"Description"];
            if (about) {
                [info setObject:about forKey:@"about"];
            }
            for (NSString *key in [NSArray arrayWithObjects:@"tagline", @"howto", @"public", nil]) {
                if ([item objectForKey:key]) {
                    [info setObject:[item objectForKey:key] forKey:key];
                }
            }
            if ([paths count]) {
                [info setObject:paths forKey:@"panes"];
            }
            // The slopkit icon; one the catalog doesn't know yet uses its own Settings or home screen icon.
            UIImage *icon = SKCatalogIcon(package) ?: [paneIcons objectForKey:package] ?: SKAppIcon(package) ?:
                            SKDefaultIcon();
            if (icon) {
                [info setObject:icon forKey:@"iconImage"];
            }
            [info setObject:[NSNumber numberWithBool:YES] forKey:@"installed"];
            [info setObject:[NSNumber numberWithBool:isApp] forKey:@"app"];
            [(isApp ? apps : mine) addObject:[self infoRow:info]];
        }
        NSComparator byName = ^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
            return [[a name] localizedCaseInsensitiveCompare:[b name]];
        };
        [mine sortUsingComparator:byName];
        [apps sortUsingComparator:byName];

        NSMutableArray *more = [NSMutableArray array];
        for (NSDictionary *item in [catalog objectForKey:@"packages"]) {
            // Only what the public repo has.
            if ([installed objectForKey:[item objectForKey:@"id"]] || ![[item objectForKey:@"public"] boolValue]) {
                continue;
            }
            NSMutableDictionary *info = [item mutableCopy];
            [info setObject:[NSNumber numberWithBool:NO] forKey:@"installed"];
            [more addObject:[self infoRow:info]];
        }

        NSMutableArray *specs = [NSMutableArray array];
        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"Tweaks"];
        if ([mine count] == 0) {
            [group setProperty:@"No slopkit tweaks installed yet." forKey:@"footerText"];
        }
        [specs addObject:group];
        [specs addObjectsFromArray:mine];

        if ([apps count]) {
            [specs addObject:[PSSpecifier groupSpecifierWithName:@"Apps"]];
            [specs addObjectsFromArray:apps];
        }

        if ([more count]) {
            [specs addObject:[PSSpecifier groupSpecifierWithName:@"Get More"]];
            [specs addObjectsFromArray:more];
        }

        PSSpecifier *also = [PSSpecifier emptyGroupSpecifier];
        [also setProperty:@"Also list each slopkit tweak on the main Settings page. Takes effect the next time "
                          @"Settings opens (close it from the app switcher)."
                   forKey:@"footerText"];
        [specs addObject:also];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"Also Show in Settings" target:self
                                                           set:@selector(setAlsoInSettings:specifier:)
                                                           get:@selector(alsoInSettings:) detail:Nil
                                                          cell:SKCell(@"PSSwitchCell") edit:Nil]];

        NSString *repo = [catalog objectForKey:@"repo"];
        if (repo) {
            PSSpecifier *links = [PSSpecifier emptyGroupSpecifier];
            [links setProperty:[NSString stringWithFormat:@"slopkit Settings %@\nWith help from Claude", SK_VERSION]
                        forKey:@"footerText"];
            [specs addObject:links];
            PSSpecifier *site = [PSSpecifier preferenceSpecifierNamed:@"slopkit Website" target:self set:NULL get:NULL
                                                               detail:Nil cell:SKCell(@"PSLinkCell") edit:Nil];
            [site setProperty:repo forKey:@"skURL"];
            [specs addObject:site];
            PSSpecifier *add = [PSSpecifier preferenceSpecifierNamed:@"Add slopkit to Cydia" target:self set:NULL
                                                                 get:NULL detail:Nil cell:SKCell(@"PSLinkCell")
                                                                edit:Nil];
            [add setProperty:[@"cydia://url/https://cydia.saurik.com/api/share#?source=" stringByAppendingString:repo]
                      forKey:@"skURL"];
            [specs addObject:add];
        }

        // Credit where it's due: the slopkit row is modelled on Lululab Settings.
        NSArray *credits = [catalog objectForKey:@"credits"];
        if ([credits count]) {
            PSSpecifier *thanks = [PSSpecifier groupSpecifierWithName:@"Credits"];
            [thanks setProperty:@"slopkit's look and this Settings page are inspired by lululab." forKey:@"footerText"];
            [specs addObject:thanks];
            for (NSDictionary *credit in credits) {
                NSString *label = [NSString stringWithFormat:@"Inspired by %@", [credit objectForKey:@"label"]];
                PSSpecifier *row = [PSSpecifier preferenceSpecifierNamed:label target:self set:NULL get:NULL
                                                                  detail:Nil cell:SKCell(@"PSLinkCell") edit:Nil];
                [row setProperty:[credit objectForKey:@"url"] forKey:@"skURL"];
                [specs addObject:row];
            }
        }
        _specifiers = specs;
        SKLog(@"pane: %lu installed (%lu with settings), %lu more", (unsigned long)[mine count],
              (unsigned long)[panes count], (unsigned long)[more count]);
    }
    return _specifiers;
}

- (id)alsoInSettings:(PSSpecifier *)spec {
    return [NSNumber numberWithBool:SKAlsoInSettings()];
}

- (void)setAlsoInSettings:(id)value specifier:(PSSpecifier *)spec {
    SKSetAlsoInSettings([value boolValue]);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = @"slopkit";
    NSDictionary *catalog = SKCatalog();
    NSString *tagline = [catalog objectForKey:@"settingsTagline"] ?: @"Homemade tweaks for iOS 6";
    SKInstallHeader(self, SKImage([[SKBundle() resourcePath] stringByAppendingPathComponent:@"logo.png"]),
                    @"slopkit", tagline);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PSSpecifier *spec = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
    NSString *url = [spec propertyForKey:@"skURL"];
    if (url) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SKOpenURL(url);
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
