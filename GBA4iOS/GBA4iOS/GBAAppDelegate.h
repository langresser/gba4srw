//
//  GBAAppDelegate.h
//  GBA4iOS
//
//  Created by Riley Testut on 5/23/12.
//  Copyright (c) 2012 Testut Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameListViewController.h"
#import "SettingViewController.h"

#define kUMengAppKey @"50a5517a52701506f8000017"
#define kDianjinAppKey 12932
#define kDianjinAppSecrect @"b46da6977eaf1861438e8cfd799a4fce"
#define kMangoAppKey @"0a6d56311af3494f8f3ce4e423269ab2"

@interface GBAAppDelegate : UIResponder <UIApplicationDelegate, UIPopoverControllerDelegate>
{
    UINavigationController* gameVC;
    GameListViewController* gameListVC;
    SettingViewController* settingVC;
    UIPopoverController * popoverVC;
}
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UIPopoverController * popoverVC;

- (void)updatePreferences;
-(void)showSettingPopup:(BOOL)show;
-(void)showGameList;
-(void)restartGame;
@end


extern GBAAppDelegate *AppDelegate();