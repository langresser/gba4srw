//
//  GBAEmulatorViewController.h
//  GBA4iOS
//
//  Created by Riley Testut on 5/29/12.
//  Copyright (c) 2012 Testut Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenView.h"
#import "EmuControllerView.h"

@class ScreenView;
@class GBAControllerViewController;

@interface GBAEmulatorViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate> {
    pthread_t emulation_tid;
    
    UIInterfaceOrientation currentOrientation;
    
    EmuControllerView* controllerView;
}

@property (copy, nonatomic) NSString *romPath;
@property (strong, nonatomic) NSMutableArray *saveStateArray;

- (void)loadROM:(NSString *)romFilePath;
- (void)quitROM;
- (void)pauseMenu;
- (void)showActionSheetWithTag:(NSInteger)tag;
@end
