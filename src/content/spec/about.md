# About

```cs
            var assemblyName = new AssemblyName("MyProfile");
            var assemblyBuilder = AssemblyBuilder.DefineDynamicAssembly(assemblyName, AssemblyBuilderAccess.Run);
            var moduleBuilder = assemblyBuilder.DefineDynamicModule("ProfileModule");
            var typeBuilder = moduleBuilder.DefineType("Blog", TypeAttributes.Public);
            var methodBuilder = typeBuilder.DefineMethod(
                "GenProfile",
                MethodAttributes.Public | MethodAttributes.Static,
                typeof(void),
                Type.EmptyTypes
            );
            var il = methodBuilder.GetILGenerator();
            il.DeclareLocal(typeof(string)); // Local 0
            il.DeclareLocal(typeof(string)); // Local 1
            il.DeclareLocal(typeof(string)); // Local 2
            il.Emit(OpCodes.Ldstr, "MVSharp");
            il.Emit(OpCodes.Stloc_0);
            il.Emit(OpCodes.Ldstr, "Love to code C# since 2012");
            il.Emit(OpCodes.Stloc_1);
            il.Emit(OpCodes.Ldstr, "Riding");
            il.Emit(OpCodes.Stloc_2);
            il.Emit(OpCodes.Ldstr, "Blogger: ");
            il.Emit(OpCodes.Ldloc_0);
            il.Emit(OpCodes.Call, typeof(string).GetMethod("Concat", new[] { typeof(string), typeof(string) }));
            il.Emit(OpCodes.Call, typeof(Console).GetMethod("WriteLine", new[] { typeof(string) }));
            il.Emit(OpCodes.Ldc_I4, 1000);
            il.Emit(OpCodes.Call, typeof(Thread).GetMethod("Sleep", new[] { typeof(int) }));
            il.Emit(OpCodes.Ldstr, "About: ");
            il.Emit(OpCodes.Ldloc_1);
            il.Emit(OpCodes.Call, typeof(string).GetMethod("Concat", new[] { typeof(string), typeof(string) }));
            il.Emit(OpCodes.Call, typeof(Console).GetMethod("WriteLine", new[] { typeof(string) }));
            il.Emit(OpCodes.Ldc_I4, 1000);
            il.Emit(OpCodes.Call, typeof(Thread).GetMethod("Sleep", new[] { typeof(int) }));
            il.Emit(OpCodes.Ldstr, "Hobby: ");
            il.Emit(OpCodes.Ldloc_2);
            il.Emit(OpCodes.Call, typeof(string).GetMethod("Concat", new[] { typeof(string), typeof(string) }));
            il.Emit(OpCodes.Call, typeof(Console).GetMethod("WriteLine", new[] { typeof(string) }));
            il.Emit(OpCodes.Ret);
```

This blog is
Fork From [Fuwari](https://github.com/saicaca/fuwari).

::github{repo="saicaca/fuwari"}

> ### Sources of images used in this site
>
> - [Unsplash](https://unsplash.com/)
> - [星と少女](https://www.pixiv.net/artworks/108916539) by [Stella](https://www.pixiv.net/users/93273965)
> - [Rabbit - v1.4 Showcase](https://civitai.com/posts/586908) by [Rabbit_YourMajesty](https://civitai.com/user/Rabbit_YourMajesty)
