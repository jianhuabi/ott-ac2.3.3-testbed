/*
 *  IPAddress.h
 *  PersonalProxy
 *
 *  Created by Apple User on 2011-01-10.
 *  Copyright 2011 Irdeto. All rights reserved.
 *
 */

#define MAXADDRS	32

// Sample code to use the function:
//
// {
//     char *if_names[MAXADDRS];
//     char *ip_names[MAXADDRS];
//     char *hw_addrs[MAXADDRS];
//     unsigned long ip_addrs[MAXADDRS];
//     GetAddresses(if_names, ip_names, hw_addrs, ip_addrs, MAXADDRS);
//     
//     NSLog (@"List of Adapter Names, MACs, and IP addresses:\n");
//
//     for (int i = 0; i < MAXADDRS; i++) {
//         static unsigned long localHost = 0x7F000001;            // 127.0.0.1
//         unsigned long theAddr;
//    
//         theAddr = ip_addrs[i];
//    
//        if (theAddr == 0) break;
//        if (theAddr == localHost) continue;
//    
//        NSString *line = [[NSString alloc] initWithFormat:@"Name: %s MAC: %s IP: %s\n", if_names[i], hw_addrs[i], ip_names[i]];
//        NSLog(line);
//        [line release];
//    
//        //decided what adapter you want details for
//        if (strncmp(if_names[i], "en", 2) == 0)
//        {
//            line = [[NSString alloc] initWithFormat:@"Adapter en has a IP of %@\n", [NSString stringWithFormat:@"%s", ip_names[i]]];
//            NSLog (line);
//            [line release];
//        }
//     }
//     NSLog(@"\n");
//
//     FreeNameArray(if_names, MAXADDRS);
//     FreeNameArray(ip_names, MAXADDRS);
//     FreeNameArray(hw_addrs, MAXADDRS);
// }
//

// Function prototypes

void GetAddresses(char** if_names, char** ip_names, char** hw_addrs, unsigned long *ip_addrs, int maxlength);
void FreeNameArray(char **name_array, int maxlength);
