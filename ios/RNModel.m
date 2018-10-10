//
//  RNModel.m
//  RNBLETest
//
//  Created by JuZe ZRY on 2018/9/19.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(BLEController, NSObject)
RCT_EXTERN_METHOD(scan)

RCT_EXTERN_METHOD(connect: (NSInteger)to
                  sensorConnectedCallback: (RCTResponseSenderBlock)sensorConnectedCallback)

RCT_EXTERN_METHOD(disConnect)

RCT_EXTERN_METHOD(setErgMode: (NSInteger)power)

RCT_EXTERN_METHOD(setStandardMode: (NSInteger)level)

RCT_EXTERN_METHOD(setResistanceMode: (NSInteger)percentage)
@end
