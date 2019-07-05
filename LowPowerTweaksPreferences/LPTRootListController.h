#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBRootListController.h>
#import <Cephei/HBPreferences.h>
#import <Cephei/HBRespringController.h>

#include <spawn.h>

@interface LPTRootListController : HBRootListController
- (void)respring:(id)sender;
- (void)reset:(id)sender;
@end
