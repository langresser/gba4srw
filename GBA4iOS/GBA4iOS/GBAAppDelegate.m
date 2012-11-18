//
//  GBAAppDelegate.m
//  GBA4iOS
//
//  Created by Riley Testut on 5/23/12.
//  Copyright (c) 2012 Testut Tech. All rights reserved.
//

#import "GBAAppDelegate.h"
#import "../../iGBA/iphone/gpSPhone/src/gpSPhone_iPhone.h"
#import "UMFeedback.h"
#import "MobClick.h"

GBAAppDelegate *AppDelegate()
{
	return (GBAAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@class gpSPhone_iphone;

char * __preferencesFilePath;
extern int gpSPhone_LoadPreferences();
extern int gpSPhone_SavePreferences();

@implementation GBAAppDelegate

@synthesize window = _window;
@synthesize popoverVC;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    NSDictionary *firstRunValues = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:YES], USER_DEFAULT_KEY_AUTOSAVE,
									[NSNumber numberWithBool:YES], USER_DEFAULT_KEY_SMOOTH_SCALING,
                                    [NSNumber numberWithBool:YES],
                                    USER_DEFAULT_KEY_SOUND,
									nil];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	for (NSString *defaultKey in [firstRunValues allKeys])
	{
		NSNumber *value = [defaults objectForKey:defaultKey];
		if (!value)
		{
			value = [firstRunValues objectForKey:defaultKey];
			[defaults setObject:value forKey:defaultKey];
		}
	}
    
    [self updatePreferences];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    documentsDirectoryPath = [documentsDirectoryPath stringByAppendingPathComponent:@"saves"];
    [fm createDirectoryAtPath:documentsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];

    gameListVC = [[GameListViewController alloc]init];
    
    [MobClick startWithAppkey:kUMengAppKey];
    [[DianJinOfferPlatform defaultPlatform] setAppId:kDianjinAppKey andSetAppKey:kDianjinAppSecrect];
	[[DianJinOfferPlatform defaultPlatform] setOfferViewColor:kDJBrownColor];
    [UMFeedback checkWithAppkey:kUMengAppKey];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecNewMsg:) name:UMFBCheckFinishedNotification object:nil];
    
    gameVC = [[UINavigationController alloc] initWithRootViewController:gameListVC];
    [gameVC setNavigationBarHidden:YES];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = gameVC;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark - Preferences

- (void)updatePreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    preferences.frameSkip = [defaults integerForKey:@"frameskip"];
    preferences.scaled = [defaults boolForKey:@"scaled"];
    preferences.selectedPortraitSkin = [defaults integerForKey:@"portraitSkin"];
    preferences.selectedLandscapeSkin = [defaults integerForKey:@"landscapeSkin"];
    preferences.cheating = [defaults boolForKey:@"cheatsEnabled"];
    
}



-(void)showSettingPopup:(BOOL)show
{
    if (show) {
        if (isPad()) {
            if (popoverVC == nil) {
                settingVC = [[SettingViewController alloc]initWithNibName:nil bundle:nil];
                popoverVC = [[UIPopoverController alloc] initWithContentViewController:settingVC];
                popoverVC.delegate = self;
            }
            
            CGRect rect;
            switch (gameVC.interfaceOrientation) {
                case UIInterfaceOrientationLandscapeLeft:
                case UIInterfaceOrientationLandscapeRight:
                    rect = CGRectMake(100, 60, 10, 10);
                    [popoverVC presentPopoverFromRect:rect inView:gameVC.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                    break;
                case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationPortraitUpsideDown:
                    rect = CGRectMake(400, 580, 10, 10);
                    [popoverVC presentPopoverFromRect:rect inView:gameVC.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
                    break;
                default:
                    break;
            }
            
        } else {
            if (settingVC == nil) {
                settingVC = [[SettingViewController alloc]initWithNibName:nil bundle:nil];
            }
            
            [gameVC pushViewController:settingVC animated:YES];
        }
    } else {
        if (isPad()) {
            [popoverVC dismissPopoverAnimated:YES];
        } else {
            [settingVC.navigationController popViewControllerAnimated:YES];
        }
    }
    
}

-(void)showGameList
{
    if (isPad()) {
        [popoverVC dismissPopoverAnimated:NO];
    }
    
    [gameVC popToRootViewControllerAnimated:YES];
}

-(void)restartGame
{
    if (isPad()) {
        [popoverVC dismissPopoverAnimated:NO];
    }
    
    [gameVC popToRootViewControllerAnimated:NO];
    [gameListVC restartGame];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
}

-(void)onRecNewMsg:(NSNotification*)notification
{
    NSArray * newReplies = [notification.userInfo objectForKey:@"newReplies"];
    if (!newReplies) {
        return;
    }
    
    UIAlertView *alertView;
    NSString *title = [NSString stringWithFormat:@"有%d条新回复", [newReplies count]];
    NSMutableString *content = [NSMutableString string];
    for (int i = 0; i < [newReplies count]; i++) {
        NSString * dateTime = [[newReplies objectAtIndex:i] objectForKey:@"datetime"];
        NSString *_content = [[newReplies objectAtIndex:i] objectForKey:@"content"];
        [content appendString:[NSString stringWithFormat:@"%d: %@---%@\n", i+1, _content, dateTime]];
    }
    
    alertView = [[UIAlertView alloc] initWithTitle:title message:content delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    ((UILabel *) [[alertView subviews] objectAtIndex:1]).textAlignment = NSTextAlignmentLeft ;
    [alertView show];
    
}



@end
