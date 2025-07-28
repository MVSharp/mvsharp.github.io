---
title: "Reading ReactOS - RtlDispatchException Behaviour In Different Architecture"
published: 2025-07-28
description: "This article just some notes when I read about ReactOS"
image: "./diff.svg"
tags: [ReactOS, NTDLL]
category: "NTDLL"
draft: false
lang: "en"
---

Based on the ReactOS source code (available in the GitHub repository), RtlDispatchException is typically found in files like ntdll/rtl/except.c or architecture-specific files (e.g., ntdll/rtl/i386/except.c for x86, ntdll/rtl/arm/except.c for ARM).

# What is RtlDispatchException

RtlDispatchException is a function in the ReactOS kernel (likely located in ntdll or related modules) that handles exception dispatching. It processes an exception by walking through the exception handler chain, invoking handlers, and managing the stack unwind process. The implementation varies between x86 and ARM due to differences in CPU architecture, register usage, and exception handling mechanisms (e.g., x86 uses a stack-based **SEH** (Structured Exception Handling) model, while ARM uses a table-based unwinding mechanism).

# In x86

For x86, ReactOS uses **Structured Exception Handling (SEH)**, which relies on a linked list of exception registration records on the stack.
![x86](./x86.svg)

## Validate Exception

Check the **EXCEPTION_RECORD** and **CONTEXT** structures for validity.

## Registers Chain

Retrieve the exception registration chain from the **Thread Environment Block** **(TEB)** via the **FS:[0]** segment register.

## Traverse Handler Chain

Iterate through the chain of **EXCEPTION_REGISTRATION_RECORD** structures for each handler, call it with the exception record, context, and dispatcher context.
he handler returns a disposition (**ExceptionContinueExecution**, **ExceptionContinueSearch**, or **ExceptionNestedException**)

## Handle Disposition

If **ExceptionContinueExecution**, restore the context and resume execution.
If **ExceptionContinueSearch**, move to the next handler in the chain.
If no handler accepts the exception, unwind the stack using RtlUnwind.

## Unwind or Terminate

If no handler is found, call the unhandled exception filter or terminate the process

# In Arm

For ARM, ReactOS uses a **table-based exception handling model** (similar to Windows on ARM), relying on unwind codes and exception tables
![arm](./arm.svg)

## Validate Exception

Ensure the **EXCEPTION_RECORD** and **CONTEXT** are valid.

## Locate Exception Table

Use the Program Counter (PC) from the context to find the relevant unwind information in the exception table (stored in the ** .pdata ** section).

## Unwind Phase 1 (Search)

Walk the unwind table to identify exception handlers.
Check for scope entries that match the exception’s PC.
Invoke language-specific handlers (e.g., C++ or SEH handlers) if found.

## Unwind Phase 2 (Cleanup)

If a handler accepts the exception, perform stack unwinding using unwind codes.
Update the context to reflect the handler’s state.

## Resume or Terminate

If a handler is found, resume execution at the handler’s address. If no handler is found, call the unhandled exception filter or terminate.

# The Diff

![diff](./diff.svg)
| Aspect | x86 Architecture | ARM Architecture |
|----------------------------|---------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| **Exception Handling Model** | Stack-based SEH with linked list of exception registration records | Table-based unwinding using `.pdata` and unwind codes |
| **Handler Lookup** | Traverses `EXCEPTION_REGISTRATION_RECORD` chain via `FS:[0]` | Uses exception tables and unwind codes indexed by PC |
| **Stack Unwinding** | Explicit unwinding via `RtlUnwind`, calling termination handlers | Guided by unwind codes in exception table, with two-phase process (search, cleanup) |
| **Register Access** | Uses `FS` segment for TEB access | Relies on ARM-specific registers (e.g., `SP`, `LR`, `PC`) and unwind codes |
