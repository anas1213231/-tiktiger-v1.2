#include "Tiktiger.h"

#include <ctype.h>
#include <stdatomic.h>
#include <string.h>

static atomic_int g_enabled = 1;
static atomic_uint_fast64_t g_counter = 0;

const char *tt_version(void) {
    return TT_RELEASE_VERSION;
}

void tt_set_enabled(int enabled) {
    atomic_store(&g_enabled, enabled ? 1 : 0);
}

int tt_is_enabled(void) {
    return atomic_load(&g_enabled);
}

uint64_t tt_increment_counter(void) {
    return atomic_fetch_add(&g_counter, 1) + 1;
}

void tt_reset_counter(void) {
    atomic_store(&g_counter, 0);
}

int tt_uppercase_ascii(const char *input, char *output, size_t output_size) {
    if (input == NULL || output == NULL || output_size == 0) {
        return -1;
    }

    size_t len = strlen(input);
    if (output_size <= len) {
        return -1;
    }

    for (size_t i = 0; i < len; ++i) {
        unsigned char ch = (unsigned char)input[i];
        output[i] = (char)toupper(ch);
    }
    output[len] = '\0';
    return 0;
}

uint64_t tt_checksum(const char *input) {
    if (input == NULL) {
        return 0;
    }

    uint64_t hash = UINT64_C(1469598103934665603);
    while (*input) {
        hash ^= (unsigned char)(*input++);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}
