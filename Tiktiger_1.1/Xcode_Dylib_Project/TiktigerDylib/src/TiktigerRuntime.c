#include "Tiktiger.h"

#include <stdatomic.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static atomic_int g_dylib_loaded = 0;
static atomic_int g_initializer_executed = 0;
static atomic_int g_core_started = 0;
static atomic_int g_feature_registry_ready = 0;
static atomic_int g_ui_registered = 0;
static atomic_int g_ui_presented = 0;
static atomic_ulong g_runtime_sequence = 0;

static long long tt_runtime_timestamp(void) {
    return (long long)time(NULL);
}

static void tt_runtime_log(const char *event) {
    fprintf(stderr, "[TiktigerRuntime] timestamp=%lld event=%s product=%s version=%s sequence=%lu\n",
            tt_runtime_timestamp(),
            event,
            TT_PRODUCT_NAME,
            TT_RELEASE_VERSION,
            (unsigned long)atomic_load(&g_runtime_sequence));
}

static void tt_runtime_bootstrap(void) {
    /* The constructor owns load/initializer/Core/registry only. UI remains Host-owned. */
    atomic_store(&g_initializer_executed, 1);
    atomic_store(&g_core_started, 1);
    atomic_store(&g_feature_registry_ready, tt_feature_count() > 0 ? 1 : 0);
    atomic_fetch_add(&g_runtime_sequence, 1);
    tt_runtime_log("initializer_executed");
    tt_runtime_log(atomic_load(&g_feature_registry_ready) ? "core_started" : "core_start_failed");
    tt_runtime_log(atomic_load(&g_feature_registry_ready) ? "feature_registry_ready" : "feature_registry_failed");
}

#if defined(__GNUC__)
__attribute__((constructor))
#endif
static void tt_runtime_constructor(void) {
    /* Do not set g_ui_registered or g_ui_presented here. The Host owns those milestones. */
    atomic_store(&g_dylib_loaded, 1);
    atomic_fetch_add(&g_runtime_sequence, 1);
    tt_runtime_log("dylib_loaded");
    tt_runtime_bootstrap();
}

void tt_runtime_initialize(void) {
    if (!atomic_load(&g_initializer_executed)) {
        tt_runtime_bootstrap();
    }
    tt_runtime_log("initialize_called");
}

void tt_runtime_mark_ui_registered(void) {
    tt_runtime_initialize();
    atomic_store(&g_ui_registered, 1);
    atomic_fetch_add(&g_runtime_sequence, 1);
    tt_runtime_log("ui_registered");
}

void tt_runtime_mark_ui_presented(void) {
    tt_runtime_initialize();
    if (!atomic_load(&g_ui_registered)) {
        tt_runtime_log("ui_present_failed_not_registered");
        return;
    }
    atomic_store(&g_ui_presented, 1);
    atomic_fetch_add(&g_runtime_sequence, 1);
    tt_runtime_log("ui_presented");
}

int tt_runtime_dylib_loaded(void) {
    return atomic_load(&g_dylib_loaded);
}

int tt_runtime_initializer_executed(void) {
    return atomic_load(&g_initializer_executed);
}

int tt_runtime_core_started(void) {
    return atomic_load(&g_core_started);
}

int tt_runtime_feature_registry_ready(void) {
    return atomic_load(&g_feature_registry_ready);
}

int tt_runtime_ui_registered(void) {
    return atomic_load(&g_ui_registered);
}

int tt_runtime_ui_presented(void) {
    return atomic_load(&g_ui_presented);
}

const char *tt_runtime_diagnostics_json(void) {
    static char buffer[768];
    int written = snprintf(
        buffer,
        sizeof(buffer),
        "{\"product\":\"%s\",\"version\":\"%s\",\"dylibLoaded\":%d,\"initializerExecuted\":%d,\"coreStarted\":%d,\"featureRegistryReady\":%d,\"uiRegistered\":%d,\"uiPresented\":%d,\"sequence\":%lu}",
        TT_PRODUCT_NAME,
        TT_RELEASE_VERSION,
        tt_runtime_dylib_loaded(),
        tt_runtime_initializer_executed(),
        tt_runtime_core_started(),
        tt_runtime_feature_registry_ready(),
        tt_runtime_ui_registered(),
        tt_runtime_ui_presented(),
        (unsigned long)atomic_load(&g_runtime_sequence)
    );
    return written > 0 && (size_t)written < sizeof(buffer) ? buffer : "{}";
}
