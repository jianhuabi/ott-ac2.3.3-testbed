/*
 *  ExampleNative.h
 *  TestBed
 *
 *  Created by Scott Seligman on 8/19/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

typedef signed char MY_BOOL;
#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#ifdef TARGET_OS_IPHONE

typedef MY_BOOL NativeTestFunc();

void NativeToObjC(char *, NativeTestFunc*);
void TestLog(char *, ...);

#define DECLARE_TEST(func, str)		\
	MY_BOOL func();					\
	__attribute__((constructor))	\
	void objcHelper##func()			\
	{								\
		NativeToObjC(str, func);	\
	}								\
	MY_BOOL func()

#else

#define NativeToObjC(a, b)
#define TestLog(a, ...)

#define DECLARE_TEST(func, str)		\
	MY_BOOL func()

#endif
