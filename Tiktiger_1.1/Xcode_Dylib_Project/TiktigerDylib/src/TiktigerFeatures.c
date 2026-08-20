#include "Tiktiger.h"

#include <ctype.h>
#include <stdatomic.h>
#include <stdio.h>
#include <string.h>

#define TT_FEATURE_COUNT 10

typedef struct {
    const char *key;
    atomic_int enabled;
} TTFeatureState;

static TTFeatureState g_features[TT_FEATURE_COUNT] = {
    {"downloadMedia", 1},
    {"downloadStories", 1},
    {"downloadAudio", 0},
    {"readChats", 0},
    {"ghostTyping", 0},
    {"lockChats", 0},
    {"lockFavorites", 0},
    {"privateProfile", 1},
    {"liquidControls", 0},
    {"followConfirm", 0}
};

static atomic_int g_stage = TT_DOWNLOAD_IDLE;

const char *tt_product_name(void) {
    return TT_PRODUCT_NAME;
}

static int tt_find_feature(const char *feature_key) {
    if (feature_key == NULL || feature_key[0] == '\0') {
        return -1;
    }
    for (int i = 0; i < TT_FEATURE_COUNT; ++i) {
        if (strcmp(g_features[i].key, feature_key) == 0) {
            return i;
        }
    }
    return -1;
}

int tt_set_feature_enabled(const char *feature_key, int enabled) {
    int index = tt_find_feature(feature_key);
    if (index < 0) {
        return -1;
    }
    atomic_store(&g_features[index].enabled, enabled ? 1 : 0);
    return 0;
}

int tt_feature_enabled(const char *feature_key) {
    int index = tt_find_feature(feature_key);
    if (index < 0) {
        return -1;
    }
    return atomic_load(&g_features[index].enabled);
}

size_t tt_feature_count(void) {
    return TT_FEATURE_COUNT;
}

const char *tt_feature_key_at(size_t index) {
    return index < TT_FEATURE_COUNT ? g_features[index].key : NULL;
}

int tt_validate_https_url(const char *url) {
    if (url == NULL || strncmp(url, "https://", 8) != 0) {
        return 0;
    }

    const char *host = url + 8;
    if (*host == '\0' || *host == '/' || *host == '?' || *host == '#') {
        return 0;
    }

    for (const unsigned char *cursor = (const unsigned char *)host; *cursor; ++cursor) {
        if (isspace(*cursor) || iscntrl(*cursor)) {
            return 0;
        }
    }
    return 1;
}

int tt_sanitize_filename(const char *input, char *output, size_t output_size) {
    if (input == NULL || output == NULL || output_size < 2) {
        return -1;
    }

    size_t written = 0;
    for (size_t i = 0; input[i] != '\0' && written + 1 < output_size; ++i) {
        unsigned char ch = (unsigned char)input[i];
        if (iscntrl(ch)) {
            continue;
        }
        switch (ch) {
            case '/': case '\\': case ':': case '*': case '?':
            case '"': case '<': case '>': case '|':
                output[written++] = '_';
                break;
            default:
                output[written++] = (char)ch;
                break;
        }
    }
    while (written > 0 && (output[written - 1] == ' ' || output[written - 1] == '.')) {
        --written;
    }
    if (written == 0) {
        output[0] = '\0';
        return -1;
    }
    output[written] = '\0';
    return 0;
}

void tt_set_download_stage(TTDownloadStage stage) {
    if (stage < TT_DOWNLOAD_IDLE || stage > TT_DOWNLOAD_CANCELLED) {
        stage = TT_DOWNLOAD_FAILED;
    }
    atomic_store(&g_stage, stage);
}

TTDownloadStage tt_download_stage(void) {
    return (TTDownloadStage)atomic_load(&g_stage);
}

const char *tt_download_stage_name(TTDownloadStage stage) {
    switch (stage) {
        case TT_DOWNLOAD_IDLE: return "Idle";
        case TT_DOWNLOAD_VALIDATING: return "Validating";
        case TT_DOWNLOAD_DOWNLOADING: return "Downloading";
        case TT_DOWNLOAD_EXTRACTING_AUDIO: return "ExtractingAudio";
        case TT_DOWNLOAD_SAVING: return "Saving";
        case TT_DOWNLOAD_COMPLETED: return "Completed";
        case TT_DOWNLOAD_FAILED: return "Failed";
        case TT_DOWNLOAD_CANCELLED: return "Cancelled";
        default: return "Unknown";
    }
}

const char *tt_diagnostics_json(void) {
    static char buffer[512];
    int written = snprintf(
        buffer,
        sizeof(buffer),
        "{\"product\":\"%s\",\"version\":\"%s\",\"featureCount\":%zu,\"downloadStage\":\"%s\"}",
        TT_PRODUCT_NAME,
        TT_RELEASE_VERSION,
        tt_feature_count(),
        tt_download_stage_name(tt_download_stage())
    );
    return written > 0 && (size_t)written < sizeof(buffer) ? buffer : "{}";
}
