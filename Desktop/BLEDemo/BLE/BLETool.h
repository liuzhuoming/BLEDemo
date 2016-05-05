//
//  BLETool.h
//  BLE
//
//  Created by lzm on 16/5/3.
//  Copyright © 2016年 lzm. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

#define KBLETool [BLETool shareInstance]

@protocol BLEToolDelegate <NSObject>

- (void)peripheralArrChange;

@end


@interface BLETool : NSObject
@property (nonatomic,weak)id<BLEToolDelegate> delegate;
@property (nonatomic,strong)NSMutableArray * peripheralArr;

+(instancetype) shareInstance;
- (void)scan;
- (void)stopScan;
- (void)connectPeripheralBy:(NSInteger)index;
/**
 *  最大值为255
 */
- (void)ble001:(NSInteger)red Green:(NSInteger)green AndBlue:(NSInteger)blue;
@end
