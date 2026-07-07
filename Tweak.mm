#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

#import "UIKit/UIKit.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/loader.h>
#import <objc/runtime.h>

#import "Menu.h"
#import "Page.h"
#import "ToggleItem.h"
#import "SliderItem.h"
#import "InvokeItem.h"
#import "PageItem.h"
#import <objc/message.h>

static Menu *menu;

static NSString * const kSplitLoopToggleTitle = @"\u5206\u88c2\u30eb\u30fc\u30d7";
static NSString * const kMasterSplitPageTitle = @"\u30de\u30b9\u30bf\u30fc\u30b9\u30d7\u30ea\u30c3\u30c8";
static NSString * const kSplitIntervalSliderTitle = @"\u5206\u88c2\u9593\u9694";
static NSString * const kShowSplitButtonToggleTitle = @"\u5206\u88c2\u30dc\u30bf\u30f3\u8868\u793a";
static NSString * const kButtonEditModeToggleTitle = @"\u30dc\u30bf\u30f3\u7de8\u96c6\u30e2\u30fc\u30c9";
static NSString * const kButtonSizeSliderTitle = @"\u30dc\u30bf\u30f3\u30b5\u30a4\u30ba";
static NSString * const kViewPageTitle = @"\u8996\u91ce";
static NSString * const kSplitViewToggleTitle = @"\u5206\u88c2\u8996\u91ce";
static NSString * const kFixedViewToggleTitle = @"\u56fa\u5b9a\u8996\u91ce";
static NSString * const kViewEditModeToggleTitle = @"\u8996\u91ce\u30dc\u30bf\u30f3\u7de8\u96c6";
static NSString * const kViewButtonSizeSliderTitle = @"\u8996\u91ce\u30dc\u30bf\u30f3\u30b5\u30a4\u30ba";
static NSString * const kViewButtonOpacitySliderTitle = @"\u8996\u91ce\u30dc\u30bf\u30f3\u900f\u660e\u5ea6";
static NSString * const kZoomHighStepSliderTitle = @"\u8996\u91ce\u5909\u66f4\u5e45 \u9ad8\u500d\u7387";
static NSString * const kZoomLowStepSliderTitle = @"\u8996\u91ce\u5909\u66f4\u5e45 \u4f4e\u500d\u7387";
static NSString * const kZoomLongPressSpeedSliderTitle = @"\u8996\u91ce\u9577\u62bc\u3057\u901f\u5ea6";
static NSString * const kLabelsPageTitle = @"\u30e9\u30d9\u30eb";
static NSString * const kEnemyScoreToggleTitle = @"\u6575\u30b9\u30b3\u30a2";
static NSString * const kSizeCheckToggleTitle = @"\u5927\u304d\u3055\u78ba\u8a8d";
static NSString * const kEnemyScoreLabelSizeSliderTitle = @"\u6575\u30b9\u30b3\u30a2\u30b5\u30a4\u30ba";
static NSString * const kVirusPageTitle = @"\u81ea\u52d5\u30ec\u30d9\u30ea\u30f3\u30b0";
static NSString * const kShowVirusButtonToggleTitle = @"\u81ea\u52d5\u30dc\u30bf\u30f3\u8868\u793a";
static NSString * const kVirusButtonEditModeToggleTitle = @"\u81ea\u52d5\u30dc\u30bf\u30f3\u7de8\u96c6";
static NSString * const kLoginFriendNavToggleTitle = @"\u30ed\u30b0\u30a4\u30f3\u5473\u65b9\u30ca\u30d3";
static NSString * const kRespawnPageTitle = @"\u30ea\u30b9\u30dd\u30fc\u30f3";
static NSString * const kAutoRespawnClassicToggleTitle = @"\u30af\u30e9\u30b7\u30c3\u30af";
static NSString * const kAutoRespawnBurstToggleTitle = @"\u30d0\u30fc\u30b9\u30c8";

static __weak id sCurrentControlsWidget = nil;
static __weak id sCurrentArenaView = nil;
static __weak id sCurrentArenaState = nil;
static __weak id sCurrentHud = nil;
static __weak id sCurrentFriendTrackerWidget = nil;
static __weak id sCurrentMinimapWidget = nil;
static UIButton *sSplitLoopButton = nil;
static NSTimer *sSplitLoopTimer = nil;
static UIPanGestureRecognizer *sSplitLoopPanGesture = nil;
static BOOL sSplitLoopRunning = NO;
static CGPoint sSplitLoopButtonPanStartCenter = CGPointZero;
static UIButton *sVirusChaseButton = nil;
static UILabel *sVirusChaseStatusLabel = nil;
static UILabel *sVirusChaseXpLabel = nil;
static NSTimer *sVirusChaseTimer = nil;
static UIPanGestureRecognizer *sVirusChasePanGesture = nil;
static BOOL sVirusChaseRunning = NO;
static BOOL sVirusChaseDesiredRunning = NO;
static float sVirusChaseSessionStartMass = 0.0f;
static float sVirusChaseSessionBestMass = 0.0f;
static float sVirusChaseLastGainedXp = 0.0f;
static float sVirusChaseNextLevelXp = -1.0f;
static double sVirusChaseEntryXp = -1.0;
static BOOL sVirusChaseXpKnown = NO;
static CGPoint sVirusChaseButtonPanStartCenter = CGPointZero;
static id sVirusChaseGestureHandler = nil;
static UIButton *sFriendChaseButton = nil;
static NSTimer *sFriendChaseTimer = nil;
static UIPanGestureRecognizer *sFriendChasePanGesture = nil;
static BOOL sFriendChaseRunning = NO;
static BOOL sFriendChaseDesiredRunning = NO;
static CGPoint sFriendChaseButtonPanStartCenter = CGPointZero;
static id sFriendChaseGestureHandler = nil;
static BOOL sTrackedFriendPositionValid = NO;
static CGPoint sTrackedFriendPosition = CGPointZero;
static int sTrackedFriendOwnerId = 0;
static NSString *sTrackedFriendAvatarUrl = nil;
static NSString *sTrackedFriendNickname = nil;
static CFTimeInterval sTrackedFriendPositionTime = 0.0;
static BOOL sNearestLoginFriendPositionValid = NO;
static CGPoint sNearestLoginFriendPosition = CGPointZero;
static int sNearestLoginFriendOwnerId = 0;
static NSString *sNearestLoginFriendAvatarUrl = nil;
static NSString *sNearestLoginFriendNickname = nil;
static CFTimeInterval sNearestLoginFriendPositionTime = 0.0;
static NSString *sFriendTrackerFriendsArgumentDebugText = nil;
static UIView *sLoginFriendNavView = nil;
static UILabel *sLoginFriendNavArrowLabel = nil;
static UILabel *sLoginFriendNavTextLabel = nil;
static NSTimer *sLoginFriendNavTimer = nil;
static id sLoginFriendNavTimerHandler = nil;
static UIButton *sZoomMinusButton = nil;
static UIButton *sZoomPlusButton = nil;
static UIPanGestureRecognizer *sZoomMinusPanGesture = nil;
static UIPanGestureRecognizer *sZoomPlusPanGesture = nil;
static UILongPressGestureRecognizer *sZoomMinusLongPressGesture = nil;
static UILongPressGestureRecognizer *sZoomPlusLongPressGesture = nil;
static UITapGestureRecognizer *sZoomMinusTapGesture = nil;
static UITapGestureRecognizer *sZoomPlusTapGesture = nil;
static NSTimer *sZoomAdjustTimer = nil;
static float sZoomAdjustDelta = 0.0f;
static CGPoint sZoomButtonPanStartCenter = CGPointZero;
static NSHashTable *sEnemyScoreCellViews = nil;
static NSString *sCurrentPartyCode = nil;
static BOOL sCurrentPartyCodeIsLive = NO;
static NSHashTable *sPartyCodeLabels = nil;
static id sMenuIconLongPressHandler = nil;
static __weak id sSkinEditorView = nil;
static __weak id sSkinEditorState = nil;
static __weak id sCreateSkinNodeView = nil;
static UIButton *sSkinImagePickerButton = nil;
static UIButton *sSkinImageApplyButton = nil;
static UIImageView *sSkinImagePreviewView = nil;
static id sSkinImagePickerDelegate = nil;
static UIImage *sImportedSkinImage = nil;
static BOOL sBurstModeEnabled = NO;
static BOOL sBurstModeValueKnown = NO;
static int sCurrentGameModeOverride = 0;
static unsigned long long sCurrentArenaStateId = 0;
static NSString *sCurrentArenaParametersSummary = nil;
static unsigned long long sArenaSetupCounter = 0;
static int sLastArenaBackground = -1;
static uintptr_t sLastArenaInitialStatePointer = 0;
static uint64_t sLastArenaInitialStateHash64 = 0;
static uint64_t sLastArenaInitialStateHash256 = 0;
static unsigned long long sMovedToNewArenaCounter = 0;
static __weak id sCurrentMenuMainState = nil;
static BOOL sAutoRespawnPending = NO;
static int sAutoRespawnPendingMode = 0;
static CFTimeInterval sLastAutoRespawnRequestTime = 0.0;
static CFTimeInterval sLastArenaPassiveRefreshTime = 0.0;
static const float kFixedViewEntryPulseMultiplier = 0.999f;
static volatile int sFixedViewEntryPulseGeneration = 0;

static NSString * const kSplitLoopButtonCenterXKey = @"KukioMod_ButtonCenterX";
static NSString * const kSplitLoopButtonCenterYKey = @"KukioMod_ButtonCenterY";
static NSString * const kZoomMultiplierKey = @"KukioMod_ZoomMultiplier";
static NSString * const kZoomMinusButtonCenterXKey = @"KukioMod_ZoomMinusButtonCenterX";
static NSString * const kZoomMinusButtonCenterYKey = @"KukioMod_ZoomMinusButtonCenterY";
static NSString * const kZoomPlusButtonCenterXKey = @"KukioMod_ZoomPlusButtonCenterX";
static NSString * const kZoomPlusButtonCenterYKey = @"KukioMod_ZoomPlusButtonCenterY";
static NSString * const kVisionModeKey = @"KukioMod_VisionMode";
static NSString * const kLastPartyCodeKey = @"KukioMod_LastPartyCode";
static NSString * const kVirusChaseButtonCenterXKey = @"KukioMod_VirusButtonCenterX";
static NSString * const kVirusChaseButtonCenterYKey = @"KukioMod_VirusButtonCenterY";
static NSString * const kFriendChaseButtonCenterXKey = @"KukioMod_FriendButtonCenterX";
static NSString * const kFriendChaseButtonCenterYKey = @"KukioMod_FriendButtonCenterY";

typedef NS_ENUM(NSInteger, ASLVisionMode) {
    ASLVisionModeOff = 0,
    ASLVisionModeSplit = 1,
    ASLVisionModeFixed = 2
};

extern void InstallImages(void);

static void ASLClampButtonToWindow();
static void ASLSaveButtonPosition();
static void ASLRefreshZoomControls();
static void ASLRefreshVirusChaseButton();
static void ASLRefreshFriendChaseButton();
static void ASLRefreshLoginFriendNav();
static void ASLStopFriendChase();
static void ASLUpdateVirusChaseStatusLabel();
static void ASLRefreshCurrentArenaView();
static void ASLScheduleArenaRefresh();
static void ASLStopZoomAdjustTimer();
static Ivar ASLEnemyScoreIvar(id object, const char *ivarName, Ivar *cache);
static BOOL ASLEnemyScoreSoftBodyHasMassLabel(id cell);
static BOOL ASLEnemyScoreShouldTargetSoftBodyCell(id cell, unsigned int mass);
static BOOL ASLEnemyScoreShouldForceSoftBodyMassLabel(id cell, unsigned int mass);
static id ASLEnemyScoreSoftBodyMassLabel(id cell);
static void ASLEnemyScoreSetVisible(id object, BOOL visible);
static void ASLEnemyScoreApplyLabelSize(id cell);
static void ASLEnemyScoreApplyLabelColor(id cell, unsigned int mass);
static BOOL ASLCellPosition(id cell, CGPoint *position);
static NSArray *ASLCurrentArenaCellViews(void);
static NSString *ASLDebugNSStringFromLibcppString(const void *stringAddress);

struct _ccColorThreeB {
    unsigned char r;
    unsigned char g;
    unsigned char b;
};

struct GameArenaDirectionVector {
    float _field1;
    float _field2;
};

typedef struct {
    int ownerId;
    unsigned char pad0[4];
    BOOL isAlive;
    unsigned char pad1[3];
    float x;
    float y;
    unsigned char pad2[4];
    unsigned char avatarUrl[24];
    unsigned char nickname[24];
} ASLArenaPartyMemberPair;

static BOOL ASLResponds(id object, SEL selector) {
    return object != nil && [object respondsToSelector:selector];
}

typedef bool (*ASLCTFontRegisterGraphicsFontFn)(CGFontRef font, CFErrorRef *error);

static ASLCTFontRegisterGraphicsFontFn ASLCTFontRegisterGraphicsFont() {
    static BOOL attempted = NO;
    static ASLCTFontRegisterGraphicsFontFn function = NULL;
    if(attempted)
        return function;

    attempted = YES;
    void *handle = dlopen("/System/Library/Frameworks/CoreText.framework/CoreText", RTLD_LAZY);
    if(handle == NULL)
        handle = RTLD_DEFAULT;

    function = (ASLCTFontRegisterGraphicsFontFn)dlsym(handle, "CTFontManagerRegisterGraphicsFont");
    return function;
}

static NSString *ASLYujiBokuPostScriptName() {
    static BOOL attempted = NO;
    static NSString *postScriptName = nil;
    if(attempted)
        return postScriptName;

    attempted = YES;
    uint32_t imageCount = _dyld_image_count();
    for(uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if(header == NULL || header->magic != MH_MAGIC_64)
            continue;

        unsigned long fontSize = 0;
        const uint8_t *fontBytes = getsectiondata((const struct mach_header_64 *)header,
                                                  "__DATA",
                                                  "__yuji_font",
                                                  &fontSize);
        if(fontBytes == NULL || fontSize == 0)
            continue;

        NSData *fontData = [NSData dataWithBytesNoCopy:(void *)fontBytes
                                                length:(NSUInteger)fontSize
                                          freeWhenDone:NO];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
        if(provider == NULL)
            continue;

        CGFontRef font = CGFontCreateWithDataProvider(provider);
        CGDataProviderRelease(provider);
        if(font == NULL)
            continue;

        ASLCTFontRegisterGraphicsFontFn registerFont = ASLCTFontRegisterGraphicsFont();
        if(registerFont != NULL) {
            CFErrorRef error = NULL;
            registerFont(font, &error);
            if(error != NULL)
                CFRelease(error);
        }

        CFStringRef name = CGFontCopyPostScriptName(font);
        if(name != NULL) {
            postScriptName = [(__bridge NSString *)name copy];
            CFRelease(name);
        }

        CGFontRelease(font);
        if(postScriptName.length > 0)
            return postScriptName;
    }

    return nil;
}

static UIFont *ASLYujiBokuFont(CGFloat size, BOOL boldFallback) {
    NSString *fontName = ASLYujiBokuPostScriptName();
    UIFont *font = fontName.length > 0 ? [UIFont fontWithName:fontName size:size] : nil;
    if(font != nil)
        return font;

    return boldFallback ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
}

static void ASLSwizzleInstanceMethod(Class cls, SEL original, SEL replacement) {
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    if(!originalMethod || !replacementMethod)
        return;

    BOOL added = class_addMethod(cls,
                                 original,
                                 method_getImplementation(replacementMethod),
                                 method_getTypeEncoding(replacementMethod));
    if(added) {
        class_replaceMethod(cls,
                            replacement,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

static UIWindow *ASLActiveWindow() {
    if(@available(iOS 13.0, *)) {
        for(UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if(![scene isKindOfClass:[UIWindowScene class]] ||
               scene.activationState != UISceneActivationStateForegroundActive)
                continue;

            for(UIWindow *window in ((UIWindowScene *)scene).windows) {
                if(window.isKeyWindow)
                    return window;
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

static BOOL ASLSplitLoopEnabled() {
    return menu != nil && [menu isItemOn:kSplitLoopToggleTitle];
}

static BOOL ASLShowSplitButtonEnabled() {
    return menu == nil || [menu isItemOn:kShowSplitButtonToggleTitle];
}

static BOOL ASLButtonEditModeEnabled() {
    return menu != nil && [menu isItemOn:kButtonEditModeToggleTitle];
}

static ASLVisionMode ASLCurrentVisionMode() {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kVisionModeKey];
    if(value < ASLVisionModeOff || value > ASLVisionModeFixed)
        value = ASLVisionModeOff;
    return (ASLVisionMode)value;
}

static void ASLSyncVisionModeFromMenu() {
    if(menu == nil)
        return;

    ASLVisionMode mode = ASLVisionModeOff;
    if([menu isItemOn:kFixedViewToggleTitle])
        mode = ASLVisionModeFixed;
    else if([menu isItemOn:kSplitViewToggleTitle])
        mode = ASLVisionModeSplit;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:mode forKey:kVisionModeKey];
    [defaults synchronize];
}

static BOOL ASLSplitViewEnabled() {
    return ASLCurrentVisionMode() == ASLVisionModeSplit;
}

static BOOL ASLFixedViewEnabled() {
    return ASLCurrentVisionMode() == ASLVisionModeFixed;
}

static BOOL ASLViewEnabled() {
    return ASLCurrentVisionMode() != ASLVisionModeOff;
}

static BOOL ASLViewEditModeEnabled() {
    return menu != nil && [menu isItemOn:kViewEditModeToggleTitle];
}

static BOOL ASLEnemyScoreEnabled() {
    return menu != nil && [menu isItemOn:kEnemyScoreToggleTitle];
}

static BOOL ASLShowVirusButtonEnabled() {
    return menu == nil || [menu isItemOn:kShowVirusButtonToggleTitle];
}

static BOOL ASLVirusButtonEditModeEnabled() {
    return menu != nil && [menu isItemOn:kVirusButtonEditModeToggleTitle];
}

static BOOL ASLLoginFriendNavEnabled() {
    return menu != nil && [menu isItemOn:kLoginFriendNavToggleTitle];
}

static int ASLAutoRespawnMode() {
    if(menu == nil)
        return 0;
    if([menu isItemOn:kAutoRespawnBurstToggleTitle])
        return 2;
    if([menu isItemOn:kAutoRespawnClassicToggleTitle])
        return 1;
    return 0;
}

static BOOL ASLSizeCheckEnabled() {
    return menu != nil && [menu isItemOn:kSizeCheckToggleTitle];
}

static float ASLEnemyScoreLabelScale() {
    if(menu == nil)
        return 1.0f;

    float value = [menu getSliderValue:kEnemyScoreLabelSizeSliderTitle];
    if(value < 0.5f)
        value = 0.5f;
    if(value > 2.0f)
        value = 2.0f;
    return value;
}

static BOOL ASLReadIntIvar(id object, const char *name, int *value) {
    if(object == nil || value == NULL)
        return NO;

    Ivar ivar = class_getInstanceVariable([object class], name);
    if(ivar == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    *value = *(int *)((uint8_t *)(__bridge void *)object + offset);
    return YES;
}

static BOOL ASLReadBoolIvar(id object, const char *name, BOOL *value) {
    if(object == nil || value == NULL)
        return NO;

    Ivar ivar = NULL;
    Class currentClass = object_getClass(object);
    while(currentClass != Nil) {
        ivar = class_getInstanceVariable(currentClass, name);
        if(ivar != NULL)
            break;
        currentClass = class_getSuperclass(currentClass);
    }
    if(ivar == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    *value = *(BOOL *)((uint8_t *)(__bridge void *)object + offset);
    return YES;
}

static BOOL ASLWriteBoolIvar(id object, const char *name, BOOL value) {
    if(object == nil)
        return NO;

    Ivar ivar = NULL;
    Class currentClass = object_getClass(object);
    while(currentClass != Nil) {
        ivar = class_getInstanceVariable(currentClass, name);
        if(ivar != NULL)
            break;
        currentClass = class_getSuperclass(currentClass);
    }
    if(ivar == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    *(BOOL *)((uint8_t *)(__bridge void *)object + offset) = value;
    return YES;
}

static BOOL ASLReadUnsignedIntIvar(id object, const char *name, unsigned int *value) {
    if(object == nil || value == NULL)
        return NO;

    Ivar ivar = class_getInstanceVariable([object class], name);
    if(ivar == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    *value = *(unsigned int *)((uint8_t *)(__bridge void *)object + offset);
    return YES;
}

static id ASLObjectIvar(id object, const char *name) {
    if(object == nil)
        return nil;

    Ivar ivar = class_getInstanceVariable([object class], name);
    if(ivar == NULL)
        return nil;

    return object_getIvar(object, ivar);
}

static float ASLSplitInterval() {
    if(menu == nil)
        return 0.5f;

    float value = [menu getSliderValue:kSplitIntervalSliderTitle];
    if(value < 0.0f)
        value = 0.0f;
    if(value > 0.5f)
        value = 0.5f;
    return value;
}

static float ASLButtonSize() {
    if(menu == nil)
        return 84.0f;

    float value = [menu getSliderValue:kButtonSizeSliderTitle];
    if(value < 50.0f)
        value = 50.0f;
    if(value > 140.0f)
        value = 140.0f;
    return value;
}

static float ASLZoomMultiplier() {
    float value = [[NSUserDefaults standardUserDefaults] floatForKey:kZoomMultiplierKey];
    if(value <= 0.0f)
        value = 1.0f;
    if(value < 0.01f)
        value = 0.01f;
    if(value > 2.00f)
        value = 2.00f;
    return value;
}

static void ASLClearFixedViewEntryPulse() {
    sFixedViewEntryPulseGeneration = 0;
}

static void ASLArmFixedViewEntryPulse() {
    if(!ASLFixedViewEnabled()) {
        ASLClearFixedViewEntryPulse();
        return;
    }

    sFixedViewEntryPulseGeneration = 1;
}

static float ASLFixedViewZoomWithEntryPulse() {
    float stableZoom = ASLZoomMultiplier();
    if(sFixedViewEntryPulseGeneration <= 0)
        return stableZoom;

    if(!ASLFixedViewEnabled()) {
        ASLClearFixedViewEntryPulse();
        return stableZoom;
    }

    sFixedViewEntryPulseGeneration--;
    float kickedZoom = stableZoom * kFixedViewEntryPulseMultiplier;
    return kickedZoom > 0.0f ? kickedZoom : stableZoom;
}

static void ASLSetZoomMultiplier(float value) {
    if(value < 0.01f)
        value = 0.01f;
    if(value > 2.00f)
        value = 2.00f;

    value = roundf(value * 1000.0f) / 1000.0f;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(value) forKey:kZoomMultiplierKey];
    [defaults synchronize];
    ASLScheduleArenaRefresh();
}

static float ASLZoomStepForDirection(float direction) {
    float value = ASLZoomMultiplier();
    float step = 0.01f;
    if(menu != nil) {
        NSString *title = value < 0.1f ? kZoomLowStepSliderTitle : kZoomHighStepSliderTitle;
        step = [menu getSliderValue:title];
    }
    if(step < 0.001f)
        step = 0.001f;
    if(step > 0.01f)
        step = 0.01f;
    return step;
}

static void ASLAdjustZoomMultiplier(float direction) {
    float step = ASLZoomStepForDirection(direction);
    ASLSetZoomMultiplier(ASLZoomMultiplier() + (direction < 0.0f ? -step : step));
    ASLRefreshZoomControls();
}

static float ASLViewButtonSize() {
    if(menu == nil)
        return 46.0f;

    float value = [menu getSliderValue:kViewButtonSizeSliderTitle];
    if(value < 36.0f)
        value = 36.0f;
    if(value > 96.0f)
        value = 96.0f;
    return value;
}

static float ASLViewButtonOpacity() {
    if(menu == nil)
        return 1.0f;

    float value = [menu getSliderValue:kViewButtonOpacitySliderTitle];
    if(value < 1.0f)
        value = 1.0f;
    if(value > 100.0f)
        value = 100.0f;
    return value / 100.0f;
}

static NSTimeInterval ASLZoomLongPressInterval() {
    if(menu == nil)
        return 0.10;

    float value = [menu getSliderValue:kZoomLongPressSpeedSliderTitle];
    if(value < 0.01f)
        value = 0.01f;
    if(value > 0.10f)
        value = 0.10f;
    return value;
}

static NSString *ASLButtonTitle(BOOL running) {
    return @"";
}

static NSString *ASLImageDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if(paths.count == 0)
        return nil;

    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"\u304f\u304d\u304amod"];
}

static UIImage *ASLMasterSplitButtonImage() {
    NSString *path = [ASLImageDirectory() stringByAppendingPathComponent:@"masterSplitButton.png"];
    if(path.length == 0)
        return nil;

    return [UIImage imageWithContentsOfFile:path];
}

static void ASLApplyButtonSize() {
    if(sSplitLoopButton == nil)
        return;

    CGFloat size = ASLButtonSize();
    CGPoint center = sSplitLoopButton.center;
    sSplitLoopButton.bounds = CGRectMake(0.0, 0.0, size, size);
    sSplitLoopButton.center = center;
    sSplitLoopButton.layer.cornerRadius = size * 0.5;
    sSplitLoopButton.titleLabel.font = [UIFont boldSystemFontOfSize:MAX(10.0, size * 0.155)];
    ASLClampButtonToWindow();
    ASLSaveButtonPosition();
}

static void ASLApplyButtonStyle() {
    if(sSplitLoopButton == nil)
        return;

    UIImage *buttonImage = ASLMasterSplitButtonImage();
    [sSplitLoopButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [sSplitLoopButton setBackgroundImage:buttonImage forState:UIControlStateHighlighted];
    sSplitLoopButton.layer.borderWidth = ASLButtonEditModeEnabled() ? 2.0 : 0.0;
    sSplitLoopButton.layer.borderColor = [UIColor yellowColor].CGColor;
    sSplitLoopButton.backgroundColor = buttonImage == nil
        ? [[UIColor blackColor] colorWithAlphaComponent:0.62]
        : [UIColor clearColor];
}

static void ASLClampButtonToWindow() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sSplitLoopButton == nil)
        return;

    CGFloat halfWidth = CGRectGetWidth(sSplitLoopButton.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(sSplitLoopButton.bounds) * 0.5;
    CGPoint center = sSplitLoopButton.center;
    center.x = MIN(CGRectGetWidth(window.bounds) - halfWidth - 8.0, MAX(halfWidth + 8.0, center.x));
    center.y = MIN(CGRectGetHeight(window.bounds) - halfHeight - 8.0, MAX(halfHeight + 8.0, center.y));
    sSplitLoopButton.center = center;
}

static void ASLSaveButtonPosition() {
    if(sSplitLoopButton == nil)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(sSplitLoopButton.center.x) forKey:kSplitLoopButtonCenterXKey];
    [defaults setObject:@(sSplitLoopButton.center.y) forKey:kSplitLoopButtonCenterYKey];
    [defaults synchronize];
}

static void ASLResetButtonPosition() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sSplitLoopButton == nil)
        return;

    sSplitLoopButton.center = CGPointMake(CGRectGetWidth(window.bounds) - 62.0,
                                          CGRectGetHeight(window.bounds) - 118.0);
    ASLClampButtonToWindow();
    ASLSaveButtonPosition();
}

static void ASLStopSplitLoop();

static NSString *ASLZoomButtonTitle(NSString *symbol) {
    return [NSString stringWithFormat:@"%@\n%.3fx", symbol, ASLZoomMultiplier()];
}

static void ASLSaveZoomButtonPosition(UIButton *button) {
    if(button == nil)
        return;

    BOOL isPlusButton = button == sZoomPlusButton;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(button.center.x) forKey:isPlusButton ? kZoomPlusButtonCenterXKey : kZoomMinusButtonCenterXKey];
    [defaults setObject:@(button.center.y) forKey:isPlusButton ? kZoomPlusButtonCenterYKey : kZoomMinusButtonCenterYKey];
    [defaults synchronize];
}

static void ASLClampZoomButtonToWindow(UIButton *button) {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || button == nil)
        return;

    CGFloat halfWidth = CGRectGetWidth(button.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(button.bounds) * 0.5;
    CGPoint center = button.center;
    center.x = MIN(CGRectGetWidth(window.bounds) - halfWidth - 8.0, MAX(halfWidth + 8.0, center.x));
    center.y = MIN(CGRectGetHeight(window.bounds) - halfHeight - 8.0, MAX(halfHeight + 8.0, center.y));
    button.center = center;
}

static void ASLApplyZoomButtonStyle(UIButton *button, NSString *symbol) {
    if(button == nil)
        return;

    CGPoint center = button.center;
    CGFloat size = ASLViewButtonSize();
    button.bounds = CGRectMake(0.0, 0.0, size, size);
    button.center = center;
    [button setTitle:ASLZoomButtonTitle(symbol) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:MAX(10.0, size * 0.25)];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.55;
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.64];
    button.layer.cornerRadius = size * 0.5;
    button.layer.borderWidth = ASLViewEditModeEnabled() ? 2.0 : 1.0;
    button.layer.borderColor = ASLViewEditModeEnabled() ? [UIColor yellowColor].CGColor : [UIColor whiteColor].CGColor;
    button.alpha = ASLViewButtonOpacity();
    ASLClampZoomButtonToWindow(button);
}

static void ASLUpdateZoomButtonVisibility() {
    BOOL visible = ASLViewEnabled();
    if(!visible)
        ASLStopZoomAdjustTimer();
    sZoomMinusButton.hidden = !visible;
    sZoomPlusButton.hidden = !visible;
}

static void ASLUpdateZoomButtonInteractionMode() {
    BOOL editMode = ASLViewEditModeEnabled();
    sZoomMinusPanGesture.enabled = editMode;
    sZoomPlusPanGesture.enabled = editMode;
    sZoomMinusLongPressGesture.enabled = !editMode;
    sZoomPlusLongPressGesture.enabled = !editMode;
    sZoomMinusTapGesture.enabled = !editMode;
    sZoomPlusTapGesture.enabled = !editMode;
    if(editMode)
        ASLStopZoomAdjustTimer();
    ASLApplyZoomButtonStyle(sZoomMinusButton, @"-");
    ASLApplyZoomButtonStyle(sZoomPlusButton, @"+");
}

@interface KukioModZoomButtonHandler : NSObject
- (void)handleMinusTap:(UITapGestureRecognizer *)gesture;
- (void)handlePlusTap:(UITapGestureRecognizer *)gesture;
- (void)handleMinusLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)handlePlusLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;
@end

static void ASLStopZoomAdjustTimer() {
    [sZoomAdjustTimer invalidate];
    sZoomAdjustTimer = nil;
    sZoomAdjustDelta = 0.0f;
}

static void ASLZoomAdjustTimerTick(__unused NSTimer *timer) {
    if(!ASLViewEnabled() || ASLViewEditModeEnabled()) {
        ASLStopZoomAdjustTimer();
        return;
    }

    ASLAdjustZoomMultiplier(sZoomAdjustDelta);
}

static void ASLStartZoomAdjustTimer(float delta) {
    if(!ASLViewEnabled() || ASLViewEditModeEnabled())
        return;

    ASLStopZoomAdjustTimer();
    sZoomAdjustDelta = delta;
    ASLAdjustZoomMultiplier(delta);
    sZoomAdjustTimer = [NSTimer scheduledTimerWithTimeInterval:ASLZoomLongPressInterval()
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
        ASLZoomAdjustTimerTick(timer);
    }];
}

@implementation KukioModZoomButtonHandler

- (void)handleMinusTap:(UITapGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateRecognized && ASLViewEnabled() && !ASLViewEditModeEnabled())
        ASLAdjustZoomMultiplier(-0.01f);
}

- (void)handlePlusTap:(UITapGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateRecognized && ASLViewEnabled() && !ASLViewEditModeEnabled())
        ASLAdjustZoomMultiplier(0.01f);
}

- (void)handleMinusLongPress:(UILongPressGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan) {
        ASLStartZoomAdjustTimer(-0.01f);
    } else if(gesture.state == UIGestureRecognizerStateEnded ||
              gesture.state == UIGestureRecognizerStateCancelled ||
              gesture.state == UIGestureRecognizerStateFailed) {
        ASLStopZoomAdjustTimer();
    }
}

- (void)handlePlusLongPress:(UILongPressGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan) {
        ASLStartZoomAdjustTimer(0.01f);
    } else if(gesture.state == UIGestureRecognizerStateEnded ||
              gesture.state == UIGestureRecognizerStateCancelled ||
              gesture.state == UIGestureRecognizerStateFailed) {
        ASLStopZoomAdjustTimer();
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIButton *button = (UIButton *)gesture.view;
    if(button == nil || !ASLViewEditModeEnabled())
        return;

    UIWindow *window = ASLActiveWindow();
    if(window == nil)
        return;

    if(gesture.state == UIGestureRecognizerStateBegan)
        sZoomButtonPanStartCenter = button.center;

    CGPoint translation = [gesture translationInView:window];
    button.center = CGPointMake(sZoomButtonPanStartCenter.x + translation.x,
                                sZoomButtonPanStartCenter.y + translation.y);
    ASLClampZoomButtonToWindow(button);

    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
        ASLSaveZoomButtonPosition(button);
}

@end

static KukioModZoomButtonHandler *sZoomButtonHandler = nil;

static CGPoint ASLSavedZoomButtonCenter(BOOL plusButton, UIWindow *window) {
    NSString *xKey = plusButton ? kZoomPlusButtonCenterXKey : kZoomMinusButtonCenterXKey;
    NSString *yKey = plusButton ? kZoomPlusButtonCenterYKey : kZoomMinusButtonCenterYKey;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *savedX = [defaults objectForKey:xKey];
    NSNumber *savedY = [defaults objectForKey:yKey];
    if(savedX != nil && savedY != nil)
        return CGPointMake(savedX.doubleValue, savedY.doubleValue);

    CGFloat x = CGRectGetWidth(window.bounds) - (plusButton ? 42.0 : 96.0);
    CGFloat y = CGRectGetHeight(window.bounds) - 204.0;
    return CGPointMake(x, y);
}

static UIButton *ASLCreateZoomButton(BOOL plusButton, UIWindow *window) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat size = ASLViewButtonSize();
    button.bounds = CGRectMake(0.0, 0.0, size, size);
    button.center = ASLSavedZoomButtonCenter(plusButton, window);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;

    NSString *symbol = plusButton ? @"+" : @"-";
    ASLApplyZoomButtonStyle(button, symbol);

    SEL tapSelector = plusButton ? @selector(handlePlusTap:) : @selector(handleMinusTap:);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:sZoomButtonHandler action:tapSelector];
    tap.cancelsTouchesInView = NO;
    [button addGestureRecognizer:tap];

    SEL longPressSelector = plusButton ? @selector(handlePlusLongPress:) : @selector(handleMinusLongPress:);
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:sZoomButtonHandler action:longPressSelector];
    longPress.minimumPressDuration = 0.10;
    longPress.cancelsTouchesInView = NO;
    [button addGestureRecognizer:longPress];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:sZoomButtonHandler action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO;
    [button addGestureRecognizer:pan];

    if(plusButton) {
        sZoomPlusPanGesture = pan;
        sZoomPlusLongPressGesture = longPress;
        sZoomPlusTapGesture = tap;
    } else {
        sZoomMinusPanGesture = pan;
        sZoomMinusLongPressGesture = longPress;
        sZoomMinusTapGesture = tap;
    }

    [window addSubview:button];
    ASLClampZoomButtonToWindow(button);
    return button;
}

static void ASLInstallZoomControls() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil)
        return;

    if(sZoomButtonHandler == nil)
        sZoomButtonHandler = [[KukioModZoomButtonHandler alloc] init];

    if(sZoomMinusButton == nil)
        sZoomMinusButton = ASLCreateZoomButton(NO, window);

    if(sZoomPlusButton == nil)
        sZoomPlusButton = ASLCreateZoomButton(YES, window);

    ASLUpdateZoomButtonInteractionMode();
    ASLUpdateZoomButtonVisibility();
}

static void ASLRefreshZoomControls() {
    ASLInstallZoomControls();
    ASLUpdateZoomButtonInteractionMode();
    ASLUpdateZoomButtonVisibility();
}

static void ASLRefreshEnemyScoreCellView(id cellView) {
    if(cellView == nil)
        return;

    unsigned int mass = 0;
    ASLReadUnsignedIntIvar(cellView, "_discreteClusterMass", &mass);
    if(!ASLEnemyScoreShouldTargetSoftBodyCell(cellView, mass))
        return;

    BOOL visible = ASLEnemyScoreEnabled();
    if(visible && !ASLEnemyScoreSoftBodyHasMassLabel(cellView) &&
       ASLResponds(cellView, NSSelectorFromString(@"initPlayerMassLabelWithMass:"))) {
        ((void (*)(id, SEL, unsigned int))objc_msgSend)(cellView,
                                                        NSSelectorFromString(@"initPlayerMassLabelWithMass:"),
                                                        mass);
    }

    if(sEnemyScoreCellViews == nil)
        sEnemyScoreCellViews = [NSHashTable weakObjectsHashTable];
    [sEnemyScoreCellViews addObject:cellView];

    ASLEnemyScoreSetVisible(ASLEnemyScoreSoftBodyMassLabel(cellView), visible);
    ASLEnemyScoreApplyLabelSize(cellView);
    ASLEnemyScoreApplyLabelColor(cellView, mass);
}

static void ASLScanVisibleArenaCellsForEnemyScore() {
    id arenaView = sCurrentArenaView;
    if(arenaView == nil || !ASLResponds(arenaView, NSSelectorFromString(@"cellViews")))
        return;

    id cellViews = ((id (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"cellViews"));
    NSArray *values = nil;
    if([cellViews respondsToSelector:@selector(allValues)])
        values = [cellViews allValues];
    else if([cellViews isKindOfClass:[NSArray class]])
        values = cellViews;

    for(id cellView in values)
        ASLRefreshEnemyScoreCellView(cellView);
}

static void ASLRefreshEnemyScoreLabels() {
    ASLScanVisibleArenaCellsForEnemyScore();

    NSArray *cellViews = sEnemyScoreCellViews.allObjects;
    for(id cellView in cellViews)
        ASLRefreshEnemyScoreCellView(cellView);
}

static void ASLRefreshCurrentArenaView() {
    id arenaView = sCurrentArenaView;
    if(arenaView == nil)
        return;

    if(ASLResponds(arenaView, NSSelectorFromString(@"setInitialCameraScale")))
        ((void (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"setInitialCameraScale"));
    if(ASLResponds(arenaView, NSSelectorFromString(@"updateViewportPosition")))
        ((void (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"updateViewportPosition"));

    ASLRefreshEnemyScoreLabels();
}

static void ASLPokeCurrentArenaView() {
    id arenaView = sCurrentArenaView;
    if(arenaView == nil)
        return;

    if(ASLResponds(arenaView, NSSelectorFromString(@"setInitialCameraScale")))
        ((void (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"setInitialCameraScale"));
    if(ASLResponds(arenaView, NSSelectorFromString(@"updateViewportPosition")))
        ((void (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"updateViewportPosition"));

    ASLRefreshEnemyScoreLabels();
}

static void ASLScheduleArenaRefresh() {
    dispatch_async(dispatch_get_main_queue(), ^{
        ASLPokeCurrentArenaView();
    });
    for(NSNumber *delayNumber in @[@0.05, @0.2, @0.6, @1.2, @2.0]) {
        NSTimeInterval delay = [delayNumber doubleValue];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ASLPokeCurrentArenaView();
        });
    }
}

static void ASLCaptureArenaViewFromState(id state) {
    id arenaView = ASLObjectIvar(state, "_arenaView");
    if(arenaView == nil)
        arenaView = ASLObjectIvar(state, "_view");

    if(arenaView == nil)
        return;

    if(ASLResponds(arenaView, NSSelectorFromString(@"setInitialCameraScale")) ||
       ASLResponds(arenaView, NSSelectorFromString(@"updateViewportPosition")) ||
       ASLResponds(arenaView, NSSelectorFromString(@"calculateZoom:cellAmount:")))
        sCurrentArenaView = arenaView;
}

static void ASLRefreshVisionForArenaEntry(id state) {
    ASLSyncVisionModeFromMenu();
    ASLCaptureArenaViewFromState(state);
    sLastArenaPassiveRefreshTime = 0.0;
    ASLArmFixedViewEntryPulse();
    ASLScheduleArenaRefresh();
}

static Ivar sEnemyScoreSoftBodyIsPlayerOwnedIvar = NULL;
static Ivar sEnemyScoreSoftBodyIsPartyCellIvar = NULL;
static Ivar sEnemyScoreSoftBodyMassLabelIvar = NULL;
static Ivar sEnemyScoreArenaDelegateIvar = NULL;
static Ivar sEnemyScoreCellRadiusIvar = NULL;

static Ivar ASLEnemyScoreIvar(id object, const char *ivarName, Ivar *cache) {
    if(object == nil || ivarName == NULL || cache == NULL)
        return NULL;

    if(*cache != NULL)
        return *cache;

    Class currentClass = object_getClass(object);
    while(currentClass != Nil) {
        Ivar ivar = class_getInstanceVariable(currentClass, ivarName);
        if(ivar != NULL) {
            *cache = ivar;
            return ivar;
        }
        currentClass = class_getSuperclass(currentClass);
    }

    return NULL;
}

static NSString *ASLTrimmedString(NSString *string) {
    if(string == nil)
        return nil;

    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length > 0 ? trimmed : nil;
}

static uint64_t ASLHashBytesFNV1a(const void *bytes, size_t length) {
    if(bytes == NULL || length == 0)
        return 0;

    const uint8_t *cursor = (const uint8_t *)bytes;
    uint64_t hash = 1469598103934665603ULL;
    for(size_t i = 0; i < length; i++) {
        hash ^= (uint64_t)cursor[i];
        hash *= 1099511628211ULL;
    }
    return hash;
}

static void ASLTrackArenaInitialState(int background, const void *initialState) {
    sLastArenaBackground = background;
    sLastArenaInitialStatePointer = (uintptr_t)initialState;

    if(initialState == NULL) {
        sLastArenaInitialStateHash64 = 0;
        sLastArenaInitialStateHash256 = 0;
        return;
    }

    sLastArenaInitialStateHash64 = ASLHashBytesFNV1a(initialState, 64);
    sLastArenaInitialStateHash256 = ASLHashBytesFNV1a(initialState, 256);
}

static NSString *ASLStringFromPotentialLabel(id object) {
    if(object == nil)
        return nil;
    if([object isKindOfClass:[NSString class]])
        return ASLTrimmedString(object);

    NSArray *selectors = @[@"getLabelText", @"getString", @"labelText", @"string", @"text", @"title", @"description"];
    for(NSString *selectorName in selectors) {
        SEL selector = NSSelectorFromString(selectorName);
        if(!ASLResponds(object, selector))
            continue;

        id value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
        if([value isKindOfClass:[NSString class]]) {
            NSString *trimmed = ASLTrimmedString(value);
            if(trimmed.length > 0)
                return trimmed;
        }
    }

    return nil;
}

static void ASLRememberPartyCode(NSString *partyCode) {
    NSString *trimmed = ASLTrimmedString(partyCode);
    if(trimmed.length > 0) {
        sCurrentPartyCode = [trimmed copy];
        sCurrentPartyCodeIsLive = YES;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:trimmed forKey:kLastPartyCodeKey];
        [defaults synchronize];
    }
}

static void ASLClearLivePartyCode() {
    sCurrentPartyCodeIsLive = NO;
}

static void ASLRememberPartyCodeLabel(id label) {
    if(label == nil)
        return;

    if(sPartyCodeLabels == nil)
        sPartyCodeLabels = [NSHashTable weakObjectsHashTable];
    [sPartyCodeLabels addObject:label];

    NSString *labelText = ASLStringFromPotentialLabel(label);
    if(labelText.length > 0)
        ASLRememberPartyCode(labelText);
}

static NSString *ASLCurrentPartyCodeText() {
    if(sCurrentPartyCode.length > 0)
        return sCurrentPartyCode;

    NSString *saved = [[NSUserDefaults standardUserDefaults] stringForKey:kLastPartyCodeKey];
    saved = ASLTrimmedString(saved);
    if(saved.length > 0) {
        sCurrentPartyCode = [saved copy];
        return saved;
    }

    return @"\u4e0d\u660e";
}

static BOOL ASLCopyCurrentPartyCodeToPasteboard() {
    NSString *partyCode = ASLCurrentPartyCodeText();
    partyCode = ASLTrimmedString(partyCode);
    if(partyCode.length == 0 || [partyCode isEqualToString:@"\u4e0d\u660e"])
        return NO;

    [UIPasteboard generalPasteboard].string = partyCode;
    return YES;
}

static void ASLRememberPartyCodeLabelFromView(id view) {
    if(view == nil)
        return;

    Ivar ivar = NULL;
    Class currentClass = object_getClass(view);
    while(currentClass != Nil) {
        ivar = class_getInstanceVariable(currentClass, "_partyCodeLabel");
        if(ivar != NULL)
            break;
        currentClass = class_getSuperclass(currentClass);
    }
    if(ivar == NULL)
        return;

    ASLRememberPartyCodeLabel(object_getIvar(view, ivar));
}

static void ASLCollectVisibleTexts(id object, NSMutableArray<NSString *> *texts, NSMutableSet<NSValue *> *visited, NSUInteger depth) {
    if(object == nil || texts == nil || visited == nil || depth > 8)
        return;

    NSValue *key = [NSValue valueWithPointer:(__bridge const void *)(object)];
    if([visited containsObject:key])
        return;
    [visited addObject:key];

    NSString *text = ASLStringFromPotentialLabel(object);
    if(text.length > 0)
        [texts addObject:text];

    if([object respondsToSelector:@selector(subviews)]) {
        NSArray *subviews = ((NSArray *(*)(id, SEL))objc_msgSend)(object, @selector(subviews));
        for(id subview in subviews)
            ASLCollectVisibleTexts(subview, texts, visited, depth + 1);
    }

    if(ASLResponds(object, NSSelectorFromString(@"children"))) {
        id children = ((id (*)(id, SEL))objc_msgSend)(object, NSSelectorFromString(@"children"));
        if([children respondsToSelector:@selector(objectEnumerator)]) {
            for(id child in children)
                ASLCollectVisibleTexts(child, texts, visited, depth + 1);
        }
    }

    if(depth < 3) {
        Class currentClass = object_getClass(object);
        while(currentClass != Nil && currentClass != [NSObject class]) {
            unsigned int count = 0;
            Ivar *ivars = class_copyIvarList(currentClass, &count);
            for(unsigned int i = 0; i < count; i++) {
                const char *type = ivar_getTypeEncoding(ivars[i]);
                if(type == NULL || type[0] != '@')
                    continue;

                id value = object_getIvar(object, ivars[i]);
                if(value != nil)
                    ASLCollectVisibleTexts(value, texts, visited, depth + 1);
            }
            if(ivars != NULL)
                free(ivars);
            currentClass = class_getSuperclass(currentClass);
        }
    }
}

static NSArray<NSNumber *> *ASLNumbersInString(NSString *text) {
    if(text.length == 0)
        return @[];

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9][0-9,]*"
                                                                           options:0
                                                                             error:&error];
    if(error != nil)
        return @[];

    NSMutableArray<NSNumber *> *numbers = [NSMutableArray array];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for(NSTextCheckingResult *match in matches) {
        NSString *raw = [text substringWithRange:match.range];
        NSString *clean = [raw stringByReplacingOccurrencesOfString:@"," withString:@""];
        [numbers addObject:@([clean doubleValue])];
    }
    return numbers;
}

static double ASLFirstNumberNearResultTexts(NSArray<NSString *> *texts, NSArray<NSString *> *keywords) {
    for(NSUInteger i = 0; i < texts.count; i++) {
        NSString *line = texts[i];
        NSString *lower = line.lowercaseString;
        BOOL matchesKeyword = NO;
        for(NSString *keyword in keywords) {
            if([lower containsString:keyword.lowercaseString]) {
                matchesKeyword = YES;
                break;
            }
        }
        if(!matchesKeyword)
            continue;

        NSArray<NSNumber *> *numbers = ASLNumbersInString(line);
        if(numbers.count > 0)
            return [numbers.firstObject doubleValue];

        NSUInteger maxIndex = MIN(texts.count, i + 3);
        for(NSUInteger j = i + 1; j < maxIndex; j++) {
            numbers = ASLNumbersInString(texts[j]);
            if(numbers.count > 0)
                return [numbers.firstObject doubleValue];
        }
    }

    return -1.0;
}

static void ASLConsumeResultXpTexts(NSArray<NSString *> *texts) {
    if(texts.count == 0)
        return;

    double gainedXp = ASLFirstNumberNearResultTexts(texts, @[@"gained xp", @"xp gained", @"earned xp", @"xp earned", @"\u7372\u5f97\u7d4c\u9a13", @"\u7d4c\u9a13\u5024"]);
    if(gainedXp >= 0.0) {
        sVirusChaseLastGainedXp = (float)gainedXp;
        sVirusChaseXpKnown = YES;
    }

    double nextLevelXp = ASLFirstNumberNearResultTexts(texts, @[@"to next", @"next level", @"needed", @"until", @"required", @"\u3042\u3068", @"\u5fc5\u8981", @"\u6b21\u30ec\u30d9\u30eb"]);
    if(nextLevelXp >= 0.0)
        sVirusChaseNextLevelXp = (float)nextLevelXp;

    ASLUpdateVirusChaseStatusLabel();
}

static void ASLConsumeResultXpText(NSString *text) {
    NSString *trimmed = ASLTrimmedString(text);
    if(trimmed.length == 0)
        return;

    ASLConsumeResultXpTexts(@[trimmed]);
}

static void ASLReadResultXpLabels(id resultView) {
    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    ASLCollectVisibleTexts(resultView, texts, [NSMutableSet set], 0);
    if(texts.count == 0)
        return;

    ASLConsumeResultXpTexts(texts);
}

static void ASLScheduleReadResultXpLabels(id resultView) {
    __weak id weakResultView = resultView;
    for(NSNumber *delayNumber in @[@0.15, @0.6, @1.2]) {
        NSTimeInterval delay = [delayNumber doubleValue];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            id strongResultView = weakResultView;
            if(strongResultView != nil)
                ASLReadResultXpLabels(strongResultView);
        });
    }
}

static double ASLNumericValueFromObject(id object, SEL selector) {
    if(object == nil || !ASLResponds(object, selector))
        return -1.0;

    NSMethodSignature *signature = [object methodSignatureForSelector:selector];
    if(signature == nil)
        return -1.0;

    const char *returnType = [signature methodReturnType];
    if(returnType == NULL)
        return -1.0;

    if(returnType[0] == '@') {
        id value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
        if([value isKindOfClass:[NSNumber class]])
            return [(NSNumber *)value doubleValue];
        if([value isKindOfClass:[NSString class]])
            return [(NSString *)value doubleValue];
        return -1.0;
    }

    if(strcmp(returnType, @encode(int)) == 0)
        return (double)((int (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(BOOL)) == 0)
        return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector) ? 1.0 : 0.0;
    if(strcmp(returnType, @encode(char)) == 0)
        return (double)((char (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(unsigned char)) == 0)
        return (double)((unsigned char (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(unsigned int)) == 0)
        return (double)((unsigned int (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(long)) == 0)
        return (double)((long (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(unsigned long)) == 0)
        return (double)((unsigned long (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(long long)) == 0)
        return (double)((long long (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(unsigned long long)) == 0)
        return (double)((unsigned long long (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(float)) == 0)
        return (double)((float (*)(id, SEL))objc_msgSend)(object, selector);
    if(strcmp(returnType, @encode(double)) == 0)
        return ((double (*)(id, SEL))objc_msgSend)(object, selector);

    return -1.0;
}

static id ASLObjectValueFromObject(id object, SEL selector) {
    if(object == nil || !ASLResponds(object, selector))
        return nil;

    NSMethodSignature *signature = [object methodSignatureForSelector:selector];
    if(signature == nil)
        return nil;

    const char *returnType = [signature methodReturnType];
    if(returnType == NULL || returnType[0] != '@')
        return nil;

    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static double ASLExperienceFromObject(id object, NSInteger depth) {
    if(object == nil || depth > 2)
        return -1.0;

    NSArray *xpSelectors = @[
        @"experience", @"xp", @"XP", @"totalExperience", @"currentExperience",
        @"levelExperience", @"playerExperience", @"userExperience", @"exp"
    ];
    for(NSString *selectorName in xpSelectors) {
        double value = ASLNumericValueFromObject(object, NSSelectorFromString(selectorName));
        if(value >= 0.0)
            return value;
    }

    NSArray *childSelectors = @[
        @"profile", @"userProfile", @"playerProfile", @"currentProfile",
        @"user", @"currentUser", @"player", @"account", @"data", @"model"
    ];
    for(NSString *selectorName in childSelectors) {
        id child = ASLObjectValueFromObject(object, NSSelectorFromString(selectorName));
        if(child == nil || child == object)
            continue;

        double value = ASLExperienceFromObject(child, depth + 1);
        if(value >= 0.0)
            return value;
    }

    return -1.0;
}

static double ASLCurrentAccountExperience() {
    double value = ASLExperienceFromObject([UIApplication sharedApplication].delegate, 0);
    if(value >= 0.0)
        return value;

    NSArray *classNames = @[
        @"UserManager", @"UserProfileManager", @"ProfileManager", @"AccountManager",
        @"PlayerProfileManager", @"GameManager", @"UserData", @"UserProfile",
        @"PlayerProfile", @"Account", @"Profile"
    ];
    NSArray *rootSelectors = @[
        @"sharedInstance", @"sharedManager", @"instance", @"defaultManager",
        @"currentUser", @"currentProfile", @"profile", @"user", @"account"
    ];

    for(NSString *className in classNames) {
        Class cls = NSClassFromString(className);
        if(cls == Nil)
            continue;

        value = ASLExperienceFromObject((id)cls, 0);
        if(value >= 0.0)
            return value;

        for(NSString *selectorName in rootSelectors) {
            SEL selector = NSSelectorFromString(selectorName);
            if(!class_respondsToSelector(object_getClass(cls), selector))
                continue;

            id root = ((id (*)(id, SEL))objc_msgSend)((id)cls, selector);
            value = ASLExperienceFromObject(root, 0);
            if(value >= 0.0)
                return value;
        }
    }

    return -1.0;
}

static BOOL ASLEnemyScoreReadBoolIvar(id object, const char *ivarName, Ivar *cache, BOOL *value) {
    Ivar ivar = ASLEnemyScoreIvar(object, ivarName, cache);
    if(ivar == NULL || value == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    if(offset < 0)
        return NO;

    *value = *(BOOL *)((uint8_t *)(__bridge void *)object + offset);
    return YES;
}

static BOOL ASLEnemyScoreReadFloatIvar(id object, const char *ivarName, Ivar *cache, float *value) {
    Ivar ivar = ASLEnemyScoreIvar(object, ivarName, cache);
    if(ivar == NULL || value == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    if(offset < 0)
        return NO;

    *value = *(float *)((uint8_t *)(__bridge void *)object + offset);
    return YES;
}

static BOOL ASLEnemyScoreWriteBoolIvar(id object, const char *ivarName, Ivar *cache, BOOL value) {
    Ivar ivar = ASLEnemyScoreIvar(object, ivarName, cache);
    if(ivar == NULL)
        return NO;

    ptrdiff_t offset = ivar_getOffset(ivar);
    if(offset < 0)
        return NO;

    *(BOOL *)((uint8_t *)(__bridge void *)object + offset) = value;
    return YES;
}

static BOOL ASLEnemyScoreSoftBodyIsVirus(id cell) {
    if(cell == nil || !ASLResponds(cell, @selector(isVirus)))
        return NO;

    return ((BOOL (*)(id, SEL))objc_msgSend)(cell, @selector(isVirus));
}

static BOOL ASLEnemyScoreSoftBodyIsPlayerOwned(id cell) {
    BOOL isPlayerOwned = NO;
    if(!ASLEnemyScoreReadBoolIvar(cell, "_isPlayerOwned", &sEnemyScoreSoftBodyIsPlayerOwnedIvar, &isPlayerOwned))
        return NO;

    return isPlayerOwned;
}

static BOOL ASLEnemyScoreSoftBodyIsPartyCell(id cell) {
    BOOL isPartyCell = NO;
    if(!ASLEnemyScoreReadBoolIvar(cell, "_isPartyCell", &sEnemyScoreSoftBodyIsPartyCellIvar, &isPartyCell))
        return NO;

    return isPartyCell;
}

static BOOL ASLEnemyScoreSoftBodyHasMassLabel(id cell) {
    Ivar ivar = ASLEnemyScoreIvar(cell, "_massLabel", &sEnemyScoreSoftBodyMassLabelIvar);
    if(ivar == NULL)
        return NO;

    return object_getIvar(cell, ivar) != nil;
}

static id ASLEnemyScoreSoftBodyMassLabel(id cell) {
    Ivar ivar = ASLEnemyScoreIvar(cell, "_massLabel", &sEnemyScoreSoftBodyMassLabelIvar);
    if(ivar == NULL)
        return nil;

    return object_getIvar(cell, ivar);
}

static void ASLEnemyScoreSetVisible(id object, BOOL visible) {
    if(object != nil && ASLResponds(object, @selector(setVisible:)))
        ((void (*)(id, SEL, BOOL))objc_msgSend)(object, @selector(setVisible:), visible);
}

static void ASLEnemyScoreApplyLabelSize(id cell) {
    id label = ASLEnemyScoreSoftBodyMassLabel(cell);
    if(label == nil)
        return;

    if(ASLResponds(label, @selector(setScale:)))
        ((void (*)(id, SEL, float))objc_msgSend)(label, @selector(setScale:), ASLEnemyScoreLabelScale());
}

static float ASLEnemyScoreFloatValue(id object, SEL selector, float fallback) {
    if(object == nil || !ASLResponds(object, selector))
        return fallback;

    return ((float (*)(id, SEL))objc_msgSend)(object, selector);
}

static float ASLEnemyScoreOwnLargestCellMass(id cell) {
    Ivar arenaDelegateIvar = ASLEnemyScoreIvar(cell, "_arenaDelegate", &sEnemyScoreArenaDelegateIvar);
    id arenaDelegate = arenaDelegateIvar != NULL ? object_getIvar(cell, arenaDelegateIvar) : nil;
    float value = ASLEnemyScoreFloatValue(arenaDelegate, NSSelectorFromString(@"maxPlayerMass"), 0.0f);
    if(value > 0.0f)
        return value;

    return ASLEnemyScoreFloatValue(sCurrentArenaView, NSSelectorFromString(@"maxPlayerMass"), 0.0f);
}

static float ASLEnemyScoreCellRadius(id cell) {
    float radius = 0.0f;
    if(ASLEnemyScoreReadFloatIvar(cell, "_radius", &sEnemyScoreCellRadiusIvar, &radius) && radius > 0.0f)
        return radius;

    return ASLEnemyScoreFloatValue(cell, NSSelectorFromString(@"radius"), 0.0f);
}

static float ASLEnemyScoreOwnLargestCellRadius() {
    id arenaView = sCurrentArenaView;
    if(arenaView == nil || !ASLResponds(arenaView, NSSelectorFromString(@"playerAgarCells")))
        return 0.0f;

    id cells = ((id (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"playerAgarCells"));
    if(cells == nil || ![cells respondsToSelector:@selector(count)] || ![cells respondsToSelector:@selector(objectAtIndex:)])
        return 0.0f;

    float largestRadius = 0.0f;
    NSUInteger count = [(NSArray *)cells count];
    for(NSUInteger index = 0; index < count; index++) {
        id playerCell = [(NSArray *)cells objectAtIndex:index];
        float radius = ASLEnemyScoreCellRadius(playerCell);
        if(radius > largestRadius)
            largestRadius = radius;
    }

    return largestRadius;
}

static void ASLEnemyScoreSetLabelColor(id label, struct _ccColorThreeB color) {
    if(label == nil)
        return;

    SEL fillColorSelector = NSSelectorFromString(@"setFontFillColor:updateImage:");
    if(ASLResponds(label, fillColorSelector))
        ((void (*)(id, SEL, struct _ccColorThreeB, unsigned char))objc_msgSend)(label, fillColorSelector, color, 1);

    if(ASLResponds(label, @selector(setColor:)))
        ((void (*)(id, SEL, struct _ccColorThreeB))objc_msgSend)(label, @selector(setColor:), color);
}

static void ASLEnemyScoreApplyLabelColor(id cell, unsigned int mass) {
    id label = ASLEnemyScoreSoftBodyMassLabel(cell);
    if(label == nil)
        return;

    struct _ccColorThreeB white = {255, 255, 255};
    if(!ASLSizeCheckEnabled() || mass == 0) {
        ASLEnemyScoreSetLabelColor(label, white);
        return;
    }

    struct _ccColorThreeB yellow = {255, 220, 0};
    struct _ccColorThreeB green = {0, 255, 80};
    struct _ccColorThreeB blue = {70, 160, 255};
    struct _ccColorThreeB red = {255, 55, 55};
    const float radiusEatRatio = 1.08f;
    const float oneSplitRadiusScale = 0.70710678f;
    const float twoSplitRadiusScale = 0.5f;

    float myMaxRadius = ASLEnemyScoreOwnLargestCellRadius();
    float enemyRadius = ASLEnemyScoreCellRadius(cell);
    if(myMaxRadius > 0.0f && enemyRadius > 0.0f) {
        float myOneSplitRadius = myMaxRadius * oneSplitRadiusScale;
        float myTwoSplitRadius = myMaxRadius * twoSplitRadiusScale;
        float enemyOneSplitRadius = enemyRadius * oneSplitRadiusScale;

        if(enemyOneSplitRadius >= myMaxRadius * radiusEatRatio) {
            ASLEnemyScoreSetLabelColor(label, red);
        } else if(myTwoSplitRadius >= enemyRadius * radiusEatRatio) {
            ASLEnemyScoreSetLabelColor(label, blue);
        } else if(myOneSplitRadius >= enemyRadius * radiusEatRatio) {
            ASLEnemyScoreSetLabelColor(label, green);
        } else if(myOneSplitRadius >= enemyRadius) {
            ASLEnemyScoreSetLabelColor(label, yellow);
        } else {
            ASLEnemyScoreSetLabelColor(label, white);
        }
        return;
    }

    float myMaxMass = ASLEnemyScoreOwnLargestCellMass(cell);
    if(myMaxMass <= 0.0f) {
        ASLEnemyScoreSetLabelColor(label, white);
        return;
    }

    float enemyMass = (float)mass;
    const float eatRatio = radiusEatRatio * radiusEatRatio;

    if((enemyMass * 0.5f) >= myMaxMass * eatRatio) {
        ASLEnemyScoreSetLabelColor(label, red);
    } else if((myMaxMass * 0.25f) >= enemyMass * eatRatio) {
        ASLEnemyScoreSetLabelColor(label, blue);
    } else if((myMaxMass * 0.5f) >= enemyMass * eatRatio) {
        ASLEnemyScoreSetLabelColor(label, green);
    } else if((myMaxMass * 0.5f) >= enemyMass) {
        ASLEnemyScoreSetLabelColor(label, yellow);
    } else {
        ASLEnemyScoreSetLabelColor(label, white);
    }
}

static BOOL ASLEnemyScoreShouldTargetSoftBodyCell(id cell, unsigned int mass) {
    if(mass == 0)
        return NO;

    if(ASLEnemyScoreSoftBodyIsPlayerOwned(cell) && !ASLEnemyScoreSoftBodyIsPartyCell(cell))
        return NO;

    return !ASLEnemyScoreSoftBodyIsVirus(cell);
}

static BOOL ASLEnemyScoreShouldForceSoftBodyMassLabel(id cell, unsigned int mass) {
    return ASLEnemyScoreEnabled() && ASLEnemyScoreShouldTargetSoftBodyCell(cell, mass);
}

static void ASLShowLaunchGreeting() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ASLShowLaunchGreeting();
        });
        return;
    }

    UIView *overlay = [[UIView alloc] initWithFrame:window.bounds];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.userInteractionEnabled = NO;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
    overlay.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(overlay.bounds, 24.0, 0.0)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.userInteractionEnabled = NO;
    label.text = @"\u304a\u3064\u304b\u308c\u3063\u3059\uff5e";
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.55;
    label.textColor = [UIColor whiteColor];
    label.font = ASLYujiBokuFont(54.0, YES);
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOpacity = 0.85;
    label.layer.shadowRadius = 8.0;
    label.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    [overlay addSubview:label];

    [window addSubview:overlay];

    [UIView animateWithDuration:0.22 animations:^{
        overlay.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.32 delay:1.46 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            overlay.alpha = 0.0;
        } completion:^(__unused BOOL done) {
            [overlay removeFromSuperview];
        }];
    }];
}

static NSString *ASLCurrentGameModeText() {
    if(sCurrentGameModeOverride == 2)
        return @"\u30d0\u30fc\u30b9\u30c8";
    if(sCurrentGameModeOverride == 1)
        return @"\u30af\u30e9\u30b7\u30c3\u30af";

    id arenaView = sCurrentArenaView;
    NSString *className = arenaView != nil ? NSStringFromClass([arenaView class]) : @"";
    NSString *rawTag = @"";
    SEL tagSelector = NSSelectorFromString(@"gameModeTagForGameplaySettings");
    if(ASLResponds(arenaView, tagSelector)) {
        const char *tag = ((const char *(*)(id, SEL))objc_msgSend)(arenaView, tagSelector);
        if(tag != NULL)
            rawTag = [NSString stringWithUTF8String:tag] ?: @"";
    }

    NSString *joined = [[className stringByAppendingString:@" "] stringByAppendingString:rawTag].lowercaseString;
    if([joined containsString:@"burst"])
        return @"\u30d0\u30fc\u30b9\u30c8";
    if([joined containsString:@"classic"])
        return @"\u30af\u30e9\u30b7\u30c3\u30af";

    return @"\u4e0d\u660e";
}

static NSString *ASLShortClassName(id object) {
    if(object == nil)
        return @"\u4e0d\u660e";

    NSString *className = NSStringFromClass([object class]);
    return className.length > 0 ? className : @"\u4e0d\u660e";
}

static NSString *ASLBoolText(BOOL known, BOOL value) {
    if(!known)
        return @"\u4e0d\u660e";
    return value ? @"YES" : @"NO";
}

static NSString *ASLCurrentServerInfoText() {
    NSString *partyCode = ASLCurrentPartyCodeText();
    NSString *mode = ASLCurrentGameModeText();
    return [NSString stringWithFormat:@"\u30d1\u30fc\u30c6\u30a3\u30fc: %@\n\u30e2\u30fc\u30c9: %@",
                                      partyCode,
                                      mode];
}

static void ASLShowPartyInfoOverlay() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil)
        return;

    UIView *overlay = [[UIView alloc] initWithFrame:CGRectZero];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.userInteractionEnabled = NO;
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
    overlay.layer.cornerRadius = 12.0;
    overlay.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28].CGColor;
    overlay.layer.borderWidth = 1.0;
    overlay.alpha = 0.0;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = ASLYujiBokuFont(18.0, YES);
    label.text = ASLCurrentServerInfoText();

    [overlay addSubview:label];
    [window addSubview:overlay];

    [NSLayoutConstraint activateConstraints:@[
        [overlay.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
        [overlay.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:18.0],
        [overlay.widthAnchor constraintLessThanOrEqualToAnchor:window.widthAnchor multiplier:0.86],
        [label.topAnchor constraintEqualToAnchor:overlay.topAnchor constant:14.0],
        [label.leadingAnchor constraintEqualToAnchor:overlay.leadingAnchor constant:18.0],
        [label.trailingAnchor constraintEqualToAnchor:overlay.trailingAnchor constant:-18.0],
        [label.bottomAnchor constraintEqualToAnchor:overlay.bottomAnchor constant:-14.0]
    ]];

    [UIView animateWithDuration:0.18 animations:^{
        overlay.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        [UIView animateWithDuration:0.25 delay:2.75 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            overlay.alpha = 0.0;
        } completion:^(__unused BOOL done) {
            [overlay removeFromSuperview];
        }];
    }];
}

static void ShowServerInfoOverlay() {
    dispatch_async(dispatch_get_main_queue(), ^{
        ASLShowPartyInfoOverlay();
    });
}

@interface KukioModMenuIconLongPressHandler : NSObject
- (void)handleMenuIconLongPress:(UILongPressGestureRecognizer *)gesture;
@end

@implementation KukioModMenuIconLongPressHandler

- (void)handleMenuIconLongPress:(UILongPressGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan) {
        ASLCopyCurrentPartyCodeToPasteboard();
        ASLShowPartyInfoOverlay();
    }
}

@end

static void ASLInstallMenuIconLongPress() {
    if(menu == nil)
        return;

    UIButton *menuButton = [menu getMenuButtRef];
    if(menuButton == nil)
        return;

    if(sMenuIconLongPressHandler == nil)
        sMenuIconLongPressHandler = [[KukioModMenuIconLongPressHandler alloc] init];

    for(UIGestureRecognizer *gesture in menuButton.gestureRecognizers) {
        if([gesture isKindOfClass:[UILongPressGestureRecognizer class]] &&
           gesture.view == menuButton &&
           gesture.enabled)
            return;
    }

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:sMenuIconLongPressHandler
                                                                                            action:@selector(handleMenuIconLongPress:)];
    longPress.minimumPressDuration = 1.0;
    longPress.cancelsTouchesInView = NO;
    [menuButton addGestureRecognizer:longPress];
}

static void ASLBringMenuAboveTetrisIfNeeded() {
    if(menu == nil)
        return;

    UIView *hostView = menu.superview;
    if(hostView == nil)
        return;

    [hostView bringSubviewToFront:menu];

    UIButton *menuButton = [menu getMenuButtRef];
    if(menuButton != nil && menuButton.superview != nil)
        [menuButton.superview bringSubviewToFront:menuButton];
}

static const int ASLTetrisShapes[7][4][4][4] = {
    {
        {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}},
        {{0,0,1,0},{0,0,1,0},{0,0,1,0},{0,0,1,0}},
        {{0,0,0,0},{0,0,0,0},{1,1,1,1},{0,0,0,0}},
        {{0,1,0,0},{0,1,0,0},{0,1,0,0},{0,1,0,0}}
    },
    {
        {{0,1,1,0},{0,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,1,0},{0,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,1,0},{0,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,1,0},{0,1,1,0},{0,0,0,0},{0,0,0,0}}
    },
    {
        {{0,1,0,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,1,0},{0,1,0,0},{0,0,0,0}},
        {{0,0,0,0},{1,1,1,0},{0,1,0,0},{0,0,0,0}},
        {{0,1,0,0},{1,1,0,0},{0,1,0,0},{0,0,0,0}}
    },
    {
        {{0,1,1,0},{1,1,0,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,1,0},{0,0,1,0},{0,0,0,0}},
        {{0,0,0,0},{0,1,1,0},{1,1,0,0},{0,0,0,0}},
        {{1,0,0,0},{1,1,0,0},{0,1,0,0},{0,0,0,0}}
    },
    {
        {{1,1,0,0},{0,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,0,1,0},{0,1,1,0},{0,1,0,0},{0,0,0,0}},
        {{0,0,0,0},{1,1,0,0},{0,1,1,0},{0,0,0,0}},
        {{0,1,0,0},{1,1,0,0},{1,0,0,0},{0,0,0,0}}
    },
    {
        {{1,0,0,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,1,0},{0,1,0,0},{0,1,0,0},{0,0,0,0}},
        {{0,0,0,0},{1,1,1,0},{0,0,1,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,0,0},{1,1,0,0},{0,0,0,0}}
    },
    {
        {{0,0,1,0},{1,1,1,0},{0,0,0,0},{0,0,0,0}},
        {{0,1,0,0},{0,1,0,0},{0,1,1,0},{0,0,0,0}},
        {{0,0,0,0},{1,1,1,0},{1,0,0,0},{0,0,0,0}},
        {{1,1,0,0},{0,1,0,0},{0,1,0,0},{0,0,0,0}}
    }
};

static UIColor *ASLTetrisColorForValue(int value) {
    switch(value) {
        case 1: return [UIColor colorWithRed:0.19 green:0.82 blue:0.96 alpha:1.0];
        case 2: return [UIColor colorWithRed:0.98 green:0.84 blue:0.20 alpha:1.0];
        case 3: return [UIColor colorWithRed:0.67 green:0.45 blue:0.95 alpha:1.0];
        case 4: return [UIColor colorWithRed:0.22 green:0.86 blue:0.45 alpha:1.0];
        case 5: return [UIColor colorWithRed:0.97 green:0.34 blue:0.31 alpha:1.0];
        case 6: return [UIColor colorWithRed:0.30 green:0.48 blue:0.95 alpha:1.0];
        case 7: return [UIColor colorWithRed:1.00 green:0.55 blue:0.20 alpha:1.0];
        default: return [UIColor clearColor];
    }
}

@interface KukioModTetrisView : UIView
- (CGRect)boardRect;
- (CGRect)nextPreviewRectForBoardRect:(CGRect)boardRect;
- (void)drawNextPieceInRect:(CGRect)previewRect;
@end

@implementation KukioModTetrisView {
    int _board[20][10];
    int _pieceType;
    int _nextPieceType;
    int _pieceRotation;
    int _pieceRow;
    int _pieceCol;
    NSInteger _score;
    BOOL _gameOver;
    NSTimer *_timer;
    UILabel *_titleLabel;
    UILabel *_scoreLabel;
    UIButton *_closeButton;
    UILabel *_nextLabel;
    UIButton *_leftButton;
    UIButton *_rightButton;
    UIButton *_downButton;
    UIButton *_rotateButton;
    UIButton *_hardDropButton;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self == nil)
        return nil;

    self.backgroundColor = [UIColor blackColor];
    self.clipsToBounds = YES;

    CGFloat topInset = 16.0;
    if(@available(iOS 11.0, *))
        topInset = 10.0 + self.safeAreaInsets.top;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, topInset, frame.size.width * 0.45, 34)];
    _titleLabel.text = @"\u30c6\u30c8\u30ea\u30b9";
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = ASLYujiBokuFont(24.0, YES);
    [self addSubview:_titleLabel];

    _closeButton = [self buttonWithTitle:@"Agar.io\u306b\u623b\u308b" action:@selector(closePressed)];
    _closeButton.frame = CGRectMake(frame.size.width - 142.0, topInset, 124.0, 36.0);
    [self addSubview:_closeButton];

    _scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, topInset + 36.0, frame.size.width * 0.45, 24)];
    _scoreLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
    _scoreLabel.font = ASLYujiBokuFont(17.0, YES);
    [self addSubview:_scoreLabel];

    _nextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nextLabel.text = @"NEXT";
    _nextLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
    _nextLabel.font = ASLYujiBokuFont(18.0, YES);
    _nextLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_nextLabel];

    _leftButton = [self buttonWithTitle:@"\u25c0" action:@selector(moveLeftPressed)];
    _rightButton = [self buttonWithTitle:@"\u25b6" action:@selector(moveRightPressed)];
    _downButton = [self buttonWithTitle:@"\u25bc" action:@selector(softDropPressed)];
    _rotateButton = [self buttonWithTitle:@"\u21bb" action:@selector(rotatePressed)];
    _hardDropButton = [self buttonWithTitle:@"\u21e9" action:@selector(hardDropPressed)];

    [self addSubview:_leftButton];
    [self addSubview:_rightButton];
    [self addSubview:_downButton];
    [self addSubview:_rotateButton];
    [self addSubview:_hardDropButton];

    [self resetGame];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat topInset = 16.0;
    CGFloat bottomInset = 12.0;
    if(@available(iOS 11.0, *)) {
        topInset = 10.0 + self.safeAreaInsets.top;
        bottomInset = 10.0 + self.safeAreaInsets.bottom;
    }

    _titleLabel.frame = CGRectMake(18.0, topInset, self.bounds.size.width * 0.45, 34.0);
    _scoreLabel.frame = CGRectMake(18.0, topInset + 36.0, self.bounds.size.width * 0.45, 24.0);
    _closeButton.frame = CGRectMake(self.bounds.size.width - 142.0, topInset, 124.0, 36.0);

    CGRect boardRect = [self boardRect];
    CGFloat buttonSize = MAX(44.0, MIN(58.0, self.bounds.size.height * 0.15));
    CGFloat gap = 7.0;
    CGFloat dpadCenterX = floor(MAX(52.0 + buttonSize * 0.5, boardRect.origin.x * 0.5));
    CGFloat dpadCenterY = floor(CGRectGetMidY(boardRect));
    if(self.bounds.size.width <= self.bounds.size.height) {
        dpadCenterX = floor(24.0 + buttonSize);
        dpadCenterY = self.bounds.size.height - bottomInset - buttonSize * 1.25;
    }

    _leftButton.frame = CGRectMake(dpadCenterX - buttonSize - gap, dpadCenterY - buttonSize * 0.5, buttonSize, buttonSize);
    _rightButton.frame = CGRectMake(dpadCenterX + gap, dpadCenterY - buttonSize * 0.5, buttonSize, buttonSize);
    _downButton.frame = CGRectMake(dpadCenterX - buttonSize * 0.5, dpadCenterY + buttonSize * 0.5 + gap, buttonSize, buttonSize);

    CGFloat actionX = floor(CGRectGetMaxX(boardRect) + (self.bounds.size.width - CGRectGetMaxX(boardRect)) * 0.5 - buttonSize * 0.5);
    if(self.bounds.size.width <= self.bounds.size.height)
        actionX = self.bounds.size.width - 24.0 - buttonSize;
    CGFloat actionY = dpadCenterY - buttonSize - gap * 0.5;
    _rotateButton.frame = CGRectMake(actionX, actionY, buttonSize, buttonSize);
    _hardDropButton.frame = CGRectMake(actionX, actionY + buttonSize + gap, buttonSize, buttonSize);

    CGRect nextRect = [self nextPreviewRectForBoardRect:boardRect];
    _nextLabel.frame = CGRectMake(nextRect.origin.x, MAX(topInset + 48.0, nextRect.origin.y - 26.0), nextRect.size.width, 22.0);
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
    button.layer.cornerRadius = 8.0;
    button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.20].CGColor;
    button.layer.borderWidth = 1.0;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = ASLYujiBokuFont(19.0, YES);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if(self.window != nil)
        [self startTimer];
}

- (void)removeFromSuperview {
    [_timer invalidate];
    _timer = nil;
    [super removeFromSuperview];
}

- (void)startTimer {
    [_timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.45
                                             repeats:YES
                                               block:^(__unused NSTimer *timer) {
                                                   [self tick];
                                               }];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)resetGame {
    memset(_board, 0, sizeof(_board));
    _score = 0;
    _gameOver = NO;
    _nextPieceType = arc4random_uniform(7);
    [self spawnPiece];
    [self updateScoreLabel];
}

- (void)updateScoreLabel {
    _scoreLabel.text = _gameOver ? @"GAME OVER" : [NSString stringWithFormat:@"SCORE %ld", (long)_score];
}

- (void)spawnPiece {
    _pieceType = _nextPieceType;
    _nextPieceType = arc4random_uniform(7);
    _pieceRotation = 0;
    _pieceRow = 0;
    _pieceCol = 3;
    if(![self canPlaceType:_pieceType rotation:_pieceRotation row:_pieceRow col:_pieceCol]) {
        _gameOver = YES;
        [self updateScoreLabel];
    }
}

- (BOOL)canPlaceType:(int)type rotation:(int)rotation row:(int)row col:(int)col {
    for(int r = 0; r < 4; r++) {
        for(int c = 0; c < 4; c++) {
            if(ASLTetrisShapes[type][rotation][r][c] == 0)
                continue;

            int boardRow = row + r;
            int boardCol = col + c;
            if(boardCol < 0 || boardCol >= 10 || boardRow >= 20)
                return NO;
            if(boardRow >= 0 && _board[boardRow][boardCol] != 0)
                return NO;
        }
    }
    return YES;
}

- (void)lockPiece {
    for(int r = 0; r < 4; r++) {
        for(int c = 0; c < 4; c++) {
            if(ASLTetrisShapes[_pieceType][_pieceRotation][r][c] == 0)
                continue;

            int boardRow = _pieceRow + r;
            int boardCol = _pieceCol + c;
            if(boardRow >= 0 && boardRow < 20 && boardCol >= 0 && boardCol < 10)
                _board[boardRow][boardCol] = _pieceType + 1;
        }
    }
    [self clearLines];
    [self spawnPiece];
}

- (void)clearLines {
    NSInteger cleared = 0;
    for(int r = 19; r >= 0; r--) {
        BOOL full = YES;
        for(int c = 0; c < 10; c++) {
            if(_board[r][c] == 0) {
                full = NO;
                break;
            }
        }
        if(!full)
            continue;

        cleared++;
        for(int moveRow = r; moveRow > 0; moveRow--) {
            for(int c = 0; c < 10; c++)
                _board[moveRow][c] = _board[moveRow - 1][c];
        }
        for(int c = 0; c < 10; c++)
            _board[0][c] = 0;
        r++;
    }
    if(cleared > 0) {
        _score += cleared * cleared * 100;
        [self updateScoreLabel];
    }
    [self setNeedsDisplay];
}

- (void)tick {
    if(_gameOver)
        return;

    if([self canPlaceType:_pieceType rotation:_pieceRotation row:_pieceRow + 1 col:_pieceCol]) {
        _pieceRow++;
    } else {
        [self lockPiece];
    }
    [self setNeedsDisplay];
}

- (void)moveLeftPressed {
    if(!_gameOver && [self canPlaceType:_pieceType rotation:_pieceRotation row:_pieceRow col:_pieceCol - 1])
        _pieceCol--;
    [self setNeedsDisplay];
}

- (void)moveRightPressed {
    if(!_gameOver && [self canPlaceType:_pieceType rotation:_pieceRotation row:_pieceRow col:_pieceCol + 1])
        _pieceCol++;
    [self setNeedsDisplay];
}

- (void)rotatePressed {
    if(_gameOver) {
        [self resetGame];
        [self setNeedsDisplay];
        return;
    }

    int nextRotation = (_pieceRotation + 1) % 4;
    if([self canPlaceType:_pieceType rotation:nextRotation row:_pieceRow col:_pieceCol])
        _pieceRotation = nextRotation;
    [self setNeedsDisplay];
}

- (void)softDropPressed {
    if(!_gameOver)
        [self tick];
}

- (void)hardDropPressed {
    if(_gameOver)
        return;

    while([self canPlaceType:_pieceType rotation:_pieceRotation row:_pieceRow + 1 col:_pieceCol])
        _pieceRow++;

    [self lockPiece];
    _score += 12;
    [self updateScoreLabel];
    [self setNeedsDisplay];
}

- (void)closePressed {
    [self removeFromSuperview];
}

- (int)ghostRow {
    int row = _pieceRow;
    while([self canPlaceType:_pieceType rotation:_pieceRotation row:row + 1 col:_pieceCol])
        row++;
    return row;
}

- (CGRect)boardRect {
    CGFloat topReserved = 72.0;
    CGFloat bottomReserved = 22.0;
    if(@available(iOS 11.0, *)) {
        topReserved += self.safeAreaInsets.top;
        bottomReserved += self.safeAreaInsets.bottom;
    }

    CGFloat availableHeight = MAX(160.0, self.bounds.size.height - topReserved - bottomReserved);
    CGFloat availableWidth = self.bounds.size.width > self.bounds.size.height ? self.bounds.size.width * 0.44 : self.bounds.size.width - 34.0;
    CGFloat cellSize = floor(MIN(availableWidth / 10.0, availableHeight / 20.0));
    CGFloat boardWidth = cellSize * 10.0;
    CGFloat boardHeight = cellSize * 20.0;
    CGFloat x = floor((self.bounds.size.width - boardWidth) / 2.0);
    CGFloat y = floor((self.bounds.size.height - boardHeight) / 2.0);
    return CGRectMake(x, y, boardWidth, boardHeight);
}

- (CGRect)nextPreviewRectForBoardRect:(CGRect)boardRect {
    CGFloat sideWidth = self.bounds.size.width - CGRectGetMaxX(boardRect) - 18.0;
    CGFloat size = floor(MIN(112.0, MAX(72.0, sideWidth - 22.0)));
    CGFloat x = floor(CGRectGetMaxX(boardRect) + (sideWidth - size) * 0.5);
    CGFloat y = floor(boardRect.origin.y + 44.0);

    if(self.bounds.size.width <= self.bounds.size.height) {
        size = floor(MIN(86.0, self.bounds.size.width * 0.22));
        x = floor(self.bounds.size.width - size - 24.0);
        y = floor(CGRectGetMaxY(boardRect) + 22.0);
    }

    return CGRectMake(x, y, size, size);
}

- (void)drawRect:(CGRect)rect {
    CGRect boardRect = [self boardRect];
    CGFloat cellSize = boardRect.size.width / 10.0;

    [[UIColor colorWithWhite:0.01 alpha:1.0] setFill];
    UIRectFill(self.bounds);

    [[UIColor colorWithWhite:0.42 alpha:0.26] setStroke];
    UIBezierPath *gridPath = [UIBezierPath bezierPath];
    gridPath.lineWidth = 0.6;
    CGFloat startX = fmod(boardRect.origin.x, cellSize);
    CGFloat startY = fmod(boardRect.origin.y, cellSize);
    for(CGFloat x = startX; x <= self.bounds.size.width; x += cellSize) {
        [gridPath moveToPoint:CGPointMake(x, 0.0)];
        [gridPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    }
    for(CGFloat y = startY; y <= self.bounds.size.height; y += cellSize) {
        [gridPath moveToPoint:CGPointMake(0.0, y)];
        [gridPath addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    }
    [gridPath stroke];

    for(int r = 0; r < 20; r++) {
        for(int c = 0; c < 10; c++) {
            [self drawCellAtRow:r col:c value:_board[r][c] boardRect:boardRect cellSize:cellSize alpha:1.0];
        }
    }

    if(!_gameOver) {
        int ghostRow = [self ghostRow];
        if(ghostRow != _pieceRow) {
            for(int r = 0; r < 4; r++) {
                for(int c = 0; c < 4; c++) {
                    if(ASLTetrisShapes[_pieceType][_pieceRotation][r][c] != 0)
                        [self drawGhostCellAtRow:ghostRow + r col:_pieceCol + c boardRect:boardRect cellSize:cellSize];
                }
            }
        }

        for(int r = 0; r < 4; r++) {
            for(int c = 0; c < 4; c++) {
                if(ASLTetrisShapes[_pieceType][_pieceRotation][r][c] != 0)
                    [self drawCellAtRow:_pieceRow + r col:_pieceCol + c value:_pieceType + 1 boardRect:boardRect cellSize:cellSize alpha:1.0];
            }
        }
    }

    [[UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:1.0] setStroke];
    UIBezierPath *border = [UIBezierPath bezierPathWithRect:boardRect];
    border.lineWidth = 4.0;
    [border stroke];

    [self drawNextPieceInRect:[self nextPreviewRectForBoardRect:boardRect]];
}

- (void)drawCellAtRow:(int)row col:(int)col value:(int)value boardRect:(CGRect)boardRect cellSize:(CGFloat)cellSize alpha:(CGFloat)alpha {
    if(value == 0 || row < 0 || row >= 20 || col < 0 || col >= 10)
        return;

    CGRect cellRect = CGRectInset(CGRectMake(boardRect.origin.x + col * cellSize,
                                             boardRect.origin.y + row * cellSize,
                                             cellSize,
                                             cellSize),
                                  0.7,
                                  0.7);
    [[ASLTetrisColorForValue(value) colorWithAlphaComponent:alpha] setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:cellRect];
    [path fill];

    [[UIColor colorWithWhite:1.0 alpha:0.24] setStroke];
    path.lineWidth = 0.7;
    [path stroke];
}

- (void)drawGhostCellAtRow:(int)row col:(int)col boardRect:(CGRect)boardRect cellSize:(CGFloat)cellSize {
    if(row < 0 || row >= 20 || col < 0 || col >= 10)
        return;

    CGRect cellRect = CGRectInset(CGRectMake(boardRect.origin.x + col * cellSize,
                                             boardRect.origin.y + row * cellSize,
                                             cellSize,
                                             cellSize),
                                  2.0,
                                  2.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:cellRect];
    CGFloat dash[] = {3.0, 3.0};
    [path setLineDash:dash count:2 phase:0.0];
    path.lineWidth = 1.3;
    [[UIColor whiteColor] setStroke];
    [path stroke];
}

- (void)drawNextPieceInRect:(CGRect)previewRect {
    if(_nextPieceType < 0 || _nextPieceType > 6)
        return;

    [[UIColor colorWithWhite:0.0 alpha:0.28] setFill];
    UIBezierPath *panel = [UIBezierPath bezierPathWithRect:previewRect];
    [panel fill];
    [[UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.82] setStroke];
    panel.lineWidth = 2.0;
    [panel stroke];

    CGFloat cellSize = floor(previewRect.size.width / 5.2);
    CGFloat blockWidth = cellSize * 4.0;
    CGFloat startX = floor(CGRectGetMidX(previewRect) - blockWidth * 0.5);
    CGFloat startY = floor(CGRectGetMidY(previewRect) - blockWidth * 0.5);

    for(int r = 0; r < 4; r++) {
        for(int c = 0; c < 4; c++) {
            if(ASLTetrisShapes[_nextPieceType][0][r][c] == 0)
                continue;

            CGRect cellRect = CGRectInset(CGRectMake(startX + c * cellSize,
                                                     startY + r * cellSize,
                                                     cellSize,
                                                     cellSize),
                                          0.8,
                                          0.8);
            UIBezierPath *cell = [UIBezierPath bezierPathWithRect:cellRect];
            [[ASLTetrisColorForValue(_nextPieceType + 1) colorWithAlphaComponent:0.96] setFill];
            [cell fill];
            [[UIColor colorWithWhite:1.0 alpha:0.24] setStroke];
            cell.lineWidth = 0.7;
            [cell stroke];
        }
    }
}

@end

static __weak KukioModTetrisView *sTetrisView = nil;

static void OpenTetrisGame() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = ASLActiveWindow();
        if(window == nil)
            return;

        if(sTetrisView != nil && sTetrisView.superview != nil) {
            [sTetrisView removeFromSuperview];
            return;
        }

        KukioModTetrisView *tetrisView = [[KukioModTetrisView alloc] initWithFrame:window.bounds];
        tetrisView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [window addSubview:tetrisView];
        sTetrisView = tetrisView;
        ASLBringMenuAboveTetrisIfNeeded();
    });
}

static NSMutableArray *sSkinQuizCachedItems = nil;

@interface KukioModSplitPracticeView : UIView
@end

@implementation KukioModSplitPracticeView {
    UILabel *_titleLabel;
    UILabel *_scoreLabel;
    UILabel *_resultLabel;
    UIButton *_closeButton;
    UIButton *_quadSplitButton;
    UIButton *_octaSplitButton;
    NSArray *_difficultyButtons;
    NSTimer *_timer;
    CGPoint _myCenter;
    CGFloat _myRadius;
    CGPoint _aimDirection;
    CGPoint _splitCellCenters[16];
    CGPoint _splitCellVelocities[16];
    CGFloat _splitCellRadii[16];
    BOOL _splitCellActive[16];
    NSInteger _splitCellCount;
    CGFloat _shotAge;
    CGFloat _myScore;
    CGPoint _enemyCenters[18];
    CGPoint _enemyVelocities[18];
    CGPoint _enemyOffsets[18];
    CGFloat _enemyRadii[18];
    BOOL _enemyActive[18];
    NSInteger _enemyTeam[18];
    NSInteger _enemyCount;
    CGPoint _enemyPackCenter;
    CGPoint _enemyPackVelocity;
    CGFloat _enemyWaveAge;
    NSInteger _feedDirection;
    BOOL _touchAiming;
    BOOL _projectileActive;
    NSInteger _splitBurstCount;
    NSInteger _difficulty;
    NSInteger _trialCount;
    NSInteger _hitCount;
    NSInteger _combo;
    CFTimeInterval _lastUpdateTime;
}

- (UIButton *)practiceButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.16];
    button.layer.cornerRadius = 8.0;
    button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.28].CGColor;
    button.layer.borderWidth = 1.0;
    button.titleLabel.font = ASLYujiBokuFont(17.0, YES);
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.62;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self == nil)
        return nil;

    self.backgroundColor = [UIColor colorWithWhite:0.02 alpha:1.0];
    self.clipsToBounds = YES;
    _difficulty = 1;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"\u5206\u88c2\u7df4\u7fd2";
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = ASLYujiBokuFont(24.0, YES);
    [self addSubview:_titleLabel];

    _scoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _scoreLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.82];
    _scoreLabel.font = ASLYujiBokuFont(17.0, YES);
    [self addSubview:_scoreLabel];

    _resultLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _resultLabel.textColor = [UIColor systemRedColor];
    _resultLabel.font = ASLYujiBokuFont(42.0, YES);
    _resultLabel.textAlignment = NSTextAlignmentCenter;
    _resultLabel.numberOfLines = 2;
    [self addSubview:_resultLabel];

    _closeButton = [self practiceButtonWithTitle:@"Agar.io\u306b\u623b\u308b" action:@selector(closePressed)];
    [self addSubview:_closeButton];

    _quadSplitButton = [self practiceButtonWithTitle:@"4\u5206\u88c2" action:@selector(quadSplitPressed)];
    _quadSplitButton.titleLabel.font = ASLYujiBokuFont(20.0, YES);
    _quadSplitButton.layer.borderColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:1.0].CGColor;
    _quadSplitButton.layer.borderWidth = 2.0;
    [self addSubview:_quadSplitButton];

    _octaSplitButton = [self practiceButtonWithTitle:@"8\u5206\u88c2" action:@selector(octaSplitPressed)];
    _octaSplitButton.titleLabel.font = ASLYujiBokuFont(20.0, YES);
    _octaSplitButton.layer.borderColor = [UIColor colorWithRed:1.0 green:0.36 blue:0.16 alpha:1.0].CGColor;
    _octaSplitButton.layer.borderWidth = 2.0;
    [self addSubview:_octaSplitButton];

    NSArray *difficultyTitles = @[@"\u521d\u7d1a", @"\u4e2d\u7d1a", @"\u4e0a\u7d1a"];
    NSMutableArray *difficultyButtons = [NSMutableArray arrayWithCapacity:difficultyTitles.count];
    for(NSUInteger i = 0; i < difficultyTitles.count; i++) {
        UIButton *button = [self practiceButtonWithTitle:[difficultyTitles objectAtIndex:i] action:@selector(difficultyPressed:)];
        button.tag = i;
        [self addSubview:button];
        [difficultyButtons addObject:button];
    }
    _difficultyButtons = [difficultyButtons copy];

    [self resetPractice];
    [self startTimer];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat topInset = 16.0;
    CGFloat bottomInset = 14.0;
    if(@available(iOS 11.0, *)) {
        topInset = 10.0 + self.safeAreaInsets.top;
        bottomInset = 10.0 + self.safeAreaInsets.bottom;
    }

    _titleLabel.frame = CGRectMake(18.0, topInset, self.bounds.size.width * 0.45, 34.0);
    _scoreLabel.frame = CGRectMake(18.0, topInset + 36.0, self.bounds.size.width * 0.58, 24.0);
    _closeButton.frame = CGRectMake(self.bounds.size.width - 142.0, topInset, 124.0, 36.0);
    _resultLabel.frame = CGRectMake(18.0, topInset + 66.0, self.bounds.size.width - 36.0, 60.0);

    CGFloat splitSize = self.bounds.size.width > self.bounds.size.height ? 82.0 : 72.0;
    _quadSplitButton.frame = CGRectMake(self.bounds.size.width - splitSize - 28.0,
                                        self.bounds.size.height - bottomInset - splitSize * 2.0 - 34.0,
                                        splitSize,
                                        splitSize);
    _octaSplitButton.frame = CGRectMake(self.bounds.size.width - splitSize - 28.0,
                                        self.bounds.size.height - bottomInset - splitSize - 22.0,
                                        splitSize,
                                        splitSize);
    _quadSplitButton.layer.cornerRadius = splitSize * 0.5;
    _octaSplitButton.layer.cornerRadius = splitSize * 0.5;

    CGFloat difficultyWidth = self.bounds.size.width > self.bounds.size.height ? 104.0 : (self.bounds.size.width - 54.0) / 3.0;
    CGFloat difficultyHeight = 38.0;
    CGFloat difficultyX = 18.0;
    CGFloat difficultyY = self.bounds.size.width > self.bounds.size.height ? CGRectGetMidY(self.bounds) - 70.0 : self.bounds.size.height - bottomInset - difficultyHeight - 22.0;
    for(NSUInteger i = 0; i < _difficultyButtons.count; i++) {
        UIButton *button = [_difficultyButtons objectAtIndex:i];
        if(self.bounds.size.width > self.bounds.size.height)
            button.frame = CGRectMake(difficultyX, difficultyY + (difficultyHeight + 8.0) * i, difficultyWidth, difficultyHeight);
        else
            button.frame = CGRectMake(difficultyX + (difficultyWidth + 9.0) * i, difficultyY, difficultyWidth, difficultyHeight);
    }

    if(CGPointEqualToPoint(_myCenter, CGPointZero))
        [self resetPractice];
}

- (void)startTimer {
    [_timer invalidate];
    _lastUpdateTime = CACurrentMediaTime();
    _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                             repeats:YES
                                               block:^(__unused NSTimer *timer) {
                                                   [self updatePractice];
                                               }];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)resetPractice {
    _trialCount = 0;
    _hitCount = 0;
    _combo = 0;
    _myScore = 22000.0;
    _aimDirection = CGPointMake(1.0, -0.12);
    [self spawnRound];
    [self updateLabels];
    [self refreshDifficultyButtons];
}

- (void)spawnRound {
    _myRadius = self.bounds.size.width > self.bounds.size.height ? 96.0 : 78.0;
    _myCenter = self.bounds.size.width > self.bounds.size.height
        ? CGPointMake(self.bounds.size.width * 0.22, self.bounds.size.height * 0.54)
        : CGPointMake(self.bounds.size.width * 0.28, self.bounds.size.height * 0.52);

    _projectileActive = NO;
    _splitCellCount = 0;
    _shotAge = 0.0;
    for(NSInteger i = 0; i < 16; i++) {
        _splitCellActive[i] = NO;
    }

    _enemyCount = _difficulty == 0 ? 10 : (_difficulty == 1 ? 14 : 16);
    _enemyWaveAge = 0.0;
    _feedDirection = 0;
    _enemyPackCenter = CGPointMake(self.bounds.size.width * 0.68, self.bounds.size.height * 0.40);
    _enemyPackVelocity = CGPointZero;
    for(NSInteger i = 0; i < 18; i++) {
        _enemyActive[i] = i < _enemyCount;
        if(!_enemyActive[i])
            continue;

        _enemyTeam[i] = i % 2;
        NSInteger local = i / 2;
        CGFloat row = (CGFloat)(local % 4) - 1.5;
        CGFloat col = (CGFloat)(local / 4);
        CGFloat side = _enemyTeam[i] == 0 ? -1.0 : 1.0;
        _enemyOffsets[i] = CGPointMake(side * (62.0 + col * 20.0),
                                       row * 28.0 + (_enemyTeam[i] == 0 ? -8.0 : 8.0));
        _enemyVelocities[i] = CGPointZero;
        if(local < 2)
            _enemyRadii[i] = _myRadius * 0.48;
        else if(local % 3 == 0)
            _enemyRadii[i] = _myRadius * 0.34;
        else
            _enemyRadii[i] = _myRadius * 0.23;
        _enemyCenters[i] = _enemyPackCenter;
    }
    _resultLabel.text = @"";
    _resultLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.70];
    [self setNeedsDisplay];
}

- (NSString *)difficultyName {
    if(_difficulty == 0)
        return @"\u521d\u7d1a";
    if(_difficulty == 2)
        return @"\u4e0a\u7d1a";
    return @"\u4e2d\u7d1a";
}

- (void)refreshDifficultyButtons {
    for(UIButton *button in _difficultyButtons) {
        BOOL selected = button.tag == _difficulty;
        button.backgroundColor = selected ? [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.42] : [[UIColor whiteColor] colorWithAlphaComponent:0.13];
        button.layer.borderColor = (selected ? [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.95] : [[UIColor whiteColor] colorWithAlphaComponent:0.22]).CGColor;
    }
}

- (void)difficultyPressed:(UIButton *)button {
    _difficulty = button.tag;
    [self resetPractice];
}

- (void)updateLabels {
    _scoreLabel.text = [NSString stringWithFormat:@"\u30b9\u30b3\u30a2 %.0f  %@", _myScore, [self difficultyName]];
}

- (CGFloat)splitRange {
    return 420.0;
}

- (CGFloat)distanceFrom:(CGPoint)a to:(CGPoint)b {
    CGFloat dx = a.x - b.x;
    CGFloat dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
}

- (CGPoint)normalizedVectorFrom:(CGPoint)a to:(CGPoint)b {
    CGFloat dx = b.x - a.x;
    CGFloat dy = b.y - a.y;
    CGFloat length = MAX(1.0, sqrt(dx * dx + dy * dy));
    return CGPointMake(dx / length, dy / length);
}

- (void)setAimTowardPoint:(CGPoint)point {
    _aimDirection = [self normalizedVectorFrom:_myCenter to:point];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if(touch == nil)
        return;
    CGPoint point = [touch locationInView:self];
    if(point.x < self.bounds.size.width * 0.72) {
        _touchAiming = YES;
        [self setAimTowardPoint:point];
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if(!_touchAiming)
        return;
    UITouch *touch = [touches anyObject];
    if(touch == nil)
        return;
    [self setAimTowardPoint:[touch locationInView:self]];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchAiming = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchAiming = NO;
}

- (void)fireSplitBurst:(NSInteger)burstCount {
    if(_projectileActive)
        return;

    _trialCount++;
    _splitBurstCount = burstCount;
    _splitCellCount = MIN(16, burstCount);
    _shotAge = 0.0;
    CGPoint direction = _aimDirection;
    CGFloat directionLength = sqrt(direction.x * direction.x + direction.y * direction.y);
    if(directionLength < 0.1)
        direction = CGPointMake(1.0, 0.0);
    CGFloat baseRadius = burstCount >= 8 ? _myRadius * 0.28 : _myRadius * 0.38;
    CGFloat speed = burstCount >= 8 ? 900.0 : 760.0;
    for(NSInteger i = 0; i < 16; i++) {
        _splitCellActive[i] = i < _splitCellCount;
        if(!_splitCellActive[i])
            continue;
        CGFloat stagger = (CGFloat)i * baseRadius * 0.52;
        _splitCellRadii[i] = baseRadius;
        _splitCellCenters[i] = CGPointMake(_myCenter.x + direction.x * (_myRadius + baseRadius + 8.0 + stagger),
                                           _myCenter.y + direction.y * (_myRadius + baseRadius + 8.0 + stagger));
        _splitCellVelocities[i] = CGPointMake(direction.x * speed, direction.y * speed);
    }
    _projectileActive = YES;
    _resultLabel.text = @"";
    [self updateLabels];
    [self setNeedsDisplay];
}

- (void)quadSplitPressed {
    [self fireSplitBurst:4];
}

- (void)octaSplitPressed {
    [self fireSplitBurst:8];
}

- (void)updatePractice {
    CFTimeInterval now = CACurrentMediaTime();
    CGFloat dt = MIN(0.05, now - _lastUpdateTime);
    _lastUpdateTime = now;

    _enemyWaveAge += dt;
    CGFloat phaseLength = _difficulty == 2 ? 1.55 : (_difficulty == 1 ? 1.85 : 2.20);
    CGFloat phase = fmod(_enemyWaveAge, phaseLength) / phaseLength;
    _feedDirection = ((NSInteger)floor(_enemyWaveAge / phaseLength)) % 2;
    CGFloat feedProgress = phase < 0.18 ? 0.0 : (phase > 0.86 ? 1.0 : (phase - 0.18) / 0.68);
    CGFloat easedFeed = 1.0 - pow(1.0 - feedProgress, 2.0);

    CGPoint blueAnchor = CGPointMake(_enemyPackCenter.x - 72.0,
                                     _enemyPackCenter.y + sin(_enemyWaveAge * 1.8) * 9.0);
    CGPoint goldAnchor = CGPointMake(_enemyPackCenter.x + 72.0,
                                     _enemyPackCenter.y + cos(_enemyWaveAge * 1.6) * 9.0);
    for(NSInteger i = 0; i < _enemyCount; i++) {
        if(!_enemyActive[i])
            continue;
        CGPoint offset = _enemyOffsets[i];
        CGPoint homeAnchor = _enemyTeam[i] == 0 ? blueAnchor : goldAnchor;
        CGPoint receiveAnchor = _enemyTeam[i] == 0 ? goldAnchor : blueAnchor;
        CGPoint home = CGPointMake(homeAnchor.x + offset.x * 0.34,
                                   homeAnchor.y + offset.y);
        CGPoint receive = CGPointMake(receiveAnchor.x - offset.x * 0.18,
                                      receiveAnchor.y + offset.y * 0.58);

        BOOL feedingCell = (i >= 4 && ((_feedDirection == 0 && _enemyTeam[i] == 0) ||
                                      (_feedDirection == 1 && _enemyTeam[i] == 1)));
        if(feedingCell) {
            CGFloat lane = sin((CGFloat)i * 1.7) * 14.0;
            _enemyCenters[i] = CGPointMake(home.x + (receive.x - home.x) * easedFeed,
                                           home.y + (receive.y - home.y) * easedFeed + lane * sin(feedProgress * 3.14159265));
        } else {
            CGFloat hold = sin(_enemyWaveAge * 3.0 + i) * 4.0;
            _enemyCenters[i] = CGPointMake(home.x, home.y + hold);
        }

        if(feedProgress >= 0.98 && feedingCell)
            _enemyRadii[i] = MAX(12.0, _enemyRadii[i] * 0.996);
    }

    if(_projectileActive) {
        _shotAge += dt;
        NSInteger activeSplitCells = 0;
        for(NSInteger i = 0; i < _splitCellCount; i++) {
            if(!_splitCellActive[i])
                continue;

            activeSplitCells++;
            _splitCellCenters[i].x += _splitCellVelocities[i].x * dt;
            _splitCellCenters[i].y += _splitCellVelocities[i].y * dt;
            _splitCellVelocities[i].x *= 0.990;
            _splitCellVelocities[i].y *= 0.990;

            for(NSInteger j = 0; j < _enemyCount; j++) {
                if(!_enemyActive[j])
                    continue;
                CGFloat distance = [self distanceFrom:_splitCellCenters[i] to:_enemyCenters[j]];
                if(distance <= _splitCellRadii[i] + _enemyRadii[j] * 0.76) {
                    if(_splitCellRadii[i] > _enemyRadii[j] * 0.72) {
                        _enemyActive[j] = NO;
                        _splitCellRadii[i] = MIN(_splitCellRadii[i] + _enemyRadii[j] * 0.22, _myRadius * 0.72);
                        _myScore += _enemyRadii[j] * 55.0;
                        _hitCount++;
                    } else {
                        _splitCellActive[i] = NO;
                        activeSplitCells--;
                    }
                }
            }

            if([self distanceFrom:_myCenter to:_splitCellCenters[i]] > [self splitRange] + 180.0 ||
               !CGRectIntersectsRect(CGRectInset(self.bounds, -160.0, -160.0), CGRectMake(_splitCellCenters[i].x, _splitCellCenters[i].y, 1.0, 1.0))) {
                _splitCellActive[i] = NO;
                activeSplitCells--;
            }
        }

        if(_shotAge > 1.8 || activeSplitCells <= 0) {
            _projectileActive = NO;
            [self updateLabels];
        }
        [self updateLabels];
    }

    [self setNeedsDisplay];
}

- (void)drawPumpkinCellAt:(CGPoint)center radius:(CGFloat)radius score:(NSString *)score alpha:(CGFloat)alpha {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetAlpha(context, alpha);

    [[UIColor colorWithRed:0.46 green:0.02 blue:0.30 alpha:1.0] setFill];
    UIBezierPath *outer = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - radius,
                                                                            center.y - radius,
                                                                            radius * 2.0,
                                                                            radius * 2.0)];
    [outer fill];

    CGFloat innerRadius = radius * 0.88;
    [[UIColor colorWithRed:1.0 green:0.52 blue:0.05 alpha:1.0] setFill];
    UIBezierPath *inner = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - innerRadius,
                                                                            center.y - innerRadius,
                                                                            innerRadius * 2.0,
                                                                            innerRadius * 2.0)];
    [inner fill];

    [[UIColor colorWithRed:0.75 green:0.28 blue:0.02 alpha:0.46] setStroke];
    for(NSInteger i = -2; i <= 2; i++) {
        UIBezierPath *stripe = [UIBezierPath bezierPath];
        CGFloat offset = i * radius * 0.22;
        [stripe moveToPoint:CGPointMake(center.x + offset, center.y - radius * 0.62)];
        [stripe addCurveToPoint:CGPointMake(center.x + offset, center.y + radius * 0.62)
                   controlPoint1:CGPointMake(center.x + offset - radius * 0.18, center.y - radius * 0.18)
                   controlPoint2:CGPointMake(center.x + offset - radius * 0.18, center.y + radius * 0.18)];
        stripe.lineWidth = MAX(1.0, radius * 0.035);
        [stripe stroke];
    }

    [[UIColor colorWithWhite:0.02 alpha:1.0] setFill];
    UIBezierPath *leftEye = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - radius * 0.34, center.y - radius * 0.18, radius * 0.16, radius * 0.16)];
    [leftEye fill];
    UIBezierPath *rightEye = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x + radius * 0.18, center.y - radius * 0.18, radius * 0.16, radius * 0.16)];
    [rightEye fill];
    UIBezierPath *mouth = [UIBezierPath bezierPath];
    [mouth moveToPoint:CGPointMake(center.x - radius * 0.28, center.y + radius * 0.18)];
    [mouth addQuadCurveToPoint:CGPointMake(center.x + radius * 0.28, center.y + radius * 0.18)
                  controlPoint:CGPointMake(center.x, center.y + radius * 0.34)];
    mouth.lineWidth = MAX(2.0, radius * 0.045);
    [mouth stroke];

    if(score.length > 0) {
        NSDictionary *attrs = @{ NSFontAttributeName: ASLYujiBokuFont(MAX(9.0, radius * 0.16), YES),
                                 NSForegroundColorAttributeName: [UIColor whiteColor],
                                 NSStrokeColorAttributeName: [UIColor blackColor],
                                 NSStrokeWidthAttributeName: @(-3.0) };
        CGSize textSize = [score sizeWithAttributes:attrs];
        [score drawAtPoint:CGPointMake(center.x - textSize.width * 0.5,
                                       center.y - textSize.height * 0.5)
            withAttributes:attrs];
    }

    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithWhite:0.02 alpha:1.0] setFill];
    UIRectFill(self.bounds);

    CGFloat gridSize = 28.0;
    [[UIColor colorWithWhite:0.36 alpha:0.24] setStroke];
    UIBezierPath *gridPath = [UIBezierPath bezierPath];
    gridPath.lineWidth = 0.6;
    for(CGFloat x = 0.0; x <= self.bounds.size.width; x += gridSize) {
        [gridPath moveToPoint:CGPointMake(x, 0.0)];
        [gridPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    }
    for(CGFloat y = 0.0; y <= self.bounds.size.height; y += gridSize) {
        [gridPath moveToPoint:CGPointMake(0.0, y)];
        [gridPath addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    }
    [gridPath stroke];

    NSArray *pelletColors = @[
        [UIColor colorWithRed:0.86 green:0.02 blue:0.20 alpha:0.78],
        [UIColor colorWithRed:0.14 green:0.85 blue:0.18 alpha:0.78],
        [UIColor colorWithRed:0.08 green:0.72 blue:0.90 alpha:0.78],
        [UIColor colorWithRed:0.95 green:0.76 blue:0.04 alpha:0.78]
    ];
    for(NSInteger i = 0; i < 120; i++) {
        CGFloat x = fmod((CGFloat)(i * 73 + 31), MAX(1.0, self.bounds.size.width));
        CGFloat y = fmod((CGFloat)(i * 41 + 17), MAX(1.0, self.bounds.size.height));
        CGFloat r = 2.0 + (i % 4);
        UIColor *color = [pelletColors objectAtIndex:(NSUInteger)(i % pelletColors.count)];
        [color setFill];
        UIBezierPath *pellet = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x - r, y - r, r * 2.0, r * 2.0)];
        [pellet fill];
    }

    CGFloat bodyRadius = _projectileActive ? _myRadius * 0.82 : _myRadius;
    [self drawPumpkinCellAt:_myCenter radius:bodyRadius score:[NSString stringWithFormat:@"%.0f", _myScore] alpha:1.0];

    [[UIColor colorWithRed:0.95 green:0.12 blue:0.34 alpha:0.38] setStroke];
    UIBezierPath *aimLine = [UIBezierPath bezierPath];
    [aimLine moveToPoint:_myCenter];
    [aimLine addLineToPoint:CGPointMake(_myCenter.x + _aimDirection.x * 220.0,
                                        _myCenter.y + _aimDirection.y * 220.0)];
    aimLine.lineWidth = 4.0;
    [aimLine stroke];

    for(NSInteger i = _enemyCount - 1; i >= 0; i--) {
        if(!_enemyActive[i])
            continue;
        CGFloat alpha = i % 5 == 0 ? 0.98 : 0.88;
        UIColor *fill = _enemyTeam[i] == 0
            ? [UIColor colorWithRed:0.18 green:0.67 blue:1.0 alpha:alpha]
            : [UIColor colorWithRed:1.0 green:0.91 blue:0.58 alpha:alpha];
        UIColor *stroke = _enemyTeam[i] == 0
            ? [UIColor colorWithRed:0.02 green:0.20 blue:0.46 alpha:1.0]
            : [UIColor colorWithRed:0.44 green:0.30 blue:0.04 alpha:1.0];
        [fill setFill];
        UIBezierPath *enemy = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(_enemyCenters[i].x - _enemyRadii[i],
                                                                                 _enemyCenters[i].y - _enemyRadii[i],
                                                                                 _enemyRadii[i] * 2.0,
                                                                                 _enemyRadii[i] * 2.0)];
        [enemy fill];
        [stroke setStroke];
        enemy.lineWidth = 2.0;
        [enemy stroke];
        if(i % 5 == 0) {
            NSDictionary *attrs = @{ NSFontAttributeName: ASLYujiBokuFont(MAX(10.0, _enemyRadii[i] * 0.18), YES),
                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSStrokeColorAttributeName: [UIColor blackColor],
                                     NSStrokeWidthAttributeName: @(-3.0) };
            NSString *label = _enemyTeam[i] == 0 ? @"B" : @"A";
            CGSize size = [label sizeWithAttributes:attrs];
            [label drawAtPoint:CGPointMake(_enemyCenters[i].x - size.width * 0.5,
                                           _enemyCenters[i].y - size.height * 0.5)
                withAttributes:attrs];
        }
    }

    if(_projectileActive || _splitCellCount > 0) {
        for(NSInteger i = 0; i < _splitCellCount; i++) {
            if(!_splitCellActive[i])
                continue;
            [self drawPumpkinCellAt:_splitCellCenters[i]
                              radius:_splitCellRadii[i]
                               score:i == 0 ? [NSString stringWithFormat:@"%.0f", _myScore] : @""
                               alpha:1.0];
        }
    }
}

- (void)closePressed {
    [self removeFromSuperview];
}

- (void)removeFromSuperview {
    [_timer invalidate];
    _timer = nil;
    [super removeFromSuperview];
}

@end

static __weak KukioModSplitPracticeView *sSplitPracticeView = nil;

static void OpenSplitPracticeGame() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = ASLActiveWindow();
        if(window == nil)
            return;

        if(sSplitPracticeView != nil && sSplitPracticeView.superview != nil) {
            [sSplitPracticeView removeFromSuperview];
            return;
        }

        KukioModSplitPracticeView *practiceView = [[KukioModSplitPracticeView alloc] initWithFrame:window.bounds];
        practiceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [window addSubview:practiceView];
        sSplitPracticeView = practiceView;
        ASLBringMenuAboveTetrisIfNeeded();
    });
}

static NSString *ASLSkinQuizAttribute(NSString *tag, NSString *attributeName) {
    if(tag.length == 0 || attributeName.length == 0)
        return nil;

    NSString *pattern = [NSString stringWithFormat:@"%@=[\"']([^\"']+)[\"']", attributeName];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:tag options:0 range:NSMakeRange(0, tag.length)];
    if(match == nil || match.numberOfRanges < 2)
        return nil;

    return [tag substringWithRange:[match rangeAtIndex:1]];
}

static NSString *ASLSkinQuizCleanName(NSString *name) {
    NSString *clean = [name stringByReplacingOccurrencesOfString:@"Image:" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, name.length)];
    clean = [clean stringByReplacingOccurrencesOfString:@"agario mobile skin" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, clean.length)];
    clean = [clean stringByReplacingOccurrencesOfString:@"agario skin" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, clean.length)];
    clean = [clean stringByReplacingOccurrencesOfString:@"agar.io skin" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, clean.length)];
    clean = [clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return clean;
}

static NSURL *ASLSkinQuizURLFromString(NSString *urlString) {
    if(urlString.length == 0)
        return nil;
    if([urlString hasPrefix:@"//"])
        urlString = [@"https:" stringByAppendingString:urlString];
    else if([urlString hasPrefix:@"/"])
        urlString = [@"https://www.agario-skins.top" stringByAppendingString:urlString];
    return [NSURL URLWithString:urlString];
}

static NSArray *ASLSkinQuizParseItemsFromHTML(NSString *html) {
    if(html.length == 0)
        return @[];

    NSMutableArray *items = [NSMutableArray array];
    NSMutableSet *seenNames = [NSMutableSet set];
    NSRegularExpression *tagRegex = [NSRegularExpression regularExpressionWithPattern:@"<img[^>]*>"
                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                error:nil];
    NSArray *matches = [tagRegex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
    for(NSTextCheckingResult *match in matches) {
        NSString *tag = [html substringWithRange:match.range];
        NSString *src = ASLSkinQuizAttribute(tag, @"src");
        NSString *alt = ASLSkinQuizAttribute(tag, @"alt");
        NSString *name = ASLSkinQuizCleanName(alt ?: @"");
        NSURL *url = ASLSkinQuizURLFromString(src);
        if(name.length < 2 || url == nil)
            continue;
        if([seenNames containsObject:name])
            continue;

        [seenNames addObject:name];
        [items addObject:@{@"name": name, @"url": url.absoluteString}];
    }
    return items;
}

@interface KukioModSkinQuizView : UIView
@end

@implementation KukioModSkinQuizView {
    UILabel *_titleLabel;
    UILabel *_statusLabel;
    UILabel *_scoreLabel;
    UILabel *_resultLabel;
    UIButton *_closeButton;
    UIView *_imageClipView;
    UIImageView *_skinImageView;
    NSArray *_answerButtons;
    NSArray *_difficultyButtons;
    NSArray *_items;
    NSDictionary *_answerItem;
    NSURLSessionDataTask *_listTask;
    NSMutableArray *_listTasks;
    NSURLSessionDataTask *_imageTask;
    NSInteger _score;
    NSInteger _streak;
    NSInteger _questionCount;
    NSInteger _correctCount;
    NSInteger _missCount;
    NSInteger _difficulty;
    BOOL _showingAnswer;
    BOOL _quizGameOver;
    BOOL _loading;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self == nil)
        return nil;

    self.backgroundColor = [UIColor blackColor];
    self.clipsToBounds = YES;
    _listTasks = [NSMutableArray array];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"\u30b9\u30ad\u30f3\u30af\u30a4\u30ba";
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = ASLYujiBokuFont(24.0, YES);
    [self addSubview:_titleLabel];

    _closeButton = [self quizButtonWithTitle:@"Agar.io\u306b\u623b\u308b" action:@selector(closePressed)];
    [self addSubview:_closeButton];

    _scoreLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _scoreLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.86];
    _scoreLabel.font = ASLYujiBokuFont(17.0, YES);
    [self addSubview:_scoreLabel];

    _resultLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _resultLabel.textColor = [UIColor systemRedColor];
    _resultLabel.font = ASLYujiBokuFont(76.0, YES);
    _resultLabel.textAlignment = NSTextAlignmentCenter;
    _resultLabel.alpha = 0.0;
    [self addSubview:_resultLabel];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.text = @"Loading skins...";
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.font = ASLYujiBokuFont(18.0, YES);
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 2;
    [self addSubview:_statusLabel];

    _imageClipView = [[UIView alloc] initWithFrame:CGRectZero];
    _imageClipView.clipsToBounds = YES;
    _imageClipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.22];
    _imageClipView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:1.0].CGColor;
    _imageClipView.layer.borderWidth = 4.0;
    [self addSubview:_imageClipView];

    _skinImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _skinImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_imageClipView addSubview:_skinImageView];

    NSArray *difficultyTitles = @[@"\u3084\u3055\u3057\u3044", @"\u3075\u3064\u3046", @"\u9b3c"];
    NSMutableArray *difficultyButtons = [NSMutableArray arrayWithCapacity:difficultyTitles.count];
    for(NSUInteger i = 0; i < difficultyTitles.count; i++) {
        UIButton *button = [self quizButtonWithTitle:[difficultyTitles objectAtIndex:i] action:@selector(difficultyPressed:)];
        button.tag = i;
        [self addSubview:button];
        [difficultyButtons addObject:button];
    }
    _difficultyButtons = [difficultyButtons copy];
    _difficulty = 1;

    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:4];
    for(int i = 0; i < 4; i++) {
        UIButton *button = [self quizButtonWithTitle:@"-" action:@selector(answerPressed:)];
        button.tag = i;
        [self addSubview:button];
        [buttons addObject:button];
    }
    _answerButtons = [buttons copy];

    [self updateScoreLabel];
    [self refreshDifficultyButtons];
    [self loadSkinListIfNeeded];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat topInset = 16.0;
    CGFloat bottomInset = 14.0;
    if(@available(iOS 11.0, *)) {
        topInset = 10.0 + self.safeAreaInsets.top;
        bottomInset = 10.0 + self.safeAreaInsets.bottom;
    }

    _titleLabel.frame = CGRectMake(18.0, topInset, self.bounds.size.width * 0.45, 34.0);
    _scoreLabel.frame = CGRectMake(18.0, topInset + 36.0, self.bounds.size.width * 0.56, 24.0);
    _closeButton.frame = CGRectMake(self.bounds.size.width - 142.0, topInset, 124.0, 36.0);

    BOOL landscape = self.bounds.size.width > self.bounds.size.height;
    CGFloat quizSize = landscape ? MIN(260.0, self.bounds.size.height - topInset - bottomInset - 98.0) : MIN(230.0, self.bounds.size.width - 54.0);
    quizSize = MAX(150.0, quizSize);
    CGFloat imageX = landscape ? floor((self.bounds.size.width - quizSize) * 0.5) : floor((self.bounds.size.width - quizSize) * 0.5);
    CGFloat imageY = landscape ? floor((self.bounds.size.height - quizSize) * 0.5) : topInset + 82.0;
    _imageClipView.frame = CGRectMake(imageX, imageY, quizSize, quizSize);
    _imageClipView.layer.cornerRadius = 10.0;

    _statusLabel.frame = CGRectMake(MAX(18.0, imageX - 20.0), CGRectGetMaxY(_imageClipView.frame) + 10.0, MIN(self.bounds.size.width - 36.0, quizSize + 40.0), 44.0);
    _resultLabel.frame = CGRectMake(_imageClipView.frame.origin.x, CGRectGetMaxY(_statusLabel.frame) + 2.0, _imageClipView.frame.size.width, 70.0);

    CGFloat buttonWidth = landscape ? MIN(220.0, (self.bounds.size.width - CGRectGetMaxX(_imageClipView.frame) - 36.0)) : self.bounds.size.width - 42.0;
    CGFloat buttonHeight = 48.0;
    CGFloat startX = landscape ? CGRectGetMaxX(_imageClipView.frame) + 24.0 : 21.0;
    CGFloat startY = landscape ? CGRectGetMidY(_imageClipView.frame) - (buttonHeight * 2.0 + 9.0) : CGRectGetMaxY(_statusLabel.frame) + 8.0;
    if(!landscape)
        startY = CGRectGetMaxY(_resultLabel.frame) + 6.0;
    for(NSUInteger i = 0; i < _answerButtons.count; i++) {
        UIButton *button = [_answerButtons objectAtIndex:i];
        button.frame = CGRectMake(startX, startY + (buttonHeight + 8.0) * i, buttonWidth, buttonHeight);
    }

    CGFloat difficultyWidth = landscape ? MIN(118.0, MAX(84.0, _imageClipView.frame.origin.x - 34.0)) : (self.bounds.size.width - 54.0) / 3.0;
    CGFloat difficultyHeight = 38.0;
    CGFloat difficultyX = landscape ? 18.0 : 18.0;
    UIButton *lastAnswerButton = (UIButton *)[_answerButtons lastObject];
    CGFloat difficultyY = landscape ? CGRectGetMidY(_imageClipView.frame) - (difficultyHeight * 1.5 + 8.0) : CGRectGetMaxY(lastAnswerButton.frame) + 12.0;
    for(NSUInteger i = 0; i < _difficultyButtons.count; i++) {
        UIButton *button = [_difficultyButtons objectAtIndex:i];
        if(landscape)
            button.frame = CGRectMake(difficultyX, difficultyY + (difficultyHeight + 8.0) * i, difficultyWidth, difficultyHeight);
        else
            button.frame = CGRectMake(difficultyX + (difficultyWidth + 9.0) * i, difficultyY, difficultyWidth, difficultyHeight);
    }

    [self layoutImageCrop];
}

- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithWhite:0.01 alpha:1.0] setFill];
    UIRectFill(self.bounds);

    CGFloat gridSize = 28.0;
    [[UIColor colorWithWhite:0.42 alpha:0.24] setStroke];
    UIBezierPath *gridPath = [UIBezierPath bezierPath];
    gridPath.lineWidth = 0.6;
    for(CGFloat x = 0.0; x <= self.bounds.size.width; x += gridSize) {
        [gridPath moveToPoint:CGPointMake(x, 0.0)];
        [gridPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    }
    for(CGFloat y = 0.0; y <= self.bounds.size.height; y += gridSize) {
        [gridPath moveToPoint:CGPointMake(0.0, y)];
        [gridPath addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    }
    [gridPath stroke];
}

- (UIButton *)quizButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.13];
    button.layer.cornerRadius = 8.0;
    button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.22].CGColor;
    button.layer.borderWidth = 1.0;
    button.titleLabel.font = ASLYujiBokuFont(17.0, YES);
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.62;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (NSString *)difficultyName {
    if(_difficulty == 0)
        return @"\u3084\u3055\u3057\u3044";
    if(_difficulty == 2)
        return @"\u9b3c";
    return @"\u3075\u3064\u3046";
}

- (CGFloat)cropScaleForDifficulty {
    if(_difficulty == 0)
        return 1.38;
    if(_difficulty == 2)
        return 4.00;
    return 1.82;
}

- (void)refreshDifficultyButtons {
    for(UIButton *button in _difficultyButtons) {
        BOOL selected = button.tag == _difficulty;
        button.backgroundColor = selected ? [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.42] : [[UIColor whiteColor] colorWithAlphaComponent:0.13];
        button.layer.borderColor = (selected ? [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.95] : [[UIColor whiteColor] colorWithAlphaComponent:0.22]).CGColor;
    }
}

- (void)difficultyPressed:(UIButton *)button {
    _difficulty = button.tag;
    [self refreshDifficultyButtons];
    if(!_showingAnswer)
        [self layoutImageCrop];
    [self updateScoreLabel];
}

- (void)loadSkinListIfNeeded {
    if(sSkinQuizCachedItems.count >= 4) {
        _items = [sSkinQuizCachedItems copy];
        [self nextQuestion];
        return;
    }

    if(_loading)
        return;
    _loading = YES;
    _statusLabel.text = @"Loading skins...";

    NSArray *urls = @[
        @"https://www.agario-skins.top/free-skins/",
        @"https://www.agario-skins.top/premium-skins/",
        @"https://www.agario-skins.top/exclusive-skins/",
        @"https://www.agario-skins.top/vip-skins/",
        @"https://www.agario-skins.top/mystery-skins/",
        @"https://www.agario-skins.top/adventure-skins/",
        @"https://www.agario-skins.top/veteran-skins/"
    ];

    __block NSInteger remaining = urls.count;
    NSMutableArray *collected = [NSMutableArray array];
    for(NSString *urlString in urls) {
        NSURL *url = [NSURL URLWithString:urlString];
        if(url == nil) {
            remaining--;
            continue;
        }

        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, __unused NSURLResponse *response, __unused NSError *error) {
            if(data.length > 0) {
                NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSArray *parsed = ASLSkinQuizParseItemsFromHTML(html);
                @synchronized(collected) {
                    [collected addObjectsFromArray:parsed];
                }
            }

            remaining--;
            if(remaining <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_loading = NO;
                    if(collected.count < 4) {
                        self->_statusLabel.text = @"Skin list load failed";
                        return;
                    }
                    sSkinQuizCachedItems = [collected mutableCopy];
                    self->_items = [sSkinQuizCachedItems copy];
                    [self nextQuestion];
                });
            }
        }];
        _listTask = task;
        [_listTasks addObject:task];
        [task resume];
    }
}

- (NSDictionary *)randomItemExcept:(NSSet *)excluded {
    if(_items.count == 0)
        return nil;

    for(int tries = 0; tries < 80; tries++) {
        NSDictionary *item = [_items objectAtIndex:arc4random_uniform((uint32_t)_items.count)];
        NSString *name = [item objectForKey:@"name"];
        if(name.length > 0 && ![excluded containsObject:name])
            return item;
    }
    return [_items firstObject];
}

- (void)nextQuestion {
    if(_quizGameOver || _items.count < 4)
        return;

    _answerItem = [self randomItemExcept:[NSSet set]];
    NSString *answerName = [_answerItem objectForKey:@"name"];
    NSMutableArray *choices = [NSMutableArray arrayWithObject:answerName ?: @"?"];
    NSMutableSet *used = [NSMutableSet setWithArray:choices];
    while(choices.count < 4) {
        NSDictionary *item = [self randomItemExcept:used];
        NSString *name = [item objectForKey:@"name"];
        if(name.length == 0 || [used containsObject:name])
            continue;
        [choices addObject:name];
        [used addObject:name];
    }

    for(NSUInteger i = choices.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [choices exchangeObjectAtIndex:i withObjectAtIndex:j];
    }

    for(NSUInteger i = 0; i < _answerButtons.count; i++) {
        UIButton *button = [_answerButtons objectAtIndex:i];
        [button setTitle:[choices objectAtIndex:i] forState:UIControlStateNormal];
        button.enabled = YES;
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.13];
    }

    _showingAnswer = NO;
    _resultLabel.alpha = 0.0;
    _statusLabel.text = @"\u3053\u306e\u30b9\u30ad\u30f3\u306e\u540d\u524d\u306f\uff1f";
    _skinImageView.image = nil;
    [self refreshDifficultyButtons];
    [self updateScoreLabel];
    [self loadAnswerImage];
}

- (NSInteger)pointForCurrentDifficulty {
    if(_difficulty == 0)
        return 1;
    if(_difficulty == 2)
        return 3;
    return 2;
}

- (void)loadAnswerImage {
    [_imageTask cancel];
    NSString *urlString = [_answerItem objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:urlString ?: @""];
    if(url == nil)
        return;

    _imageTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, __unused NSURLResponse *response, __unused NSError *error) {
        UIImage *image = data.length > 0 ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(image == nil) {
                self->_statusLabel.text = @"Image load failed";
                return;
            }
            self->_skinImageView.image = image;
            [self layoutImageCrop];
        });
    }];
    [_imageTask resume];
}

- (void)layoutImageCrop {
    if(_imageClipView.bounds.size.width <= 0.0)
        return;

    CGFloat scale = _showingAnswer ? 1.0 : [self cropScaleForDifficulty];
    CGSize size = CGSizeMake(_imageClipView.bounds.size.width * scale, _imageClipView.bounds.size.height * scale);
    CGFloat maxOffset = _showingAnswer ? 0.0 : (size.width - _imageClipView.bounds.size.width) * 0.35;
    CGFloat offsetX = _showingAnswer ? 0.0 : ((int)arc4random_uniform(100) / 100.0f - 0.5f) * maxOffset;
    CGFloat offsetY = _showingAnswer ? 0.0 : ((int)arc4random_uniform(100) / 100.0f - 0.5f) * maxOffset;
    _skinImageView.contentMode = _showingAnswer ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    _skinImageView.bounds = CGRectMake(0, 0, size.width, size.height);
    _skinImageView.center = CGPointMake(CGRectGetMidX(_imageClipView.bounds) + offsetX,
                                        CGRectGetMidY(_imageClipView.bounds) + offsetY);
}

- (void)answerPressed:(UIButton *)button {
    if(_quizGameOver)
        return;

    NSString *selected = [button titleForState:UIControlStateNormal] ?: @"";
    NSString *answer = [_answerItem objectForKey:@"name"] ?: @"";
    BOOL correct = [selected isEqualToString:answer];

    for(UIButton *choiceButton in _answerButtons)
        choiceButton.enabled = NO;

    _questionCount++;
    _showingAnswer = YES;
    [self layoutImageCrop];

    if(correct) {
        _score += [self pointForCurrentDifficulty];
        _streak++;
        _correctCount++;
        _statusLabel.text = [NSString stringWithFormat:@"\u6b63\u89e3\uff01 %@", answer];
        _resultLabel.text = @"\u25ef";
        _resultLabel.textColor = [UIColor systemRedColor];
        _resultLabel.alpha = 1.0;
        button.backgroundColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.72];
    } else {
        _streak = 0;
        _missCount++;
        _statusLabel.text = [NSString stringWithFormat:@"\u6b63\u89e3: %@", answer];
        _resultLabel.text = @"\u00d7";
        _resultLabel.textColor = [UIColor systemRedColor];
        _resultLabel.alpha = 1.0;
        button.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.72];
    }

    [self updateScoreLabel];
    if(_missCount >= 6) {
        _quizGameOver = YES;
        _statusLabel.text = [NSString stringWithFormat:@"GAME OVER  \u6b63\u89e3: %@", answer];
        for(UIButton *choiceButton in _answerButtons)
            choiceButton.enabled = NO;
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.superview != nil)
            [self nextQuestion];
    });
}

- (void)updateScoreLabel {
    NSInteger remainingMiss = MAX(0, 5 - _missCount);
    _scoreLabel.text = [NSString stringWithFormat:@"\u70b9 %ld  \u6b63\u89e3 %ld/%ld  \u6b8b\u308aMISS %ld  %@", (long)_score, (long)_correctCount, (long)_questionCount, (long)remainingMiss, [self difficultyName]];
}

- (void)closePressed {
    [self removeFromSuperview];
}

- (void)removeFromSuperview {
    [_listTask cancel];
    for(NSURLSessionDataTask *task in _listTasks)
        [task cancel];
    [_listTasks removeAllObjects];
    [_imageTask cancel];
    _listTask = nil;
    _imageTask = nil;
    [super removeFromSuperview];
}

@end

static __weak KukioModSkinQuizView *sSkinQuizView = nil;

static void OpenSkinQuizGame() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = ASLActiveWindow();
        if(window == nil)
            return;

        if(sSkinQuizView != nil && sSkinQuizView.superview != nil) {
            [sSkinQuizView removeFromSuperview];
            return;
        }

        KukioModSkinQuizView *quizView = [[KukioModSkinQuizView alloc] initWithFrame:window.bounds];
        quizView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [window addSubview:quizView];
        sSkinQuizView = quizView;
        ASLBringMenuAboveTetrisIfNeeded();
    });
}

static void ASLUpdateButtonInteractionMode() {
    if(sSplitLoopPanGesture != nil)
        sSplitLoopPanGesture.enabled = ASLButtonEditModeEnabled();

    if(sSplitLoopButton != nil) {
        ASLApplyButtonSize();
        sSplitLoopButton.alpha = ASLButtonEditModeEnabled() ? 0.78 : 1.0;
        [sSplitLoopButton setTitle:ASLButtonTitle(sSplitLoopRunning) forState:UIControlStateNormal];
    }
    ASLApplyButtonStyle();
}

static void ASLUpdateButtonVisibility() {
    if(sSplitLoopButton == nil)
        return;

    sSplitLoopButton.hidden = !ASLShowSplitButtonEnabled();
    if(sSplitLoopButton.hidden)
        ASLStopSplitLoop();
}

static void ASLFireSplit() {
    id widget = sCurrentControlsWidget;
    if(widget == nil) {
        [sSplitLoopButton setTitle:@"\u5f85\u6a5f\n\u4e2d" forState:UIControlStateNormal];
        return;
    }

    SEL splitSelector = @selector(splitButtonCallback);
    if(!ASLResponds(widget, splitSelector))
        splitSelector = @selector(maybeSplitPlayer);
    if(!ASLResponds(widget, splitSelector))
        splitSelector = @selector(splitPlayer);

    if(!ASLResponds(widget, splitSelector)) {
        [sSplitLoopButton setTitle:@"\u672a\u5bfe\u5fdc" forState:UIControlStateNormal];
        return;
    }

    @try {
        IMP imp = [widget methodForSelector:splitSelector];
        ((void (*)(id, SEL))imp)(widget, splitSelector);
        [sSplitLoopButton setTitle:ASLButtonTitle(YES) forState:UIControlStateNormal];
    }
    @catch(NSException *exception) {
        [sSplitLoopButton setTitle:@"\u30a8\u30e9\u30fc" forState:UIControlStateNormal];
    }
}

static void ASLScheduleTimer() {
    [sSplitLoopTimer invalidate];
    float interval = ASLSplitInterval();
    if(interval < 0.01f)
        interval = 0.01f;

    sSplitLoopTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       repeats:YES
                                                         block:^(__unused NSTimer *timer) {
                                                             ASLFireSplit();
                                                         }];
    [[NSRunLoop mainRunLoop] addTimer:sSplitLoopTimer forMode:NSRunLoopCommonModes];
}

static void ASLStartSplitLoop() {
    if(sSplitLoopButton == nil || !ASLShowSplitButtonEnabled() || ASLButtonEditModeEnabled())
        return;

    ASLStopSplitLoop();
    sSplitLoopRunning = YES;
    sSplitLoopButton.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.78];
    [sSplitLoopButton setTitle:ASLButtonTitle(YES) forState:UIControlStateNormal];
    ASLApplyButtonStyle();
    ASLFireSplit();
    ASLScheduleTimer();
}

static void ASLStopSplitLoop() {
    [sSplitLoopTimer invalidate];
    sSplitLoopTimer = nil;
    sSplitLoopRunning = NO;
    if(sSplitLoopButton != nil) {
        sSplitLoopButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
        [sSplitLoopButton setTitle:ASLButtonTitle(NO) forState:UIControlStateNormal];
        ASLApplyButtonStyle();
    }
}

static CGPoint ASLCurrentPlayerCenter() {
    NSArray *cellViews = ASLCurrentArenaCellViews();
    CGFloat totalX = 0.0;
    CGFloat totalY = 0.0;
    NSUInteger used = 0;
    CGFloat largestRadius = 0.0;
    CGPoint largestPosition = CGPointZero;
    BOOL hasLargestPosition = NO;
    for(id cell in cellViews) {
        if(!ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;

        CGPoint position = CGPointZero;
        if(ASLCellPosition(cell, &position)) {
            CGFloat radius = ASLEnemyScoreCellRadius(cell);
            if(radius > largestRadius) {
                largestRadius = radius;
                largestPosition = position;
                hasLargestPosition = YES;
            }
            totalX += position.x;
            totalY += position.y;
            used += 1;
        }
    }
    if(hasLargestPosition)
        return largestPosition;
    if(used > 0)
        return CGPointMake(totalX / used, totalY / used);

    id arenaView = sCurrentArenaView;
    if(arenaView != nil && ASLResponds(arenaView, NSSelectorFromString(@"playerAgarCells"))) {
        id playerCells = ((id (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"playerAgarCells"));
        if([playerCells respondsToSelector:@selector(count)] && [playerCells respondsToSelector:@selector(objectAtIndex:)]) {
            NSUInteger count = [playerCells count];
            totalX = 0.0;
            totalY = 0.0;
            used = 0;
            largestRadius = 0.0;
            hasLargestPosition = NO;
            for(NSUInteger i = 0; i < count; i++) {
                id cell = [playerCells objectAtIndex:i];
                CGPoint position = CGPointZero;
                if(ASLCellPosition(cell, &position)) {
                    CGFloat radius = ASLEnemyScoreCellRadius(cell);
                    if(radius > largestRadius) {
                        largestRadius = radius;
                        largestPosition = position;
                        hasLargestPosition = YES;
                    }
                    totalX += position.x;
                    totalY += position.y;
                    used += 1;
                }
            }
            if(hasLargestPosition)
                return largestPosition;
            if(used > 0)
                return CGPointMake(totalX / used, totalY / used);
        }
    }

    if(arenaView != nil && ASLResponds(arenaView, NSSelectorFromString(@"massCenter")))
        return ((CGPoint (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"massCenter"));

    id arenaState = sCurrentArenaState;
    if(arenaState != nil && ASLResponds(arenaState, NSSelectorFromString(@"massCenter")))
        return ((CGPoint (*)(id, SEL))objc_msgSend)(arenaState, NSSelectorFromString(@"massCenter"));

    return CGPointZero;
}

static NSArray *ASLCurrentArenaCellViews() {
    id arenaView = sCurrentArenaView;
    if(arenaView == nil || !ASLResponds(arenaView, NSSelectorFromString(@"cellViews")))
        return nil;

    id cellViews = ((id (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"cellViews"));
    if([cellViews respondsToSelector:@selector(allValues)])
        return [cellViews allValues];
    if([cellViews isKindOfClass:[NSArray class]])
        return cellViews;

    return nil;
}

static BOOL ASLCellPosition(id cell, CGPoint *position) {
    if(cell == nil || position == NULL || !ASLResponds(cell, @selector(position)))
        return NO;

    *position = ((CGPoint (*)(id, SEL))objc_msgSend)(cell, @selector(position));
    return YES;
}

static unsigned int ASLCellMass(id cell) {
    unsigned int mass = 0;
    if(ASLReadUnsignedIntIvar(cell, "_discreteClusterMass", &mass) && mass > 0)
        return mass;
    if(ASLResponds(cell, NSSelectorFromString(@"discreteClusterMass")))
        return ((unsigned int (*)(id, SEL))objc_msgSend)(cell, NSSelectorFromString(@"discreteClusterMass"));
    return 0;
}

static BOOL ASLBoolValueFromObject(id object, SEL selector) {
    double value = ASLNumericValueFromObject(object, selector);
    return value > 0.0;
}

static NSString *ASLLowercaseClassName(id object) {
    if(object == nil)
        return @"";
    return NSStringFromClass([object class]).lowercaseString ?: @"";
}

static BOOL ASLCellIsToken(id cell) {
    if(cell == nil)
        return NO;
    if(ASLBoolValueFromObject(cell, NSSelectorFromString(@"isToken")) ||
       ASLBoolValueFromObject(cell, NSSelectorFromString(@"isCoin")) ||
       ASLBoolValueFromObject(cell, NSSelectorFromString(@"isCollectible")) ||
       ASLBoolValueFromObject(cell, NSSelectorFromString(@"isCollectable")))
        return YES;

    NSString *className = ASLLowercaseClassName(cell);
    return [className containsString:@"token"] ||
           [className containsString:@"coin"] ||
           [className containsString:@"collect"];
}

static BOOL ASLCellIsPellet(id cell) {
    if(cell == nil)
        return NO;
    if(ASLBoolValueFromObject(cell, NSSelectorFromString(@"isFood")) ||
       ASLBoolValueFromObject(cell, NSSelectorFromString(@"isPellet")) ||
       ASLBoolValueFromObject(cell, NSSelectorFromString(@"isFoodCell")))
        return YES;

    NSString *className = ASLLowercaseClassName(cell);
    if([className containsString:@"food"] || [className containsString:@"pellet"])
        return YES;

    float radius = ASLEnemyScoreCellRadius(cell);
    unsigned int mass = ASLCellMass(cell);
    return radius > 0.0f && radius <= 16.0f && mass <= 5;
}

static int ASLLevelingTargetPriority(id cell) {
    if(ASLEnemyScoreSoftBodyIsVirus(cell))
        return 3;
    if(ASLCellIsToken(cell))
        return 2;
    if(ASLCellIsPellet(cell))
        return 1;
    return 0;
}

static float ASLCurrentLargestPlayerMass() {
    float largestMass = ASLEnemyScoreOwnLargestCellMass(nil);
    NSArray *cellViews = ASLCurrentArenaCellViews();
    for(id cell in cellViews) {
        if(!ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;

        unsigned int mass = ASLCellMass(cell);
        if((float)mass > largestMass)
            largestMass = (float)mass;
    }
    return largestMass;
}

static float ASLCurrentLargestPlayerRadius() {
    float largestRadius = ASLEnemyScoreOwnLargestCellRadius();
    NSArray *cellViews = ASLCurrentArenaCellViews();
    for(id cell in cellViews) {
        if(!ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;

        float radius = ASLEnemyScoreCellRadius(cell);
        if(radius > largestRadius)
            largestRadius = radius;
    }
    return largestRadius;
}

static CGFloat ASLDistanceFromPointToSegment(CGPoint point, CGPoint start, CGPoint end, CGFloat *projectionOut) {
    CGFloat dx = end.x - start.x;
    CGFloat dy = end.y - start.y;
    CGFloat lengthSq = dx * dx + dy * dy;
    if(lengthSq < 1.0) {
        if(projectionOut != NULL)
            *projectionOut = 0.0;
        CGFloat px = point.x - start.x;
        CGFloat py = point.y - start.y;
        return sqrt(px * px + py * py);
    }

    CGFloat t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSq;
    if(projectionOut != NULL)
        *projectionOut = t;
    t = MIN(1.0, MAX(0.0, t));

    CGPoint closest = CGPointMake(start.x + dx * t, start.y + dy * t);
    CGFloat px = point.x - closest.x;
    CGFloat py = point.y - closest.y;
    return sqrt(px * px + py * py);
}

static BOOL ASLVirusPathBlockedByEnemy(CGPoint playerCenter, CGPoint virusPosition, NSArray *cells) {
    float ownRadius = ASLCurrentLargestPlayerRadius();
    if(ownRadius <= 0.0f)
        ownRadius = 32.0f;

    for(id cell in cells) {
        if(ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;
        if(ASLEnemyScoreSoftBodyIsPartyCell(cell))
            continue;
        if(ASLEnemyScoreSoftBodyIsVirus(cell))
            continue;
        if(ASLLevelingTargetPriority(cell) > 0)
            continue;

        float enemyRadius = ASLEnemyScoreCellRadius(cell);
        if(enemyRadius < 18.0f)
            continue;

        CGPoint enemyPosition = CGPointZero;
        if(!ASLCellPosition(cell, &enemyPosition))
            continue;

        CGFloat projection = 0.0;
        CGFloat distance = ASLDistanceFromPointToSegment(enemyPosition, playerCenter, virusPosition, &projection);
        if(projection <= 0.05 || projection >= 0.98)
            continue;

        CGFloat clearance = enemyRadius + ownRadius * 0.55f + 18.0f;
        if(distance < clearance)
            return YES;
    }

    return NO;
}

static BOOL ASLNearestLevelingTargetPosition(CGPoint *targetPosition) {
    if(targetPosition == NULL)
        return NO;

    CGPoint playerCenter = ASLCurrentPlayerCenter();
    NSArray *cells = ASLCurrentArenaCellViews();
    CGFloat bestDistanceSq = CGFLOAT_MAX;
    int bestPriority = 0;
    BOOL found = NO;
    BOOL hasVisibleVirus = NO;

    for(id cell in cells) {
        if(ASLEnemyScoreSoftBodyIsPlayerOwned(cell) || ASLEnemyScoreSoftBodyIsPartyCell(cell))
            continue;
        if(ASLEnemyScoreSoftBodyIsVirus(cell)) {
            hasVisibleVirus = YES;
            break;
        }
    }

    for(id cell in cells) {
        if(ASLEnemyScoreSoftBodyIsPlayerOwned(cell) || ASLEnemyScoreSoftBodyIsPartyCell(cell))
            continue;

        if(hasVisibleVirus && !ASLEnemyScoreSoftBodyIsVirus(cell))
            continue;

        int priority = ASLLevelingTargetPriority(cell);
        if(priority <= 0)
            continue;
        if(priority < bestPriority)
            continue;

        CGPoint cellPosition = CGPointZero;
        if(!ASLCellPosition(cell, &cellPosition))
            continue;

        CGFloat dx = cellPosition.x - playerCenter.x;
        CGFloat dy = cellPosition.y - playerCenter.y;
        CGFloat distanceSq = dx * dx + dy * dy;
        if(priority > bestPriority || distanceSq < bestDistanceSq) {
            bestPriority = priority;
            bestDistanceSq = distanceSq;
            *targetPosition = cellPosition;
            found = YES;
        }
    }

    return found;
}

static BOOL ASLTrackedPartyFriendPosition(CGPoint *targetPosition, int *ownerIdOut) {
    id tracker = sCurrentFriendTrackerWidget;
    if(tracker == nil || ![NSStringFromClass([tracker class]) containsString:@"FriendTracker"]) {
        if(!sTrackedFriendPositionValid || targetPosition == NULL)
            return NO;
        *targetPosition = sTrackedFriendPosition;
        if(ownerIdOut != NULL)
            *ownerIdOut = sTrackedFriendOwnerId;
        return YES;
    }

    Ivar ivar = NULL;
    Class currentClass = object_getClass(tracker);
    while(currentClass != Nil && currentClass != [NSObject class]) {
        ivar = class_getInstanceVariable(currentClass, "_friendToTrack");
        if(ivar != NULL)
            break;
        currentClass = class_getSuperclass(currentClass);
    }
    if(ivar == NULL) {
        if(!sTrackedFriendPositionValid || targetPosition == NULL)
            return NO;
        *targetPosition = sTrackedFriendPosition;
        if(ownerIdOut != NULL)
            *ownerIdOut = sTrackedFriendOwnerId;
        return YES;
    }

    ptrdiff_t offset = ivar_getOffset(ivar);
    uint8_t *base = (uint8_t *)(__bridge void *)tracker + offset;
    int ownerId = *(int *)base;
    BOOL isAlive = *(BOOL *)(base + 8);
    float x = *(float *)(base + 12);
    float y = *(float *)(base + 16);

    if(ownerId <= 0 || !isAlive || !isfinite(x) || !isfinite(y))
        goto fallback;
    if(fabsf(x) < 0.01f && fabsf(y) < 0.01f)
        goto fallback;
    if(fabsf(x) > 20000.0f || fabsf(y) > 20000.0f)
        goto fallback;

    sTrackedFriendOwnerId = ownerId;
    sTrackedFriendPosition = CGPointMake(x, y);
    sTrackedFriendAvatarUrl = [ASLDebugNSStringFromLibcppString(base + 24) copy];
    sTrackedFriendNickname = [ASLDebugNSStringFromLibcppString(base + 48) copy];
    sTrackedFriendPositionValid = YES;
    sTrackedFriendPositionTime = CACurrentMediaTime();

fallback:
    if(!sTrackedFriendPositionValid || targetPosition == NULL)
        return NO;

    *targetPosition = sTrackedFriendPosition;
    if(ownerIdOut != NULL)
        *ownerIdOut = sTrackedFriendOwnerId;
    return YES;
}

static void ASLSendArenaDirection(CGPoint direction) {
    id widget = sCurrentControlsWidget;
    if(widget != nil && ASLResponds(widget, NSSelectorFromString(@"onInputAxisChangedCallback:priority:"))) {
        ((void (*)(id, SEL, CGPoint, int))objc_msgSend)(widget,
                                                        NSSelectorFromString(@"onInputAxisChangedCallback:priority:"),
                                                        direction,
                                                        3);
        return;
    }
}

static BOOL ASLChaseNearestVirusOnce() {
    CGPoint targetPosition = CGPointZero;
    if(!ASLNearestLevelingTargetPosition(&targetPosition))
        return NO;

    CGPoint playerCenter = ASLCurrentPlayerCenter();
    CGFloat dx = targetPosition.x - playerCenter.x;
    CGFloat dy = targetPosition.y - playerCenter.y;
    CGFloat length = sqrt(dx * dx + dy * dy);
    if(length < 1.0)
        return NO;

    ASLSendArenaDirection(CGPointMake(dx / length, dy / length));
    return YES;
}

static BOOL ASLChaseTrackedPartyFriendOnce() {
    CGPoint targetPosition = CGPointZero;
    if(!ASLTrackedPartyFriendPosition(&targetPosition, NULL))
        return NO;

    CGPoint playerCenter = ASLCurrentPlayerCenter();
    CGFloat dx = targetPosition.x - playerCenter.x;
    CGFloat dy = targetPosition.y - playerCenter.y;
    CGFloat length = sqrt(dx * dx + dy * dy);
    if(length < 24.0)
        return NO;

    ASLSendArenaDirection(CGPointMake(dx / length, dy / length));
    return YES;
}

static BOOL ASLAvatarUrlLooksLoggedIn(NSString *avatarUrl) {
    avatarUrl = ASLTrimmedString(avatarUrl);
    if(avatarUrl.length == 0)
        return NO;

    NSString *lower = avatarUrl.lowercaseString;
    if([lower containsString:@"profilepic_guest.png"])
        return NO;
    if([lower containsString:@"guest"])
        return NO;
    return YES;
}

static BOOL ASLTrackedFriendLooksLoggedIn() {
    return ASLAvatarUrlLooksLoggedIn(sTrackedFriendAvatarUrl);
}

static BOOL ASLPointLooksValidArenaPosition(CGPoint position) {
    return isfinite(position.x) && isfinite(position.y) &&
           (fabs(position.x) > 0.01 || fabs(position.y) > 0.01) &&
           fabs(position.x) < 20000.0 && fabs(position.y) < 20000.0;
}

static NSString *ASLCompactDebugString(NSString *value) {
    if(value.length == 0)
        return @"(empty)";

    NSMutableString *clean = [NSMutableString stringWithCapacity:MIN(value.length, (NSUInteger)140)];
    for(NSUInteger index = 0; index < value.length && clean.length < 140; index++) {
        unichar ch = [value characterAtIndex:index];
        if(ch == '\n' || ch == '\r' || ch == '\t') {
            [clean appendString:@" "];
        } else if(ch >= 0x20 && ch != 0x7F) {
            [clean appendFormat:@"%C", ch];
        }
    }
    if(clean.length == 0)
        return @"(empty)";
    if(value.length > clean.length)
        [clean appendString:@"..."];
    return clean;
}

static void ASLInspectFriendMemberRange(NSMutableString *debug,
                                        const uint8_t *begin,
                                        NSUInteger count,
                                        CGPoint playerPosition,
                                        NSString *label) {
    NSUInteger elementSize = sizeof(ASLArenaPartyMemberPair);
    [debug appendFormat:@"%@ count=%lu elementSize=%lu\n", label, (unsigned long)count, (unsigned long)elementSize];

    CGFloat bestDistanceSq = sNearestLoginFriendPositionValid ? 0.0 : CGFLOAT_MAX;
    if(sNearestLoginFriendPositionValid) {
        CGFloat dx = sNearestLoginFriendPosition.x - playerPosition.x;
        CGFloat dy = sNearestLoginFriendPosition.y - playerPosition.y;
        bestDistanceSq = dx * dx + dy * dy;
    }

    for(NSUInteger index = 0; index < count && index < 16; index++) {
        const uint8_t *base = begin + elementSize * index;
        int ownerId = *(const int *)(base + 0);
        BOOL isAlive = *(const BOOL *)(base + 8);
        float x = *(const float *)(base + 12);
        float y = *(const float *)(base + 16);
        NSString *avatarUrl = ASLDebugNSStringFromLibcppString(base + 24);
        NSString *nickname = ASLDebugNSStringFromLibcppString(base + 48);
        BOOL isLogin = isAlive && ASLAvatarUrlLooksLoggedIn(avatarUrl);
        CGPoint position = CGPointMake(x, y);
        CGFloat dx = position.x - playerPosition.x;
        CGFloat dy = position.y - playerPosition.y;
        CGFloat distanceSq = dx * dx + dy * dy;

        [debug appendFormat:@"%@ member %lu owner=%d alive=%@ pos=(%.1f, %.1f) login=%@ avatar=%@ nick=%@\n",
                            label,
                            (unsigned long)index,
                            ownerId,
                            isAlive ? @"YES" : @"NO",
                            x,
                            y,
                            isLogin ? @"YES" : @"NO",
                            ASLCompactDebugString(avatarUrl),
                            ASLCompactDebugString(nickname)];

        if(ownerId > 0 && isLogin && ASLPointLooksValidArenaPosition(position) && distanceSq < bestDistanceSq) {
            bestDistanceSq = distanceSq;
            sNearestLoginFriendPosition = position;
            sNearestLoginFriendOwnerId = ownerId;
            sNearestLoginFriendAvatarUrl = [avatarUrl copy];
            sNearestLoginFriendNickname = [nickname copy];
            sNearestLoginFriendPositionValid = YES;
            sNearestLoginFriendPositionTime = CACurrentMediaTime();
        }
    }

    if(sNearestLoginFriendPositionValid) {
        [debug appendFormat:@"%@ selectedNearestLogin owner=%d pos=(%.1f, %.1f) distance=%.0f\n",
                            label,
                            sNearestLoginFriendOwnerId,
                            sNearestLoginFriendPosition.x,
                            sNearestLoginFriendPosition.y,
                            sqrt(bestDistanceSq)];
    } else {
        [debug appendFormat:@"%@ selectedNearestLogin none\n", label];
    }
}

static void ASLScanFriendMemberCandidates(NSMutableString *debug,
                                          const uint8_t *baseAddress,
                                          NSString *label) {
    if(baseAddress == NULL) {
        [debug appendFormat:@"%@ candidateScan nil\n", label];
        return;
    }

    [debug appendFormat:@"%@ candidateScan base=%p\n", label, baseAddress];
    NSUInteger added = 0;
    for(NSUInteger offset = 0; offset <= 256 && added < 12; offset += 4) {
        const uint8_t *base = baseAddress + offset;
        int ownerId = *(const int *)(base + 0);
        BOOL isAlive = *(const BOOL *)(base + 8);
        float x = *(const float *)(base + 12);
        float y = *(const float *)(base + 16);
        CGPoint position = CGPointMake(x, y);
        NSString *avatarUrl = ASLDebugNSStringFromLibcppString(base + 24);
        NSString *nickname = ASLDebugNSStringFromLibcppString(base + 48);
        BOOL hasUsefulOwner = ownerId > 0 && ownerId < 10000000;
        BOOL hasUsefulPosition = ASLPointLooksValidArenaPosition(position);
        BOOL hasUsefulAvatar = avatarUrl.length > 0;
        if(!hasUsefulOwner && !hasUsefulPosition && !hasUsefulAvatar)
            continue;

        [debug appendFormat:@"%@ cand +%lu layout=pair owner=%d alive=%@ pos=(%.1f, %.1f) avatar=%@ nick=%@\n",
                            label,
                            (unsigned long)offset,
                            ownerId,
                            isAlive ? @"YES" : @"NO",
                            x,
                            y,
                            ASLCompactDebugString(avatarUrl),
                            ASLCompactDebugString(nickname)];
        added += 1;
    }

    if(added == 0)
        [debug appendFormat:@"%@ candidateScan none\n", label];
}

static void ASLScanFriendMemberCandidateLayouts(NSMutableString *debug,
                                                const uint8_t *baseAddress,
                                                NSString *label) {
    if(baseAddress == NULL) {
        [debug appendFormat:@"%@ layoutScan nil\n", label];
        return;
    }

    [debug appendFormat:@"%@ layoutScan base=%p\n", label, baseAddress];
    NSUInteger added = 0;
    for(NSUInteger offset = 0; offset <= 192 && added < 18; offset += 4) {
        const uint8_t *base = baseAddress + offset;
        struct LayoutGuess {
            const char *name;
            NSUInteger ownerOffset;
            NSUInteger aliveOffset;
            NSUInteger xOffset;
            NSUInteger yOffset;
            NSUInteger avatarOffset;
            NSUInteger nickOffset;
            BOOL hasOwner;
        };
        struct LayoutGuess layouts[] = {
            {"pair", 0, 8, 12, 16, 24, 48, YES},
            {"packedPair", 0, 4, 8, 12, 16, 40, YES},
            {"infoOnly", 0, 0, 4, 8, 16, 40, NO},
        };
        for(NSUInteger layoutIndex = 0; layoutIndex < sizeof(layouts) / sizeof(layouts[0]) && added < 18; layoutIndex++) {
            struct LayoutGuess layout = layouts[layoutIndex];
            int ownerId = layout.hasOwner ? *(const int *)(base + layout.ownerOffset) : 0;
            BOOL isAlive = *(const BOOL *)(base + layout.aliveOffset);
            float x = *(const float *)(base + layout.xOffset);
            float y = *(const float *)(base + layout.yOffset);
            CGPoint position = CGPointMake(x, y);
            NSString *avatarUrl = ASLDebugNSStringFromLibcppString(base + layout.avatarOffset);
            NSString *nickname = ASLDebugNSStringFromLibcppString(base + layout.nickOffset);
            BOOL hasUsefulOwner = ownerId > 0 && ownerId < 10000000;
            BOOL hasUsefulPosition = ASLPointLooksValidArenaPosition(position);
            BOOL hasUsefulAvatar = avatarUrl.length > 0;
            if(!hasUsefulOwner && !hasUsefulPosition && !hasUsefulAvatar)
                continue;

            [debug appendFormat:@"%@ cand +%lu layout=%s owner=%d alive=%@ pos=(%.1f, %.1f) login=%@ avatar=%@ nick=%@\n",
                                label,
                                (unsigned long)offset,
                                layout.name,
                                ownerId,
                                isAlive ? @"YES" : @"NO",
                                x,
                                y,
                                ASLAvatarUrlLooksLoggedIn(avatarUrl) ? @"YES" : @"NO",
                                ASLCompactDebugString(avatarUrl),
                                ASLCompactDebugString(nickname)];
            added += 1;
        }
    }

    if(added == 0)
        [debug appendFormat:@"%@ layoutScan none\n", label];
}

static void ASLScanFriendPointerArrayCandidates(NSMutableString *debug,
                                                const uint8_t *baseAddress,
                                                NSUInteger count,
                                                NSString *label) {
    if(baseAddress == NULL) {
        [debug appendFormat:@"%@ ptrArray nil\n", label];
        return;
    }

    [debug appendFormat:@"%@ ptrArray base=%p count=%lu\n", label, baseAddress, (unsigned long)count];
    NSUInteger inspected = 0;
    for(NSUInteger index = 0; index < count && index < 8; index++) {
        uintptr_t pointer = *(const uintptr_t *)(baseAddress + sizeof(void *) * index);
        [debug appendFormat:@"%@ ptr[%lu]=0x%llx\n",
                            label,
                            (unsigned long)index,
                            (unsigned long long)pointer];
        if(pointer <= 0x1000)
            continue;
        ASLScanFriendMemberCandidateLayouts(debug,
                                            (const uint8_t *)pointer,
                                            [NSString stringWithFormat:@"%@.ptr%lu", label, (unsigned long)index]);
        inspected += 1;
        if(inspected >= 4)
            break;
    }
}

static void ASLAppendFriendContainerRawWords(NSMutableString *debug, const uint8_t *container) {
    [debug appendString:@"containerRawWords:\n"];
    for(NSUInteger row = 0; row < 4; row++) {
        [debug appendFormat:@"  +%03lu:", (unsigned long)(row * 32)];
        for(NSUInteger column = 0; column < 4; column++) {
            NSUInteger offset = row * 32 + column * sizeof(uintptr_t);
            uintptr_t value = *(const uintptr_t *)(container + offset);
            [debug appendFormat:@" w%02lu=0x%llx", (unsigned long)(offset / sizeof(uintptr_t)), (unsigned long long)value];
        }
        [debug appendString:@"\n"];
    }
}

static void ASLAppendFriendContainerRawInts(NSMutableString *debug, const uint8_t *container) {
    [debug appendString:@"containerRawInts32:\n"];
    for(NSUInteger row = 0; row < 4; row++) {
        [debug appendFormat:@"  +%03lu:", (unsigned long)(row * 32)];
        for(NSUInteger column = 0; column < 8; column++) {
            NSUInteger offset = row * 32 + column * sizeof(uint32_t);
            uint32_t value = *(const uint32_t *)(container + offset);
            [debug appendFormat:@" i%02lu=%u", (unsigned long)(offset / sizeof(uint32_t)), (unsigned int)value];
        }
        [debug appendString:@"\n"];
    }
}

static void ASLAppendFriendContainerUsefulFloats(NSMutableString *debug, const uint8_t *container) {
    [debug appendString:@"containerUsefulFloats:\n"];
    NSUInteger added = 0;
    for(NSUInteger offset = 0; offset <= 160; offset += 4) {
        float value = *(const float *)(container + offset);
        if(!isfinite(value))
            continue;
        if(fabs(value) < 0.01 || fabs(value) > 20000.0)
            continue;

        [debug appendFormat:@"  +%03lu=%.1f\n", (unsigned long)offset, value];
        added += 1;
        if(added >= 32)
            break;
    }

    if(added == 0)
        [debug appendString:@"  none\n"];
}

static void ASLInspectFriendTrackerFriendsArgument(const void *friends, CGPoint playerPosition) {
    NSMutableString *debug = [NSMutableString stringWithString:@"[FriendTracker friends蠑墓焚]\n"];
    [debug appendFormat:@"friends=%p player=(%.1f, %.1f)\n", friends, playerPosition.x, playerPosition.y];

    sNearestLoginFriendPositionValid = NO;
    sNearestLoginFriendOwnerId = 0;
    sNearestLoginFriendAvatarUrl = nil;
    sNearestLoginFriendNickname = nil;

    if(friends == NULL) {
        [debug appendString:@"friends is NULL\n"];
        sFriendTrackerFriendsArgumentDebugText = [debug copy];
        return;
    }

    const uint8_t *container = (const uint8_t *)friends;
    uintptr_t begin = *(const uintptr_t *)(container + 0);
    uintptr_t end = *(const uintptr_t *)(container + sizeof(void *));
    uintptr_t capacity = *(const uintptr_t *)(container + sizeof(void *) * 2);
    uintptr_t word3 = *(const uintptr_t *)(container + sizeof(void *) * 3);
    uintptr_t word4 = *(const uintptr_t *)(container + sizeof(void *) * 4);
    uintptr_t word5 = *(const uintptr_t *)(container + sizeof(void *) * 5);
    [debug appendFormat:@"vectorGuess begin=0x%llx end=0x%llx cap=0x%llx\n",
                        (unsigned long long)begin,
                        (unsigned long long)end,
                        (unsigned long long)capacity];
    [debug appendFormat:@"rawWords w0=0x%llx w1=0x%llx w2=0x%llx w3=0x%llx w4=0x%llx w5=0x%llx\n",
                        (unsigned long long)begin,
                        (unsigned long long)end,
                        (unsigned long long)capacity,
                        (unsigned long long)word3,
                        (unsigned long long)word4,
                        (unsigned long long)word5];
    ASLAppendFriendContainerRawWords(debug, container);
    ASLAppendFriendContainerRawInts(debug, container);
    ASLAppendFriendContainerUsefulFloats(debug, container);

    NSUInteger elementSize = sizeof(ASLArenaPartyMemberPair);
    BOOL vectorLooksPlausible = begin > 0x1000 &&
                                end >= begin &&
                                capacity >= end &&
                                (end - begin) <= elementSize * 64 &&
                                ((end - begin) % elementSize) == 0;
    if(vectorLooksPlausible) {
        NSUInteger count = (NSUInteger)((end - begin) / elementSize);
        ASLInspectFriendMemberRange(debug, (const uint8_t *)begin, count, playerPosition, @"vectorGuess");
    } else {
        [debug appendFormat:@"vectorGuess invalid elementSize=%lu\n", (unsigned long)elementSize];
    }

    BOOL pointerCountLooksPlausible = begin > 0x1000 && end > 0 && end <= 64;
    if(pointerCountLooksPlausible) {
        ASLInspectFriendMemberRange(debug, (const uint8_t *)begin, (NSUInteger)end, playerPosition, @"pointerCountGuess");
    } else {
        [debug appendString:@"pointerCountGuess invalid\n"];
    }

    ASLScanFriendMemberCandidates(debug, container, @"container");
    [debug appendString:@"word0/word2 deep scan disabled for crash safety\n"];

    sFriendTrackerFriendsArgumentDebugText = [debug copy];
}

static void ASLHideLoginFriendNavView() {
    if(sLoginFriendNavView != nil)
        sLoginFriendNavView.hidden = YES;
}

static void ASLStopLoginFriendNav() {
    [sLoginFriendNavTimer invalidate];
    sLoginFriendNavTimer = nil;
    ASLHideLoginFriendNavView();
}

static void ASLInstallLoginFriendNavView() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sLoginFriendNavView != nil)
        return;

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 98.0, 74.0)];
    view.userInteractionEnabled = NO;
    view.backgroundColor = [UIColor clearColor];

    UILabel *arrow = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 0.0, 70.0, 48.0)];
    arrow.text = @"\u25b6";
    arrow.textAlignment = NSTextAlignmentCenter;
    arrow.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.0 alpha:1.0];
    arrow.font = [UIFont boldSystemFontOfSize:44.0];
    arrow.layer.shadowColor = [UIColor blackColor].CGColor;
    arrow.layer.shadowOpacity = 0.9;
    arrow.layer.shadowRadius = 4.0;
    arrow.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [view addSubview:arrow];

    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 45.0, 98.0, 24.0)];
    text.textAlignment = NSTextAlignmentCenter;
    text.textColor = [UIColor colorWithRed:0.55 green:1.0 blue:0.0 alpha:1.0];
    text.font = ASLYujiBokuFont(13.0, YES);
    text.layer.shadowColor = [UIColor blackColor].CGColor;
    text.layer.shadowOpacity = 0.9;
    text.layer.shadowRadius = 3.0;
    text.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [view addSubview:text];

    sLoginFriendNavView = view;
    sLoginFriendNavArrowLabel = arrow;
    sLoginFriendNavTextLabel = text;
    [window addSubview:view];
    [window bringSubviewToFront:view];
}

static void ASLUpdateLoginFriendNavOnce() {
    if(!ASLLoginFriendNavEnabled() || sCurrentControlsWidget == nil) {
        ASLHideLoginFriendNavView();
        return;
    }

    CGPoint targetPosition = CGPointZero;
    int ownerId = 0;
    BOOL hasTarget = NO;
    CFTimeInterval now = CACurrentMediaTime();
    if(sNearestLoginFriendPositionValid && now - sNearestLoginFriendPositionTime < 2.0) {
        targetPosition = sNearestLoginFriendPosition;
        ownerId = sNearestLoginFriendOwnerId;
        hasTarget = YES;
    } else if(ASLTrackedPartyFriendPosition(&targetPosition, &ownerId) && ASLTrackedFriendLooksLoggedIn()) {
        hasTarget = YES;
    }

    if(!hasTarget) {
        ASLHideLoginFriendNavView();
        return;
    }

    UIWindow *window = ASLActiveWindow();
    if(window == nil) {
        ASLHideLoginFriendNavView();
        return;
    }

    ASLInstallLoginFriendNavView();
    if(sLoginFriendNavView == nil)
        return;

    CGPoint playerCenter = ASLCurrentPlayerCenter();
    CGFloat dx = targetPosition.x - playerCenter.x;
    CGFloat dy = targetPosition.y - playerCenter.y;
    CGFloat length = sqrt(dx * dx + dy * dy);
    if(length < 1.0) {
        ASLHideLoginFriendNavView();
        return;
    }

    CGFloat nx = dx / length;
    CGFloat ny = -dy / length;
    CGSize boundsSize = window.bounds.size;
    CGPoint screenCenter = CGPointMake(boundsSize.width * 0.5, boundsSize.height * 0.5);
    CGFloat radius = MIN(boundsSize.width, boundsSize.height) * 0.40;
    CGPoint navCenter = CGPointMake(screenCenter.x + nx * radius, screenCenter.y + ny * radius);
    CGFloat halfWidth = CGRectGetWidth(sLoginFriendNavView.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(sLoginFriendNavView.bounds) * 0.5;
    navCenter.x = MIN(boundsSize.width - halfWidth - 10.0, MAX(halfWidth + 10.0, navCenter.x));
    navCenter.y = MIN(boundsSize.height - halfHeight - 10.0, MAX(halfHeight + 10.0, navCenter.y));

    sLoginFriendNavView.center = navCenter;
    sLoginFriendNavView.hidden = NO;
    sLoginFriendNavArrowLabel.transform = CGAffineTransformMakeRotation(atan2(ny, nx));
    sLoginFriendNavTextLabel.text = [NSString stringWithFormat:@"%.0f", length];
    [window bringSubviewToFront:sLoginFriendNavView];
}

@interface ASLLoginFriendNavTimerHandler : NSObject
- (void)handleTimer:(NSTimer *)timer;
@end

@implementation ASLLoginFriendNavTimerHandler

- (void)handleTimer:(NSTimer *)timer {
    ASLUpdateLoginFriendNavOnce();
}

@end

static void ASLRefreshLoginFriendNav() {
    if(!ASLLoginFriendNavEnabled()) {
        ASLStopLoginFriendNav();
        return;
    }

    ASLInstallLoginFriendNavView();
    ASLUpdateLoginFriendNavOnce();
    if(sLoginFriendNavTimer == nil) {
        if(sLoginFriendNavTimerHandler == nil)
            sLoginFriendNavTimerHandler = [ASLLoginFriendNavTimerHandler new];
        sLoginFriendNavTimer = [NSTimer scheduledTimerWithTimeInterval:0.12
                                                                target:sLoginFriendNavTimerHandler
                                                              selector:@selector(handleTimer:)
                                                              userInfo:nil
                                                               repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:sLoginFriendNavTimer forMode:NSRunLoopCommonModes];
    }
}

static void ASLUpdateVirusChaseXpTracking() {
}

static void ASLFinalizeVirusChaseXpSession() {
    sVirusChaseSessionStartMass = 0.0f;
    sVirusChaseSessionBestMass = 0.0f;
}

static void ASLCaptureVirusChaseEntryXp() {
}

static void ASLFinalizeVirusChaseAccountXpAfterDelay(NSTimeInterval delay) {
}

static void ASLFinalizeVirusChaseAccountXpSession() {
    ASLFinalizeVirusChaseAccountXpAfterDelay(1.0);
    ASLFinalizeVirusChaseAccountXpAfterDelay(3.0);
}

static void ASLUpdateVirusChaseStatusLabel() {
    UIWindow *window = ASLActiveWindow();
    BOOL shouldShow = sVirusChaseDesiredRunning && sCurrentControlsWidget != nil && ASLShowVirusButtonEnabled() && !ASLVirusButtonEditModeEnabled();

    if(window == nil || !shouldShow) {
        [sVirusChaseStatusLabel removeFromSuperview];
        sVirusChaseStatusLabel = nil;
        [sVirusChaseXpLabel removeFromSuperview];
        sVirusChaseXpLabel = nil;
        return;
    }

    if(sVirusChaseStatusLabel == nil) {
        sVirusChaseStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        sVirusChaseStatusLabel.textAlignment = NSTextAlignmentCenter;
        sVirusChaseStatusLabel.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.36 alpha:1.0];
        sVirusChaseStatusLabel.font = ASLYujiBokuFont(22.0, YES);
        sVirusChaseStatusLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        sVirusChaseStatusLabel.layer.shadowOpacity = 0.85;
        sVirusChaseStatusLabel.layer.shadowRadius = 3.0;
        sVirusChaseStatusLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        sVirusChaseStatusLabel.userInteractionEnabled = NO;
        [window addSubview:sVirusChaseStatusLabel];
    } else if(sVirusChaseStatusLabel.superview != window) {
        [sVirusChaseStatusLabel removeFromSuperview];
        [window addSubview:sVirusChaseStatusLabel];
    }

    sVirusChaseStatusLabel.text = @"\u81ea\u52d5\u30ec\u30d9\u30ea\u30f3\u30b0\u4e2d";
    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 32.0, 340.0);
    sVirusChaseStatusLabel.frame = CGRectMake((CGRectGetWidth(window.bounds) - width) * 0.5,
                                              16.0 + window.safeAreaInsets.top,
                                              width,
                                              34.0);
    [window bringSubviewToFront:sVirusChaseStatusLabel];

    [sVirusChaseXpLabel removeFromSuperview];
    sVirusChaseXpLabel = nil;
    return;
}

static void ASLSuspendVirusChase() {
    [sVirusChaseTimer invalidate];
    sVirusChaseTimer = nil;
    sVirusChaseRunning = NO;

    if(sVirusChaseButton != nil) {
        sVirusChaseButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
        [sVirusChaseButton setTitle:@"\u81ea\u52d5" forState:UIControlStateNormal];
    }
    ASLUpdateVirusChaseStatusLabel();
}

static void ASLStopVirusChase() {
    sVirusChaseDesiredRunning = NO;
    ASLFinalizeVirusChaseXpSession();
    ASLSuspendVirusChase();
}

static void ASLVirusChaseTimerTick(__unused NSTimer *timer) {
    if(!ASLShowVirusButtonEnabled()) {
        ASLStopVirusChase();
        return;
    }
    if(sCurrentControlsWidget == nil || ASLVirusButtonEditModeEnabled()) {
        ASLSuspendVirusChase();
        return;
    }

    BOOL foundTarget = ASLChaseNearestVirusOnce();
    if(!foundTarget)
        ASLSendArenaDirection(CGPointZero);
    [sVirusChaseButton setTitle:@"\u81ea\u52d5" forState:UIControlStateNormal];
    ASLUpdateVirusChaseStatusLabel();
}

static void ASLStartVirusChase() {
    sVirusChaseDesiredRunning = YES;
    if(sVirusChaseButton == nil || sCurrentControlsWidget == nil || !ASLShowVirusButtonEnabled() || ASLVirusButtonEditModeEnabled())
        return;

    ASLStopFriendChase();
    ASLSuspendVirusChase();
    sVirusChaseRunning = YES;
    sVirusChaseButton.backgroundColor = [[UIColor colorWithRed:0.0 green:0.72 blue:0.42 alpha:1.0] colorWithAlphaComponent:0.82];
    ASLUpdateVirusChaseStatusLabel();
    sVirusChaseTimer = [NSTimer scheduledTimerWithTimeInterval:0.12
                                                        target:sVirusChaseGestureHandler
                                                      selector:@selector(handleTimer:)
                                                      userInfo:nil
                                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:sVirusChaseTimer forMode:NSRunLoopCommonModes];
}

static void ASLClampVirusChaseButtonToWindow() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sVirusChaseButton == nil)
        return;

    CGFloat halfWidth = CGRectGetWidth(sVirusChaseButton.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(sVirusChaseButton.bounds) * 0.5;
    CGPoint center = sVirusChaseButton.center;
    center.x = MIN(CGRectGetWidth(window.bounds) - halfWidth - 8.0, MAX(halfWidth + 8.0, center.x));
    center.y = MIN(CGRectGetHeight(window.bounds) - halfHeight - 8.0, MAX(halfHeight + 8.0, center.y));
    sVirusChaseButton.center = center;
}

static void ASLSaveVirusChaseButtonPosition() {
    if(sVirusChaseButton == nil)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:sVirusChaseButton.center.x forKey:kVirusChaseButtonCenterXKey];
    [defaults setDouble:sVirusChaseButton.center.y forKey:kVirusChaseButtonCenterYKey];
    [defaults synchronize];
}

static void ASLApplyVirusChaseButtonStyle() {
    if(sVirusChaseButton == nil)
        return;

    sVirusChaseButton.layer.cornerRadius = CGRectGetWidth(sVirusChaseButton.bounds) * 0.5;
    sVirusChaseButton.layer.borderWidth = ASLVirusButtonEditModeEnabled() ? 3.0 : 2.0;
    sVirusChaseButton.layer.borderColor = (ASLVirusButtonEditModeEnabled() ? [UIColor systemYellowColor] : [UIColor whiteColor]).CGColor;
    sVirusChaseButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    sVirusChaseButton.titleLabel.numberOfLines = 2;
    sVirusChaseButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    sVirusChaseButton.alpha = ASLVirusButtonEditModeEnabled() ? 0.78 : 1.0;
}

static void ASLUpdateVirusChaseButtonInteractionMode() {
    if(sVirusChasePanGesture != nil)
        sVirusChasePanGesture.enabled = ASLVirusButtonEditModeEnabled();

    if(sVirusChaseButton != nil) {
        ASLApplyVirusChaseButtonStyle();
        if(!sVirusChaseRunning)
            [sVirusChaseButton setTitle:@"\u81ea\u52d5" forState:UIControlStateNormal];
    }
}

static void ASLUpdateVirusChaseButtonVisibility() {
    if(sVirusChaseButton == nil)
        return;

    sVirusChaseButton.hidden = !ASLShowVirusButtonEnabled();
    if(sVirusChaseButton.hidden || ASLVirusButtonEditModeEnabled())
        ASLSuspendVirusChase();
    else if(sVirusChaseDesiredRunning && !sVirusChaseRunning)
        ASLStartVirusChase();
    else
        ASLUpdateVirusChaseStatusLabel();
}

@interface ASLVirusChaseGestureHandler : NSObject
@end

@implementation ASLVirusChaseGestureHandler

- (void)handleTimer:(NSTimer *)timer {
    ASLVirusChaseTimerTick(timer);
}

- (void)handleTouchDown:(UIButton *)button {
    if(sVirusChaseRunning || sVirusChaseDesiredRunning)
        ASLStopVirusChase();
    else
        ASLStartVirusChase();
}

- (void)handleTouchEnd:(UIButton *)button {
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if(sVirusChaseButton == nil || !ASLVirusButtonEditModeEnabled())
        return;

    if(gesture.state == UIGestureRecognizerStateBegan)
        sVirusChaseButtonPanStartCenter = sVirusChaseButton.center;

    CGPoint translation = [gesture translationInView:sVirusChaseButton.superview];
    sVirusChaseButton.center = CGPointMake(sVirusChaseButtonPanStartCenter.x + translation.x,
                                           sVirusChaseButtonPanStartCenter.y + translation.y);
    ASLClampVirusChaseButtonToWindow();

    if(gesture.state == UIGestureRecognizerStateEnded ||
       gesture.state == UIGestureRecognizerStateCancelled ||
       gesture.state == UIGestureRecognizerStateFailed)
        ASLSaveVirusChaseButtonPosition();
}

@end

static void ASLInstallVirusChaseButton() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sVirusChaseButton != nil)
        return;

    sVirusChaseGestureHandler = [ASLVirusChaseGestureHandler new];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(24.0,
                              CGRectGetMidY(window.bounds) + 88.0,
                              68.0,
                              68.0);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id savedX = [defaults objectForKey:kVirusChaseButtonCenterXKey];
    id savedY = [defaults objectForKey:kVirusChaseButtonCenterYKey];
    if(savedX != nil && savedY != nil)
        button.center = CGPointMake([(NSNumber *)savedX doubleValue], [(NSNumber *)savedY doubleValue]);

    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
    [button setTitle:@"\u81ea\u52d5" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [button addTarget:sVirusChaseGestureHandler action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:sVirusChaseGestureHandler action:@selector(handleTouchEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:sVirusChaseGestureHandler
                                                                          action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO;
    [button addGestureRecognizer:pan];
    sVirusChasePanGesture = pan;

    [window addSubview:button];
    [window bringSubviewToFront:button];
    sVirusChaseButton = button;
    ASLClampVirusChaseButtonToWindow();
    ASLUpdateVirusChaseButtonInteractionMode();
    ASLUpdateVirusChaseButtonVisibility();
}

static void ASLRefreshVirusChaseButton() {
    ASLInstallVirusChaseButton();
    ASLUpdateVirusChaseButtonInteractionMode();
    ASLUpdateVirusChaseButtonVisibility();
    ASLRefreshFriendChaseButton();
}

static void ASLSuspendFriendChase() {
    [sFriendChaseTimer invalidate];
    sFriendChaseTimer = nil;
    sFriendChaseRunning = NO;

    if(sFriendChaseButton != nil) {
        sFriendChaseButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
        [sFriendChaseButton setTitle:@"\u8ffd\u8de1" forState:UIControlStateNormal];
    }
}

static void ASLStopFriendChase() {
    sFriendChaseDesiredRunning = NO;
    ASLSuspendFriendChase();
}

static void ASLFriendChaseTimerTick(__unused NSTimer *timer) {
    if(sCurrentControlsWidget == nil || ASLVirusButtonEditModeEnabled()) {
        ASLSuspendFriendChase();
        return;
    }

    BOOL foundTarget = ASLChaseTrackedPartyFriendOnce();
    if(!foundTarget)
        [sFriendChaseButton setTitle:@"\u5f85\u6a5f" forState:UIControlStateNormal];
    else
        [sFriendChaseButton setTitle:@"\u8ffd\u8de1" forState:UIControlStateNormal];
}

static void ASLStartFriendChase() {
    sFriendChaseDesiredRunning = YES;
    if(sFriendChaseButton == nil || sCurrentControlsWidget == nil || ASLVirusButtonEditModeEnabled())
        return;

    ASLStopVirusChase();
    ASLSuspendFriendChase();
    sFriendChaseRunning = YES;
    sFriendChaseButton.backgroundColor = [[UIColor colorWithRed:0.0 green:0.45 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.84];
    [sFriendChaseButton setTitle:@"\u8ffd\u8de1" forState:UIControlStateNormal];
    sFriendChaseTimer = [NSTimer scheduledTimerWithTimeInterval:0.12
                                                         target:sFriendChaseGestureHandler
                                                       selector:@selector(handleTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:sFriendChaseTimer forMode:NSRunLoopCommonModes];
}

static void ASLClampFriendChaseButtonToWindow() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sFriendChaseButton == nil)
        return;

    CGFloat halfWidth = CGRectGetWidth(sFriendChaseButton.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(sFriendChaseButton.bounds) * 0.5;
    CGPoint center = sFriendChaseButton.center;
    center.x = MIN(CGRectGetWidth(window.bounds) - halfWidth - 8.0, MAX(halfWidth + 8.0, center.x));
    center.y = MIN(CGRectGetHeight(window.bounds) - halfHeight - 8.0, MAX(halfHeight + 8.0, center.y));
    sFriendChaseButton.center = center;
}

static void ASLSaveFriendChaseButtonPosition() {
    if(sFriendChaseButton == nil)
        return;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:sFriendChaseButton.center.x forKey:kFriendChaseButtonCenterXKey];
    [defaults setDouble:sFriendChaseButton.center.y forKey:kFriendChaseButtonCenterYKey];
    [defaults synchronize];
}

static void ASLApplyFriendChaseButtonStyle() {
    if(sFriendChaseButton == nil)
        return;

    sFriendChaseButton.layer.cornerRadius = CGRectGetWidth(sFriendChaseButton.bounds) * 0.5;
    sFriendChaseButton.layer.borderWidth = ASLVirusButtonEditModeEnabled() ? 3.0 : 2.0;
    sFriendChaseButton.layer.borderColor = (ASLVirusButtonEditModeEnabled() ? [UIColor systemYellowColor] : [UIColor whiteColor]).CGColor;
    sFriendChaseButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    sFriendChaseButton.titleLabel.numberOfLines = 2;
    sFriendChaseButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    sFriendChaseButton.alpha = ASLVirusButtonEditModeEnabled() ? 0.78 : 1.0;
}

static void ASLUpdateFriendChaseButtonInteractionMode() {
    if(sFriendChasePanGesture != nil)
        sFriendChasePanGesture.enabled = ASLVirusButtonEditModeEnabled();

    if(sFriendChaseButton != nil) {
        ASLApplyFriendChaseButtonStyle();
        if(!sFriendChaseRunning)
            [sFriendChaseButton setTitle:@"\u8ffd\u8de1" forState:UIControlStateNormal];
    }
}

static void ASLUpdateFriendChaseButtonVisibility() {
    if(sFriendChaseButton == nil)
        return;

    sFriendChaseButton.hidden = !ASLShowVirusButtonEnabled();
    if(sFriendChaseButton.hidden || ASLVirusButtonEditModeEnabled())
        ASLSuspendFriendChase();
    else if(sFriendChaseDesiredRunning && !sFriendChaseRunning)
        ASLStartFriendChase();
}

@interface ASLFriendChaseGestureHandler : NSObject
@end

@implementation ASLFriendChaseGestureHandler

- (void)handleTimer:(NSTimer *)timer {
    ASLFriendChaseTimerTick(timer);
}

- (void)handleTouchDown:(UIButton *)button {
    if(sFriendChaseRunning || sFriendChaseDesiredRunning)
        ASLStopFriendChase();
    else
        ASLStartFriendChase();
}

- (void)handleTouchEnd:(UIButton *)button {
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if(sFriendChaseButton == nil || !ASLVirusButtonEditModeEnabled())
        return;

    if(gesture.state == UIGestureRecognizerStateBegan)
        sFriendChaseButtonPanStartCenter = sFriendChaseButton.center;

    CGPoint translation = [gesture translationInView:sFriendChaseButton.superview];
    sFriendChaseButton.center = CGPointMake(sFriendChaseButtonPanStartCenter.x + translation.x,
                                            sFriendChaseButtonPanStartCenter.y + translation.y);
    ASLClampFriendChaseButtonToWindow();

    if(gesture.state == UIGestureRecognizerStateEnded ||
       gesture.state == UIGestureRecognizerStateCancelled ||
       gesture.state == UIGestureRecognizerStateFailed)
        ASLSaveFriendChaseButtonPosition();
}

@end

static void ASLInstallFriendChaseButton() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sFriendChaseButton != nil)
        return;

    sFriendChaseGestureHandler = [ASLFriendChaseGestureHandler new];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(24.0,
                              CGRectGetMidY(window.bounds) + 164.0,
                              68.0,
                              68.0);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id savedX = [defaults objectForKey:kFriendChaseButtonCenterXKey];
    id savedY = [defaults objectForKey:kFriendChaseButtonCenterYKey];
    if(savedX != nil && savedY != nil)
        button.center = CGPointMake([(NSNumber *)savedX doubleValue], [(NSNumber *)savedY doubleValue]);

    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
    [button setTitle:@"\u8ffd\u8de1" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [button addTarget:sFriendChaseGestureHandler action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:sFriendChaseGestureHandler action:@selector(handleTouchEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:sFriendChaseGestureHandler
                                                                          action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO;
    [button addGestureRecognizer:pan];
    sFriendChasePanGesture = pan;

    [window addSubview:button];
    [window bringSubviewToFront:button];
    sFriendChaseButton = button;
    ASLClampFriendChaseButtonToWindow();
    ASLUpdateFriendChaseButtonInteractionMode();
    ASLUpdateFriendChaseButtonVisibility();
}

static void ASLRefreshFriendChaseButton() {
    ASLInstallFriendChaseButton();
    ASLUpdateFriendChaseButtonInteractionMode();
    ASLUpdateFriendChaseButtonVisibility();
}

@interface ASLSplitLoopGestureHandler : NSObject
@end

@implementation ASLSplitLoopGestureHandler

- (void)handleTouchDown:(UIButton *)button {
    if(ASLSplitLoopEnabled())
        ASLStartSplitLoop();
}

- (void)handleTouchEnd:(UIButton *)button {
    ASLStopSplitLoop();
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if(sSplitLoopButton == nil || !ASLButtonEditModeEnabled())
        return;

    if(gesture.state == UIGestureRecognizerStateBegan)
        sSplitLoopButtonPanStartCenter = sSplitLoopButton.center;

    CGPoint translation = [gesture translationInView:sSplitLoopButton.superview];
    sSplitLoopButton.center = CGPointMake(sSplitLoopButtonPanStartCenter.x + translation.x,
                                          sSplitLoopButtonPanStartCenter.y + translation.y);
    ASLClampButtonToWindow();

    if(gesture.state == UIGestureRecognizerStateEnded ||
       gesture.state == UIGestureRecognizerStateCancelled ||
       gesture.state == UIGestureRecognizerStateFailed)
        ASLSaveButtonPosition();
}

@end

static ASLSplitLoopGestureHandler *sSplitLoopGestureHandler = nil;

static void ASLInstallSplitLoopButton() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sSplitLoopButton != nil)
        return;

    sSplitLoopGestureHandler = [ASLSplitLoopGestureHandler new];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(CGRectGetWidth(window.bounds) - 104.0,
                              CGRectGetHeight(window.bounds) - 160.0,
                              84.0,
                              84.0);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id savedX = [defaults objectForKey:kSplitLoopButtonCenterXKey];
    id savedY = [defaults objectForKey:kSplitLoopButtonCenterYKey];
    if(savedX != nil && savedY != nil)
        button.center = CGPointMake([(NSNumber *)savedX doubleValue], [(NSNumber *)savedY doubleValue]);

    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    button.layer.cornerRadius = 42.0;
    button.layer.borderWidth = 2.0;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.62];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setTitle:ASLButtonTitle(NO) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [button addTarget:sSplitLoopGestureHandler action:@selector(handleTouchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:sSplitLoopGestureHandler action:@selector(handleTouchEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:sSplitLoopGestureHandler
                                                                          action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO;
    [button addGestureRecognizer:pan];
    sSplitLoopPanGesture = pan;

    [window addSubview:button];
    sSplitLoopButton = button;
    ASLApplyButtonSize();
    ASLClampButtonToWindow();
    ASLUpdateButtonInteractionMode();
    ASLUpdateButtonVisibility();
}

static void ASLRefreshSplitLoop() {
    ASLInstallSplitLoopButton();
    ASLUpdateButtonVisibility();
    ASLUpdateButtonInteractionMode();

    if(!ASLSplitLoopEnabled() || ASLButtonEditModeEnabled())
        ASLStopSplitLoop();
    else if(sSplitLoopRunning) {
        [sSplitLoopButton setTitle:ASLButtonTitle(YES) forState:UIControlStateNormal];
        ASLScheduleTimer();
    } else {
        [sSplitLoopButton setTitle:ASLButtonTitle(NO) forState:UIControlStateNormal];
    }
}

static void ResetSplitLoopButtonPosition() {
    dispatch_async(dispatch_get_main_queue(), ^{
        ASLResetButtonPosition();
    });
}

static void OpenSkinMakerWebsite() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:@"https://biteyt.com/makeskins"];
        if(url == nil)
            return;

        UIApplication *application = [UIApplication sharedApplication];
        if(@available(iOS 10.0, *)) {
            [application openURL:url options:@{} completionHandler:nil];
        } else {
            [application openURL:url];
        }
    });
}

static void OpenGlitchRequestX() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:@"https://x.com/s_cookie2?s=21&t=B_VFrWwDM5AAUlypnJXMDw"];
        if(url == nil)
            return;

        UIApplication *application = [UIApplication sharedApplication];
        if(@available(iOS 10.0, *)) {
            [application openURL:url options:@{} completionHandler:nil];
        } else {
            [application openURL:url];
        }
    });
}

static void OpenDrawingRequestX() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:@"https://x.com/nayo_hh?s=21&t=B_VFrWwDM5AAUlypnJXMDw"];
        if(url == nil)
            return;

        UIApplication *application = [UIApplication sharedApplication];
        if(@available(iOS 10.0, *)) {
            [application openURL:url options:@{} completionHandler:nil];
        } else {
            [application openURL:url];
        }
    });
}

static UIViewController *ASLTopViewController() {
    UIWindow *window = ASLActiveWindow();
    UIViewController *controller = window.rootViewController;
    while(controller.presentedViewController != nil)
        controller = controller.presentedViewController;
    return controller;
}

static void ASLShowToast(NSString *text) {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || text.length == 0)
        return;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.font = ASLYujiBokuFont(15.0, YES);
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
    label.layer.cornerRadius = 10.0;
    label.clipsToBounds = YES;
    CGFloat width = MIN(CGRectGetWidth(window.bounds) - 36.0, 420.0);
    label.frame = CGRectMake((CGRectGetWidth(window.bounds) - width) * 0.5,
                             CGRectGetHeight(window.bounds) * 0.22,
                             width,
                             54.0);
    [window addSubview:label];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [label removeFromSuperview];
    });
}

static NSString *ASLSkinImportDirectory() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if(paths.count == 0)
        return nil;
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"kukiomod"];
}

static NSString *ASLSkinImportImagePath() {
    NSString *directory = ASLSkinImportDirectory();
    if(directory.length == 0)
        return nil;
    return [directory stringByAppendingPathComponent:@"skin-import.jpg"];
}

static UIImage *ASLCircleCroppedImage(UIImage *image, CGFloat side) {
    if(image == nil || side <= 0.0)
        return nil;

    CGSize size = CGSizeMake(side, side);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGRect rect = CGRectMake(0.0, 0.0, side, side);
    [[UIBezierPath bezierPathWithOvalInRect:rect] addClip];
    CGFloat scale = MAX(side / MAX(1.0, image.size.width), side / MAX(1.0, image.size.height));
    CGSize drawSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    CGRect drawRect = CGRectMake((side - drawSize.width) * 0.5,
                                 (side - drawSize.height) * 0.5,
                                 drawSize.width,
                                 drawSize.height);
    [image drawInRect:drawRect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

typedef struct {
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} ASLCCColor4B;

static UIColor *ASLUIColorFromCCColor(ASLCCColor4B color, UIColor *fallback) {
    if(color.a == 0)
        return fallback;
    return [UIColor colorWithRed:(CGFloat)color.r / 255.0
                           green:(CGFloat)color.g / 255.0
                            blue:(CGFloat)color.b / 255.0
                           alpha:(CGFloat)color.a / 255.0];
}

static UIImage *ASLCurrentImportedSkinImage() {
    if(sImportedSkinImage != nil)
        return sImportedSkinImage;

    NSString *path = ASLSkinImportImagePath();
    if(path.length > 0)
        sImportedSkinImage = [UIImage imageWithContentsOfFile:path];
    return sImportedSkinImage;
}

static CGFloat ASLSkinEditorRenderContentRatio() {
    return 0.52;
}

static CGRect ASLSkinEditorImportedImageFrameInWindow() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil)
        return CGRectZero;

    CGFloat fullSide = MIN(CGRectGetWidth(window.bounds) * 0.42, CGRectGetHeight(window.bounds) * 0.78);
    CGFloat side = fullSide * ASLSkinEditorRenderContentRatio();
    CGPoint center = CGPointMake(CGRectGetMidX(window.bounds), CGRectGetHeight(window.bounds) * 0.47);

    if(side < 120.0)
        side = 120.0;
    if(side > MIN(CGRectGetWidth(window.bounds), CGRectGetHeight(window.bounds)) * 0.62)
        side = MIN(CGRectGetWidth(window.bounds), CGRectGetHeight(window.bounds)) * 0.62;
    return CGRectMake(center.x - side * 0.5, center.y - side * 0.5, side, side);
}

static UIImage *ASLImportedSkinExportImage(BOOL includeBackground, unsigned int imageSideSize) {
    UIImage *source = ASLCurrentImportedSkinImage();
    if(source == nil)
        return nil;

    CGFloat side = imageSideSize > 0 ? (CGFloat)imageSideSize : 512.0;
    if(side < 64.0)
        side = 512.0;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect fullRect = CGRectMake(0.0, 0.0, side, side);

    if(includeBackground) {
        ASLCCColor4B backgroundColor = { 255, 255, 255, 255 };
        ASLCCColor4B borderColor = { 0, 0, 0, 255 };
        if(sSkinEditorState != nil && [sSkinEditorState respondsToSelector:NSSelectorFromString(@"getBackgroundColor")])
            backgroundColor = ((ASLCCColor4B (*)(id, SEL))objc_msgSend)(sSkinEditorState, NSSelectorFromString(@"getBackgroundColor"));
        if(sSkinEditorState != nil && [sSkinEditorState respondsToSelector:NSSelectorFromString(@"getBorderColor")])
            borderColor = ((ASLCCColor4B (*)(id, SEL))objc_msgSend)(sSkinEditorState, NSSelectorFromString(@"getBorderColor"));

        UIBezierPath *cellPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(fullRect, 1.0, 1.0)];
        [ASLUIColorFromCCColor(backgroundColor, [UIColor whiteColor]) setFill];
        [cellPath fill];

        CGFloat borderWidth = side * 0.045;
        if(sSkinEditorState != nil && [sSkinEditorState respondsToSelector:NSSelectorFromString(@"borderSize")]) {
            unsigned int borderSize = ((unsigned int (*)(id, SEL))objc_msgSend)(sSkinEditorState, NSSelectorFromString(@"borderSize"));
            if(borderSize > 0)
                borderWidth = MAX(2.0, MIN(side * 0.18, (CGFloat)borderSize));
        }
        [ASLUIColorFromCCColor(borderColor, [UIColor blackColor]) setStroke];
        cellPath.lineWidth = borderWidth;
        [cellPath stroke];
    } else {
        CGContextClearRect(context, fullRect);
    }

    CGFloat ratio = ASLSkinEditorRenderContentRatio();
    CGFloat innerSide = side * ratio;
    CGRect innerRect = CGRectMake((side - innerSide) * 0.5, (side - innerSide) * 0.5, innerSide, innerSide);
    CGContextSaveGState(context);
    [[UIBezierPath bezierPathWithOvalInRect:innerRect] addClip];
    CGFloat scale = MAX(innerSide / MAX(1.0, source.size.width), innerSide / MAX(1.0, source.size.height));
    CGSize drawSize = CGSizeMake(source.size.width * scale, source.size.height * scale);
    CGRect drawRect = CGRectMake(CGRectGetMidX(innerRect) - drawSize.width * 0.5,
                                 CGRectGetMidY(innerRect) - drawSize.height * 0.5,
                                 drawSize.width,
                                 drawSize.height);
    [source drawInRect:drawRect];
    CGContextRestoreGState(context);

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

static CGFloat ASLSkinEditorDrawingSide() {
    CGSize contentSize = CGSizeZero;
    if(sSkinEditorState != nil && [sSkinEditorState respondsToSelector:NSSelectorFromString(@"renderTextureContentSize")])
        contentSize = ((CGSize (*)(id, SEL))objc_msgSend)(sSkinEditorState, NSSelectorFromString(@"renderTextureContentSize"));

    CGFloat side = MIN(contentSize.width, contentSize.height);
    if(side < 64.0)
        side = 512.0;
    if(side > 512.0)
        side = 512.0;
    return side;
}

static UIImage *ASLResizeImageToSquare(UIImage *image, CGFloat side, BOOL circleClip) {
    if(image == nil || side <= 0.0)
        return nil;

    CGSize size = CGSizeMake(side, side);
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0.0, 0.0, side, side);
    if(circleClip)
        [[UIBezierPath bezierPathWithOvalInRect:rect] addClip];

    CGFloat scale = MAX(side / MAX(1.0, image.size.width), side / MAX(1.0, image.size.height));
    CGSize drawSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    CGRect drawRect = CGRectMake((side - drawSize.width) * 0.5,
                                 (side - drawSize.height) * 0.5,
                                 drawSize.width,
                                 drawSize.height);
    [image drawInRect:drawRect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

static void ASLMarkSkinEditorDirty() {
    if(sSkinEditorState == nil)
        return;

    ASLWriteBoolIvar(sSkinEditorState, "_hasDrawing", YES);
    if([sSkinEditorState respondsToSelector:NSSelectorFromString(@"enableSave:")])
        ((void (*)(id, SEL, BOOL))objc_msgSend)(sSkinEditorState, NSSelectorFromString(@"enableSave:"), YES);
    if(sSkinEditorView != nil && [sSkinEditorView respondsToSelector:NSSelectorFromString(@"enableSave:")])
        ((void (*)(id, SEL, BOOL))objc_msgSend)(sSkinEditorView, NSSelectorFromString(@"enableSave:"), YES);
}

static BOOL ASLApplyImportedSkinToLineDrawer() {
    UIImage *image = ASLCurrentImportedSkinImage();
    if(sSkinEditorState == nil || image == nil)
        return NO;

    id lineDrawer = ASLObjectIvar(sSkinEditorState, "_lineDrawer");
    if(lineDrawer == nil || ![lineDrawer respondsToSelector:NSSelectorFromString(@"setRecoveredDrawing:")])
        return NO;

    UIImage *drawingImage = ASLResizeImageToSquare(image, ASLSkinEditorDrawingSide(), YES);
    if(drawingImage == nil)
        return NO;

    ((void (*)(id, SEL, id))objc_msgSend)(lineDrawer, NSSelectorFromString(@"setRecoveredDrawing:"), drawingImage);
    ASLMarkSkinEditorDirty();
    return YES;
}

static void ASLSaveImportedSkinImage(UIImage *image) {
    NSData *data = nil;
    UIImage *encodedImage = nil;
    CGFloat sizes[] = {512.0, 448.0, 384.0, 336.0, 300.0, 256.0};
    for(unsigned int sizeIndex = 0; sizeIndex < sizeof(sizes) / sizeof(CGFloat); sizeIndex++) {
        UIImage *square = ASLResizeImageToSquare(image, sizes[sizeIndex], NO);
        for(CGFloat quality = 0.92; quality >= 0.18; quality -= 0.04) {
            data = UIImageJPEGRepresentation(square ?: image, quality);
            encodedImage = square ?: image;
            if(data.length > 0 && data.length <= 30 * 1024)
                break;
        }
        if(data.length > 0 && data.length <= 30 * 1024)
            break;
    }
    NSString *directory = ASLSkinImportDirectory();
    NSString *path = ASLSkinImportImagePath();
    if(data == nil || directory.length == 0 || path.length == 0)
        return;

    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    [data writeToFile:path atomically:YES];
    sImportedSkinImage = [UIImage imageWithData:data] ?: encodedImage ?: image;
}

static void ASLRefreshSkinImagePreview(UIImage *image) {
    UIWindow *window = ASLActiveWindow();
    if(window == nil)
        return;

    if(sSkinImagePreviewView == nil) {
        sSkinImagePreviewView = [[UIImageView alloc] initWithFrame:CGRectZero];
        sSkinImagePreviewView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        sSkinImagePreviewView.contentMode = UIViewContentModeScaleAspectFill;
        sSkinImagePreviewView.clipsToBounds = YES;
        sSkinImagePreviewView.layer.cornerRadius = 0.0;
        sSkinImagePreviewView.layer.borderWidth = 3.0;
        sSkinImagePreviewView.layer.borderColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:1.0].CGColor;
        [window addSubview:sSkinImagePreviewView];
    }

    CGRect frame = ASLSkinEditorImportedImageFrameInWindow();
    if(CGRectIsEmpty(frame))
        frame = CGRectMake(CGRectGetMidX(window.bounds) - 120.0, CGRectGetMidY(window.bounds) - 120.0, 240.0, 240.0);
    sSkinImagePreviewView.frame = frame;
    sSkinImagePreviewView.layer.cornerRadius = CGRectGetWidth(frame) * 0.5;
    sSkinImagePreviewView.image = ASLCircleCroppedImage(image, 512.0) ?: image;
    [window bringSubviewToFront:sSkinImagePreviewView];
}

static void ASLOpenPhotoPickerForSkinImport();

@interface KukioModSkinImagePickerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
- (void)kukiomod_pickSkinImage:(id)sender;
- (void)kukiomod_applySkinImage:(id)sender;
@end

@implementation KukioModSkinImagePickerDelegate

- (void)kukiomod_pickSkinImage:(id)sender {
    ASLOpenPhotoPickerForSkinImport();
}

- (void)kukiomod_applySkinImage:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL applied = ASLApplyImportedSkinToLineDrawer();
        ASLShowToast(applied ? @"\u30b9\u30ad\u30f3\u306b\u753b\u50cf\u3092\u53cd\u6620\u3057\u307e\u3057\u305f" : @"\u753b\u50cf\u53cd\u6620\u306b\u5931\u6557\u3057\u307e\u3057\u305f");
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if(image == nil)
        image = [info objectForKey:UIImagePickerControllerOriginalImage];

    if(image != nil) {
        ASLSaveImportedSkinImage(image);
    }

    [picker dismissViewControllerAnimated:YES completion:^{
        if(image != nil) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ASLShowToast(@"\u753b\u50cf\u309230KB\u4ee5\u4e0b\u3067\u4fdd\u5b58\u3057\u307e\u3057\u305f");
            });
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end

static void ASLOpenPhotoPickerForSkinImport() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controller = ASLTopViewController();
        if(controller == nil || ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            return;

        if(sSkinImagePickerDelegate == nil)
            sSkinImagePickerDelegate = [[KukioModSkinImagePickerDelegate alloc] init];

        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = YES;
        picker.delegate = sSkinImagePickerDelegate;
        [controller presentViewController:picker animated:YES completion:nil];
    });
}

static void ASLRemoveSkinImportOverlay() {
    [sSkinImagePickerButton removeFromSuperview];
    sSkinImagePickerButton = nil;
    [sSkinImageApplyButton removeFromSuperview];
    sSkinImageApplyButton = nil;
    [sSkinImagePreviewView removeFromSuperview];
    sSkinImagePreviewView = nil;
}

static void ASLInstallSkinImportButton() {
    UIWindow *window = ASLActiveWindow();
    if(window == nil || sSkinEditorView == nil)
        return;

    if(sSkinImagePickerDelegate == nil)
        sSkinImagePickerDelegate = [[KukioModSkinImagePickerDelegate alloc] init];

    if(sSkinImagePickerButton == nil) {
        sSkinImagePickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sSkinImagePickerButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.64];
        sSkinImagePickerButton.layer.cornerRadius = 18.0;
        sSkinImagePickerButton.layer.borderWidth = 1.4;
        sSkinImagePickerButton.layer.borderColor = [UIColor colorWithRed:1.0 green:0.82 blue:0.05 alpha:0.95].CGColor;
        sSkinImagePickerButton.titleLabel.font = ASLYujiBokuFont(16.0, YES);
        [sSkinImagePickerButton setTitle:@"\u753b\u50cf\u8ffd\u52a0" forState:UIControlStateNormal];
        [sSkinImagePickerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sSkinImagePickerButton addTarget:sSkinImagePickerDelegate action:@selector(kukiomod_pickSkinImage:) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:sSkinImagePickerButton];
    }

    if(sSkinImageApplyButton == nil) {
        sSkinImageApplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sSkinImageApplyButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.64];
        sSkinImageApplyButton.layer.cornerRadius = 18.0;
        sSkinImageApplyButton.layer.borderWidth = 1.4;
        sSkinImageApplyButton.layer.borderColor = [UIColor colorWithRed:0.2 green:0.9 blue:0.55 alpha:0.95].CGColor;
        sSkinImageApplyButton.titleLabel.font = ASLYujiBokuFont(16.0, YES);
        [sSkinImageApplyButton setTitle:@"\u53cd\u6620" forState:UIControlStateNormal];
        [sSkinImageApplyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sSkinImageApplyButton addTarget:sSkinImagePickerDelegate action:@selector(kukiomod_applySkinImage:) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:sSkinImageApplyButton];
    }

    CGFloat topInset = 14.0;
    if(@available(iOS 11.0, *))
        topInset += window.safeAreaInsets.top;
    sSkinImagePickerButton.frame = CGRectMake(CGRectGetWidth(window.bounds) - 142.0,
                                              topInset + 48.0,
                                              124.0,
                                              38.0);
    sSkinImagePickerButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [window bringSubviewToFront:sSkinImagePickerButton];

    sSkinImageApplyButton.frame = CGRectMake(CGRectGetWidth(window.bounds) - 142.0,
                                             topInset + 92.0,
                                             124.0,
                                             38.0);
    sSkinImageApplyButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [window bringSubviewToFront:sSkinImageApplyButton];
}

static void OpenAgarSkinCreator() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(sSkinEditorView != nil) {
            ASLInstallSkinImportButton();
            return;
        }

        if(sCreateSkinNodeView != nil && [sCreateSkinNodeView respondsToSelector:NSSelectorFromString(@"createButtonCallback")]) {
            ((void (*)(id, SEL))objc_msgSend)(sCreateSkinNodeView, NSSelectorFromString(@"createButtonCallback"));
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ASLInstallSkinImportButton();
            });
            return;
        }

        ASLShowToast(@"\u30b9\u30ad\u30f3\u30b7\u30e7\u30c3\u30d7\u306e\u4f5c\u6210\u753b\u9762\u3092\u4e00\u5ea6\u958b\u3044\u3066\u304f\u3060\u3055\u3044");
    });
}

static BOOL ASLMiniMapDebugNameIsInteresting(NSString *name) {
    NSString *lower = name.lowercaseString ?: @"";
    NSArray *keywords = @[
        @"mini", @"map", @"radar", @"party", @"team", @"mate", @"friend",
        @"member", @"player", @"cell", @"cells", @"world", @"entity",
        @"entities", @"position", @"positions", @"coord", @"location",
        @"point", @"dot", @"marker", @"visible", @"all", @"guest",
        @"facebook", @"fb", @"login", @"account", @"profile", @"user",
        @"uid", @"id", @"name", @"nick", @"avatar", @"social"
    ];
    for(NSString *keyword in keywords) {
        if([lower containsString:keyword])
            return YES;
    }
    return NO;
}

static BOOL ASLPartyRuntimeDebugTextIsInteresting(NSString *text) {
    NSString *lower = text.lowercaseString ?: @"";
    NSArray *keywords = @[
        @"arena", @"party", @"member", @"friend", @"mate", @"team",
        @"profile", @"avatar", @"nickname", @"player", @"owner",
        @"uid", @"id", @"cell", @"minimap", @"tracker", @"map",
        @"position", @"visible", @"alive", @"guest", @"facebook",
        @"login", @"account"
    ];
    for(NSString *keyword in keywords) {
        if([lower containsString:keyword])
            return YES;
    }
    return NO;
}

static BOOL ASLIdentityDebugNameIsInteresting(NSString *name) {
    NSString *lower = name.lowercaseString ?: @"";
    NSArray *keywords = @[
        @"guest", @"facebook", @"fb", @"login", @"logged", @"account",
        @"profile", @"user", @"uid", @"id", @"name", @"nick", @"display",
        @"avatar", @"social", @"provider", @"session", @"token", @"auth",
        @"player", @"friend", @"member", @"party", @"owner"
    ];
    for(NSString *keyword in keywords) {
        if([lower containsString:keyword])
            return YES;
    }
    return NO;
}

static NSString *ASLMiniMapDebugObjectSummary(id object) {
    if(object == nil)
        return @"nil";

    NSMutableString *summary = [NSMutableString stringWithFormat:@"%@", NSStringFromClass([object class])];
    if([object respondsToSelector:@selector(count)]) {
        NSUInteger count = ((NSUInteger (*)(id, SEL))objc_msgSend)(object, @selector(count));
        [summary appendFormat:@" count=%lu", (unsigned long)count];
    }

    NSString *text = ASLStringFromPotentialLabel(object);
    if(text.length > 0) {
        if(text.length > 48)
            text = [[text substringToIndex:48] stringByAppendingString:@"..."];
        [summary appendFormat:@" text=%@", text];
    }

    return summary;
}

static NSString *ASLIdentityDebugValueSummary(id value) {
    if(value == nil)
        return @"nil";

    if([value isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)value;
        if(string.length > 80)
            string = [[string substringToIndex:80] stringByAppendingString:@"..."];
        return [NSString stringWithFormat:@"\"%@\"", string];
    }
    if([value isKindOfClass:[NSNumber class]])
        return [NSString stringWithFormat:@"%@", value];

    NSString *text = ASLStringFromPotentialLabel(value);
    NSString *summary = ASLMiniMapDebugObjectSummary(value);
    if(text.length > 0)
        return [NSString stringWithFormat:@"%@ label=\"%@\"", summary, text];
    return summary;
}

static NSString *ASLMiniMapDebugIvarValue(id object, Ivar ivar);

static NSString *ASLDebugNSStringFromLibcppString(const void *stringAddress) {
    if(stringAddress == NULL)
        return @"";

    const uint8_t *raw = (const uint8_t *)stringAddress;
    BOOL isLong = (raw[23] & 0x80) != 0;
    const char *bytes = NULL;
    size_t length = 0;

    if(isLong) {
        bytes = *(const char * const *)raw;
        length = *(const size_t *)(raw + sizeof(void *));
    } else {
        bytes = (const char *)raw;
        length = (size_t)(raw[23] & 0x7F);
    }

    if(bytes == NULL || length == 0 || length > 2048)
        return @"";

    NSString *string = [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
    if(string.length == 0)
        string = [[NSString alloc] initWithBytes:bytes length:length encoding:NSISOLatin1StringEncoding];
    return string ?: @"";
}

static void ASLIdentityDebugAppendIvars(NSMutableString *output, NSString *prefix, id object, NSUInteger depth) {
    if(object == nil || depth > 1)
        return;

    Class currentClass = object_getClass(object);
    NSUInteger added = 0;
    while(currentClass != Nil && currentClass != [NSObject class] && added < 48) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(currentClass, &count);
        for(unsigned int index = 0; index < count && added < 48; index++) {
            const char *nameC = ivar_getName(ivars[index]);
            const char *typeC = ivar_getTypeEncoding(ivars[index]);
            NSString *name = nameC != NULL ? [NSString stringWithUTF8String:nameC] : @"";
            if(!ASLIdentityDebugNameIsInteresting(name))
                continue;

            NSString *path = prefix.length > 0 ? [NSString stringWithFormat:@"%@.%@", prefix, name] : name;
            if(typeC != NULL && typeC[0] == '@') {
                id value = object_getIvar(object, ivars[index]);
                [output appendFormat:@"%@ = %@\n", path, ASLIdentityDebugValueSummary(value)];
                if(value != nil &&
                   ![value isKindOfClass:[NSString class]] &&
                   ![value isKindOfClass:[NSNumber class]] &&
                   ![value isKindOfClass:[NSArray class]] &&
                   ![value isKindOfClass:[NSDictionary class]]) {
                    ASLIdentityDebugAppendIvars(output, path, value, depth + 1);
                }
            } else {
                NSString *ivarValue = ASLMiniMapDebugIvarValue(object, ivars[index]);
                if(ivarValue.length > 0)
                    [output appendFormat:@"%@\n", ivarValue];
                else
                    [output appendFormat:@"%@ type=%s offset=%td\n", path, typeC ?: "?", ivar_getOffset(ivars[index])];
            }
            added += 1;
        }
        if(ivars != NULL)
            free(ivars);
        currentClass = class_getSuperclass(currentClass);
    }
}

static void ASLIdentityDebugAppendSelectors(NSMutableString *output, NSString *prefix, id object) {
    if(object == nil)
        return;

    NSArray *selectorNames = @[
        @"isGuest", @"guest", @"isLoggedIn", @"loggedIn", @"isFacebook",
        @"facebook", @"facebookId", @"fbId", @"loginType", @"loginProvider",
        @"provider", @"account", @"profile", @"user", @"userId", @"uid",
        @"UID", @"playerId", @"ownerId", @"id", @"name", @"nickname",
        @"displayName", @"nick", @"avatar", @"avatarId", @"socialId",
        @"partyMembers", @"members", @"friends", @"friendPlayers",
        @"partyPlayers", @"teammates", @"teamMates"
    ];

    NSUInteger added = 0;
    for(NSString *selectorName in selectorNames) {
        if(added >= 40)
            break;

        SEL selector = NSSelectorFromString(selectorName);
        if(!ASLResponds(object, selector))
            continue;

        id value = ASLObjectValueFromObject(object, selector);
        if(value != nil) {
            [output appendFormat:@"%@.%@ => %@\n", prefix, selectorName, ASLIdentityDebugValueSummary(value)];
            added += 1;
            continue;
        }

        double numeric = ASLNumericValueFromObject(object, selector);
        if(numeric >= 0.0) {
            [output appendFormat:@"%@.%@ => %.0f\n", prefix, selectorName, numeric];
            added += 1;
        } else {
            [output appendFormat:@"%@.%@ => responds\n", prefix, selectorName];
            added += 1;
        }
    }
}

static void ASLIdentityDebugAppendObject(NSMutableString *output, NSString *title, id object) {
    [output appendFormat:@"\n[%@]\n", title];
    if(object == nil) {
        [output appendString:@"nil\n"];
        return;
    }

    [output appendFormat:@"class=%@\n", NSStringFromClass([object class])];
    ASLIdentityDebugAppendIvars(output, @"ivar", object, 0);
    ASLIdentityDebugAppendSelectors(output, @"sel", object);
}

static void ASLPartyRuntimeDebugAppendClass(NSMutableString *output, NSString *title, id object) {
    [output appendFormat:@"\n[%@ runtime scan]\n", title];
    if(object == nil) {
        [output appendString:@"nil\n"];
        return;
    }

    Class currentClass = object_getClass(object);
    NSUInteger addedIvars = 0;
    NSUInteger addedMethods = 0;
    NSUInteger addedProperties = 0;
    [output appendFormat:@"class=%@\n", NSStringFromClass([object class])];

    while(currentClass != Nil && currentClass != [NSObject class]) {
        NSString *className = NSStringFromClass(currentClass);

        unsigned int ivarCount = 0;
        Ivar *ivars = class_copyIvarList(currentClass, &ivarCount);
        for(unsigned int index = 0; index < ivarCount && addedIvars < 120; index++) {
            const char *nameC = ivar_getName(ivars[index]);
            const char *typeC = ivar_getTypeEncoding(ivars[index]);
            NSString *name = nameC != NULL ? [NSString stringWithUTF8String:nameC] : @"";
            NSString *type = typeC != NULL ? [NSString stringWithUTF8String:typeC] : @"";
            if(!ASLPartyRuntimeDebugTextIsInteresting(name) && !ASLPartyRuntimeDebugTextIsInteresting(type))
                continue;

            [output appendFormat:@"ivar %@.%@ type=%@ offset=%td\n",
                                 className,
                                 name,
                                 type.length > 240 ? [[type substringToIndex:240] stringByAppendingString:@"..."] : type,
                                 ivar_getOffset(ivars[index])];
            addedIvars += 1;
        }
        if(ivars != NULL)
            free(ivars);

        unsigned int propertyCount = 0;
        objc_property_t *properties = class_copyPropertyList(currentClass, &propertyCount);
        for(unsigned int index = 0; index < propertyCount && addedProperties < 80; index++) {
            const char *nameC = property_getName(properties[index]);
            const char *attrsC = property_getAttributes(properties[index]);
            NSString *name = nameC != NULL ? [NSString stringWithUTF8String:nameC] : @"";
            NSString *attrs = attrsC != NULL ? [NSString stringWithUTF8String:attrsC] : @"";
            if(!ASLPartyRuntimeDebugTextIsInteresting(name) && !ASLPartyRuntimeDebugTextIsInteresting(attrs))
                continue;

            [output appendFormat:@"prop %@.%@ attrs=%@\n",
                                 className,
                                 name,
                                 attrs.length > 220 ? [[attrs substringToIndex:220] stringByAppendingString:@"..."] : attrs];
            addedProperties += 1;
        }
        if(properties != NULL)
            free(properties);

        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(currentClass, &methodCount);
        for(unsigned int index = 0; index < methodCount && addedMethods < 160; index++) {
            SEL selector = method_getName(methods[index]);
            NSString *name = selector != NULL ? NSStringFromSelector(selector) : @"";
            if(!ASLPartyRuntimeDebugTextIsInteresting(name))
                continue;

            const char *typesC = method_getTypeEncoding(methods[index]);
            NSString *types = typesC != NULL ? [NSString stringWithUTF8String:typesC] : @"";
            [output appendFormat:@"method %@.%@ types=%@\n",
                                 className,
                                 name,
                                 types.length > 240 ? [[types substringToIndex:240] stringByAppendingString:@"..."] : types];
            addedMethods += 1;
        }
        if(methods != NULL)
            free(methods);

        currentClass = class_getSuperclass(currentClass);
    }

    [output appendFormat:@"runtime totals ivars=%lu props=%lu methods=%lu\n",
                         (unsigned long)addedIvars,
                         (unsigned long)addedProperties,
                         (unsigned long)addedMethods];
}

static void ASLPartyRuntimeDebugAppendMethodDetails(NSMutableString *output, id object, SEL selector) {
    [output appendString:@"\n[FriendTracker target method details]\n"];
    if(object == nil || selector == NULL) {
        [output appendString:@"object or selector is nil\n"];
        return;
    }

    Class currentClass = object_getClass(object);
    while(currentClass != Nil && currentClass != [NSObject class]) {
        Method method = class_getInstanceMethod(currentClass, selector);
        if(method != NULL) {
            [output appendFormat:@"class=%@ selector=%@\n", NSStringFromClass(currentClass), NSStringFromSelector(selector)];

            const char *typesC = method_getTypeEncoding(method);
            NSString *types = typesC != NULL ? [NSString stringWithUTF8String:typesC] : @"";
            [output appendFormat:@"fullTypes=%@\n", types];

            char *returnTypeC = method_copyReturnType(method);
            NSString *returnType = returnTypeC != NULL ? [NSString stringWithUTF8String:returnTypeC] : @"";
            [output appendFormat:@"returnType=%@\n", returnType];
            if(returnTypeC != NULL)
                free(returnTypeC);

            unsigned int argumentCount = method_getNumberOfArguments(method);
            [output appendFormat:@"argumentCount=%u\n", argumentCount];
            for(unsigned int index = 0; index < argumentCount; index++) {
                char *argTypeC = method_copyArgumentType(method, index);
                NSString *argType = argTypeC != NULL ? [NSString stringWithUTF8String:argTypeC] : @"";
                [output appendFormat:@"arg%u=%@\n", index, argType];
                if(argTypeC != NULL)
                    free(argTypeC);
            }
            return;
        }

        currentClass = class_getSuperclass(currentClass);
    }

    [output appendFormat:@"selector not found: %@\n", NSStringFromSelector(selector)];
}

static void ASLMiniMapDebugAppendObject(NSMutableString *output, NSString *title, id object) {
    [output appendFormat:@"\n[%@]\n", title];
    if(object == nil) {
        [output appendString:@"nil\n"];
        return;
    }

    [output appendFormat:@"class: %@\n", NSStringFromClass([object class])];

    Class currentClass = object_getClass(object);
    NSUInteger addedIvars = 0;
    while(currentClass != Nil && currentClass != [NSObject class] && addedIvars < 80) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(currentClass, &count);
        for(unsigned int index = 0; index < count && addedIvars < 80; index++) {
            const char *nameC = ivar_getName(ivars[index]);
            const char *typeC = ivar_getTypeEncoding(ivars[index]);
            NSString *name = nameC != NULL ? [NSString stringWithUTF8String:nameC] : @"";
            if(!ASLMiniMapDebugNameIsInteresting(name))
                continue;

            if(typeC != NULL && typeC[0] == '@') {
                id value = object_getIvar(object, ivars[index]);
                [output appendFormat:@"ivar %@ = %@\n", name, ASLMiniMapDebugObjectSummary(value)];
            } else {
                ptrdiff_t offset = ivar_getOffset(ivars[index]);
                [output appendFormat:@"ivar %@ type=%s offset=%td\n", name, typeC ?: "?", offset];
            }
            addedIvars += 1;
        }
        if(ivars != NULL)
            free(ivars);
        currentClass = class_getSuperclass(currentClass);
    }

    NSArray *selectorNames = @[
        @"miniMap", @"minimap", @"miniMapView", @"radar", @"map", @"mapView",
        @"party", @"partyMembers", @"partyPlayers", @"teammates", @"teamMates",
        @"friends", @"friendPlayers", @"players", @"playerCells",
        @"playerAgarCells", @"cellViews", @"cells", @"allCells", @"worldCells",
        @"visibleCells", @"entities", @"world", @"arena", @"positions",
        @"playerPositions", @"partyPositions", @"memberPositions", @"markers",
        @"dots", @"location", @"position", @"massCenter"
    ];
    NSUInteger addedSelectors = 0;
    for(NSString *selectorName in selectorNames) {
        if(addedSelectors >= 60)
            break;

        SEL selector = NSSelectorFromString(selectorName);
        if(!ASLResponds(object, selector))
            continue;

        id value = ASLObjectValueFromObject(object, selector);
        if(value != nil) {
            [output appendFormat:@"sel %@ => %@\n", selectorName, ASLMiniMapDebugObjectSummary(value)];
            addedSelectors += 1;
            continue;
        }

        double numeric = ASLNumericValueFromObject(object, selector);
        if(numeric >= 0.0) {
            [output appendFormat:@"sel %@ => %.2f\n", selectorName, numeric];
            addedSelectors += 1;
        } else {
            [output appendFormat:@"sel %@ => responds\n", selectorName];
            addedSelectors += 1;
        }
    }
}

static NSString *ASLMiniMapDebugIvarValue(id object, Ivar ivar) {
    if(object == nil || ivar == NULL)
        return nil;

    const char *typeC = ivar_getTypeEncoding(ivar);
    const char *nameC = ivar_getName(ivar);
    if(typeC == NULL || nameC == NULL)
        return nil;

    ptrdiff_t offset = ivar_getOffset(ivar);
    void *base = (uint8_t *)(__bridge void *)object + offset;
    if(typeC[0] == '@') {
        id value = object_getIvar(object, ivar);
        return [NSString stringWithFormat:@"%s=%@", nameC, ASLMiniMapDebugObjectSummary(value)];
    }
    if(strcmp(typeC, @encode(BOOL)) == 0 || strcmp(typeC, "B") == 0)
        return [NSString stringWithFormat:@"%s=%@", nameC, (*(BOOL *)base) ? @"YES" : @"NO"];
    if(strcmp(typeC, @encode(char)) == 0)
        return [NSString stringWithFormat:@"%s=%d", nameC, (int)(*(char *)base)];
    if(strcmp(typeC, @encode(unsigned char)) == 0)
        return [NSString stringWithFormat:@"%s=%u", nameC, (unsigned int)(*(unsigned char *)base)];
    if(strcmp(typeC, @encode(short)) == 0)
        return [NSString stringWithFormat:@"%s=%d", nameC, (int)(*(short *)base)];
    if(strcmp(typeC, @encode(unsigned short)) == 0)
        return [NSString stringWithFormat:@"%s=%u", nameC, (unsigned int)(*(unsigned short *)base)];
    if(strcmp(typeC, @encode(int)) == 0)
        return [NSString stringWithFormat:@"%s=%d", nameC, *(int *)base];
    if(strcmp(typeC, @encode(unsigned int)) == 0)
        return [NSString stringWithFormat:@"%s=%u", nameC, *(unsigned int *)base];
    if(strcmp(typeC, @encode(long)) == 0)
        return [NSString stringWithFormat:@"%s=%ld", nameC, *(long *)base];
    if(strcmp(typeC, @encode(unsigned long)) == 0)
        return [NSString stringWithFormat:@"%s=%lu", nameC, *(unsigned long *)base];
    if(strcmp(typeC, @encode(long long)) == 0)
        return [NSString stringWithFormat:@"%s=%lld", nameC, *(long long *)base];
    if(strcmp(typeC, @encode(unsigned long long)) == 0)
        return [NSString stringWithFormat:@"%s=%llu", nameC, *(unsigned long long *)base];
    if(strcmp(typeC, @encode(float)) == 0)
        return [NSString stringWithFormat:@"%s=%.2f", nameC, *(float *)base];
    if(strcmp(typeC, @encode(double)) == 0)
        return [NSString stringWithFormat:@"%s=%.2f", nameC, *(double *)base];
    if(strncmp(typeC, @encode(CGPoint), strlen(@encode(CGPoint))) == 0 ||
       strncmp(typeC, "{CGPoint", 8) == 0) {
        CGPoint point = *(CGPoint *)base;
        return [NSString stringWithFormat:@"%s=(%.1f, %.1f)", nameC, point.x, point.y];
    }

    return nil;
}

static BOOL ASLMiniMapDebugCellIvarNameIsInteresting(NSString *name) {
    NSString *lower = name.lowercaseString ?: @"";
    NSArray *keywords = @[
        @"owner", @"player", @"party", @"team", @"friend", @"mate", @"member",
        @"id", @"uid", @"cell", @"mass", @"radius", @"position", @"coord",
        @"point", @"visible", @"virus", @"name", @"nick"
    ];
    for(NSString *keyword in keywords) {
        if([lower containsString:keyword])
            return YES;
    }
    return NO;
}

static id ASLMiniMapDebugObjectIvarDeep(id object, const char *ivarName) {
    if(object == nil || ivarName == NULL)
        return nil;

    Class currentClass = object_getClass(object);
    while(currentClass != Nil && currentClass != [NSObject class]) {
        Ivar ivar = class_getInstanceVariable(currentClass, ivarName);
        if(ivar != NULL)
            return object_getIvar(object, ivar);
        currentClass = class_getSuperclass(currentClass);
    }
    return nil;
}

static void ASLMiniMapDebugAppendRawFriendTrack(NSMutableString *output, id tracker) {
    [output appendString:@"\n[FriendTracker raw]\n"];
    if(tracker == nil) {
        [output appendString:@"nil\n"];
        return;
    }

    Ivar ivar = NULL;
    Class currentClass = object_getClass(tracker);
    while(currentClass != Nil && currentClass != [NSObject class]) {
        ivar = class_getInstanceVariable(currentClass, "_friendToTrack");
        if(ivar != NULL)
            break;
        currentClass = class_getSuperclass(currentClass);
    }
    if(ivar == NULL) {
        [output appendString:@"_friendToTrack not found\n"];
        return;
    }

    ptrdiff_t offset = ivar_getOffset(ivar);
    uint8_t *base = (uint8_t *)(__bridge void *)tracker + offset;
    int ownerId = *(int *)base;
    [output appendFormat:@"_friendToTrack offset=%td ownerIdCandidate=%d\n", offset, ownerId];

    BOOL isAlive = *(BOOL *)(base + 8);
    float positionX = *(float *)(base + 12);
    float positionY = *(float *)(base + 16);
    NSString *avatarUrl = ASLDebugNSStringFromLibcppString(base + 24);
    NSString *nickname = ASLDebugNSStringFromLibcppString(base + 48);
    [output appendString:@"decoded ArenaPartyMemberInfo:\n"];
    [output appendFormat:@"  ownerId=%d alive=%@ position=(%.1f, %.1f)\n",
                         ownerId,
                         isAlive ? @"YES" : @"NO",
                         positionX,
                         positionY];
    [output appendFormat:@"  avatarUrl=%@\n", avatarUrl.length > 0 ? avatarUrl : @"(empty)"];
    [output appendFormat:@"  nickname=%@\n", nickname.length > 0 ? nickname : @"(empty)"];
    NSString *lowerAvatarUrl = avatarUrl.lowercaseString ?: @"";
    BOOL guestAvatar = [lowerAvatarUrl containsString:@"profilepic_guest.png"] || [lowerAvatarUrl containsString:@"guest"];
    NSString *candidateText = avatarUrl.length == 0
        ? @"NO/avatarUrl empty"
        : (guestAvatar ? @"NO/guest avatar" : @"YES/login avatar");
    [output appendFormat:@"  loginCandidate=%@\n", candidateText];

    [output appendString:@"float candidates:\n"];
    for(NSUInteger cursor = 0; cursor <= 80; cursor += 4) {
        float a = *(float *)(base + cursor);
        float b = *(float *)(base + cursor + 4);
        if(isfinite(a) && isfinite(b) && fabsf(a) < 20000.0f && fabsf(b) < 20000.0f)
            [output appendFormat:@"  +%02lu: %.1f, %.1f\n", (unsigned long)cursor, a, b];
    }

    [output appendString:@"int candidates:\n"];
    for(NSUInteger cursor = 0; cursor <= 64; cursor += 4) {
        int value = *(int *)(base + cursor);
        if(value > 0 && value < 10000000)
            [output appendFormat:@"  +%02lu: %d\n", (unsigned long)cursor, value];
    }
}

static void ASLMiniMapDebugAppendWidgetObjects(NSMutableString *output) {
    [output appendString:@"\n[Hud / tracker widgets]\n"];

    id hud = sCurrentHud;
    if(hud == nil)
        hud = ASLMiniMapDebugObjectIvarDeep(sCurrentArenaState, "_hud");
    [output appendFormat:@"hud=%@\n", ASLMiniMapDebugObjectSummary(hud)];

    id arenaViewFromState = ASLMiniMapDebugObjectIvarDeep(sCurrentArenaState, "_arenaView");
    [output appendFormat:@"state._arenaView=%@\n", ASLMiniMapDebugObjectSummary(arenaViewFromState)];

    id tracker = sCurrentFriendTrackerWidget;
    id minimap = sCurrentMinimapWidget;
    [output appendFormat:@"friendTracker=%@\n", ASLMiniMapDebugObjectSummary(tracker)];
    [output appendFormat:@"minimap=%@\n", ASLMiniMapDebugObjectSummary(minimap)];

    if(tracker != nil) {
        ASLMiniMapDebugAppendObject(output, @"FriendTrackerWidget", tracker);
        id delegate = ASLMiniMapDebugObjectIvarDeep(tracker, "_delegate");
        [output appendFormat:@"FriendTracker delegate=%@\n", ASLMiniMapDebugObjectSummary(delegate)];
        ASLMiniMapDebugAppendRawFriendTrack(output, tracker);
    }
    if(minimap != nil) {
        ASLMiniMapDebugAppendObject(output, @"MinimapWidget", minimap);
        id delegate = ASLMiniMapDebugObjectIvarDeep(minimap, "_delegate");
        [output appendFormat:@"Minimap delegate=%@\n", ASLMiniMapDebugObjectSummary(delegate)];
        if(delegate != nil && ASLResponds(delegate, NSSelectorFromString(@"cellsInMinimap")))
            [output appendString:@"Minimap delegate responds cellsInMinimap\n"];
    }
}

static void ASLIdentityDebugAppendFriendCandidates(NSMutableString *output) {
    [output appendString:@"\n[蜻ｳ譁ｹ繝ｭ繧ｰ繧､繝ｳ蛻､蛻･蛟呵｣彎\n"];
    [output appendString:@"繧ｲ繧ｹ繝亥椶縺ｨ繝ｭ繧ｰ繧､繝ｳ蝙｢繧貞酔縺倥ヱ繝ｼ繝・ぅ繝ｼ縺ｫ蜈･繧後※縲√％縺ｮ荳九・ guest/facebook/uid/name/profile/account 邉ｻ縺ｮ蟾ｮ繧定ｦ九∪縺吶・n"];

    id tracker = sCurrentFriendTrackerWidget;
    id trackerDelegate = tracker != nil ? ASLMiniMapDebugObjectIvarDeep(tracker, "_delegate") : nil;
    id minimap = sCurrentMinimapWidget;
    id minimapDelegate = minimap != nil ? ASLMiniMapDebugObjectIvarDeep(minimap, "_delegate") : nil;

    ASLIdentityDebugAppendObject(output, @"FriendTrackerWidget identity", tracker);
    if(tracker != nil)
        ASLMiniMapDebugAppendRawFriendTrack(output, tracker);
    ASLIdentityDebugAppendObject(output, @"FriendTracker delegate identity", trackerDelegate);
    ASLIdentityDebugAppendObject(output, @"MinimapWidget identity", minimap);
    ASLIdentityDebugAppendObject(output, @"Minimap delegate identity", minimapDelegate);
    ASLIdentityDebugAppendObject(output, @"ArenaState identity", sCurrentArenaState);
    ASLIdentityDebugAppendObject(output, @"BaseArenaView identity", sCurrentArenaView);

    if(sFriendTrackerFriendsArgumentDebugText.length > 0)
        [output appendFormat:@"\n%@\n", sFriendTrackerFriendsArgumentDebugText];
    else
        [output appendString:@"\n[FriendTracker friends蠑墓焚]\n縺ｾ縺蜿門ｾ励↑縺励ゅご繝ｼ繝荳ｭ縺ｫ蟆代＠蠕・▲縺ｦ縺九ｉ蜀崎｡ｨ遉ｺ縺励※縺上□縺輔＞縲・n"];

    [output appendString:@"\n[繝代・繝・ぅ繝ｼ蜈ｨ蜩｡蜿門ｾ怜・蜿｣縺輔′縺余\n"];
    [output appendString:@"party/member/friend/avatar/nickname/position 邉ｻ縺ｮivar繝ｻproperty繝ｻmethod繧貞ｺ・ａ縺ｫ蜃ｺ縺励※縺・∪縺吶・n"];
    [output appendString:@"譛邨ょ呵｣懊・驕ｸ縺ｳ譁ｹ縺ｯ縲∽ｸ逡ｪ霑代＞繝ｭ繧ｰ繧､繝ｳ蜻ｳ譁ｹ縺ｧ縺吶Ｈuest逕ｻ蜒上・髯､螟悶＠縺ｾ縺吶・n"];
    [output appendString:@"getClosestFriendFromFriends:withPlayerPosition: 縺ｮ types= 縺碁㍾隕√〒縺吶よ綾繧雁､蝙九′蛻・°繧後・friends蠑墓焚繧貞ｮ牙・縺ｫ隱ｿ譟ｻ縺ｧ縺阪∪縺吶・n"];
    ASLPartyRuntimeDebugAppendMethodDetails(output, tracker, NSSelectorFromString(@"getClosestFriendFromFriends:withPlayerPosition:"));
    ASLPartyRuntimeDebugAppendClass(output, @"FriendTrackerWidget", tracker);
    ASLPartyRuntimeDebugAppendClass(output, @"FriendTracker delegate", trackerDelegate);
    ASLPartyRuntimeDebugAppendClass(output, @"ArenaState", sCurrentArenaState);
    ASLPartyRuntimeDebugAppendClass(output, @"BaseArenaView", sCurrentArenaView);
}

static void ASLMiniMapDebugAppendCellDetails(NSMutableString *output, NSString *key, id cell) {
    if(cell == nil)
        return;

    CGPoint position = CGPointZero;
    BOOL hasPosition = ASLCellPosition(cell, &position);
    unsigned int mass = ASLCellMass(cell);
    float radius = ASLEnemyScoreCellRadius(cell);
    BOOL isPlayerOwned = ASLEnemyScoreSoftBodyIsPlayerOwned(cell);
    BOOL isPartyCell = ASLEnemyScoreSoftBodyIsPartyCell(cell);
    BOOL isVirus = ASLEnemyScoreSoftBodyIsVirus(cell);
    BOOL visible = NO;
    BOOL hasVisible = ASLReadBoolIvar(cell, "_visible", &visible);

    [output appendFormat:@"\ncell %@ %@ mass=%u radius=%.1f player=%@ party=%@ virus=%@",
                         key ?: @"?",
                         NSStringFromClass([cell class]),
                         mass,
                         radius,
                         isPlayerOwned ? @"YES" : @"NO",
                         isPartyCell ? @"YES" : @"NO",
                         isVirus ? @"YES" : @"NO"];
    if(hasPosition)
        [output appendFormat:@" pos=(%.1f, %.1f)", position.x, position.y];
    if(hasVisible)
        [output appendFormat:@" visible=%@", visible ? @"YES" : @"NO"];
    [output appendString:@"\n"];

    NSUInteger added = 0;
    Class currentClass = object_getClass(cell);
    while(currentClass != Nil && currentClass != [NSObject class] && added < 32) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(currentClass, &count);
        for(unsigned int index = 0; index < count && added < 32; index++) {
            const char *nameC = ivar_getName(ivars[index]);
            NSString *name = nameC != NULL ? [NSString stringWithUTF8String:nameC] : @"";
            if(!ASLMiniMapDebugCellIvarNameIsInteresting(name))
                continue;

            NSString *value = ASLMiniMapDebugIvarValue(cell, ivars[index]);
            if(value.length == 0)
                continue;

            [output appendFormat:@"  %@\n", value];
            added += 1;
        }
        if(ivars != NULL)
            free(ivars);
        currentClass = class_getSuperclass(currentClass);
    }
}

static void ASLMiniMapDebugAppendCellViews(NSMutableString *output) {
    [output appendString:@"\n[Cell sample / visible dictionary]\n"];
    id arenaView = sCurrentArenaView;
    if(arenaView == nil || !ASLResponds(arenaView, NSSelectorFromString(@"cellViews"))) {
        [output appendString:@"cellViews unavailable\n"];
        return;
    }

    id cellViews = ((id (*)(id, SEL))objc_msgSend)(arenaView, NSSelectorFromString(@"cellViews"));
    NSArray *keys = nil;
    NSArray *values = nil;
    if([cellViews respondsToSelector:@selector(allKeys)] && [cellViews respondsToSelector:@selector(allValues)]) {
        keys = [cellViews allKeys];
        values = [cellViews allValues];
    } else if([cellViews isKindOfClass:[NSArray class]]) {
        values = cellViews;
    }

    [output appendFormat:@"total=%lu\n", (unsigned long)[values count]];
    NSUInteger partyCount = 0;
    NSUInteger playerCount = 0;
    NSUInteger virusCount = 0;
    for(id cell in values) {
        if(ASLEnemyScoreSoftBodyIsPartyCell(cell))
            partyCount += 1;
        if(ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            playerCount += 1;
        if(ASLEnemyScoreSoftBodyIsVirus(cell))
            virusCount += 1;
    }
    [output appendFormat:@"playerCells=%lu partyCells=%lu virusCells=%lu\n",
                         (unsigned long)playerCount,
                         (unsigned long)partyCount,
                         (unsigned long)virusCount];

    NSUInteger added = 0;
    for(NSUInteger index = 0; index < values.count && added < 40; index++) {
        id cell = values[index];
        if(!ASLEnemyScoreSoftBodyIsPartyCell(cell) && !ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;
        NSString *key = keys != nil && index < keys.count ? [NSString stringWithFormat:@"%@", keys[index]] : [NSString stringWithFormat:@"%lu", (unsigned long)index];
        ASLMiniMapDebugAppendCellDetails(output, key, cell);
        added += 1;
    }

    for(NSUInteger index = 0; index < values.count && added < 40; index++) {
        id cell = values[index];
        if(ASLEnemyScoreSoftBodyIsPartyCell(cell) || ASLEnemyScoreSoftBodyIsPlayerOwned(cell))
            continue;
        NSString *key = keys != nil && index < keys.count ? [NSString stringWithFormat:@"%@", keys[index]] : [NSString stringWithFormat:@"%lu", (unsigned long)index];
        ASLMiniMapDebugAppendCellDetails(output, key, cell);
        added += 1;
    }
}

static void ShowMiniMapDebugOverlay() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = ASLActiveWindow();
        if(window == nil)
            return;

        NSMutableString *text = [NSMutableString string];
        [text appendString:@"\u5473\u65b9\u60c5\u5831\u8abf\u67fb\n"];
        [text appendString:@"\u30b2\u30b9\u30c8\u57a2\u3068\u30ed\u30b0\u30a4\u30f3\u57a2\u3092\u540c\u3058\u30d1\u30fc\u30c6\u30a3\u30fc\u306b\u5165\u308c\u3066\u3001\u5473\u65b9\u304c\u8996\u91ce\u5916\u306b\u3044\u308b\u72b6\u614b\u3067\u3053\u306e\u753b\u9762\u3092\u30b9\u30af\u30b7\u30e7\u3057\u3066\u9001\u3063\u3066\u304f\u3060\u3055\u3044\u3002\n"];
        [text appendFormat:@"party: %@\nmode: %@\n", ASLCurrentPartyCodeText(), ASLCurrentGameModeText()];

        ASLIdentityDebugAppendFriendCandidates(text);
        ASLMiniMapDebugAppendObject(text, @"BaseArenaView / currentArenaView", sCurrentArenaView);
        ASLMiniMapDebugAppendObject(text, @"ArenaState / currentArenaState", sCurrentArenaState);
        ASLMiniMapDebugAppendObject(text, @"ControlsWidget", sCurrentControlsWidget);
        ASLMiniMapDebugAppendWidgetObjects(text);
        ASLMiniMapDebugAppendCellViews(text);

        UIView *overlay = [[UIView alloc] initWithFrame:CGRectInset(window.bounds, 14.0, 34.0)];
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
        overlay.layer.cornerRadius = 12.0;
        overlay.layer.borderWidth = 1.0;
        overlay.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35].CGColor;

        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectInset(overlay.bounds, 10.0, 48.0)];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.backgroundColor = [UIColor clearColor];
        textView.textColor = [UIColor whiteColor];
        textView.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightRegular];
        textView.editable = NO;
        textView.selectable = YES;
        textView.text = text;
        [overlay addSubview:textView];

        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        closeButton.frame = CGRectMake(CGRectGetWidth(overlay.bounds) - 86.0, 8.0, 76.0, 34.0);
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        closeButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.14];
        closeButton.layer.cornerRadius = 8.0;
        [closeButton setTitle:@"\u9589\u3058\u308b" forState:UIControlStateNormal];
        [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [closeButton addTarget:overlay action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
        [overlay addSubview:closeButton];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 8.0, CGRectGetWidth(overlay.bounds) - 110.0, 34.0)];
        title.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        title.text = @"\u5473\u65b9\u60c5\u5831\u8abf\u67fb";
        title.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.36 alpha:1.0];
        title.font = ASLYujiBokuFont(20.0, YES);
        [overlay addSubview:title];

        [window addSubview:overlay];
        [window bringSubviewToFront:overlay];
    });
}

static void initMenu() {
    menu = [[Menu alloc] initMenu];

    PageItem *viewPageItem = [[PageItem alloc] init];
    viewPageItem.Title = kViewPageTitle;
    viewPageItem.TargetPage = 2;

    ToggleItem *splitViewItem = [[ToggleItem alloc] init];
    splitViewItem.Title = kSplitViewToggleTitle;
    splitViewItem.Description = @"\u81ea\u5206\u306e\u5927\u304d\u3055\u306b\u5408\u308f\u305b\u3066\u5909\u308f\u308b\u8996\u91ce\u306b\u30ba\u30fc\u30e0\u500d\u7387\u3092\u304b\u3051\u307e\u3059";
    splitViewItem.IsOn = NO;

    ToggleItem *fixedViewItem = [[ToggleItem alloc] init];
    fixedViewItem.Title = kFixedViewToggleTitle;
    fixedViewItem.Description = @"\u81ea\u5206\u306e\u5927\u304d\u3055\u306b\u95a2\u308f\u3089\u305a\u8996\u91ce\u306e\u5927\u304d\u3055\u3092\u56fa\u5b9a\u3057\u307e\u3059\u3002\u5206\u88c2\u8996\u91ce\u3068\u540c\u6642ON\u306e\u5834\u5408\u306f\u56fa\u5b9a\u8996\u91ce\u3092\u512a\u5148\u3057\u307e\u3059";
    fixedViewItem.IsOn = NO;

    ToggleItem *viewEditModeItem = [[ToggleItem alloc] init];
    viewEditModeItem.Title = kViewEditModeToggleTitle;
    viewEditModeItem.Description = @"ON\u306e\u6642\u3060\u3051\u8996\u91ce\u306e+\u30dc\u30bf\u30f3\u3068-\u30dc\u30bf\u30f3\u3092\u79fb\u52d5\u3067\u304d\u307e\u3059";
    viewEditModeItem.IsOn = NO;

    SliderItem *viewButtonSizeItem = [[SliderItem alloc] init];
    viewButtonSizeItem.Title = kViewButtonSizeSliderTitle;
    viewButtonSizeItem.Description = @"\u8996\u91ce\u306e+\u30dc\u30bf\u30f3\u3068-\u30dc\u30bf\u30f3\u306e\u5927\u304d\u3055\u309236\u304b\u308996\u3067\u8abf\u6574\u3057\u307e\u3059";
    viewButtonSizeItem.IsOn = YES;
    viewButtonSizeItem.IsFloating = NO;
    viewButtonSizeItem.DefaultValue = 46.0f;
    viewButtonSizeItem.MinValue = 36.0f;
    viewButtonSizeItem.MaxValue = 96.0f;

    SliderItem *viewButtonOpacityItem = [[SliderItem alloc] init];
    viewButtonOpacityItem.Title = kViewButtonOpacitySliderTitle;
    viewButtonOpacityItem.Description = @"1% - 100%";
    viewButtonOpacityItem.IsOn = YES;
    viewButtonOpacityItem.IsFloating = NO;
    viewButtonOpacityItem.DefaultValue = 100.0f;
    viewButtonOpacityItem.MinValue = 1.0f;
    viewButtonOpacityItem.MaxValue = 100.0f;

    SliderItem *zoomHighStepItem = [[SliderItem alloc] init];
    zoomHighStepItem.Title = kZoomHighStepSliderTitle;
    zoomHighStepItem.Description = @"0.10x - 2.00x step: 0.001 - 0.010";
    zoomHighStepItem.IsOn = YES;
    zoomHighStepItem.IsFloating = YES;
    zoomHighStepItem.DefaultValue = 0.010f;
    zoomHighStepItem.MinValue = 0.001f;
    zoomHighStepItem.MaxValue = 0.010f;

    SliderItem *zoomLowStepItem = [[SliderItem alloc] init];
    zoomLowStepItem.Title = kZoomLowStepSliderTitle;
    zoomLowStepItem.Description = @"0.01x - 0.10x step: 0.001 - 0.010";
    zoomLowStepItem.IsOn = YES;
    zoomLowStepItem.IsFloating = YES;
    zoomLowStepItem.DefaultValue = 0.001f;
    zoomLowStepItem.MinValue = 0.001f;
    zoomLowStepItem.MaxValue = 0.010f;

    SliderItem *zoomLongPressSpeedItem = [[SliderItem alloc] init];
    zoomLongPressSpeedItem.Title = kZoomLongPressSpeedSliderTitle;
    zoomLongPressSpeedItem.Description = @"0.01s - 0.10s";
    zoomLongPressSpeedItem.IsOn = YES;
    zoomLongPressSpeedItem.IsFloating = YES;
    zoomLongPressSpeedItem.DefaultValue = 0.10f;
    zoomLongPressSpeedItem.MinValue = 0.01f;
    zoomLongPressSpeedItem.MaxValue = 0.10f;

    Page *page1 = [[Page alloc] initWithPageNumber:1 parentPage:1];
    [page1 addItem:viewPageItem];
    [menu addPage:page1];

    Page *viewPage = [[Page alloc] initWithPageNumber:2 parentPage:1];
    [viewPage addItem:splitViewItem];
    [viewPage addItem:fixedViewItem];
    [viewPage addItem:viewEditModeItem];
    [viewPage addItem:viewButtonSizeItem];
    [viewPage addItem:viewButtonOpacityItem];
    [viewPage addItem:zoomHighStepItem];
    [viewPage addItem:zoomLowStepItem];
    [viewPage addItem:zoomLongPressSpeedItem];
    [menu addPage:viewPage];

    [menu setUserDefaultsAndDict];
    [menu loadPage:1];
    ASLSyncVisionModeFromMenu();
    ASLInstallMenuIconLongPress();
    ASLRefreshZoomControls();
    ASLScheduleArenaRefresh();
}
@interface NSObject (KukioModSoftBodyCellViewHooks)
- (void)kukiomod_initPlayerMassLabelWithMass:(unsigned int)mass;
- (void)kukiomod_onRadiusChanged:(float)radius discreteClusterMass:(unsigned int)mass;
@end

@implementation NSObject (KukioModSoftBodyCellViewHooks)

- (void)kukiomod_initPlayerMassLabelWithMass:(unsigned int)mass {
    if(!ASLEnemyScoreShouldForceSoftBodyMassLabel(self, mass)) {
        [self kukiomod_initPlayerMassLabelWithMass:mass];
        return;
    }

    BOOL originalIsPlayerOwned = NO;
    BOOL hasIsPlayerOwned = ASLEnemyScoreReadBoolIvar(self,
                                                      "_isPlayerOwned",
                                                      &sEnemyScoreSoftBodyIsPlayerOwnedIvar,
                                                      &originalIsPlayerOwned);
    if(hasIsPlayerOwned)
        ASLEnemyScoreWriteBoolIvar(self, "_isPlayerOwned", &sEnemyScoreSoftBodyIsPlayerOwnedIvar, YES);

    [self kukiomod_initPlayerMassLabelWithMass:mass];

    if(sEnemyScoreCellViews == nil)
        sEnemyScoreCellViews = [NSHashTable weakObjectsHashTable];
    [sEnemyScoreCellViews addObject:self];
    ASLEnemyScoreSetVisible(ASLEnemyScoreSoftBodyMassLabel(self), ASLEnemyScoreEnabled());
    ASLEnemyScoreApplyLabelSize(self);
    ASLEnemyScoreApplyLabelColor(self, mass);

    if(hasIsPlayerOwned)
        ASLEnemyScoreWriteBoolIvar(self, "_isPlayerOwned", &sEnemyScoreSoftBodyIsPlayerOwnedIvar, originalIsPlayerOwned);
}

- (void)kukiomod_onRadiusChanged:(float)radius discreteClusterMass:(unsigned int)mass {
    [self kukiomod_onRadiusChanged:radius discreteClusterMass:mass];

    BOOL shouldForceLabel = ASLEnemyScoreShouldForceSoftBodyMassLabel(self, mass);
    if(shouldForceLabel && !ASLEnemyScoreSoftBodyHasMassLabel(self))
        [self kukiomod_initPlayerMassLabelWithMass:mass];

    if(shouldForceLabel) {
        ASLEnemyScoreApplyLabelSize(self);
        ASLEnemyScoreApplyLabelColor(self, mass);
    }
}

@end

@interface NSObject (KukioModPartyCodeHooks)
- (void)kukiomod_setupLayoutWithPartyCode:(id)partyCode isFacebookAccount:(BOOL)isFacebookAccount subtitle:(id)subtitle;
- (void)kukiomod_setupLayoutWithPartyCode:(id)partyCode productAmountAndName:(id)productAmountAndName;
@end

@implementation NSObject (KukioModPartyCodeHooks)

- (void)kukiomod_setupLayoutWithPartyCode:(id)partyCode isFacebookAccount:(BOOL)isFacebookAccount subtitle:(id)subtitle {
    [self kukiomod_setupLayoutWithPartyCode:partyCode isFacebookAccount:isFacebookAccount subtitle:subtitle];

    if([partyCode isKindOfClass:[NSString class]] && [partyCode length] > 0)
        ASLRememberPartyCode(partyCode);
    else
        ASLRememberPartyCodeLabelFromView(self);
}

- (void)kukiomod_setupLayoutWithPartyCode:(id)partyCode productAmountAndName:(id)productAmountAndName {
    [self kukiomod_setupLayoutWithPartyCode:partyCode productAmountAndName:productAmountAndName];

    if([partyCode isKindOfClass:[NSString class]] && [partyCode length] > 0)
        ASLRememberPartyCode(partyCode);
    else
        ASLRememberPartyCodeLabelFromView(self);
}

@end

@interface NSObject (KukioModBaseArenaViewHooks)
- (float)kukiomod_calculateZoom:(float)value cellAmount:(int)cellAmount;
- (void)kukiomod_setupWithBackground:(int)background initialState:(const void *)initialState;
- (void)kukiomod_update:(double)delta;
@end

@implementation NSObject (KukioModBaseArenaViewHooks)

- (void)kukiomod_setupWithBackground:(int)background initialState:(const void *)initialState {
    sCurrentArenaView = self;
    ASLTrackArenaInitialState(background, initialState);
    [self kukiomod_setupWithBackground:background initialState:initialState];
    ASLArmFixedViewEntryPulse();
    ASLScheduleArenaRefresh();
}

- (float)kukiomod_calculateZoom:(float)value cellAmount:(int)cellAmount {
    sCurrentArenaView = self;
    float originalZoom = [self kukiomod_calculateZoom:value cellAmount:cellAmount];
    if(ASLFixedViewEnabled())
        return ASLFixedViewZoomWithEntryPulse();

    if(!ASLSplitViewEnabled())
        return originalZoom;

    return originalZoom * ASLZoomMultiplier();
}

- (void)kukiomod_update:(double)delta {
    sCurrentArenaView = self;
    [self kukiomod_update:delta];

    if(!ASLViewEnabled() && !ASLEnemyScoreEnabled())
        return;

    CFTimeInterval now = CACurrentMediaTime();
    if(now - sLastArenaPassiveRefreshTime < 0.25)
        return;

    sLastArenaPassiveRefreshTime = now;
    if(ASLViewEnabled()) {
        ASLPokeCurrentArenaView();
    } else {
        ASLRefreshEnemyScoreLabels();
    }
}

@end

static void ASLUpdateGameModeFromState(id state) {
    NSString *className = state != nil ? NSStringFromClass([state class]).lowercaseString : @"";
    if([className containsString:@"burst"]) {
        sCurrentGameModeOverride = 2;
    } else if([className containsString:@"classic"]) {
        sCurrentGameModeOverride = 1;
    }
}

static NSString *ASLAutoRespawnModeName(int mode) {
    if(mode == 2)
        return @"\u30d0\u30fc\u30b9\u30c8";
    if(mode == 1)
        return @"\u30af\u30e9\u30b7\u30c3\u30af";
    return @"OFF";
}

static void ASLPerformPendingAutoRespawn() {
    if(!sAutoRespawnPending || sCurrentMenuMainState == nil)
        return;

    int mode = sAutoRespawnPendingMode;
    sAutoRespawnPending = NO;
    sAutoRespawnPendingMode = 0;

    id menuMain = sCurrentMenuMainState;
    SEL playSelector = mode == 2 ? NSSelectorFromString(@"burstPlayButtonCallback") : NSSelectorFromString(@"playButtonCallback");
    if(mode == 2 && ASLResponds(menuMain, NSSelectorFromString(@"canPlayBurst"))) {
        BOOL canPlayBurst = ((BOOL (*)(id, SEL))objc_msgSend)(menuMain, NSSelectorFromString(@"canPlayBurst"));
        if(!canPlayBurst) {
            ASLShowToast(@"\u30d0\u30fc\u30b9\u30c8\u304c\u307e\u3060\u958b\u653e\u3055\u308c\u3066\u3044\u307e\u305b\u3093");
            return;
        }
    }

    if(!ASLResponds(menuMain, playSelector)) {
        ASLShowToast(@"\u30ea\u30b9\u30dd\u30fc\u30f3\u306e\u30d7\u30ec\u30a4\u30dc\u30bf\u30f3\u304c\u898b\u3064\u304b\u308a\u307e\u305b\u3093");
        return;
    }

    ASLShowToast([NSString stringWithFormat:@"%@\u306b\u30ea\u30b9\u30dd\u30fc\u30f3", ASLAutoRespawnModeName(mode)]);
    ((void (*)(id, SEL))objc_msgSend)(menuMain, playSelector);
}

static void ASLSchedulePendingAutoRespawnAttempt(NSTimeInterval delay) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ASLPerformPendingAutoRespawn();
    });
}

static void ASLRequestAutoRespawnFromContinueGame(id continueGameState) {
    int mode = ASLAutoRespawnMode();
    if(mode == 0)
        return;

    CFTimeInterval now = CACurrentMediaTime();
    if(now - sLastAutoRespawnRequestTime < 2.0)
        return;

    sLastAutoRespawnRequestTime = now;
    sAutoRespawnPending = YES;
    sAutoRespawnPendingMode = mode;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(continueGameState != nil && ASLResponds(continueGameState, NSSelectorFromString(@"closeAndLeaveArena")))
            ((void (*)(id, SEL))objc_msgSend)(continueGameState, NSSelectorFromString(@"closeAndLeaveArena"));
        ASLSchedulePendingAutoRespawnAttempt(3.0);
        ASLSchedulePendingAutoRespawnAttempt(4.0);
        ASLSchedulePendingAutoRespawnAttempt(5.5);
    });
}

static void ASLRequestAutoRespawnFromArenaState(id arenaState) {
    int mode = ASLAutoRespawnMode();
    if(mode == 0)
        return;

    CFTimeInterval now = CACurrentMediaTime();
    if(now - sLastAutoRespawnRequestTime < 2.0)
        return;

    sLastAutoRespawnRequestTime = now;
    sAutoRespawnPending = YES;
    sAutoRespawnPendingMode = mode;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(arenaState != nil && ASLResponds(arenaState, NSSelectorFromString(@"leaveArena")))
            ((void (*)(id, SEL))objc_msgSend)(arenaState, NSSelectorFromString(@"leaveArena"));
        ASLSchedulePendingAutoRespawnAttempt(3.0);
        ASLSchedulePendingAutoRespawnAttempt(4.0);
        ASLSchedulePendingAutoRespawnAttempt(5.5);
    });
}

static void ASLRequestAutoRespawnFromResultState(id resultState) {
    int mode = ASLAutoRespawnMode();
    if(mode == 0)
        return;

    CFTimeInterval now = CACurrentMediaTime();
    if(now - sLastAutoRespawnRequestTime < 2.0)
        return;

    sLastAutoRespawnRequestTime = now;
    sAutoRespawnPending = YES;
    sAutoRespawnPendingMode = mode;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(resultState != nil && mode == 2 && ASLResponds(resultState, NSSelectorFromString(@"playAgainButtonCallback"))) {
            sAutoRespawnPending = NO;
            sAutoRespawnPendingMode = 0;
            ((void (*)(id, SEL))objc_msgSend)(resultState, NSSelectorFromString(@"playAgainButtonCallback"));
            return;
        }

        if(resultState != nil && ASLResponds(resultState, NSSelectorFromString(@"backButtonCallback")))
            ((void (*)(id, SEL))objc_msgSend)(resultState, NSSelectorFromString(@"backButtonCallback"));
        else if(resultState != nil && ASLResponds(resultState, NSSelectorFromString(@"dismiss")))
            ((void (*)(id, SEL))objc_msgSend)(resultState, NSSelectorFromString(@"dismiss"));

        ASLSchedulePendingAutoRespawnAttempt(3.0);
        ASLSchedulePendingAutoRespawnAttempt(4.0);
        ASLSchedulePendingAutoRespawnAttempt(5.5);
    });
}

static void ASLTrackArenaState(id state, unsigned long long stateId, id parameters) {
    sCurrentArenaState = state;
    sCurrentArenaStateId = stateId;
    sArenaSetupCounter += 1;
    sCurrentMenuMainState = nil;
    ASLCaptureVirusChaseEntryXp();

    NSString *summary = nil;
    if([parameters isKindOfClass:[NSDictionary class]])
        summary = [(NSDictionary *)parameters descriptionWithLocale:nil indent:0];
    else if(parameters != nil)
        summary = [parameters description];

    sCurrentArenaParametersSummary = [ASLTrimmedString(summary) copy];
}

@interface NSObject (KukioModArenaStateHooks)
- (void)kukiomod_setupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (void)kukiomod_destroy;
- (void)kukiomod_leaveArena;
- (void)kukiomod_arenaStateUpdate:(double)delta;
- (void)kukiomod_onMovedToNewArena;
@end

@implementation NSObject (KukioModArenaStateHooks)

- (void)kukiomod_setupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    ASLUpdateGameModeFromState(self);
    ASLTrackArenaState(self, stateId, parameters);
    [self kukiomod_setupWithStateId:stateId parameters:parameters];
    ASLUpdateGameModeFromState(self);
    sCurrentArenaState = self;
    ASLRefreshVisionForArenaEntry(self);

    BOOL hasParty = NO;
    if(ASLReadBoolIvar(self, "_hasParty", &hasParty) && !hasParty)
        ASLClearLivePartyCode();
}

- (void)kukiomod_destroy {
    if(sCurrentArenaState == self) {
        sCurrentArenaState = nil;
        sCurrentArenaStateId = 0;
    }
    ASLFinalizeVirusChaseAccountXpSession();
    [self kukiomod_destroy];
}

- (void)kukiomod_leaveArena {
    ASLFinalizeVirusChaseAccountXpSession();
    int mode = ASLAutoRespawnMode();
    if(mode != 0) {
        sAutoRespawnPending = YES;
        sAutoRespawnPendingMode = mode;
        sLastAutoRespawnRequestTime = CACurrentMediaTime();
        ASLSchedulePendingAutoRespawnAttempt(3.0);
        ASLSchedulePendingAutoRespawnAttempt(4.0);
        ASLSchedulePendingAutoRespawnAttempt(5.5);
    }

    [self kukiomod_leaveArena];
}

- (void)kukiomod_arenaStateUpdate:(double)delta {
    [self kukiomod_arenaStateUpdate:delta];
    BOOL isDying = NO;
    if(ASLResponds(self, NSSelectorFromString(@"isDying")))
        isDying = ((BOOL (*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"isDying"));
    if(isDying)
        ASLRequestAutoRespawnFromArenaState(self);
}

- (void)kukiomod_onMovedToNewArena {
    sMovedToNewArenaCounter += 1;
    [self kukiomod_onMovedToNewArena];
    ASLRefreshVisionForArenaEntry(self);
}

@end

static void ASLTrackSkinEditorState(id state) {
    if(state == nil)
        return;
    sSkinEditorState = state;
    id view = ASLObjectIvar(state, "_view");
    if(view != nil)
        sSkinEditorView = view;
    dispatch_async(dispatch_get_main_queue(), ^{
        ASLInstallSkinImportButton();
    });
}

@interface NSObject (KukioModSkinEditorHooks)
- (void)kukiomod_skinEditorSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (double)kukiomod_skinEditorEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack;
- (double)kukiomod_skinEditorLeaveWithNewState:(unsigned long long)state toStack:(BOOL)toStack;
- (void)kukiomod_createSkinViewSetupWithTab:(id)tab;
- (void)kukiomod_createSkinViewRefresh;
@end

@implementation NSObject (KukioModSkinEditorHooks)

- (void)kukiomod_skinEditorSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    [self kukiomod_skinEditorSetupWithStateId:stateId parameters:parameters];
    ASLTrackSkinEditorState(self);
}

- (double)kukiomod_skinEditorEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack {
    double result = [self kukiomod_skinEditorEnterWithPreviousState:state fromStack:fromStack];
    ASLTrackSkinEditorState(self);
    return result;
}

- (double)kukiomod_skinEditorLeaveWithNewState:(unsigned long long)state toStack:(BOOL)toStack {
    double result = [self kukiomod_skinEditorLeaveWithNewState:state toStack:toStack];
    if(sSkinEditorState == self) {
        sSkinEditorState = nil;
        sSkinEditorView = nil;
        ASLRemoveSkinImportOverlay();
    }
    return result;
}

- (void)kukiomod_createSkinViewSetupWithTab:(id)tab {
    [self kukiomod_createSkinViewSetupWithTab:tab];
    sCreateSkinNodeView = self;
}

- (void)kukiomod_createSkinViewRefresh {
    [self kukiomod_createSkinViewRefresh];
    sCreateSkinNodeView = self;
}

@end

@interface NSObject (KukioModResultRespawnHooks)
- (void)kukiomod_battleResultSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (double)kukiomod_battleResultEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack;
- (void)kukiomod_rushGameOverSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (double)kukiomod_rushGameOverEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack;
@end

@implementation NSObject (KukioModResultRespawnHooks)

- (void)kukiomod_battleResultSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    [self kukiomod_battleResultSetupWithStateId:stateId parameters:parameters];
    ASLScheduleReadResultXpLabels(self);
    ASLRequestAutoRespawnFromResultState(self);
}

- (double)kukiomod_battleResultEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack {
    double result = [self kukiomod_battleResultEnterWithPreviousState:state fromStack:fromStack];
    ASLScheduleReadResultXpLabels(self);
    ASLRequestAutoRespawnFromResultState(self);
    return result;
}

- (void)kukiomod_rushGameOverSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    [self kukiomod_rushGameOverSetupWithStateId:stateId parameters:parameters];
    ASLScheduleReadResultXpLabels(self);
    ASLRequestAutoRespawnFromResultState(self);
}

- (double)kukiomod_rushGameOverEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack {
    double result = [self kukiomod_rushGameOverEnterWithPreviousState:state fromStack:fromStack];
    ASLScheduleReadResultXpLabels(self);
    ASLRequestAutoRespawnFromResultState(self);
    return result;
}

@end

@interface UILabel (KukioModResultTextHooks)
- (void)kukiomod_resultSetText:(NSString *)text;
@end

@implementation UILabel (KukioModResultTextHooks)

- (void)kukiomod_resultSetText:(NSString *)text {
    [self kukiomod_resultSetText:text];
    ASLConsumeResultXpText(text);
}

@end

@interface NSObject (KukioModCocosResultTextHooks)
- (void)kukiomod_resultSetString:(id)string;
@end

@implementation NSObject (KukioModCocosResultTextHooks)

- (void)kukiomod_resultSetString:(id)string {
    [self kukiomod_resultSetString:string];
    if([string isKindOfClass:[NSString class]])
        ASLConsumeResultXpText((NSString *)string);
}

@end

@interface NSObject (KukioModMenuMainHooks)
- (void)kukiomod_menuMainSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (double)kukiomod_menuMainEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack;
- (void)kukiomod_menuMainEnableInput;
@end

@implementation NSObject (KukioModMenuMainHooks)

- (void)kukiomod_menuMainSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    [self kukiomod_menuMainSetupWithStateId:stateId parameters:parameters];
    sCurrentMenuMainState = self;
    ASLSchedulePendingAutoRespawnAttempt(0.05);
}

- (double)kukiomod_menuMainEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack {
    double result = [self kukiomod_menuMainEnterWithPreviousState:state fromStack:fromStack];
    sCurrentMenuMainState = self;
    ASLSchedulePendingAutoRespawnAttempt(0.05);
    return result;
}

- (void)kukiomod_menuMainEnableInput {
    [self kukiomod_menuMainEnableInput];
    sCurrentMenuMainState = self;
    ASLSchedulePendingAutoRespawnAttempt(0.05);
}

@end

@interface NSObject (KukioModContinueGameHooks)
- (void)kukiomod_continueGameSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters;
- (double)kukiomod_continueGameEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack;
@end

@implementation NSObject (KukioModContinueGameHooks)

- (void)kukiomod_continueGameSetupWithStateId:(unsigned long long)stateId parameters:(id)parameters {
    [self kukiomod_continueGameSetupWithStateId:stateId parameters:parameters];
    ASLRequestAutoRespawnFromContinueGame(self);
}

- (double)kukiomod_continueGameEnterWithPreviousState:(unsigned long long)state fromStack:(BOOL)fromStack {
    double result = [self kukiomod_continueGameEnterWithPreviousState:state fromStack:fromStack];
    ASLRequestAutoRespawnFromContinueGame(self);
    return result;
}

@end

@interface Menu (KukioModHooks)
- (void)kukiomod_openMenu:(id)tap;
- (void)kukiomod_toggleItemOnOff:(id)tap;
- (void)kukiomod_menuSliderValueChanged:(id)slider;
@end

@implementation Menu (KukioModHooks)

- (void)kukiomod_openMenu:(id)tap {
    ASLBringMenuAboveTetrisIfNeeded();
    [self kukiomod_openMenu:tap];
    ASLBringMenuAboveTetrisIfNeeded();
}

- (void)kukiomod_toggleItemOnOff:(id)tap {
    [self kukiomod_toggleItemOnOff:tap];
    ASLSyncVisionModeFromMenu();
    ASLRefreshZoomControls();
    ASLArmFixedViewEntryPulse();
    ASLScheduleArenaRefresh();
}

- (void)kukiomod_menuSliderValueChanged:(id)slider {
    [self kukiomod_menuSliderValueChanged:slider];
    ASLRefreshZoomControls();
    ASLScheduleArenaRefresh();
}

@end

@interface NSObject (KukioModControlsWidgetHooks)
- (id)kukiomod_init;
- (void)kukiomod_enableInput;
- (void)kukiomod_disableInput;
- (void)kukiomod_enableBurstMode:(BOOL)enabled;
- (void)kukiomod_cleanup;
@end

@implementation NSObject (KukioModControlsWidgetHooks)

- (id)kukiomod_init {
    id object = [self kukiomod_init];
    if([NSStringFromClass([object class]) isEqualToString:@"ControlsWidget"]) {
        sCurrentControlsWidget = object;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ASLRefreshVirusChaseButton();
        });
    }
    return object;
}

- (void)kukiomod_enableInput {
    sCurrentControlsWidget = self;
    [self kukiomod_enableInput];
    BOOL currentBurstEnabled = NO;
    if(ASLReadBoolIvar(self, "_burstModeEnabled", &currentBurstEnabled)) {
        sBurstModeEnabled = currentBurstEnabled;
        sBurstModeValueKnown = YES;
    }
    ASLRefreshVisionForArenaEntry(sCurrentArenaState);
    ASLRefreshVirusChaseButton();
}

- (void)kukiomod_disableInput {
    if(sCurrentControlsWidget == self) {
        sCurrentControlsWidget = nil;
        sBurstModeEnabled = NO;
        sBurstModeValueKnown = NO;
    }
    ASLFinalizeVirusChaseXpSession();
    ASLFinalizeVirusChaseAccountXpSession();
    ASLSuspendVirusChase();
    ASLSuspendFriendChase();
    [self kukiomod_disableInput];
}

- (void)kukiomod_enableBurstMode:(BOOL)enabled {
    sBurstModeEnabled = enabled;
    sBurstModeValueKnown = YES;
    [self kukiomod_enableBurstMode:enabled];
}

- (void)kukiomod_cleanup {
    if(sCurrentControlsWidget == self) {
        sCurrentControlsWidget = nil;
        sBurstModeValueKnown = NO;
    }
    sBurstModeEnabled = NO;
    ASLStopSplitLoop();
    ASLFinalizeVirusChaseXpSession();
    ASLFinalizeVirusChaseAccountXpSession();
    ASLSuspendVirusChase();
    ASLSuspendFriendChase();
    [self kukiomod_cleanup];
}

@end

@interface NSObject (KukioModHudWidgetHooks)
- (void)kukiomod_addWidget:(id)widget;
@end

@implementation NSObject (KukioModHudWidgetHooks)

- (void)kukiomod_addWidget:(id)widget {
    sCurrentHud = self;
    NSString *className = NSStringFromClass([widget class]);
    if([className containsString:@"FriendTracker"])
        sCurrentFriendTrackerWidget = widget;
    if([className containsString:@"Minimap"])
        sCurrentMinimapWidget = widget;
    [self kukiomod_addWidget:widget];
}

@end

@interface NSObject (KukioModFriendTrackerHooks)
- (void)kukiomod_friendTrackerSetDelegate:(id)delegate;
- (void)kukiomod_friendTrackerUpdate:(double)delta;
- (void)kukiomod_friendTrackerTrackClosestFriend;
- (void)kukiomod_friendTrackerSetTargetRotationWithPlayerPosition:(CGPoint)playerPosition andFriendPosition:(CGPoint)friendPosition;
- (void)kukiomod_friendTrackerStartTracker;
@end

@implementation NSObject (KukioModFriendTrackerHooks)

- (void)kukiomod_friendTrackerSetDelegate:(id)delegate {
    sCurrentFriendTrackerWidget = self;
    [self kukiomod_friendTrackerSetDelegate:delegate];
}

- (void)kukiomod_friendTrackerUpdate:(double)delta {
    sCurrentFriendTrackerWidget = self;
    [self kukiomod_friendTrackerUpdate:delta];
    CGPoint ignored = CGPointZero;
    ASLTrackedPartyFriendPosition(&ignored, NULL);
}

- (void)kukiomod_friendTrackerTrackClosestFriend {
    sCurrentFriendTrackerWidget = self;
    [self kukiomod_friendTrackerTrackClosestFriend];
    CGPoint ignored = CGPointZero;
    ASLTrackedPartyFriendPosition(&ignored, NULL);
}

- (void)kukiomod_friendTrackerSetTargetRotationWithPlayerPosition:(CGPoint)playerPosition andFriendPosition:(CGPoint)friendPosition {
    sCurrentFriendTrackerWidget = self;
    if(isfinite(friendPosition.x) && isfinite(friendPosition.y) &&
       (fabs(friendPosition.x) > 0.01 || fabs(friendPosition.y) > 0.01) &&
       fabs(friendPosition.x) < 20000.0 && fabs(friendPosition.y) < 20000.0) {
        sTrackedFriendPosition = friendPosition;
        sTrackedFriendPositionValid = YES;
        sTrackedFriendPositionTime = CACurrentMediaTime();
    }
    [self kukiomod_friendTrackerSetTargetRotationWithPlayerPosition:playerPosition andFriendPosition:friendPosition];
}

- (void)kukiomod_friendTrackerStartTracker {
    sCurrentFriendTrackerWidget = self;
    [self kukiomod_friendTrackerStartTracker];
    CGPoint ignored = CGPointZero;
    ASLTrackedPartyFriendPosition(&ignored, NULL);
}

@end

@interface NSObject (KukioModMinimapWidgetHooks)
- (void)kukiomod_minimapSetupWithDelegate:(id)delegate;
- (void)kukiomod_minimapVisit;
@end

@implementation NSObject (KukioModMinimapWidgetHooks)

- (void)kukiomod_minimapSetupWithDelegate:(id)delegate {
    sCurrentMinimapWidget = self;
    [self kukiomod_minimapSetupWithDelegate:delegate];
}

- (void)kukiomod_minimapVisit {
    sCurrentMinimapWidget = self;
    [self kukiomod_minimapVisit];
}

@end

static BOOL sMenuHooksInstalled = NO;
static BOOL sControlsWidgetHooksInstalled = NO;
static BOOL sBaseArenaViewHooksInstalled = NO;
static BOOL sSoftBodyCellViewHooksInstalled = NO;
static BOOL sPartyCodeHooksInstalled = NO;
static BOOL sPartyShareCodeHooksInstalled = NO;
static BOOL sArenaStateHooksInstalled = NO;
static BOOL sOnlineClassicArenaStateHooksInstalled = NO;
static BOOL sSkinEditorHooksInstalled = YES;
static BOOL sCreateSkinViewHooksInstalled = YES;
static BOOL sMenuMainHooksInstalled = NO;
static BOOL sContinueGameHooksInstalled = NO;
static BOOL sResultRespawnHooksInstalled = NO;
static BOOL sResultTextHooksInstalled = YES;
static BOOL sHudWidgetHooksInstalled = NO;
static BOOL sFriendTrackerHooksInstalled = NO;
static BOOL sMinimapWidgetHooksInstalled = NO;

static void ASLInstallRuntimeHooks() {
    if(!sMenuHooksInstalled) {
        Class menuClass = NSClassFromString(@"Menu");
        if(menuClass != nil) {
            ASLSwizzleInstanceMethod(menuClass, NSSelectorFromString(@"openMenu:"), @selector(kukiomod_openMenu:));
            ASLSwizzleInstanceMethod(menuClass, NSSelectorFromString(@"toggleItemOnOff:"), @selector(kukiomod_toggleItemOnOff:));
            ASLSwizzleInstanceMethod(menuClass, NSSelectorFromString(@"menuSliderValueChanged:"), @selector(kukiomod_menuSliderValueChanged:));
            sMenuHooksInstalled = YES;
        }
    }

    if(!sBaseArenaViewHooksInstalled) {
        Class baseArenaViewClass = NSClassFromString(@"BaseArenaView");
        if(baseArenaViewClass != nil) {
            ASLSwizzleInstanceMethod(baseArenaViewClass, NSSelectorFromString(@"calculateZoom:cellAmount:"), @selector(kukiomod_calculateZoom:cellAmount:));
            ASLSwizzleInstanceMethod(baseArenaViewClass, NSSelectorFromString(@"setupWithBackground:initialState:"), @selector(kukiomod_setupWithBackground:initialState:));
            ASLSwizzleInstanceMethod(baseArenaViewClass, NSSelectorFromString(@"update:"), @selector(kukiomod_update:));
            sBaseArenaViewHooksInstalled = YES;
        }
    }

    if(!sPartyCodeHooksInstalled) {
        Class partyViewClass = NSClassFromString(@"ContentPartyCreatedOrJoinedView");
        if(partyViewClass != nil) {
            ASLSwizzleInstanceMethod(partyViewClass,
                                     NSSelectorFromString(@"setupLayoutWithPartyCode:isFacebookAccount:subtitle:"),
                                     @selector(kukiomod_setupLayoutWithPartyCode:isFacebookAccount:subtitle:));
            sPartyCodeHooksInstalled = YES;
        }
    }

    if(!sPartyShareCodeHooksInstalled) {
        Class partyShareViewClass = NSClassFromString(@"MenuPartyModeShareWithFriendsView");
        if(partyShareViewClass != nil) {
            ASLSwizzleInstanceMethod(partyShareViewClass,
                                     NSSelectorFromString(@"setupLayoutWithPartyCode:productAmountAndName:"),
                                     @selector(kukiomod_setupLayoutWithPartyCode:productAmountAndName:));
            sPartyShareCodeHooksInstalled = YES;
        }
    }

    if(!sArenaStateHooksInstalled) {
        Class baseArenaStateClass = NSClassFromString(@"BaseArenaState");
        if(baseArenaStateClass != nil) {
            ASLSwizzleInstanceMethod(baseArenaStateClass,
                                     NSSelectorFromString(@"setupWithStateId:parameters:"),
                                     @selector(kukiomod_setupWithStateId:parameters:));
            sArenaStateHooksInstalled = YES;
        }
    }

    if(!sBaseArenaViewHooksInstalled || !sMenuHooksInstalled || !sPartyCodeHooksInstalled || !sPartyShareCodeHooksInstalled || !sArenaStateHooksInstalled) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ASLInstallRuntimeHooks();
        });
    }
}
__attribute__((constructor))
static void KukioModLoad(void) {
    @autoreleasepool {
        NSString *bundleId = NSBundle.mainBundle.bundleIdentifier ?: @"";
        if(![bundleId hasPrefix:@"com.miniclip.agar.io"])
            return;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            InstallImages();
            ASLInstallRuntimeHooks();
            initMenu();
        });
    }
}

