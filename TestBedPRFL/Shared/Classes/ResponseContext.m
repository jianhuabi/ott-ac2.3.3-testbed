//
//  ResponseParsingContext.m
//  TestBoss
//
//  Created by Apple User on 12/21/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#import "ResponseContext.h"

// Function prototypes for SAX callbacks. 
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorHandlerSAX (void *userData, xmlErrorPtr error);

static xmlSAXHandler responseSAXHandler = {
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

#pragma mark SAX Parsing Callbacks

USES_STRING(tagName_Response)
USES_STRING(tagName_DeviceName);

// The following static structures declared in the ProtocolFramework.c file:
extern const AttributeRequirements _responseTypeAttrRequirements;
extern const AttributeRequirements _responseKindAttrRequirements;
extern const AttributeRequirements _responseIdAttrRequirements;
extern const AttributeRequirements _responseCmdAttrRequirements;
extern const AttributeRequirements _responseStatusAttrRequirements;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void analyzeResponseTag(ResponseContext *responseContext,
                        const xmlChar **attributes,
                        int nb_attributes) {
    
    int context;
    
    if (responseContext != nil) {
        if (analyzeAttributes(attributes, nb_attributes, &_responseTypeAttrRequirements, &context, NULL, NULL)) {
            responseContext.responseType = context;
            
            if (analyzeAttributes(attributes, nb_attributes, &_responseStatusAttrRequirements, &context, NULL, NULL)) {
                responseContext.responseStatus = context;
            } else {
                [responseContext setParsingStatus:statusType_Error];
            }
            
            switch (responseContext.responseType) {
                case msgType_Pong:;
                    //
                    break;
                case msgType_Hello:;
                    //
                    break;
                case msgType_Cmd:;
                    //
                    if (analyzeAttributes(attributes, nb_attributes, &_responseCmdAttrRequirements, &context, NULL, NULL)) {
                        responseContext.cmdType = context;
                    } else {
                        [responseContext setParsingStatus:statusType_Error];
                    }
                    break;
                case msgType_Report:;
                    //
                    if (analyzeAttributes(attributes, nb_attributes, &_responseKindAttrRequirements, &context, NULL, NULL)) {
                        responseContext.reportType = context;
                    } else {
                        [responseContext setParsingStatus:statusType_Error];
                    }
                    int idSize = 0;
                    const char* idValue = NULL;
                    if (analyzeAttributes(attributes, nb_attributes, &_responseIdAttrRequirements, NULL, &idValue, &idSize)) {
                        NSString *responseId = [[NSString alloc] initWithBytes:idValue length:idSize encoding:NSUTF8StringEncoding];
                        responseContext.responseId = responseId;
                    } else {
                        [responseContext setParsingStatus:statusType_Error];
                    }
                    break;
                    
                default:;
                    break;
            }
        }
    }
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
    
    ResponseContext *responseContext = (ResponseContext *)ctx;
    
    if (localname != NULL) {
        const char* localName = (const char*)localname;
        if (prefix == NULL && strcmp(localName, tagName_Response) == 0) {
            analyzeResponseTag(responseContext, attributes, nb_attributes);
            // verify that <response> node does not have a parent
            [responseContext setParsingStatus:[responseContext verifyParentLocalName:nil]];
        } 
        [responseContext addNode:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)URI];
    }
}

/*-----------------------------------------------------------------------------
 This callback is invoked when the parse reaches the end of a node.
 ----------------------------------------------------------------------------*/
static void	endElementSAX(void *ctx,
                          const xmlChar *localname,
                          const xmlChar *prefix,
                          const xmlChar *URI) {
    ResponseContext *responseContext = (ResponseContext *)ctx;
    if ([responseContext currentNodeIsEqualTo:(const char*)localname withPrefix:(const char*)prefix andUri:(const char*)URI]) {
        if (strncmp((const char*)localname, tagName_DeviceName, tagName_DeviceName_Length) == 0) {
            ParsingNodeInfo *nodeInfo = responseContext.currentNodeInfo;
            if (nodeInfo->nodeValue.length > 0)
            {
                NSString *deviceName = [[NSString alloc] initWithBytes:nodeInfo->nodeValue.buffer length:nodeInfo->nodeValue.length encoding:NSUTF8StringEncoding];
                [responseContext.deviceNameList addObject:deviceName];
            }
        }
        [responseContext removeCurrentNode];
    } else {
        [responseContext setParsingStatus:statusType_Error];
    }
    
}

/*-----------------------------------------------------------------------------
 This callback is invoked when the parser encounters character data
 inside a node.
 ----------------------------------------------------------------------------*/
static void	charactersFoundSAX(void *ctx, const xmlChar *value, int length) {
    ResponseContext *responseContext = (ResponseContext *)ctx;
    ParsingNodeInfo *nodeInfo = responseContext.currentNodeInfo;
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

@implementation ResponseContext

@synthesize responseType = _responseType;
@synthesize reportType = _reportType;
@synthesize responseStatus = _responseStatus;
@synthesize cmdType = _cmdType;
@synthesize deviceNameList = _deviceNameList;
@synthesize responseId;

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (id) init {
    self = [super init];
    if (self != nil) {
        self->_deviceNameList = NULL;
        [self reset];
    }
    return self;
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)dealloc {
    if (self->_deviceNameList != nil) {
        if ([self->_deviceNameList count] > 0) {
            [self->_deviceNameList removeAllObjects];
        }
        [self->_deviceNameList release];
    }
    [responseId release];
    [super dealloc];
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)reset {
    self->_responseType = msgType_Unknown;
    self->_reportType = reportType_Unknown;
    self->_responseStatus = statusType_Ok;
    self->_cmdType = cmdType_Unknown;
    if (self->_deviceNameList == NULL) {
        self->_deviceNameList = [[NSMutableArray alloc] initWithCapacity:10];
    }
    if ([self->_deviceNameList count] > 0) {
        [self->_deviceNameList removeAllObjects]; 
    }
    [super reset];
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
- (void)parseResponse:(const MessageBuffer *)response {
    [self reset];
    xmlSAXUserParseMemory(&responseSAXHandler, self, (const char *)response->buffer, response->length);
}

@end
