//
//  VC1.m
//  BLE
//
//  Created by lzm on 16/5/3.
//  Copyright © 2016年 lzm. All rights reserved.
//

#import "VC1.h"
#import "KZColorPicker.h"
#import "BLETool.h"
#import "UIColor-Expanded.h"
@interface VC1 ()<UITableViewDataSource,UITableViewDelegate,BLEToolDelegate>
@property (weak, nonatomic) IBOutlet UIView *colorPickerContainerView;
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;
@property (weak, nonatomic) IBOutlet UILabel *lbStatu;
@property (nonatomic,strong) KZColorPicker * picker;
@end

@implementation VC1

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    KBLETool.delegate =self;
    //----------------------------
    //  观察
//    [KBLETool addObserver:self forKeyPath:@"peripheralArr" options:NSKeyValueObservingOptionNew context:nil];
    
}


#pragma mark - 初始化ui

- (void)initUI
{
    self.picker = [[KZColorPicker alloc]initWithFrame:self.colorPickerContainerView.bounds];
    [self.picker addTarget:self action:@selector(pickerChanged:) forControlEvents:UIControlEventValueChanged];
    [self.colorPickerContainerView addSubview:self.picker];
    
}

#pragma mark - colorPickerchange

- (void)pickerChanged:(KZColorPicker *)picker
{
    NSArray * RGBColor = [picker.selectedColor arrayFromRGBAComponents];
    NSInteger R = [RGBColor[0] floatValue] * 255;
    NSInteger G = [RGBColor[1] floatValue] * 255;
    NSInteger B = [RGBColor[2] floatValue] * 255;
    [KBLETool ble001:R Green:G AndBlue:B];
}


#pragma mark - Action

- (IBAction)btnScanCLick:(id)sender {
    
    [KBLETool scan];
    
}

#pragma mark - tableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [KBLETool peripheralArr].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * ID = @"UITableViewCell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    CBPeripheral * per = [KBLETool peripheralArr][indexPath.row];
    cell.textLabel.text = per.name;
    cell.detailTextLabel.text = per.state==CBPeripheralStateConnected?@"已连接":@"未连接";
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [KBLETool connectPeripheralBy:indexPath.row];
    
}

#pragma mark - BLETooldelegate
- (void)peripheralArrChange
{
    [self.resultTableView reloadData];
}

@end
