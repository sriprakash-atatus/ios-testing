/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#ifndef AT_PROFILER_DD_PPROF_TESTING_H_
#define AT_PROFILER_DD_PPROF_TESTING_H_

#ifdef __APPLE__
#include <TargetConditionals.h>
#if !TARGET_OS_WATCH

#include <stddef.h>
#include "dd_pprof.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Returns the number of deduplicated samples stored in the profile.
 *
 * @param profile Profile pointer or NULL.
 * @return Sample count, or 0 if `profile` is NULL.
 *
 * @warning FOR TESTING USE ONLY - Not intended for production environments
 */
size_t dd_pprof_sample_count(dd_pprof_t* profile);

#ifdef __cplusplus
}
#endif

#endif // !TARGET_OS_WATCH
#endif // __APPLE__

#endif // AT_PROFILER_DD_PPROF_TESTING_H_
