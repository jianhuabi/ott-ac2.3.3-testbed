//
//  ProtocolFramework.m
//  TestBoss
//
//  Created by Apple User on 12/7/10.
//  Copyright 2010 Irdeto. All rights reserved.
//

#include "ProtocolFramework.h"

DECLARE_STRING(tagName_Request, "request")
DECLARE_STRING(tagName_Response, "response")
DECLARE_STRING(attrName_Type, "type")
DECLARE_STRING(valueName_Ping, "ping")
DECLARE_STRING(valueName_Pong, "pong")
DECLARE_STRING(valueName_Hello, "hello")
DECLARE_STRING(valueName_NextCmd, "next-cmd")
DECLARE_STRING(valueName_Report, "report")
DECLARE_STRING(valueName_Cmd, "cmd")
DECLARE_STRING(attrName_Kind, "kind")
DECLARE_STRING(valueName_Log, "log")
DECLARE_STRING(valueName_Status, "status")
DECLARE_STRING(valueName_List, "list")
DECLARE_STRING(attrName_Id, "id")
DECLARE_STRING(attrName_Cmd, "cmd")
DECLARE_STRING(valueName_DoManual, "do-manual")
DECLARE_STRING(valueName_DoAutomatic, "do-automatic")
DECLARE_STRING(valueName_DoExit, "do-exit")
DECLARE_STRING(valueName_GetTestList, "get-test-list")
DECLARE_STRING(valueName_GetStatus, "get-status")
DECLARE_STRING(valueName_RunAll, "run-all")
DECLARE_STRING(valueName_RunSelected, "run-selected")
DECLARE_STRING(attrName_Status, "status")
DECLARE_STRING(valueName_Unknown, "unknown")
DECLARE_STRING(valueName_Ok, "ok")
DECLARE_STRING(valueName_Error, "error")
DECLARE_STRING(valueName_Repeat, "repeat")
DECLARE_STRING(tagName_DeviceInfo, "deviceInfo")
DECLARE_STRING(tagName_UniqueId, "uniqueId")
DECLARE_STRING(tagName_Name, "name")
DECLARE_STRING(tagName_SystemName, "systemName")
DECLARE_STRING(tagName_SystemVersion, "systemVersion")
DECLARE_STRING(tagName_Model, "model")
DECLARE_STRING(tagName_LocalizedModel, "localizedModel")
DECLARE_STRING(tagName_UserInterfaceIdiom, "userInterfaceIdiom")
DECLARE_STRING(tagName_Log, "log")
DECLARE_STRING(tagName_Status, "status")
DECLARE_STRING(tagName_DeviceName, "deviceName")

ValueProperties _responseTypeAttrValues [] =
{
    {NULL, msgType_Empty},
    {valueName_Pong, valueName_PongLength, msgType_Pong},
    {valueName_Hello, valueName_HelloLength, msgType_Hello},
    {valueName_Cmd, valueName_CmdLength, msgType_Cmd},
    {valueName_Report, valueName_ReportLength, msgType_Report}
};

ValueProperties _responseKindAttrValues [] =
{
    {valueName_Log, valueName_LogLength, reportType_Log},
    {valueName_Status, valueName_StatusLength, reportType_Status},
    {valueName_List, valueName_ListLength, reportType_List}
};

ValueProperties _responseCmdAttrValues [] =
{
    {valueName_DoManual, valueName_DoManualLength, cmdType_DoManual},
    {valueName_DoAutomatic, valueName_DoAutomaticLength, cmdType_DoAutomatic},
    {valueName_DoExit, valueName_DoExitLength, cmdType_DoExit},
    {valueName_GetTestList, valueName_GetTestListLength, cmdType_GetTestList},
    {valueName_GetStatus, valueName_GetStatusLength, cmdType_GetStatus},
    {valueName_RunAll, valueName_RunAllLength, cmdType_RunAll},
    {valueName_RunSelected, valueName_RunSelectedLength, cmdType_RunSelected}
};

ValueProperties _responseStatusAttrValues [] =
{
    {valueName_Ok, valueName_OkLength, statusType_Ok},
    {valueName_Error, valueName_ErrorLength, statusType_Error},
    {valueName_Repeat, valueName_RepeatLength, statusType_Repeat}
};

ValueProperties _requestTypeAttrValues [] =
{
    {NULL, 0, msgType_Empty},
    {valueName_Ping, valueName_PingLength, msgType_Ping},
    {valueName_Hello, valueName_HelloLength, msgType_Hello},
    {valueName_NextCmd, valueName_NextCmdLength, msgType_NextCmd},
    {valueName_Report, valueName_ReportLength, msgType_Report}
};

ValueProperties _requestKindAttrValues [] =
{
    {valueName_Unknown, valueName_UnknownLength, reportType_Unknown},
    {valueName_Log, valueName_LogLength, reportType_Log},
    {valueName_Status, valueName_StatusLength, reportType_Status},
    {valueName_List, valueName_ListLength, reportType_List}
};

const AttributeRequirements _requestTypeAttrRequirements = {attrName_Type, attrName_TypeLength,
    YES, NO, _requestTypeAttrValues, ARRAYSIZE(_requestTypeAttrValues)};
const AttributeRequirements _requestKindAttrRequirements = {attrName_Kind, attrName_KindLength,
    YES, NO, _requestKindAttrValues, ARRAYSIZE(_requestKindAttrValues)};
const AttributeRequirements _requestIdAttrRequirements = {attrName_Id, attrName_IdLength,
    NO, YES, NULL, 0};

const AttributeRequirements _responseTypeAttrRequirements = {attrName_Type, attrName_TypeLength,
    YES, NO, _responseTypeAttrValues, ARRAYSIZE(_responseTypeAttrValues)};
const AttributeRequirements _responseKindAttrRequirements = {attrName_Kind, attrName_KindLength,
    YES, NO, _responseKindAttrValues, ARRAYSIZE(_responseKindAttrValues)};
const AttributeRequirements _responseIdAttrRequirements = {attrName_Id, attrName_IdLength,
    NO, YES, NULL, 0};
const AttributeRequirements _responseCmdAttrRequirements = {attrName_Cmd, attrName_CmdLength,
    YES, NO, _responseCmdAttrValues, ARRAYSIZE(_responseCmdAttrValues)};
const AttributeRequirements _responseStatusAttrRequirements = {attrName_Status, attrName_StatusLength,
    YES, NO, _responseStatusAttrValues, ARRAYSIZE(_responseStatusAttrValues)};

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void initMessageBuffer(MessageBuffer *message) {
    if (message != NULL) {
        message->buffer = NULL;
        message->capacity = 0;
        message->length = 0;
    }
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void freeMessageBuffer(MessageBuffer *message) {
    if (message != NULL) {
        if (message->buffer != NULL) {
            free(message->buffer);
        }
        initMessageBuffer(message);
    }
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void extendMessageBuffer(MessageBuffer *message, uint16_t delta) {
    if (message != NULL && delta > 0) {
        uint16_t newSize = message->capacity + delta + 1024;
        message->buffer = realloc(message->buffer, newSize);
        message->capacity = newSize;
    }
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void appendMessageBuffer(MessageBuffer *message, const uint8_t *data, uint16_t dataLength) {
    if (data != NULL && message != NULL && dataLength > 0) {
        while (message->capacity <= message->length + dataLength + 1) {
            extendMessageBuffer(message, dataLength + 1);
        }
        memcpy(message->buffer + message->length, data, dataLength);
        message->length += dataLength;
        message->buffer[message->length] = 0;
    }
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void appendMessageBufferWithFormat(MessageBuffer *message, const char *template, ...) {
    while (YES) {
        va_list argList;
        va_start(argList, template);
        int requiredLength = vsnprintf((char *)message->buffer + message->length, message->capacity - message->length, template, argList);
        va_end(argList);
        
        if (message->capacity <= message->length + requiredLength + 1) {
            extendMessageBuffer(message, requiredLength + 1);
        } else {
            message->length += requiredLength;
            message->buffer[message->length] = 0;
            break;
        }
    }
}

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/
void resetMessageBuffer(MessageBuffer *message) {
    message->length = 0;
    if (message->buffer != NULL) {
        message->buffer[message->length] = 0;
    }
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void moveNodeInfoInstanceToFreePool(ParsingNodeInfo **list, ParsingNodeInfo** freePool) {
    if (list != NULL && *list != NULL && freePool != NULL) {
        ParsingNodeInfo *nodeToFree = *list;
        *list = nodeToFree->parentNode;
        freeMessageBuffer(&nodeToFree->nodeValue);
        nodeToFree->parentNode = *freePool;
        *freePool = nodeToFree;
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void moveAllNodeInfoInstancesToFreePool(ParsingNodeInfo **list, ParsingNodeInfo** freePool) {
    if (list != NULL && freePool != NULL) {
        while (*list != NULL) {
            moveNodeInfoInstanceToFreePool(list, freePool);
        }
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void cleanFreePool(ParsingNodeInfo **freePool) {
    while (freePool != NULL && *freePool != NULL) {
        ParsingNodeInfo *info = *freePool;
        *freePool = info->parentNode;
        free(info);
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void initNodeInfo(ParsingNodeInfo *info) {
    if (info != NULL) {
        info->parentNode = NULL;
        info->localname = NULL;
        info->prefix = NULL;
        info->URI = NULL;
        initMessageBuffer(&info->nodeValue);
    }
}

/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
ParsingNodeInfo *getNewNodeInfo (ParsingNodeInfo **freePool) {
    ParsingNodeInfo *newInfo = NULL;
    
    if (freePool != NULL && *freePool != NULL) {
        newInfo = *freePool;
        *freePool = newInfo->parentNode;
    } else {
        newInfo = malloc(sizeof(ParsingNodeInfo));
    }
    
    initNodeInfo(newInfo);
    
    return newInfo;
}

DECLARE_STRING(c_quoteEscapeValue,          "&quot;")
DECLARE_STRING(c_ampersandEscapeValue,      "&amp;")
DECLARE_STRING(c_greaterThanEscapeValue,    "&gt;")
DECLARE_STRING(c_lessThanEscapeValue,       "&lt;")
DECLARE_STRING(c_apostropheEscapeValue,     "&apos;")
DECLARE_STRING(c_crEscapeValue,             "&#xD;")
DECLARE_STRING(c_lfEscapeValue,             "&#xA;")

typedef struct _SpecialXmlCharacter
{
    char          symbol;
    const char*   escapedValue;
    long          sizeOfEscapedValue;
} SpecialXmlCharacter;

SpecialXmlCharacter xmlSpecials[] = 
{
    {'\"',  c_quoteEscapeValue,         c_quoteEscapeValueLength},
    {'&',   c_ampersandEscapeValue,     c_ampersandEscapeValueLength},
    {'>',   c_greaterThanEscapeValue,   c_greaterThanEscapeValueLength},
    {'<',   c_lessThanEscapeValue,      c_lessThanEscapeValueLength},
    {'\'',   c_apostropheEscapeValue,    c_apostropheEscapeValueLength},
    {'\n',   c_lfEscapeValue,    c_lfEscapeValueLength},
    {'\r',   c_crEscapeValue,    c_crEscapeValueLength},
};

/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
void rangeCopy (const char *source, int rangeStart, int rangeSize, char **destination, int *start, int *capacity, int *left, int initialCapacity)
{
    if (source != NULL && destination != NULL && *destination != NULL && capacity != NULL && left != NULL) {
        if (rangeSize > 0)
        {
            while (*left <= rangeSize) {
                *capacity += initialCapacity;
                *left += initialCapacity;
                *destination = realloc(*destination, *capacity);
            }
            strncpy(*destination + *start, source + rangeStart, rangeSize);
            *start += rangeSize;
            *left -= rangeSize;
        }
    }
}


/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
char *escapeCString(const char *source, int size) {
    
    char *converted = NULL;
    
    if (source != NULL && size >= 0)
    {
        int initalCapacity = size + (size / 10 + 1) * 5; // 10% of the source string multiply on avarage size of the escaped sympbol like '&amp;'
        int capacity = initalCapacity;
        int left = capacity;
        int index = 0;
        int rangeStart = 0;
        int o_start = 0;
        int rangeSize = 0;
        
        converted = malloc(capacity);
        
        // copy the end 0 as well
        for (index = 0; index <= size; index++) {
            char ch = source[index];
            int count;
            for (count = 0; count < ARRAYSIZE(xmlSpecials); count++)
            {
                SpecialXmlCharacter*    xmlChar = &xmlSpecials[count];
                if (ch == xmlChar->symbol)
                {
                    rangeSize = index - rangeStart;
                    rangeCopy(source, rangeStart, rangeSize, &converted, &o_start, &capacity, &left, initalCapacity);
                    rangeStart = index + 1;
                    rangeCopy(xmlChar->escapedValue, 0, xmlChar->sizeOfEscapedValue, &converted, &o_start, &capacity, &left, initalCapacity);
                    break;
                }
            }            
        }
        
        rangeSize = index - rangeStart;
        rangeCopy(source, rangeStart, rangeSize, &converted, &o_start, &capacity, &left, initalCapacity);
    }
    
    return converted;
}

/*----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
char *unescapeCString(const char *source, int size) {
    
    char *converted = NULL;
    
    if (source != NULL && size >=0)
    {
        int capacity = size + 1; // 10% of the source string multiply on avarage size of the escaped sympbol like '&amp;'
        int s_index = 0;
        int d_index = 0;
        
        converted = malloc(capacity);
        
        // copy the end 0 as well
        for (s_index = 0; s_index <= size; s_index++) {
            char ch = source[s_index];
            if (ch == '&')
            {
                for (int count = 0; count < ARRAYSIZE(xmlSpecials); count++)
                {
                    SpecialXmlCharacter*    xmlChar = &xmlSpecials[count];
                    if (strncmp(source + s_index, xmlChar->escapedValue, xmlChar->sizeOfEscapedValue) == 0) {
                        if (d_index < capacity)
                        {
                            converted[d_index++] = xmlChar->symbol;
                        }
                        s_index += xmlChar->sizeOfEscapedValue - 1;
                        break;
                    }
                }
            } else if (d_index < capacity) {
                converted[d_index++] = ch;
            }
        }    
    }
    
    return converted;
}


/*-----------------------------------------------------------------------------
 
 ----------------------------------------------------------------------------*/
BOOL analyzeAttributes (const xmlChar **attributes,
                        int nb_attributes,
                        const AttributeRequirements *attrRequirements,
                        int *context,
                        const char **value,
                        int *valueSize) {
    BOOL success = NO;
    
    // verify that input prameters are correct
    if (attributes != 0 && nb_attributes > 0
        && attrRequirements != NULL && attrRequirements->attrName != NULL
        && attrRequirements->attrNameSize > 0) {
        
        ValueProperties *valueProp = NULL;
        BOOL attrExists = NO;
        
        // perform loop through all available attributes (localname/prefix/URI/value/end)
        for (int count = 0; count < nb_attributes; count ++) {
            
            const xmlChar *attrName = attributes[count * 5 + 0];
            //const xmlChar *prefix = attributes[count * 5 + 1];
            //const xmlChar *uri = attributes[count * 5 + 2]
            const xmlChar *attrValue = attributes[count * 5 + 3];
            uint16_t attrValueSize = attributes[count * 5 + 4] - attrValue;
            
            if (strncmp((const char*)attrName, attrRequirements->attrName, attrRequirements->attrNameSize) == 0) {
                
                attrExists = YES;
                
                if (attrRequirements->checkForExpectedValues
                    && attrRequirements->expectedValues != NULL) {
                    // check for expected atttribute values
                    for (int index = 0; index < attrRequirements->expectedValuesSize; index++) {
                        valueProp = &(attrRequirements->expectedValues[index]);
                        if (valueProp->valNameSize == attrValueSize
                            && strncmp(valueProp->valName, (const char*)attrValue, attrValueSize) == 0) {
                            success = YES;
                            if (context != NULL) {
                                *context = valueProp->context;
                            }
                            break;
                        }
                    }
                }
                
                if (attrRequirements->checkForExistense) {
                    success = YES;
                    if (value != NULL && valueSize != NULL) {
                        *value = (const char*)attrValue;
                        *valueSize = attrValueSize;
                    }
                }
                break;
            }
        }
        
        if (!success && !attrExists) {
            // verify 
            for (int index = 0; index < attrRequirements->expectedValuesSize; index++) {
                valueProp = &(attrRequirements->expectedValues[index]);
                if (valueProp->valName == NULL && valueProp->valNameSize == 0) {
                    success = YES;
                    if (context != NULL) {
                        *context = valueProp->context;
                    }
                    break;
                }
            }
        }
    }
    return success;
}

