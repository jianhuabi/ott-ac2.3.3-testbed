//
//  hlsurls.h
//  TestBed
//
//  Created by Apple User on 02/17/11.
//  Copyright 2010 Irdeto. All rights reserved.
//


// we use this header to define our own media URLs for testing purpose

// Each new media URL can be added below on a single line with the following format:
//    TESTURLCHOICE(index, description, url, license_override_url, type);
//
// For example:
//    TESTURLCHOICE(MP40k, "MP4 Clear or Encrypted - Somevideo", "http://demo.irdeto.com/Test/somevideo.m3u8", "http://demo.irdeto.com/Override_link/overridevideo.asmx", 1);
//


#ifndef MP4URLS_H
#define MP4URLS_H


// Irdeto MP4 content
// unprotected:
TESTURLCHOICE(MP401, "MP4 Clear - Shutter Island", "http://demo.irdeto.com/Test/download/shutter_island.mp4", NULL, 2);
//TESTURLCHOICE(MP402, "MP4 Clear - Climate", "http://demo.irdeto.com/Test/download/climate.mp4", NULL, 2);
// protected
TESTURLCHOICE(MP411, "MP4 Encrypted - Shutter Island", "http://demo.irdeto.com/Test/download/shutter_island.prdy", NULL, 2);

// unprotected:
TESTURLCHOICE(MP402, "MP4 Clear - Sintel", "http://demo.irdeto.com/Test/download/sintel.mp4", NULL, 2);

// protected
TESTURLCHOICE(MP412, "MP4 Encrypted - Sintel", "http://demo.irdeto.com/Test/download/sintel.prdy", NULL, 2);


//TESTURLCHOICE(MP412, "MP4 Encrypted - Climate", "http://demo.irdeto.com/Test/download/climate.mp4", NULL, 2);
// file:// URL (download and go)
TESTURLCHOICE(MP421, "MP4 Clear (relative file path) - Demo", "file://demovideo.m4v", NULL, 2);

TESTURLCHOICE(MP422, "MP4 Clear (absolute file path) - Demo", ([[NSString stringWithFormat:@"file://%@", [[NSBundle mainBundle] pathForResource:@"demovideo" ofType:@"m4v"]] cStringUsingEncoding:NSUTF8StringEncoding]), NULL, 2);

#endif /* MP4URLS_H */
