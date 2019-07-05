#include "LPTRootListController.h"

@implementation LPTRootListController
- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *specifiers = [[[self loadSpecifiersFromPlistName:@"Root" target:self] retain] mutableCopy];

		// Read tweaks from directory.
		NSArray *tweaks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries" error:nil];

		if(tweaks) {
			for(NSString *tweak_file in tweaks) {
				if([[tweak_file pathExtension] isEqualToString:@"dylib"]) {
					// Create toggle entry for this dylib.
					PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:tweak_file target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSwitchCell edit:nil];

					[specifier setProperty:@YES forKey:@"enabled"];
					[specifier setProperty:tweak_file forKey:@"key"];
					[specifier setProperty:@NO forKey:@"default"];
					[specifier setProperty:@"me.jjolano.lowpowertweaks" forKey:@"defaults"];
					[specifier setProperty:[tweak_file stringByDeletingPathExtension] forKey:@"label"];

					// Add to specifiers.
					[specifiers addObject:specifier];
				}
			}
		}

		_specifiers = [specifiers copy];
	}

	return _specifiers;
}

- (void)respring:(id)sender {
    // Use sbreload if available.
    if([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/sbreload"]) {
        pid_t pid;
        const char *args[] = {"sbreload", NULL, NULL, NULL};
        posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
    } else {
        [HBRespringController respring];
    }
}

- (void)reset:(id)sender {
    HBPreferences *prefs = [HBPreferences preferencesForIdentifier:@"me.jjolano.lowpowertweaks"];

    if(prefs) {
        [prefs removeAllObjects];
    }
    
    [self respring:sender];
}
@end
