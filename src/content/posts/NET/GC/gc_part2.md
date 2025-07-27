---
title: Reading CoreClr Code- 18 Reasons Trigger GC in DotNET (Part 1)
published: 2025-07-29
description: "Some Info"
image: ""
tags: [DOTNET, GC, CSharp, CoreClr]
category: "CoreClr"
draft: false
lang: "en"
---

# The 18 triggers in GC By reading DOTNET Source Code

By reading DOTNET source code , in file [runtime/src/coreclr/gc
/gc.cpp](https://github.com/dotnet/runtime/blob/main/src/coreclr/gc/gc.cpp)

```cs
// These values should be in sync with the GC_REASONs (in eventtrace.h) used for ETW.
// TODO : it would be easier to make this an ORed value
enum gc_reason
{
    reason_alloc_soh = 0,
    reason_induced = 1,
    reason_lowmemory = 2,
    reason_empty = 3,
    reason_alloc_loh = 4,
    reason_oos_soh = 5,
    reason_oos_loh = 6,
    reason_induced_noforce = 7, // it's an induced GC and doesn't have to be blocking.
    reason_gcstress = 8,        // this turns into reason_induced & gc_mechanisms.stress_induced = true
    reason_lowmemory_blocking = 9,
    reason_induced_compacting = 10,
    reason_lowmemory_host = 11,
    reason_pm_full_gc = 12, // provisional mode requested to trigger full GC
    reason_lowmemory_host_blocking = 13,
    reason_bgc_tuning_soh = 14,
    reason_bgc_tuning_loh = 15,
    reason_bgc_stepping = 16,
    reason_induced_aggressive = 17,
    reason_max
};
```

## The GC Reasons

Based on the provided `gc_reason` enumeration from the .NET source code in `runtime/src/coreclr/gc/gc.cpp`

1. **Generation Full**: When a generation's scope is exhausted, corresponding to the `xxx_alloc_xxx` enumeration values.

   - Enum values:
     - `reason_alloc_soh` (Small Object Heap allocation triggering GC)
     - `reason_alloc_loh` (Large Object Heap allocation triggering GC)

2. **Segment Full**: When the allocated segment requires expansion or is depleted, corresponding to the `xxx_oos_xxx` enumeration values.

   - Enum values:
     - `reason_oos_soh` (Out of space in Small Object Heap)
     - `reason_oos_loh` (Out of space in Large Object Heap)

3. **Deliberate Induction**: GC intentionally triggered at the C# or CLR level, corresponding to the `xxx_induced_xxx` enumeration values.

   - Enum values:
     - `reason_induced` (Standard induced GC, typically blocking)
     - `reason_induced_noforce` (Induced GC, non-blocking)
     - `reason_induced_compacting` (Induced GC with compaction)
     - `reason_induced_aggressive` (Aggressive induced GC)

4. **Low Memory**: Insufficient memory within the operating system, forcing CLR to proactively initiate GC, corresponding to the `xxx_lowmemory_xxx` enumeration values.

   - Enum values:
     - `reason_lowmemory` (General low memory condition)
     - `reason_lowmemory_blocking` (Low memory triggering a blocking GC)
     - `reason_lowmemory_host` (Low memory reported by the host)
     - `reason_lowmemory_host_blocking` (Low memory reported by the host, triggering a blocking GC)

5. **Other**: Various reasons, such as configuring parameters to make GC trigger more aggressively, for example, the `reason_gcstress` enumeration value.
   - Enum values:
     - `reason_gcstress` (GC triggered due to stress testing)
     - `reason_empty` (GC triggered due to an empty generation)
     - `reason_pm_full_gc` (Provisional mode requested to trigger full GC)
     - `reason_bgc_tuning_soh` (Background GC tuning for Small Object Heap)
     - `reason_bgc_tuning_loh` (Background GC tuning for Large Object Heap)
     - `reason_bgc_stepping` (Background GC stepping)

### Summary Table

| Category                 | Enum Values                                                                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| **Generation Full**      | `reason_alloc_soh`, `reason_alloc_loh`                                                                                          |
| **Segment Full**         | `reason_oos_soh`, `reason_oos_loh`                                                                                              |
| **Deliberate Induction** | `reason_induced`, `reason_induced_noforce`, `reason_induced_compacting`, `reason_induced_aggressive`                            |
| **Low Memory**           | `reason_lowmemory`, `reason_lowmemory_blocking`, `reason_lowmemory_host`, `reason_lowmemory_host_blocking`                      |
| **Other**                | `reason_gcstress`, `reason_empty`, `reason_pm_full_gc`, `reason_bgc_tuning_soh`, `reason_bgc_tuning_loh`, `reason_bgc_stepping` |
