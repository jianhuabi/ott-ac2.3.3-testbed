#include <objc/runtime.h>
#include <objc/message.h>
#include <stdlib.h>
#include <string.h>
#include "TestBedTests.h"

DECLARE_TEST(ExampleNativeTest, "Native Test")
{
	TestLog("Hey! %s!\n", "I'm running from the native test");
	
	return TRUE;
}

DECLARE_TEST(ObjCInCTest, "Objective-C in C Test")
{
    BOOL success = TRUE;
	id idAutoRelease = objc_lookUpClass("NSAutoreleasePool");
	SEL selAlloc = sel_getUid("alloc");
	SEL selInit = sel_getUid("init");
	id idPool = (id)objc_msgSend(idAutoRelease, selAlloc);
	idPool = (id)objc_msgSend(idPool, selInit);
	
	id idString = objc_lookUpClass("NSString");
	SEL selStringWithCString = sel_getUid("stringWithCString:encoding:");
	id idDemoVideo = objc_msgSend(idString, selStringWithCString, "demovideo", 4);
	id idM4V = (id)objc_msgSend(idString, selStringWithCString, "m4v", 4);
	
	id idBundle = objc_lookUpClass("NSBundle");
	SEL selMainBundle = sel_getUid("mainBundle");
	
	id idMainBundle = (id)objc_msgSend(idBundle, selMainBundle);
	
	SEL selPathForResource = sel_getUid("pathForResource:ofType:");
	
	id idPathDemoVideo = (id)objc_msgSend(idMainBundle, selPathForResource, idDemoVideo, idM4V);
    
    if (idPathDemoVideo != nil) {
        SEL selStringByDeletingLastPathComponent = sel_getUid("stringByDeletingLastPathComponent");
        
        id idPath = (id)objc_msgSend(idPathDemoVideo, selStringByDeletingLastPathComponent);
        
        SEL selCStringUsingEncoding = sel_getUid("cStringUsingEncoding:");
        const char * szTempPath = (const char *) objc_msgSend(idPath, selCStringUsingEncoding, 4);
        char * szPath = malloc(sizeof(char) * (strlen(szTempPath) + 1));
        strcpy(szPath, szTempPath);
        
        SEL selRelease = sel_getUid("release");
        
        objc_msgSend(idMainBundle, selRelease);
        
        objc_msgSend(idPool, selRelease);
        
        TestLog("The path is [%s]\n", szPath);
        free(szPath);
    }
    else {
        success = FALSE;
    }
	
	return success;
}
