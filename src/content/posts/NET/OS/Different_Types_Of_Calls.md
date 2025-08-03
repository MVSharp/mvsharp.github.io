---
title: "Calling Convention"
published: 2025-05-28
description: "Small talks on Calling Convention"
image: "./callingconvention.svg"
tags: [OS]
category: "OS"
draft: false
lang: "en"
---

## Introduction to Calling Conventions

A calling convention is a set of rules governing how functions are called in a program. It defines how parameters are passed to functions, how return values are handled, how the stack is managed, and which registers are used or preserved during a function call. These conventions ensure compatibility between different software components, compilers, and hardware architectures.

Calling conventions are critical in low-level programming, particularly in system-level development, as they directly impact performance, compatibility, and correctness. This article explores the main types of calling conventions, their register usage, and their implications, with a focus on x86 and x64 architectures.

## Types of Calling Conventions

| Calling Convention     | Parameter Passing Mechanism                                                    | Stack Management         | Primary Use Case                            |
| ---------------------- | ------------------------------------------------------------------------------ | ------------------------ | ------------------------------------------- |
| **Cdecl**              | Parameters passed on the stack, pushed right-to-left.                          | Caller cleans the stack. | C/C++ default in many compilers.            |
| **Stdcall**            | Parameters passed on the stack, pushed right-to-left.                          | Callee cleans the stack. | Windows API functions.                      |
| **Fastcall**           | First two parameters in ECX, EDX registers; remaining on stack, right-to-left. | Callee cleans the stack. | Performance-critical applications.          |
| **Thiscall**           | Implicit `this` pointer in ECX; other parameters on stack, right-to-left.      | Callee cleans the stack. | C++ member functions (Microsoft compilers). |
| **Pascal**             | Parameters pushed on the stack, left-to-right.                                 | Callee cleans the stack. | Legacy Pascal and Delphi applications.      |
| **System V AMD64 ABI** | First six parameters in RDI, RSI, RDX, RCX, R8, R9; remaining on stack.        | Caller cleans the stack. | Linux/Unix on x64 architectures.            |
| **Microsoft x64**      | First four parameters in RCX, RDX, R8, R9; remaining on stack.                 | Caller cleans the stack. | Windows on x64 architectures.               |

## Why Multiple Calling Conventions in x86?

The x86 architecture, with its long history, has accumulated multiple calling conventions due to evolving hardware and software needs. Different vendors and programming languages introduced their own conventions to optimize for specific use cases, such as performance (e.g., `fastcall`) or compatibility (e.g., `cdecl`). This variety, while flexible, introduced challenges:

- **Explicit Specification**: Developers must explicitly declare calling conventions (e.g., `__cdecl`, `__stdcall`), increasing code complexity.
- **Interoperability Issues**: Mixing conventions can lead to stack imbalances, causing crashes or undefined behavior.

To address these issues, the x64 architecture streamlined the approach. Linux adopts the **System V AMD64 ABI**, using six registers (RDI, RSI, RDX, RCX, R8, R9) for parameter passing, while Windows uses the **Microsoft x64 Calling Convention**, relying on four registers (RCX, RDX, R8, R9). This unification reduces errors and simplifies development.

## System.Reflection CallingConventions Enum

In .NET, the `System.Reflection` namespace includes the `CallingConventions` enum, which defines flags for method calling conventions. Below is the enum definition in C#:

```cs
public enum CallingConventions
{
    Standard = 0x0001,
    VarArgs = 0x0002,
    Any = Standard | VarArgs,
    HasThis = 0x0020,
    ExplicitThis = 0x0040
}
```

| Enum Value       | Description                                                                           |
| ---------------- | ------------------------------------------------------------------------------------- |
| **Standard**     | Represents the default calling convention (e.g., `cdecl` or `stdcall`).               |
| **VarArgs**      | Indicates the method supports a variable number of arguments (e.g., C-style varargs). |
| **Any**          | Combination of `Standard` and `VarArgs`, allowing either convention.                  |
| **HasThis**      | Indicates the method has an implicit `this` parameter (used in instance methods).     |
| **ExplicitThis** | Specifies that the `this` parameter is explicitly declared in the signature.          |

## Challenges and Best Practices

- **x86 Complexity**: Developers must be cautious when mixing libraries or modules using different calling conventions. Always verify the convention used by external APIs.
- **x64 Simplicity**: The unified conventions in x64 reduce errors but require understanding register-based parameter passing for optimal performance.
- **Tooling Support**: Modern compilers (e.g., GCC, MSVC) provide attributes or keywords (e.g., `__attribute__((cdecl))`, `__stdcall`) to enforce conventions. Use these explicitly in mixed-language projects.
- **Debugging**: Stack misalignment issues often stem from mismatched conventions. Use debugging tools to inspect stack frames and register states.
