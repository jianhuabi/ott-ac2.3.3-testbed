/*
 *  IPAddress.c
 *  PersonalProxy
 *
 *  Created by Apple User on 2011-01-10.
 *  Copyright 2011 Irdeto. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/sockio.h>
#include <net/if.h>
#include <errno.h>
#include <net/if_dl.h>
#include <net/ethernet.h>

#include "IPAddress.h"

#define	min(a,b)	((a) < (b) ? (a) : (b))
#define	max(a,b)	((a) > (b) ? (a) : (b))

#define BUFFERSIZE	4000

void GetIPAddresses(char** if_names, char** ip_names, unsigned long *ip_addrs, int maxlength);
void GetHWAddresses(char **if_names, char **hw_addrs, int maxlength);

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void InitNameArray(char **name_array, int maxlength)
{
	int i;
	for (i=0; name_array != NULL && i < maxlength; ++i)
	{
		name_array[i] = NULL;
	}
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void InitAddressArray(unsigned long *addr_array, int maxlength)
{
	int i;
	for (i=0; addr_array != NULL && i < maxlength; ++i)
	{
		addr_array[i] = 0;
	}
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void FreeNameArray(char **name_array, int maxlength)
{
	int i;
	for (i=0; name_array != NULL && i < maxlength; ++i)
	{
		if (name_array[i] != NULL) free(name_array[i]);
	}
	InitNameArray(name_array, maxlength);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void GetAddresses(char** if_names, char** ip_names, char** hw_addrs, unsigned long *ip_addrs, int maxlength)
{
    InitNameArray(if_names, maxlength);
    InitNameArray(ip_names, maxlength);
    InitNameArray(hw_addrs, maxlength);
    InitAddressArray(ip_addrs, maxlength);
    GetIPAddresses(if_names, ip_names, ip_addrs, maxlength);
    GetHWAddresses(if_names, hw_addrs, maxlength);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void GetIPAddresses(char** if_names, char** ip_names, unsigned long *ip_addrs, int maxlength)
{
    int len;
    int flags;
	char buffer[BUFFERSIZE];
    char* ptr = NULL;
    char lastname[IFNAMSIZ];
    char* cptr = NULL;
	struct ifconf ifc;
	struct ifreq *ifr = NULL;
	struct ifreq ifrcopy;
	struct sockaddr_in* sin = NULL;

    int   nextAddr = 0;
    
	char temp[80];

	int sockfd;

	sockfd = socket(AF_INET, SOCK_DGRAM, 0);
	if (sockfd < 0)
	{
		perror("socket failed");
		return;
	}
	
	ifc.ifc_len = BUFFERSIZE;
	ifc.ifc_buf = buffer;
	
	if (ioctl(sockfd, SIOCGIFCONF, &ifc) < 0)
	{
		perror("ioctl error");
		return;
	}
	
	lastname[0] = 0;
	
	for (ptr = buffer; ptr < buffer + ifc.ifc_len; )
	{
		ifr = (struct ifreq *)ptr;
		len = max(sizeof(struct sockaddr), ifr->ifr_addr.sa_len);
		ptr += sizeof(ifr->ifr_name) + len;	// for next one in buffer
	
		if (ifr->ifr_addr.sa_family != AF_INET)
		{
			continue;	// ignore if not desired address family
		}
	
		if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL)
		{
			*cptr = 0;		// replace colon with null
		}
	
		if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0)
		{
			continue;	// already processed this interface
		}
	
		memcpy(lastname, ifr->ifr_name, IFNAMSIZ);
	
		ifrcopy = *ifr;
		ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
		flags = ifrcopy.ifr_flags;
		if ((flags & IFF_UP) == 0)
		{
			continue;	// ignore if interface not up
		}
	
		if_names[nextAddr] = (char *)malloc(strlen(ifr->ifr_name)+1);
		if (if_names[nextAddr] == NULL)
		{
			return;
		}
		strcpy(if_names[nextAddr], ifr->ifr_name);
	
		sin = (struct sockaddr_in *)&ifr->ifr_addr;
		strcpy(temp, inet_ntoa(sin->sin_addr));
	
		ip_names[nextAddr] = (char *)malloc(strlen(temp)+1);
		if (ip_names[nextAddr] == NULL)
		{
			return;
		}
		strcpy(ip_names[nextAddr], temp);

		ip_addrs[nextAddr] = sin->sin_addr.s_addr;

		++nextAddr;
	}
	
	close(sockfd);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void GetHWAddresses(char **if_names, char **hw_addrs, int maxlength)
{
    struct ifconf ifc = {};
    struct ifreq *ifr = NULL;
    int sockfd = 0;
    char buffer[BUFFERSIZE];
    char* cp = NULL;
    char* cplim = NULL;
    char temp[80];

   sockfd = socket(AF_INET, SOCK_DGRAM, 0);
   if (sockfd < 0)
   {
      perror("socket failed");
      return;
   }

   ifc.ifc_len = BUFFERSIZE;
   ifc.ifc_buf = buffer;

   if (ioctl(sockfd, SIOCGIFCONF, (char *)&ifc) < 0)
   {
      perror("ioctl error");
      close(sockfd);
	  return;
   }

   ifr = ifc.ifc_req;

   cplim = buffer + ifc.ifc_len;

   for (cp=buffer; cp < cplim; )
   {
      ifr = (struct ifreq *)cp;
	  if (ifr->ifr_addr.sa_family == AF_LINK)
	  {
	     struct sockaddr_dl *sdl = (struct sockaddr_dl *)&ifr->ifr_addr;
		 int a,b,c,d,e,f;
		 int i;

		 strcpy(temp, (char *)ether_ntoa((const struct ether_addr *)LLADDR(sdl)));
		 sscanf(temp, "%x:%x:%x:%x:%x:%x", &a, &b, &c, &d, &e, &f);
         sprintf(temp, "%02X:%02X:%02X:%02X:%02X:%02X",a,b,c,d,e,f);

		 for (i=0; i < maxlength; ++i)
		 {
		    if ((if_names[i] != NULL) && (strcmp(ifr->ifr_name, if_names[i]) == 0))
			{
			   if (hw_addrs[i] == NULL)
			   {
   			      hw_addrs[i] = (char *)malloc(strlen(temp)+1);
				  strcpy(hw_addrs[i], temp);
				  break;
			   }
			}
		}
	  }
      cp += sizeof(ifr->ifr_name) + max(sizeof(ifr->ifr_addr), ifr->ifr_addr.sa_len);
   }

   close(sockfd);
}
