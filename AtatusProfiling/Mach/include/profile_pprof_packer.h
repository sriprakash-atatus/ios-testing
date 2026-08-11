/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#ifndef AT_PROFILER_PROFILE_PACKER_H_
#define AT_PROFILER_PROFILE_PACKER_H_

#ifdef __APPLE__
#include <TargetConditionals.h>
#if !TARGET_OS_WATCH

#include <cstdint>
#include <cstddef>

namespace dd::profiler {

class profile;

/**
 * Pack profile data into pprof protobuf binary format
 *
 * Converts internal profile data structures to the standardized pprof
 * protobuf format for serialization and consumption by profiling tools.
 *
 * @param prof The profile data to pack
 * @param data Output buffer pointer - allocated buffer containing serialized data
 * @return Size of serialized data in bytes, or 0 on failure
 * 
 * @note The caller is responsible for freeing the returned buffer with free()
 * @note This function is thread-safe and does not modify the input profile
 */
size_t profile_pprof_pack(const profile& prof, uint8_t** data);

} // namespace dd::profiler

#endif // !TARGET_OS_WATCH
#endif // __APPLE__

#endif // AT_PROFILER_PROFILE_PACKER_H_
