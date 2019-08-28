//
//  NSObject+ObjectiveC.m
//  LocalizadorInalambrik
//
//  Created by Peter Arcentales on 8/22/19.
//  Copyright © 2019 Inalambrilk. All rights reserved.
//

#import "CustomObject.h"

@implementation CustomObject

-(NSString *)saveDeviceIDInKeychain:(NSString*)devID
{
    
    OSStatus sts;
    
    //Let's create an empty mutable dictionary:
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    //Populate it with the data and the attributes we want to use.
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassCertificate; // We specify what kind of keychain item this is.
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked; // This item can only be accessed when the user unlocks the device.
    keychainItem[(__bridge id)kSecAttrSubject] = @"INALAMBRIK_KEY"; // This item can only be accessed when the user unlocks the device.
    
    // Si Item del Keychain no existe, entonces crearlo con el "IMEI" generado por el portal (IOSXXXXXX).
    if(SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, NULL) != noErr)
    {
        
        keychainItem[(__bridge id)kSecAttrSubjectKeyID] = devID;
        
        sts = SecItemAdd((__bridge CFDictionaryRef)keychainItem, NULL);
        //NSLog(@"CREANDO KEYCHAIN ITEM Error Code: %d", (int)sts);
    }
    else // Ya existe, entonces se modifica...
    {
        
        NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
        
        attributesToUpdate[(__bridge id)kSecAttrSubjectKeyID] = devID;
        
        sts = SecItemUpdate((__bridge CFDictionaryRef)keychainItem, (__bridge CFDictionaryRef)attributesToUpdate);
        //NSLog(@"MOFICANDO KEYCHAIN ITEM Error Code: %d", (int)sts);
    }
    
    if(sts == noErr)
        return @"1";
    else
        return @"0";
}

-(NSString *) getGeneratedDeviceIDFromKeychain
{
    
    NSString *keychainDevID = @"";
    
    //Let's create an empty mutable dictionary:
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    
    //Populate it with the data and the attributes we want to use.
    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassCertificate; // We specify what kind of keychain item this is.
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleWhenUnlocked; // This item can only be accessed when the user unlocks the device.
    keychainItem[(__bridge id)kSecAttrSubject] = @"INALAMBRIK_KEY"; // This item can only be accessed when the user unlocks the device.
    
    //Check if this keychain item already exists.
    
    keychainItem[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    keychainItem[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    
    CFDictionaryRef result = nil;
    
    OSStatus sts = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, (CFTypeRef *)&result);
    
    //NSLog(@"GET KEYCHAIN VALUE Error Code: %d", (int)sts);
    
    if(sts == noErr)
    {
        NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
        NSData *dataDevId = resultDict[(__bridge id)kSecAttrSubjectKeyID];
        keychainDevID = [[NSString alloc] initWithData:dataDevId encoding:NSUTF8StringEncoding];
        // Si el valor no empieza con IOS, entonces es una valor no válido.
        if (![keychainDevID hasPrefix:@"IOS"])
            keychainDevID = @"";
    }
    
    return keychainDevID;
}
@end
