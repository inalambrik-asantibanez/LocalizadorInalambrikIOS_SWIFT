//
//  NSObject+ObjectiveC.h
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/22/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CustomObject : NSObject

-(NSString *)saveDeviceIDInKeychain:(NSString*)devID;
@end
