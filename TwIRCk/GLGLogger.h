//
//  GLGLogger.h
//  TwIRCk
//
//  Created by Tim Jarratt on 12/7/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#ifdef DEBUG
    #define NSLog(...) NSLog(__VA_ARGS__)
#else
    #define NSLog(...)
#endif