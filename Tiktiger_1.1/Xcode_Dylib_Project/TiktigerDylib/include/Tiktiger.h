#ifndef TIKTIGER_H
#define TIKTIGER_H

#include <stddef.h>
#include <stdint.h>

#if defined(__GNUC__)
#define TT_EXPORT __attribute__((visibility("default")))
#else
#define TT_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define TT_PRODUCT_NAME "Tiktiger"
#define TT_RELEASE_VERSION "1.1"

/** Returns the product name, always "Tiktiger". */
TT_EXPORT const char *tt_product_name(void);

/** Returns the public release version, currently "1.1". */
TT_EXPORT const char *tt_version(void);

TT_EXPORT void tt_set_enabled(int enabled);
TT_EXPORT int tt_is_enabled(void);

TT_EXPORT uint64_t tt_increment_counter(void);
TT_EXPORT void tt_reset_counter(void);

/** Uppercases ASCII characters. Returns 0 on success, -1 for invalid arguments. */
TT_EXPORT int tt_uppercase_ascii(const char *input, char *output, size_t output_size);

/** Small deterministic checksum for diagnostics/testing. */
TT_EXPORT uint64_t tt_checksum(const char *input);

/** Enable or disable a supported feature key. Returns 0 on success, -1 if unknown/invalid. */
TT_EXPORT int tt_set_feature_enabled(const char *feature_key, int enabled);

/** Returns 1 enabled, 0 disabled, or -1 for an unknown/invalid feature key. */
TT_EXPORT int tt_feature_enabled(const char *feature_key);

/** Returns the number of feature keys supported by this core. */
TT_EXPORT size_t tt_feature_count(void);

/** Returns the key at index, or NULL when index is out of range. */
TT_EXPORT const char *tt_feature_key_at(size_t index);

/** Validates an HTTPS URL without performing a network request. */
TT_EXPORT int tt_validate_https_url(const char *url);

/** Sanitizes a filename for temporary/local storage. Returns 0 on success. */
TT_EXPORT int tt_sanitize_filename(const char *input, char *output, size_t output_size);

typedef enum {
    TT_DOWNLOAD_IDLE = 0,
    TT_DOWNLOAD_VALIDATING = 1,
    TT_DOWNLOAD_DOWNLOADING = 2,
    TT_DOWNLOAD_EXTRACTING_AUDIO = 3,
    TT_DOWNLOAD_SAVING = 4,
    TT_DOWNLOAD_COMPLETED = 5,
    TT_DOWNLOAD_FAILED = 6,
    TT_DOWNLOAD_CANCELLED = 7
} TTDownloadStage;

TT_EXPORT void tt_set_download_stage(TTDownloadStage stage);
TT_EXPORT TTDownloadStage tt_download_stage(void);
TT_EXPORT const char *tt_download_stage_name(TTDownloadStage stage);

/** Returns a small diagnostics JSON string without secrets or user data. */
TT_EXPORT const char *tt_diagnostics_json(void);

#ifdef __cplusplus
}
#endif

#endif /* TIKTIGER_H */
