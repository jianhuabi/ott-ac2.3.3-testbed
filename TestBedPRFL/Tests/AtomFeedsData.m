//
//  AtomFeedsData.m
//  TestBed
//
//  Created by Apple User on 5/18/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

#import "AtomFeedsData.h"
#import "ActiveCloakMediaPlayer.h"

DECLARE_STRING(tagName_Feed, "feed")
DECLARE_STRING(tagName_Title, "title")
DECLARE_STRING(tagName_Link, "link")
DECLARE_STRING(tagName_Updated, "updated")
DECLARE_STRING(tagName_Author, "author")
DECLARE_STRING(tagName_Id, "id")
DECLARE_STRING(tagName_Entry, "entry")
DECLARE_STRING(tagName_Summary, "summary")
DECLARE_STRING(tagName_Image, "image")
DECLARE_STRING(attrName_Href, "href")
DECLARE_STRING(attrName_Urltype, "urltype")
DECLARE_STRING(attrName_Height, "height")
DECLARE_STRING(attrName_Width, "width")
DECLARE_STRING(attrName_Size, "size")
DECLARE_STRING(attrName_DownloadTo, "download-to")
DECLARE_STRING(valueName_Iisss, "iisss")
DECLARE_STRING(valueName_Hls, "hls")
DECLARE_STRING(valueName_Envelope, "envelope")

USES_STRING(tagName_Name)

ValueProperties _linkUrltypeAttrValues [] =
{
    {valueName_Iisss, valueName_IisssLength, ACURLTypeIIS},
    {valueName_Hls, valueName_HlsLength, ACURLTypeHLS},
    {valueName_Envelope, valueName_EnvelopeLength, ACURLTypeEnvelope},
};

const AttributeRequirements _linkHrefAttrRequirements = {attrName_Href, attrName_HrefLength, NO, YES, NULL, 0};
const AttributeRequirements _linkUrltypeAttrRequirements = {attrName_Urltype, attrName_UrltypeLength, YES, YES, 
    _linkUrltypeAttrValues, ARRAYSIZE(_linkUrltypeAttrValues)};
const AttributeRequirements _linkSizeAttrRequirements = {attrName_Size, attrName_SizeLength, NO, YES, NULL, 0};
const AttributeRequirements _linkDownloadToAttrRequirements = {attrName_DownloadTo, attrName_DownloadToLength, NO, YES, NULL, 0};
const AttributeRequirements _imageHeightAttrRequirements = {attrName_Height, attrName_HeightLength, NO, YES, NULL, 0};
const AttributeRequirements _imageWidthAttrRequirements = {attrName_Width, attrName_WidthLength, NO, YES, NULL, 0};

// Function prototypes for SAX callbacks. 
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorHandlerSAX (void *userData, xmlErrorPtr error);

static xmlSAXHandler atomFeedsSAXHandler = {
    NULL,                       /* internalSubsetSAXFunc internalSubset; */
    NULL,                       /* isStandaloneSAXFunc isStandalone;   */
    NULL,                       /* hasInternalSubsetSAXFunc hasInternalSubset; */
    NULL,                       /* hasExternalSubsetSAXFunc hasExternalSubset; */
    NULL,                       /* resolveEntitySAXFunc resolveEntity; */
    NULL,                       /* getEntitySAXFunc getEntity; */
    NULL,                       /* entityDeclSAXFunc entityDecl; */
    NULL,                       /* notationDeclSAXFunc notationDecl; */
    NULL,                       /* attributeDeclSAXFunc attributeDecl; */
    NULL,                       /* elementDeclSAXFunc elementDecl; */
    NULL,                       /* unparsedEntityDeclSAXFunc unparsedEntityDecl; */
    NULL,                       /* setDocumentLocatorSAXFunc setDocumentLocator; */
    NULL,                       /* startDocumentSAXFunc startDocument; */
    NULL,                       /* endDocumentSAXFunc endDocument; */
    NULL,                       /* startElementSAXFunc startElement;*/
    NULL,                       /* endElementSAXFunc endElement; */
    NULL,                       /* referenceSAXFunc reference; */
    charactersFoundSAX,         /* charactersSAXFunc characters; */
    NULL,                       /* ignorableWhitespaceSAXFunc ignorableWhitespace; */
    NULL,                       /* processingInstructionSAXFunc processingInstruction; */
    NULL,                       /* commentSAXFunc comment; */
    NULL,                       /* warningSAXFunc warning; */
    NULL,                       /* errorSAXFunc error; */
    NULL,                       /* fatalErrorSAXFunc fatalError; //: unused error() get all the errors */
    NULL,                       /* getParameterEntitySAXFunc getParameterEntity; */
    NULL,                       /* cdataBlockSAXFunc cdataBlock; */
    NULL,                       /* externalSubsetSAXFunc externalSubset; */
    XML_SAX2_MAGIC,             /* unsigned int initialized; */
    NULL,                       /* void *_private; */
    startElementSAX,            /* startElementNsSAX2Func startElementNs; */
    endElementSAX,              /* endElementNsSAX2Func endElementNs; */
    errorHandlerSAX,            /* xmlStructuredErrorFunc serror; */
};

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
static BOOL analyzeLinkTag(AtomFeedsData *atomFeedsData,
                        const xmlChar **attributes,
                        int nb_attributes) {

    BOOL success = YES; // set the return value to YES because the <image> attributes are not mandatory
    int context;

    if (atomFeedsData != nil) {
        int hrefSize = 0;
        const char* hrefValue = NULL;
        if (analyzeAttributes(attributes, nb_attributes, &_linkHrefAttrRequirements, NULL, &hrefValue, &hrefSize)) {

            int attrSize = 0;
            const char* attrValue = NULL;
            
            NSString *href = [[NSString alloc] initWithBytes:hrefValue length:hrefSize encoding:NSUTF8StringEncoding];
            
            if (atomFeedsData.currentEntryRecord != nil) {
                atomFeedsData.currentEntryRecord.link = href;
            } 
            else {
                atomFeedsData.link = href;
            }
            
            // parse cw:urltype
            if (atomFeedsData.currentEntryRecord != nil && analyzeAttributes(attributes, nb_attributes, &_linkUrltypeAttrRequirements, &context, NULL, NULL)) {
                atomFeedsData.currentEntryRecord.urltype = context;
            }
            else {
                success = NO;
            }
            
            // parse cw:size
            if (success 
                && analyzeAttributes(attributes, nb_attributes, &_linkSizeAttrRequirements, NULL, &attrValue, &attrSize) 
                && attrValue != NULL 
                && attrSize > 0) {
                // if the attribute exists, calculate its value converting it from string representation to long integer
                char *endPointer = NULL;
                long size = strtol(attrValue, &endPointer, 0);
                if (endPointer - attrValue == attrSize) {
                    // conversion is correct, accept the value
                    atomFeedsData.currentEntryRecord.contentSize = size;
                }
                else {
                    // conversion is not correct, XML is broken
                    success = NO;
                }
                
            }             
            
            // parse cw:download-to
            if (success 
                && analyzeAttributes(attributes, nb_attributes, &_linkDownloadToAttrRequirements, NULL, &attrValue, &attrSize)
                && attrValue != NULL 
                && attrSize > 0) {
                atomFeedsData.currentEntryRecord.downloadToFile = [[NSString alloc] initWithBytes:attrValue length:attrSize encoding:NSUTF8StringEncoding];
            }                
        } else {
            [atomFeedsData setParsingStatus:statusType_Error];
        }
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
static BOOL analyzeImageTag(AtomFeedsData *atomFeedsData,
                            const xmlChar **attributes,
                            int nb_attributes) {

    BOOL success = YES; // set the return value to YES because the <image> attributes are not mandatory
    
    if (atomFeedsData != nil) {
        int attrSize = 0;
        const char* attrValue = NULL;
        
        // verify for 'height' attribute first
        if (analyzeAttributes(attributes, nb_attributes, &_imageHeightAttrRequirements, NULL, &attrValue, &attrSize) 
            && attrValue != NULL 
            && attrSize > 0) {
            // if the attribute exists, calculate its value converting it from string representation to long integer
            char *endPointer = NULL;
            long height = strtol(attrValue, &endPointer, 0);
            if (endPointer - attrValue == attrSize) {
                // conversion is correct, accept the value
                atomFeedsData.currentEntryRecord.imageHeight = height;
                success = YES;
            }
            else {
                // conversion is not correct, XML is broken
                success = NO;
            }
        }
        // verify for 'width' attribute
        if (analyzeAttributes(attributes, nb_attributes, &_imageWidthAttrRequirements, NULL, &attrValue, &attrSize) 
            && attrValue != NULL 
            && attrSize > 0) {
            // if the attribute exists, calculate its value converting it from string representation to long integer
            char *endPointer = NULL;
            long width = strtol(attrValue, &endPointer, 0);
            if (endPointer - attrValue == attrSize) {
                // conversion is correct, accept the value
                atomFeedsData.currentEntryRecord.imageWidth = width;
                success = YES;
            }
            else {
                // conversion is not correct, XML is broken
                success = NO;
            }
        }
    }
    
    return success;
}

/*-----------------------------------------------------------------------------
 This callback is invoked when the parser finds the beginning of a node
 in the XML.  
 ----------------------------------------------------------------------------*/
static void startElementSAX(void *ctx,
                            const xmlChar *localname,
                            const xmlChar *prefix,
                            const xmlChar *URI, 
                            int nb_namespaces,
                            const xmlChar **namespaces,
                            int nb_attributes,
                            int nb_defaulted,
                            const xmlChar **attributes) {
    
    AtomFeedsData *atomFeedsData = (AtomFeedsData *)ctx;
    
    // process the tag if it is not NULL
    if (localname != NULL) {
        const char* localName = (const char*)localname;
        const char* parentTagName = NULL;
        BOOL hasParent = YES;
        
        // obtain a parent name according to XML schema
        if (prefix == NULL && strcmp(localName, tagName_Feed) == 0) {
            hasParent = NO;
        } else if (prefix == NULL && strcmp(localName, tagName_Entry) == 0) {
            // allocate a new EntryRecord to collect the information
            atomFeedsData.currentEntryRecord = [[EntryRecord alloc] init];
            atomFeedsData.currentEntryRecord.serialNumber = atomFeedsData.serialNumber;
            [atomFeedsData incrementEntriesSerialNumber];
            parentTagName = tagName_Feed;
        } else if (prefix == NULL && strcmp(localName, tagName_Author) == 0) {
            parentTagName = tagName_Feed;
        } else if (prefix == NULL && strcmp(localName, tagName_Summary) == 0) {
            parentTagName = tagName_Entry;
        } else if (prefix != NULL && strcmp(localName, tagName_Image) == 0) {
            parentTagName = tagName_Entry;
            analyzeImageTag(atomFeedsData, attributes, nb_attributes);
        } else if (prefix == NULL
                   && (strcmp(localName, tagName_Title) == 0
                       || strcmp(localName, tagName_Link) == 0
                       || strcmp(localName, tagName_Updated) == 0
                       || strcmp(localName, tagName_Id) == 0)) {
            parentTagName = atomFeedsData.currentEntryRecord != nil ? tagName_Entry : tagName_Feed;
            if (strcmp(localName, tagName_Link) == 0) {
                // analyze 'href' attribute
                analyzeLinkTag(atomFeedsData, attributes, nb_attributes);
            }
        } else if (prefix == NULL && strcmp(localName, tagName_Name) == 0) {
            parentTagName = tagName_Author;
        }
        
        // verify that the node has a correct parent node
        if (parentTagName != NULL || !hasParent) {    
            [atomFeedsData setParsingStatus:[atomFeedsData verifyParentLocalName:parentTagName]];
        }
        
        // push the current node to the stack for futher verification
        [atomFeedsData addNode:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)URI];
    }
}

/*-----------------------------------------------------------------------------
 This callback is invoked when the parse reaches the end of a node.
 ----------------------------------------------------------------------------*/
static void	endElementSAX(void *ctx,
                          const xmlChar *localname,
                          const xmlChar *prefix,
                          const xmlChar *URI) {
    AtomFeedsData *atomFeedsData = (AtomFeedsData *)ctx;
    
    // verify that the just-finished-to-parse node is on the top of the stack
    if ([atomFeedsData currentNodeIsEqualTo:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)URI]) {
        const char* localName = (const char*)localname;
        ParsingNodeInfo *nodeInfo = atomFeedsData.currentNodeInfo;
        
        NSString *nodeValue = nil;
        if (nodeInfo->nodeValue.length > 0)
        {
            nodeValue = [[NSString alloc] initWithBytes:nodeInfo->nodeValue.buffer length:nodeInfo->nodeValue.length encoding:NSUTF8StringEncoding];
        }
        
        // if currentEntryNode != nil, it means that an <entry> node is still being parsed
        if (atomFeedsData.currentEntryRecord != nil) {
            // parsing <entry> node
            if (prefix == NULL && strcmp(localName, tagName_Title) == 0) {
                atomFeedsData.currentEntryRecord.title = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Link) == 0) {
            } else if (prefix == NULL && strcmp(localName, tagName_Updated) == 0) {
                atomFeedsData.currentEntryRecord.updated = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Id) == 0) {
                atomFeedsData.currentEntryRecord.entryId = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Summary) == 0) {
                atomFeedsData.currentEntryRecord.summary = nodeValue;
            } else if (prefix != NULL && strcmp(localName, tagName_Image) == 0) {
                atomFeedsData.currentEntryRecord.imageUrl = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Entry) == 0) {
                [atomFeedsData.entryRecordList setValue:atomFeedsData.currentEntryRecord forKey:atomFeedsData.currentEntryRecord.entryId];  
                [atomFeedsData.currentEntryRecord release];
                atomFeedsData.currentEntryRecord = nil; // drop the entryState flag
            }
        } else {
            // parsing <feed> node
            if (prefix == NULL && strcmp(localName, tagName_Title) == 0) {
                atomFeedsData.title = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Link) == 0) {
            } else if (prefix == NULL && strcmp(localName, tagName_Updated) == 0) {
                atomFeedsData.updated = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Id) == 0) {
                atomFeedsData.feedId = nodeValue;
            } else if (prefix == NULL && strcmp(localName, tagName_Name) == 0) {
                atomFeedsData.author = nodeValue;
            }
        }

        
        // remove the parsed node from the stack
        [atomFeedsData removeCurrentNode];
    } else {
        [atomFeedsData setParsingStatus:statusType_Error];
    }
}

/*-----------------------------------------------------------------------------
 This callback is invoked when the parser encounters character data
 inside a node.
 ----------------------------------------------------------------------------*/
static void	charactersFoundSAX(void *ctx, const xmlChar *value, int length) {
    AtomFeedsData *atomFeedsData = (AtomFeedsData *)ctx;
    ParsingNodeInfo *nodeInfo = atomFeedsData.currentNodeInfo;
    if (nodeInfo != nil) {
        appendMessageBuffer(&nodeInfo->nodeValue, value, length);
    }
}

/*-----------------------------------------------------------------------------
 "Robust" error handling
 ----------------------------------------------------------------------------*/
static void errorHandlerSAX (void *userData, xmlErrorPtr error) {
    fprintf(stderr, "*** Error encountered during SAX parse (%s): code = %d, message = %s\n", 
            error->level == XML_ERR_WARNING ? "WARNING" : 
            error->level == XML_ERR_ERROR ? "ERROR" : 
            error->level == XML_ERR_FATAL ? "FATAL" : "UNKNOWN", error->code, error->message);
    fprintf(stderr, "     str1 = %s\n", error->str1);
    fprintf(stderr, "     str2 = %s\n", error->str2);
    fprintf(stderr, "     str3 = %s\n", error->str3);
    fprintf(stderr, "     int1 = %d int2 = %d\n", error->int1, error->int1);
}

@implementation AtomFeedsData

@synthesize currentEntryRecord;
@synthesize link;
@synthesize title;
@synthesize feedId;
@synthesize updated;
@synthesize author;
@synthesize entryRecordList;
@synthesize serialNumber = _serialNumber;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) init {
    self = [super init];
    [self reset];
    self.entryRecordList = [[NSMutableDictionary alloc] initWithCapacity:10];
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)releaseAll {
    [self.link release];
    [self.title release];
    [self.feedId release];
    [self.updated release];
    [self.author release];
    [self.currentEntryRecord release];
    [self.entryRecordList release];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    [self releaseAll];
    [super dealloc];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)reset {
    [self releaseAll];
    self.entryRecordList = [[NSMutableDictionary alloc] initWithCapacity:10];
    self->_serialNumber = 0;
    [super reset];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)parseAtomFeeds:(const MessageBuffer *)feeds {
    xmlSAXUserParseMemory(&atomFeedsSAXHandler, self, (const char *)feeds->buffer, feeds->length);
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)incrementEntriesSerialNumber {
    self->_serialNumber++;
}

@end


