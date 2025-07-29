---
title: Reading CoreClr Code- GC The Mark Queue
published: 2025-08-01
description: "Some small talks about GCHeap::mark_queue
image: "./mark_queue/full.svg"
tags: [DOTNET, GC, CSharp, CoreClr]
category: "CoreClr"
draft: false
lang: "en"
---

::github{repo="dotnet/runtime"}

# Overview

The **mark_queue** is like a to-do list for the garbage collector, holding objects that need to be checked to see if they’re still needed by the program. The sequence diagram below shows how the garbage collector uses this list, starting with objects in a thread’s memory, marking them, processing the list, handling special cases, and dealing with objects that need extra cleanup.

# WorkFlow

| **Method**            | **Role**                                         | **Interaction with `mark_queue`**                                  |
| --------------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| `mark_thread_heap`    | Initiates marking for thread-specific objects    | Adds thread-local roots to `mark_queue`                            |
| `mark_object_simple`  | Marks an object as live and scans its references | Dequeues object, marks it, adds references to `mark_queue`         |
| `drain_mark_queue`    | Processes all objects in the queue until empty   | Repeatedly dequeues and processes objects                          |
| `mark_object_simple1` | Handles special cases (e.g., pinned objects)     | Marks special objects, adds references to `mark_queue` if needed   |
| `finalize_queue`      | Manages objects with finalizers                  | Indirectly related; populated with unreachable finalizable objects |

### Step Explanation of `gc_heap::mark_queue` Workflow in .NET CoreCLR

overview of the `gc_heap::mark_queue` workflow in the .NET CoreCLR garbage collector, the sequence of method calls specified: `mark_thread_heap` → `mark_object_simple` → `drain_mark_queue` → `mark_object_simple1` → `finalize_queue` → `mark_object_simple` → `drain_mark_queue` → `mark_object_simple1` → end.

# General Process

# Purpose of `mark_queue`

- **Core Function**: The `mark_queue` is a data structure that holds references to objects that need to be processed during the mark phase of garbage collection.
- **Role in GC**:
  - It manages the traversal of the object graph, ensuring all reachable objects are marked as live.
  - It acts as a temporary storage for objects discovered during marking but not yet fully processed.
- **Analogy**: Think of the `mark_queue` as a to-do list for the GC, where each item is an object that needs to be checked to see if it’s still in use and what other objects it points to.

# Structure of `mark_queue`

- **Likely Implementation**:
  - The `mark_queue` is likely implemented as a First-In-First-Out (FIFO) queue to support breadth-first traversal of the object graph.
  - It may be an array-based structure or a specialized data structure optimized for performance, as suggested by references to `mark_stack_array` in the CoreCLR source code ([GitHub: gc.cpp](https://github.com/dotnet/runtime/blob/main/src/coreclr/gc/gc.cpp)).
  - Variables like `mark_stack_tos` (top of stack) and `mark_stack_bos` (bottom of stack) indicate a stack-like behavior, but it functions as a queue for marking purposes.
- **Key Properties**:
  - Stores pointers to objects on the managed heap.
  - Supports dynamic resizing to handle varying numbers of objects.
  - In server GC modes, it likely includes thread-safe mechanisms to allow concurrent access by multiple GC threads.
- **Performance Considerations**:
  - Optimized to minimize overhead, as the mark phase can impact application performance.
  - May use lock-free techniques or parallel processing to enhance efficiency.

# `mark_thread_heap`

- **Purpose**: Initiates marking for objects associated with a specific thread, particularly for thread-local storage or thread-specific heaps.
- **Interaction with `mark_queue`**:
  - Adds thread-local roots (e.g., objects referenced by thread-local variables) to the `mark_queue`.
  - Ensures that thread-specific objects are included in the marking process.
- **Usage**: Critical in multi-threaded environments, especially in server GC modes where each thread may have its own heap.

# Conculsion

The **mark_queue** is a pivotal component in the .NET CoreCLR GC’s mark phase, enabling efficient traversal of the object graph to identify live objects. The sequence diagram captures the user-specified workflow, starting with mark_thread_heap, proceeding through mark_object_simple, drain_mark_queue, mark_object_simple1, and finalize_queue, and repeating some steps to account for additional marking needs. While the exact implementation details are inferred due to limited direct access to the source code, the diagram provides a clear and professional visualization of the process, suitable for understanding the GC’s operation in .NET CoreCLR.
