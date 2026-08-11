/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`; rebranded the licence header.

#import <XCTest/XCTest.h>

#if TARGET_OS_IOS

@import AtatusSessionReplay;

@interface ATSessionReplay_apiTests : XCTestCase
@end

@implementation ATSessionReplay_apiTests

// MARK: Configuration

- (void)testConfigurationWithNewApi {
    ATSessionReplayConfiguration *configuration = [[ATSessionReplayConfiguration alloc] initWithReplaySampleRate:100
                                                                                        textAndInputPrivacyLevel:ATTextAndInputPrivacyLevelMaskAll
                                                                                               imagePrivacyLevel:ATImagePrivacyLevelMaskNone
                                                                                               touchPrivacyLevel:ATTouchPrivacyLevelShow
                                                                                                    featureFlags:nil];
    configuration.customEndpoint = [NSURL new];

    configuration.textAndInputPrivacyLevel = ATTextAndInputPrivacyLevelMaskSensitiveInputs;
    configuration.imagePrivacyLevel = ATImagePrivacyLevelMaskAll;
    configuration.touchPrivacyLevel = ATTouchPrivacyLevelHide;

    [ATSessionReplay enableWith:configuration];
}

- (void)testStartAndStopRecording {
    [ATSessionReplay startRecording];
    [ATSessionReplay stopRecording];
}

- (void)testSessionReplayInstanceNameAPI {
    ATSessionReplayConfiguration *configuration = [[ATSessionReplayConfiguration alloc] initWithReplaySampleRate:100
                                                                                        textAndInputPrivacyLevel:ATTextAndInputPrivacyLevelMaskAll
                                                                                               imagePrivacyLevel:ATImagePrivacyLevelMaskNone
                                                                                               touchPrivacyLevel:ATTouchPrivacyLevelShow
                                                                                                    featureFlags:nil];
    NSString *instanceName = @"sr-test-instance";
    [ATSessionReplay enableWith:configuration instanceName:instanceName];
    [ATSessionReplay startRecordingWithInstanceName:instanceName];
    [ATSessionReplay stopRecordingWithInstanceName:instanceName];
}

- (void)testStartRecordingImmediately {
    ATSessionReplayConfiguration *configuration = [[ATSessionReplayConfiguration alloc] initWithReplaySampleRate:100
                                                                                        textAndInputPrivacyLevel:ATTextAndInputPrivacyLevelMaskAll
                                                                                               imagePrivacyLevel:ATImagePrivacyLevelMaskAll
                                                                                               touchPrivacyLevel:ATTouchPrivacyLevelHide
                                                                                                    featureFlags:nil];

    configuration.startRecordingImmediately = false;

    XCTAssertFalse(configuration.startRecordingImmediately);
}

// MARK: Privacy Overrides
- (void)testSettingAndGettingOverrides {
    // Given
    UIView *view = [[UIView alloc] init];

    // When
    view.atSessionReplayPrivacyOverrides.textAndInputPrivacy = ATTextAndInputPrivacyLevelOverrideMaskAll;
    view.atSessionReplayPrivacyOverrides.imagePrivacy = ATImagePrivacyLevelOverrideMaskAll;
    view.atSessionReplayPrivacyOverrides.touchPrivacy = ATTouchPrivacyLevelOverrideHide;
    view.atSessionReplayPrivacyOverrides.hide = @YES;

    // Then
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.textAndInputPrivacy, ATTextAndInputPrivacyLevelOverrideMaskAll);
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.imagePrivacy, ATImagePrivacyLevelOverrideMaskAll);
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.touchPrivacy, ATTouchPrivacyLevelOverrideHide);
    XCTAssertTrue(view.atSessionReplayPrivacyOverrides.hide.boolValue);
}

- (void)testClearingOverride {
    // Given
    UIView *view = [[UIView alloc] init];

    // Set initial values
    view.atSessionReplayPrivacyOverrides.textAndInputPrivacy = ATTextAndInputPrivacyLevelOverrideMaskAll;
    view.atSessionReplayPrivacyOverrides.imagePrivacy = ATImagePrivacyLevelOverrideMaskAll;
    view.atSessionReplayPrivacyOverrides.touchPrivacy = ATTouchPrivacyLevelOverrideHide;
    view.atSessionReplayPrivacyOverrides.hide = @YES;

    // When
    view.atSessionReplayPrivacyOverrides.textAndInputPrivacy = ATTextAndInputPrivacyLevelOverrideNone;
    view.atSessionReplayPrivacyOverrides.imagePrivacy = ATImagePrivacyLevelOverrideNone;
    view.atSessionReplayPrivacyOverrides.touchPrivacy = ATTouchPrivacyLevelOverrideNone;
    view.atSessionReplayPrivacyOverrides.hide = nil;

    // Then
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.textAndInputPrivacy, ATTextAndInputPrivacyLevelOverrideNone);
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.imagePrivacy, ATImagePrivacyLevelOverrideNone);
    XCTAssertEqual(view.atSessionReplayPrivacyOverrides.touchPrivacy, ATTouchPrivacyLevelOverrideNone);
    XCTAssertNil(view.atSessionReplayPrivacyOverrides.hide);
}
@end

#endif
