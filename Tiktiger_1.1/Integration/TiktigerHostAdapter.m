#import "TiktigerHostAdapter.h"

@implementation TiktigerHostAdapter

- (BOOL)validateDirectMediaURL:(NSURL *)url {
    const char *value = url.absoluteString.UTF8String;
    return value != NULL && tt_validate_https_url(value) == 1;
}

- (BOOL)setFeature:(NSString *)featureKey enabled:(BOOL)enabled {
    const char *key = featureKey.UTF8String;
    return key != NULL && tt_set_feature_enabled(key, enabled ? 1 : 0) == 0;
}

- (BOOL)isFeatureEnabled:(NSString *)featureKey {
    const char *key = featureKey.UTF8String;
    return key != NULL && tt_feature_enabled(key) == 1;
}

- (NSString *)safeFilenameForName:(NSString *)name {
    const char *input = name.UTF8String;
    if (input == NULL) {
        return @"Tiktiger-Media";
    }

    char output[256] = {0};
    if (tt_sanitize_filename(input, output, sizeof(output)) != 0) {
        return @"Tiktiger-Media";
    }
    return [NSString stringWithUTF8String:output] ?: @"Tiktiger-Media";
}

- (void)setDownloadStage:(TTDownloadStage)stage {
    tt_set_download_stage(stage);
}

- (NSString *)downloadStageName {
    return [NSString stringWithUTF8String:tt_download_stage_name(tt_download_stage())] ?: @"Unknown";
}

- (NSString *)diagnosticsJSON {
    return [NSString stringWithUTF8String:tt_diagnostics_json()] ?: @"{}";
}

- (void)initializeRuntime {
    tt_runtime_initialize();
}

- (void)markUIRegistered {
    tt_runtime_mark_ui_registered();
}

- (void)markUIPresented {
    tt_runtime_mark_ui_presented();
}

- (NSString *)runtimeDiagnosticsJSON {
    return [NSString stringWithUTF8String:tt_runtime_diagnostics_json()] ?: @"{}";
}

- (BOOL)runtimeDylibLoaded {
    return tt_runtime_dylib_loaded() == 1;
}

@end
