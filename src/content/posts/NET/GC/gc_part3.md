---
title: "Reading CoreClr- Four Types Of GC In DOTNET"
published: 2025-07-29
description: "Understanding Four  Types of GC how it works by reading the source code in DOTNET"
image: "./gc_flow/sd_workstation_background.svg"
tags: [DOTNET, GC, CSharp, CoreClr]
category: "CoreClr"
draft: false
lang: "en"
---

:::Tip
This article main focus on WKS background GC as It is default for DOTNET
:::

# Some Resouces

- [.NET CLR GC Implementation](https://raw.githubusercontent.com/dotnet/runtime/main/src/coreclr/gc/gc.cpp)
- [The Garbage Collection Handbook: The Art of Automatic Memory Management](http://www.amazon.com/Garbage-Collection-Handbook-Management-Algorithms/dp/1420082795)
- [Garbage collection (Wikipedia)](<http://en.wikipedia.org/wiki/Garbage_collection_(computer_science)>)
- [Pro .NET Memory Management](https://prodotnetmemory.com/)
- [.NET GC Internals video series](https://www.youtube.com/playlist?list=PLpUkQYy-K8Y-wYcDgDXKhfs6OT8fFQtVm)

# WorkStation GC (WKS GC)

![workstation gc](./gc_flow/workstation.svg)
By reading DOTNET source code , in file [runtime/src/coreclr/gc
/gc.cpp](https://github.com/dotnet/runtime/blob/main/src/coreclr/gc/gc.cpp)

````c
Given WKS GC with concurrent GC off, GarbageCollectGeneration is done all
on the user thread that triggered the GC. The code flow is:

     GarbageCollectGeneration()
     {
         SuspendEE();
         garbage_collect();
         RestartEE();
     }

     garbage_collect()
     {
         generation_to_condemn();
         gc1();
     }

     gc1()
     {
         mark_phase();
         plan_phase();
     }

     plan_phase()
     {
         // actual plan phase work to decide to
         // compact or not
         if (compact)
         {
            //compact gc
             relocate_phase();
             compact_phase();
         }
         else
             //mark and sweep
             make_free_lists();
     }

# Server GC
![server gc](./gc_flow/server.svg)
```c
GarbageCollectGeneration()
{
	//wake up an event
	ee_suspend_event.set();
	wait_for_gc_done();
}

gc_thread_function()
{
	while (1)
	{
		ee_suspend_event.Wait();
		SuspendEE();
		garbage_collect();
		RestartEE();
	}
}

garbage_collect()
{
	generation_to_condemn();
	gc1();
}

gc1()
{
	mark_phase();
	plan_phase();
}

plan_phase()
{
	// actual plan phase work to decide to
	// compact or not
	if (compact)
	{
		relocate_phase();
		compact_phase();
	}
	else
		make_free_lists();
}

````

:::Tip
so as we can we plan_phase must be execute , this is different from concurrent mode WKS GC
:::

# WorkStation Background(Background Threads Unlock Managed Threads)[Default Case for WKS GC]

![workstation background](./gc_flow/workstation_background.svg)

By reading DOTNET source code , in file [runtime/src/coreclr/gc
/gc.cpp](https://github.com/dotnet/runtime/blob/main/src/coreclr/gc/gc.cpp)

As we can see , there is a **optimization** compare to WKSGC for **gc1() **
where WKS originally blocked thread in single mode
but now **background_mark_phase();** & **background_sweep();** is a game changer
It doesn't block the thread
which means , **IT AVOID STW**
It doesn't the fuck STOP THE WORLD
the **managed thread** doesn't get blocked .

![workstation background2](./gc_flow/sd_workstation_background.svg)

```c

Given WKS GC with concurrent GC on (default case), the code flow for a background GC is

     GarbageCollectGeneration()
     {
         SuspendEE();
         garbage_collect();
         RestartEE();
     }

     garbage_collect()
     {
         generation_to_condemn();
         // decide to do a background GC
         // wake up the background GC thread to do the work
         do_background_gc();
     }

     do_background_gc()
     {
         init_background_gc();
         start_c_gc ();

         //wait until restarted by the BGC.
         wait_to_proceed();
     }

     bgc_thread_function()
     {
         while (1)
         {
             // wait on an event
             // wake up

             gc1();
         }
     }

     gc1()
     {
         background_mark_phase();
         background_sweep();
     }
```

# Server Background(Concurrent)

![server background](./gc_flow/server_background.svg)

```c

GarbageCollectGeneration()
{
	//wake up an event
	ee_suspend_event.set();
	wait_for_gc_done();
}

gc_thread_function()
{
	while (1)
	{
        ee_suspend_event.Wait();

		SuspendEE();
		garbage_collect();
		RestartEE();
	}
}

garbage_collect()
{
    generation_to_condemn();
    // decide to do a background GC
    // wake up the background GC thread to do the work
    do_background_gc();
}

do_background_gc()
{
    init_background_gc();
    start_c_gc();

    //wait until restarted by the BGC.
    wait_to_proceed();
}

bgc_thread_function()
{
    while (1)
    {
        bgc_start_event.Wait();

        gc1();
    }
}

gc1()
{
    background_mark_phase();
    background_sweep();
}

```
