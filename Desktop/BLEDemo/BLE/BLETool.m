//
//  BLETool.m
//  BLE
//
//  Created by lzm on 16/5/3.
//  Copyright © 2016年 lzm. All rights reserved.
//

#import "BLETool.h"
#define freeTime 0.38


@interface BLETool()<CBCentralManagerDelegate,CBPeripheralDelegate>
// 代表手机的中心
@property (nonatomic,strong)CBCentralManager * manager;
@property (nonatomic,strong)CBPeripheral * curPeripheral;
@property (nonatomic,strong)CBCharacteristic * characteristic1001;
@property (nonatomic,strong)CBCharacteristic * characteristic1002;

@property (nonatomic,strong)NSTimer * timer;
// 每间隔 一定时间 重置
@property (nonatomic,assign)BOOL free;
@end


static BLETool * shareUtil = nil;

@implementation BLETool


#pragma mark - 构造方法
/**
 *  单例
 */
+(instancetype) shareInstance
{
    // 保证程序的运行中 只执行一次
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        shareUtil = [[self alloc] init] ;
    }) ;
    return shareUtil ;
}

- (instancetype)init
{
    self = [super init];
    _peripheralArr = [@[] mutableCopy];
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    _timer = [NSTimer scheduledTimerWithTimeInterval:freeTime target:self selector:@selector(repeatState) userInfo:nil repeats:YES];
    return self;
}

- (void)repeatState
{
    _free = YES;
}

#pragma mark - custom Method


/**
 *  判断 蓝牙是否开启
 */
- (BOOL)isLECapableHardware
{
    NSString * state = nil;
    
    int iState = (int)[_manager state];
    
    NSLog(@"Central manager state: %i", iState);
    
    switch ([_manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"蓝牙关闭了 Bluetooth is currently powered off.";
            
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"蓝牙是打开的";
            
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
    }
    
    NSLog(@"手机蓝牙状态Central manager state: %@", state);
    
    return FALSE;
}


- (void)scan
{
    //----------------------------
    // 1. 要先判断蓝牙的状态
    if ([self isLECapableHardware]) {
         // 调用中心的搜索方法
         // nil 代表所有
        [_manager scanForPeripheralsWithServices:nil options:nil];
    }
    
    /**
     *  针对性扫秒的例子
     */
    //        [_manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"180D"]] options:nil];
   
    
}

- (void)stopScan
{
    
}


- (void)connectPeripheralBy:(NSInteger)index
{
    [_manager connectPeripheral:self.peripheralArr[index] options:nil];
}


#pragma mark - CBCentralManagerDelegate 
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"蓝牙状态更新了");
    [self isLECapableHardware];
}

/**
 *  确实连接上了设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral");
    if ([self.delegate respondsToSelector:@selector(peripheralArrChange)]) {
        [self.delegate peripheralArrChange];
    }
    //----------------------------
    // 1.连接上后 应该停止扫描
    [_manager stopScan];
    
    // 2.发现服务 nil--> 全部
    peripheral.delegate = self;
    _curPeripheral = peripheral;
    [peripheral discoverServices:nil];
}

/**
 *  断开了连接
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral");
}

/**
 *  发现了设备
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral = %@ -- RSSI = %@",peripheral,RSSI);
    if (![_peripheralArr containsObject:peripheral]) {
        [_peripheralArr addObject:peripheral];
        if (self.delegate) {
            [self.delegate peripheralArrChange];
        }
    }
    
}

/**
 *  连接失败
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral");
}

#pragma mark - CBPeripheralDelegate
/**
 *  发现服务
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"Services == > %@",peripheral.services);
    //----------------------------
    // 1.遍历服务 找到需要的服务
    for (CBService * service in peripheral.services) {
        //----------------------------
        // 2. 对找到的服务进行查看里面的特征
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FF01"]]) {
            // 第一个参数nil == >所有   第二个代表我们需要的service
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
   NSLog(@"Services == > %@",peripheral.services);
    for (CBCharacteristic * character in service.characteristics ) {
        //----------------------------
        // 1. 1001 写入的通道
        if ([character.UUID isEqual:[CBUUID UUIDWithString:@"1001"]]) {
            _characteristic1001 = character;
        }
        if ([character.UUID isEqual:[CBUUID UUIDWithString:@"1002"]]) {
            _characteristic1002 = character;
            // 设置监听
            [peripheral setNotifyValue:YES forCharacteristic:character];

        }
    }
  

    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    NSLog(@"收到返回 = %@",characteristic.value);
}

#pragma mark - 自定义发送数据

/**
 *  最大值为255 
 */
- (void)ble001:(NSInteger)red Green:(NSInteger)green AndBlue:(NSInteger)blue
{
    if (!_free)  return;

    int i = 0;
    char dataArr[10] = {0x00};
    dataArr[i++] = 0xBB;
    dataArr[i++] = 0xAA;
    dataArr[i++] = 0x07;
    dataArr[i++] = red;
    dataArr[i++] = green;
    dataArr[i++] = blue;
    dataArr[i++] = 0;
    dataArr[i++] = 80;
    
    //----------------------------
    // 2. 打包成data
    NSData * data = [NSData dataWithBytes:dataArr length:10];
    
    //----------------------------
    // 3. 发送
    [_curPeripheral writeValue:data forCharacteristic:_characteristic1001 type:CBCharacteristicWriteWithResponse];
    _free = NO;
}


@end
