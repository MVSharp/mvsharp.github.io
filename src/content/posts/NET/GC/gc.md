---
title: "What Is GC (Part 1)"
published: 2025-07-28
description: "Some Info"
image: ""
tags: [DOTNET, GC, CSharp]
category: "DOTNET"
draft: false
lang: "en"
---

## Key Concepts in Garbage Collection

Before we start , we needed to know some common terms for GC
Terms Garbage Collection (GC) in the Common Language Runtime (CLR), with descriptions to aid understanding.

- **Mark and Sweep / Compact**

  - The GC process involves two main phases: _Mark and Sweep_ identifies live objects (marking) and removes unreachable ones (sweeping), while _Compaction_ moves surviving objects to eliminate memory fragmentation, optimizing the managed heap for future allocations. Compaction is typically applied to small objects but can be enabled for the large object heap (LOH) on demand in newer .NET versions.

- **GC Root**

  - : GC Roots are starting points for the garbage collector to determine object reachability. They include static fields, local variables on a thread’s stack, CPU registers, GC handles, and the finalize queue. Objects referenced by roots are considered live; those not in the reachability graph are deemed garbage and reclaimed.

- **Stop The World (STW)**

  - : During a garbage collection, all managed threads (except the one triggering the GC) are suspended to ensure a consistent heap state. This pause, known as **Stop The World**, ensures the GC can accurately mark and compact objects without interference from running threads.
    :::Tip
    So When we optimize .NET code , we wanted less STW occurs
    also we wanted to minized STW time even STW occurs
    :::

- **Condemn Generation (0, 1, 2, Full GC)**

  - : The managed heap is divided into three generations (0, 1, 2) to optimize GC performance. Generation 0 holds newly allocated, short-lived objects; Generation 1 acts as a buffer for objects surviving Generation 0; Generation 2 contains long-lived objects. A _Full GC_ (Generation 2 collection) reclaims objects across all generations. A generation is "condemned" when it’s selected for collection, including all younger generations.
    :::Tip
    For optimizing .NET code we wanted less objects to GEN 2
    :::

- **Workstation and Server GC**

  - : The CLR supports two GC modes: _Workstation GC_ is optimized for client applications, minimizing pauses for responsiveness, with smaller ephemeral segment sizes (e.g., 16 MB on 32-bit, 256 MB on 64-bit). _Server GC_ is designed for high-throughput server applications, using larger segments (e.g., 64 MB on 32-bit, up to 4 GB on 64-bit) and parallel collections but with potentially longer pauses.

- **Blocking and Background GC**

  - : _Blocking GC_ suspends all managed threads during the entire collection, causing noticeable pauses, especially in Generation 2 collections. _Background GC_ (available in .NET Framework 4 and later) allows Generation 0 and 1 collections to run concurrently with application threads, reducing pause times, while Generation 2 collections may still block.

- **Preemptive and Cooperative**
  - : Thread suspension during GC can be _Preemptive_, where the runtime forcibly pauses threads at any point, or _Cooperative_, where threads are paused only at safe points (e.g., during method calls or when explicitly yielding). Cooperative suspension is more predictable but may delay GC slightly until threads reach safe points.
- **Managed Heap**: A contiguous virtual memory region for allocating objects, divided into small object heap and large object heap (LOH, for objects ≥ 85,000 bytes). The GC manages this heap, compacting small objects and optionally large ones to reduce fragmentation.
- **Triggers for GC**: Low physical memory, excessive heap usage, or explicit calls to `GC.Collect` (rarely needed, mainly for testing).
- **Unmanaged Resources**: Objects wrapping resources like file handles require explicit cleanup via a `Dispose` method or safe handles, as the GC lacks specific knowledge to reclaim them.
- **Performance Optimization**: Generational GC reduces overhead by focusing on short-lived objects (Generation 0). Fewer heap allocations and smaller object sizes minimize GC workload.

For more in-depth information, refer to: [Microsoft Learn - Fundamentals of Garbage Collection](https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/fundamentals).
