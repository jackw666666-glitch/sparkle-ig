#import "SPKPreferenceAvailability.h"

#import <UIKit/UIKit.h>

#import "../App/SPKFlexLoader.h"
#import "../Shared/MediaPreview/SPKFullScreenImageViewController.h"
#import "SPKPreferences.h"

static BOOL SPKIsIOSVersionAtLeast(NSString *version) {
    return [[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}

BOOL SPKPrefIsAvailable(NSString *key) {
    if (key.length == 0)
        return YES;

    // JACK BUILD: features that make extra/automated Instagram API calls (ban risk)
    // or contact third parties are removed — always off, hidden in Settings.
    static NSSet<NSString *> *jackBlocked;
    static dispatch_once_t jackOnce;
    dispatch_once(&jackOnce, ^{
        jackBlocked = [NSSet setWithArray:@[
            @"profile_analyzer_track_visits",                       // Profile Analyzer visit tracking
            @"profile_follow_indicator", @"profile_follow_indicator_mode", @"profile_follow_indicator_colorful", // extra friendship lookup on every profile
            @"stories_search_viewer_list",                          // pages every story viewer + bulk friendship
            @"stories_mentions_btn", @"stories_mentions_count_badge", // bulk friendship lookups on mentions
            @"msgs_presence_notifications", @"msgs_presence_accurate_status", // background presence polling
            @"msgs_presence_notify_online", @"msgs_presence_notify_offline",
            @"msgs_presence_notify_typing", @"msgs_presence_notify_read",
            @"msgs_presence_mirror_notification_center",
            @"stories_auto_save", @"msgs_auto_save", @"instants_auto_save", // background mass downloads
            @"msgs_gif_title", @"general_comments_gif_title",       // GIF lookups sent to giphy.com
        ]];
    });
    if ([jackBlocked containsObject:key])
        return NO;

    // The Liquid Glass pref and its tab bar mode also back the pre-iOS 26
    // "Pill-Shaped Tab Bar" toggle — the tab bar experiment gates reshape the
    // bar into the floating pill on any iOS, only the glass material is 26+.
    if ([key isEqualToString:kSPKPrefInterfaceLiquidGlassMode] ||
        [key isEqualToString:kSPKPrefInterfaceLiquidGlassTabBarMode]) {
        return YES;
    }

    // The scroll edge style relies on UIScrollEdgeEffect, which only exists on iOS 26+.
    if ([key isEqualToString:kSPKPrefInterfaceScrollEdgeStyle]) {
        return SPKIsIOSVersionAtLeast(@"26.0");
    }

    // Liquid Glass, and so its OLED tint choice, only exists on iOS 26+.
    if ([key isEqualToString:@"interface_oled_black_glass"]) {
        return SPKIsIOSVersionAtLeast(@"26.0");
    }

    if ([key isEqualToString:@"notifs_pill_liquid_glass"]) {
        return SPKIsIOSVersionAtLeast(@"26.0");
    }

    // Live Text needs VisionKit's image analyzer: iOS 16+ on supported hardware.
    if ([key isEqualToString:@"general_preview_live_text"]) {
        return SPKLiveTextIsSupported();
    }

    if ([key isEqualToString:kSPKPrefInstantsDisableCameraControl]) {
        return SPKDeviceHasCameraControl();
    }

    if ([key hasPrefix:@"tools_flex_"]) {
        return SPKFlexIsBundled();
    }

    return YES;
}
