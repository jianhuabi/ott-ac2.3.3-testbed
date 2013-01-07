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
//    TESTURLCHOICE(HLS0k, "HLS Clear or Encrypted - Somevideo", "http://demo.irdeto.com/Test/somevideo.m3u8", "http://demo.irdeto.com/Override_link/overridevideo.asmx", 1);
//


#ifndef HLSURLS_H
#define HLSURLS_H

// IBB Test URLs

//TESTURLCHOICEDEMO(IBB_CLR_BUNNY, "IBB:Clear - Bunny", "IBB: Clr - Bunny", 1, "http://iis7test.entriq.net/ActiveCloak/Clear/bunny.m3u8", "BigBuckBunny_Open.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_CLR_POTTER, "IBB:Clear - Potter", "IBB: Clr - Potter", 2, "http://iis7test.entriq.net/ActiveCloak/Clear/Potter.m3u8", "HarryPotter_Open.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_CLR_TRANSFORMERS, "IBB:Clear - Transformers", "IBB: Clr - Transformers", 3, "http://iis7test.entriq.net/ActiveCloak/Clear/Transformers.m3u8", "Content.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_CLR_TRON, "IBB:Clear - Tron", "IBB: Clr - Tron", 4, "http://iis7test.entriq.net/ActiveCloak/Clear/Tron.m3u8", "Content.png", "HLS URLs", NULL, 0);
//
//TESTURLCHOICEDEMO(IBB_ENC_BUNNY, "IBB:Enc - Bunny", "IBB: Enc - Bunny", 5, "http://iis7test.entriq.net/ActiveCloak/Encrypted/Bunny.m3u8.prdy", "BigBuckBunny_Locked.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_ENC_POTTER, "IBB:Enc - Potter", "IBB: Enc - Potter", 6, "http://iis7test.entriq.net/ActiveCloak/Encrypted/Potter.m3u8.prdy", "Content.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_ENC_TRANSFORMERS, "IBB:Enc - Transformers", "IBB: Enc - Transformers", 7, "http://iis7test.entriq.net/ActiveCloak/Encrypted/Transformers.m3u8.prdy", "Content.png", "HLS URLs", NULL, 0);
//TESTURLCHOICEDEMO(IBB_ENC_TRON, "IBB:Enc - Tron", "IBB: Enc - Tron", 8, "http://iis7test.entriq.net/ActiveCloak/Encrypted/Tron.m3u8.prdy", "Content.png", "HLS URLs", NULL, 0);


// Irdeto clear HLS content:

// unprotected:
TESTURLCHOICE(HLS01, "HLS Clear - Bipbop", "http://demo.irdeto.com/Test/bipbop/hls/clear/bipbopall.m3u8", NULL, 0);

TESTURLCHOICE(HLS02, "HLS Clear - Climate", "http://demo.irdeto.com/Test/climate/hls/clear/index.m3u8", NULL, 0);

TESTURLCHOICE(HLS03, "HLS Clear - Code Breakers", "http://demo.irdeto.com/Test/codebreaker/hls/clear/index.m3u8", NULL, 0);

TESTURLCHOICE(HLS04, "HLS Clear - Code Breakers 2hrs", "http://demo.irdeto.com/Test/codebreaker_long/hls/clear/index.m3u8", NULL, 0);

//IBB clear HLS content:
TESTURLCHOICE(HLSIBB001, "HLS IBB Clear - MultiBR - AsteroidImpact", "http://iis7test.entriq.net/ActiveCloak/Clear/AsteroidImpact.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB002, "HLS IBB Clear - MUltiBR - Bridesmaids", "http://iis7test.entriq.net/ActiveCloak/Clear/Bridesmaids.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB003, "HLS IBB Clear - MultiBR - DisneyPirates", "http://iis7test.entriq.net/ActiveCloak/Clear/DisneyPirates.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB004, "HLS IBB Clear - SingleBR - China1", "http://iis7test.entriq.net/ActiveCloak/Clear/China1.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB005, "HLS IBB Clear - SingleBR - CartoonGirls2000", "http://iis7test.entriq.net/ActiveCloak/Clear/cartoon_girls_2000.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB006, "HLS IBB Clear - MultiBR - Lost1_01_3GHD", "http://iis7test.entriq.net/ActiveCloak/Clear/LOST1_01_3GHD.m3u8", NULL, 0);
TESTURLCHOICE(HLSIBB008, "HLS IBB Clear - MultiBR - LoveStory", "http://iis7test.entriq.net/ActiveCloak/Clear/LoveStory.m3u8", NULL, 0);

//IBB Encrypted HLS content:
TESTURLCHOICE(HLSPIBB101, "HLS IBB Encrypted - MultiBR - AsteroidImpact", "http://iis7test.entriq.net/ActiveCloak/Encrypted/AsteroidImpact.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSPIBB104, "HLS IBB Encrypted - SingleBR - China1", "http://iis7test.entriq.net/ActiveCloak/Encrypted/China1.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSPIBB105, "HLS IBB Encrypted - SingleBR - cartoon_girls_2000", "http://iis7test.entriq.net/ActiveCloak/encrypted/cartoon_girls_2000.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSPIBB106, "HLS IBB Encrypted - MultiBR -Lost1_01_3GHD", "http://iis7test.entriq.net/ActiveCloak/Encrypted/LOST1_01_3GHD.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSPIBB107, "HLS IBB Encrypted - MultiBR -Lost_01_HD", "http://iis7test.entriq.net/ActiveCloak/Encrypted/LOST1_01_HD.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSPIBB108, "HLS IBB Encrypted - MultiBR -LoveStory",  "http://iis7test.entriq.net/ActiveCloak/Encrypted/LoveStory.m3u8.prdy", NULL, 0);

//HLS2.0
TESTURLCHOICE(HLS2001, "HLS Encrypted (HLS2.0) clear faststart - Bipbop", "http://demo.irdeto.com/Test/bipbop/hlsp/enc_hls2/bipbopall.hls2.m3u8", NULL, 0);
TESTURLCHOICE(HLS2002, "HLS Encrypted (HLS2.0) clear faststart - Big Buck Bunny", "http://demo.irdeto.com/Test/big_buck_bunny/hlsp/enc_hls2/index.hls2.m3u8", NULL, 0);
TESTURLCHOICE(HLS2003, "HLS Encrypted (HLS2.0) clear faststart - Code Breakers", "http://demo.irdeto.com/Test/codebreaker/hlsp/enc_hls2/index.hls2.m3u8", NULL, 0);
TESTURLCHOICE(HLS2010, "HLS Encrypted (HLS2.0) fixed key faststart - Big Buck Bunny", "http://demo.irdeto.com/Test/big_buck_bunny/hlsp/enc_hls2_fixedkey/index.hls2.m3u8", NULL, 0);
TESTURLCHOICE(HLS2011, "HLS Encrypted (HLS2.0) fixed key faststart - codebreaker",  "http://demo.irdeto.com/Test/codebreaker/hlsp/enc_hls2_fixedkey/index.hls2.m3u8", NULL, 0);

// protected with playready, AES CBC (Option #1):
//TESTURLCHOICE(HLSP01, "HLS Encrypted (CBC) - Bipbop", "http://demo.irdeto.com/Test/bipbop/hlsp/enc/bipbopall.m3u8.prdy", NULL, 0);

// protected with playready, AES CTR (option #2):
TESTURLCHOICE(HLSP11, "HLS Encrypted (CTR) - Bipbop", "http://demo.irdeto.com/Test/bipbop/hlsp/enc_opt2/bipbopall.m3u8.prdy", NULL, 0);

// protected with playready, AES CTR, UNENCRYPTED manifest:
TESTURLCHOICE(HLSX21, "HLS-X Encrypted (CTR) - Bipbop", "http://demo.irdeto.com/Test/bipbop/hlsp/enc_opt2/bipbopall.hlsx.m3u8", NULL, 0);

//protected with option1:
//TESTURLCHOICE(HLSP04, "HLS Encrypted (CBC) - Code Breakers 2hrs", "http://demo.irdeto.com/Test/codebreaker_long/hlsp/enc/index.m3u8.prdy", NULL, 0);

//protected with option2:
TESTURLCHOICE(HLSP14, "HLS Encrypted (CTR) - Code Breakers 2hrs", "http://demo.irdeto.com/Test/codebreaker_long/hlsp/enc_opt2/index.m3u8.prdy", NULL, 0);

TESTURLCHOICE(HLS05, "HLS Clear - Live", "http://demo.irdeto.com/Test/LiveBipBopAll/bipbopall.m3u8", NULL, 0);

TESTURLCHOICE(HLSP15, "HLS Encrypted - CTR", "http://demo.irdeto.com/Test/LiveEnc2/media/index.m3u8.prdy", NULL, 0);

//OPL urls
TESTURLCHOICE(HLSOPL12, "OPL Encrypted p2 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m2_4088/sintelm2.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSOPL13, "OPL Encrypted p3 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m3_4089/sintelm3.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSOPL14, "OPL Encrypted p4 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m4_4090/sintelm4.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSOPL15, "OPL Encrypted p5 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m5_4091/sintelm5.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSOPL16, "OPL Encrypted p6 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m6_4092/sintelm6.m3u8.prdy", NULL, 0);
TESTURLCHOICE(HLSOPL17, "OPL Encrypted p7 - Sintel", "http://demo.irdeto.com/Test/Sintel/Sintel_m7_4093/sintelm7.m3u8.prdy", NULL, 0);
#endif /* INTERNALURLS_H */
