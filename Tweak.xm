#import <Cephei/HBPreferences.h>

#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <string.h>

static HBPreferences *prefs = nil;
static BOOL passthrough = NO;
static BOOL disable_all_tweaks = NO;
static BOOL whitelist = NO;

static BOOL is_dylib_disabled(const char *path) {
	NSString *path_ns = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];
	NSString *name = [path_ns lastPathComponent];

	if([path_ns hasPrefix:@"/Library/MobileSubstrate"]
	|| [path_ns hasPrefix:@"/Library/TweakInject"]
	|| [path_ns hasPrefix:@"/usr/lib/tweaks"]
	|| [path_ns hasPrefix:@"/usr/lib/TweakInject"]
	|| [path_ns hasPrefix:@"/usr/lib/substrate"]) {
		if(disable_all_tweaks) {
			return YES;
		}

		if(whitelist) {
			if(![prefs boolForKey:name]) {
				return YES;
			}
		} else {
			if([prefs boolForKey:name]) {
				return YES;
			}
		}
	}

	return NO;
}

static void dyld_image_added(const struct mach_header *mh, intptr_t slide) {
	Dl_info info;
    int addr = dladdr(mh, &info);

    if(addr) {
		// Check if this dylib is disabled.
        if(is_dylib_disabled(info.dli_fname)) {
			passthrough = YES;
            void *handle = dlopen(info.dli_fname, RTLD_NOLOAD);
			passthrough = NO;

            if(handle) {
                dlclose(handle);
            }
        }
    }
}

%group hook_dlopen
%hookf(void *, dlopen, const char *path, int mode) {
    if(!passthrough && path) {
		// Check if this dylib is disabled.
        if(is_dylib_disabled(path)) {
            return NULL;
        }
    }

    return %orig;
}
%end

%ctor {
	// Enable hooks only in Low Power Mode.
	if([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
		prefs = [HBPreferences preferencesForIdentifier:@"me.jjolano.lowpowertweaks"];

		[prefs registerDefaults:@{
			@"enabled" : @NO,
			@"mode" : @"blacklist",
			@"enable_apps_only" : @NO,
			@"disable_all_tweaks" : @YES
		}];

		if([prefs boolForKey:@"enabled"]) {
			if([prefs boolForKey:@"enable_apps_only"]) {
				NSBundle *bundle = [NSBundle mainBundle];

				if(bundle != nil) {
					NSString *executablePath = [bundle executablePath];

					if(![executablePath hasPrefix:@"/var/containers/Bundle/Application"]
					&& ![executablePath hasPrefix:@"/private/var/containers/Bundle/Application"]
					&& ![executablePath hasPrefix:@"/var/mobile/Containers/Bundle/Application"]
					&& ![executablePath hasPrefix:@"/private/var/mobile/Containers/Bundle/Application"]
					&& ![executablePath hasPrefix:@"/Applications"]) {
						// Don't hook if apps only.
						return;
					}
				}
			}
			
			disable_all_tweaks = [prefs boolForKey:@"disable_all_tweaks"];
			whitelist = [[prefs objectForKey:@"mode"] isEqualToString:@"whitelist"];

			%init(hook_dlopen);
			_dyld_register_func_for_add_image(dyld_image_added);
		}
	}
}
