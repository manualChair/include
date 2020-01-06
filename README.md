# include

Library system for AutoLISP on Visual LISP IDE

## Overview

AutoLISP has a load function that allows you to load the required functions from other files. But since it is a simple operation, you must always keep mind of which files are loaded. Therefore, a library system that automatically loads necessary functions cannot be used in the Visual LISP IDE. This library system is built by defining an include function that extends the load function. The main difference between the include function and load function is that the already loaded files are remembered and not loaded unnecessarily.

In addition to existing libraries that assume include function, by organizeing your own highly reusable functions in a different folder from the folder of the program you are writing, in the same way, You can make your own library.

When this system is built, functions are automatically loaded, but it is difficult to know which functions are to be loaded. This makes it difficult to use the program in other than the AutoLISP execution environment used for development. Therefore, it is necessary to finally combine the program you wrote and the functions of the required library into one *Separate-namespace VLX application*. By using *Separate-namespace VLX application*, you can create a program that is easy to handle with one file and that operates without interference in the AutoLISP execution environment of other AutoCAD users.

The list of function files loaded and stored by the include function can be exported to the Visual LISP project file format. This can be used as a resource in the application definition file when you finish up your program as *Separate-namespace VLX application*.

## About license

The function source code is a *MIT license*. The MIT license is one of the open source software licenses that has few restrictions.

The outline of the MIT license is translated into this case as follows.
* No warranty!
* Anyone can use the source code of this library for free. You can freely distribute and change the source code, including commercial use, and create programs that use it.
* When redistributing or changing the source code of this library, the following copyright notices already included in these libraries must not be erased. Also, when you try to distribute your program created using this library, please display the following three copyright notice lines in appropriate place where we can confirm, such as another file for the license display that is included.
```
Copyright (c) 20xx manual chair japan
Released under the MIT license
https://opensource.org/licenses/mit-license.php
```