//
//  SettingViewController.m
//  MD
//
//  Created by 王 佳 on 12-9-5.
//  Copyright (c) 2012年 Gingco.Net New Media GmbH. All rights reserved.
//

#import "SettingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIDevice+Util.h"
#import "UIGlossyButton.h"
#import "UMFeedback.h"
#import "GBAAppDelegate.h"

#define kTagAutoSave  100
#define kTagSmoothScaling 101
#define kTagSound 102
#define kTagFrameSkip 103

int g_currentMB = 0;
int g_currentSlot = 1;
NSString* g_currentRom = nil;


extern void save_game_state(char *filepath);
extern void load_game_state(char *filepath);
extern volatile int __emulation_paused;

@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSString*)saveFilePath:(NSString*)fileName slot:(int)slot
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString* saveName = [[g_currentRom stringByDeletingPathExtension] stringByAppendingFormat:@".%d.svs", g_currentSlot];
    NSString* savePath = [[documentsDirectoryPath stringByAppendingPathComponent:@"saves"]stringByAppendingPathComponent:saveName];
    return savePath;
}

-(void)loadView
{
    settingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 480)];
    settingView.backgroundColor = [UIColor colorWithRed:240.0 / 255 green:248.0 / 255 blue:1.0 alpha:1.0];
    m_tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 320, 430) style:UITableViewStyleGrouped];
    m_tableView.delegate = self;
    m_tableView.dataSource = self;
    m_tableView.backgroundColor = [UIColor colorWithRed:240.0 / 255 green:248.0 / 255 blue:1.0 alpha:1.0];
    [m_tableView setBackgroundView:nil];
    [settingView addSubview:m_tableView];

    UIGlossyButton* btnBack = [[UIGlossyButton alloc]initWithFrame:CGRectMake(220, 10, 80, 30)];
    [btnBack setTitle:@"返回游戏" forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(onClickBack) forControlEvents:UIControlEventTouchUpInside];

	[btnBack useWhiteLabel: YES];
    btnBack.tintColor = [UIColor brownColor];
	[btnBack setShadow:[UIColor blackColor] opacity:0.8 offset:CGSizeMake(0, 1) blurRadius: 4];
    [btnBack setGradientType:kUIGlossyButtonGradientTypeLinearSmoothBrightToNormal];
//    btnBack.alpha = 0.7;
    [settingView addSubview:btnBack];
    
    UIGlossyButton* btnBackList = [[UIGlossyButton alloc]initWithFrame:CGRectMake(20, 10, 80, 30)];
    [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btnBackList setTitle:@"游戏列表" forState:UIControlStateNormal];
    [btnBackList addTarget:self action:@selector(onClickBackList) forControlEvents:UIControlEventTouchUpInside];
    
//    btnBackList.alpha = 0.7;
    [btnBackList useWhiteLabel: YES];
    btnBackList.tintColor = [UIColor brownColor];
	[btnBackList setShadow:[UIColor blackColor] opacity:0.8 offset:CGSizeMake(0, 1) blurRadius: 4];
    [btnBackList setGradientType:kUIGlossyButtonGradientTypeLinearSmoothBrightToNormal];
    [settingView addSubview:btnBackList];
    
    [self setView:settingView];
}

- (void)done
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsChanged" object:nil userInfo:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake(320, 480);
    
    static NSString* cellIdent = @"MySellGaoji";
    CGRect rectS = CGRectMake(200, 10, 100, 50);
    autosave = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    autosave.textLabel.font = [UIFont systemFontOfSize:17.0];
    autosave.selectionStyle = UITableViewCellSelectionStyleGray;
    autosave.accessoryType = UITableViewCellAccessoryNone;
    autosave.textLabel.text = @"使用自动存档";
    
    UISwitch* swh1 = [[UISwitch alloc]initWithFrame:rectS];
    swh1.tag = kTagAutoSave;
    [swh1 addTarget:self action:@selector(settingChanged:) forControlEvents:UIControlEventValueChanged];
    [autosave.contentView addSubview:swh1];

    smoothScaling = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    smoothScaling.textLabel.font = [UIFont systemFontOfSize:17.0];
    smoothScaling.selectionStyle = UITableViewCellSelectionStyleGray;
    smoothScaling.accessoryType = UITableViewCellAccessoryNone;
    smoothScaling.textLabel.text = @"抗锯齿";
    
    UISwitch* swh2 = [[UISwitch alloc]initWithFrame:rectS];
    swh2.tag = kTagSmoothScaling;
    [swh2 addTarget:self action:@selector(settingChanged:) forControlEvents:UIControlEventValueChanged];
    [smoothScaling.contentView addSubview:swh2];
    
    enableSound = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    enableSound.textLabel.font = [UIFont systemFontOfSize:17.0];
    enableSound.selectionStyle = UITableViewCellSelectionStyleGray;
    enableSound.accessoryType = UITableViewCellAccessoryNone;
    enableSound.textLabel.text = @"开启声音";
    
    UISwitch* swh3 = [[UISwitch alloc]initWithFrame:rectS];
    swh3.tag = kTagSound;
    [swh3 addTarget:self action:@selector(settingChanged:) forControlEvents:UIControlEventValueChanged];
    [enableSound.contentView addSubview:swh3];
}

- (IBAction) settingChanged:(id)sender
{
    UISwitch* swh = (UISwitch*)sender;
	if (swh.tag == kTagAutoSave) {
        [[NSUserDefaults standardUserDefaults] setBool:[swh isOn] forKey:USER_DEFAULT_KEY_AUTOSAVE];
        [self done];
    } else if (swh.tag == kTagSmoothScaling) {
        [[NSUserDefaults standardUserDefaults] setBool:[swh isOn] forKey:USER_DEFAULT_KEY_SMOOTH_SCALING];
        [self done];
    } else if (swh.tag == kTagSound) {
        [[NSUserDefaults standardUserDefaults] setBool:[swh isOn] forKey:USER_DEFAULT_KEY_SOUND];
        needRestart = YES;
        [self done];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    g_currentMB = [[NSUserDefaults standardUserDefaults]integerForKey:@"MB"];
    [m_tableView reloadData];
    
    needRestart = NO;
    
    __emulation_paused = 1;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    __emulation_paused = 0;
}

-(void)onClickBackList
{
    [AppDelegate() showGameList];
}

-(void)onClickBack
{
    [AppDelegate() showSettingPopup:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"系统设置";
    } else if (section == 1) {
        return @"高级设置";
    } else if (section == 2) {
        return @"其他";
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 4;
    } else if (section == 1) {
        return 3;
    } else if (section == 2) {
        return 4;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 2) {
            static NSString *CellIdentifier = @"PickCell";
            CPPickerViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            if (cell == nil) {
                cell = [[CPPickerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.textLabel.text = @"存档位置";
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.dataSource = self;
            cell.delegate = self;
            cell.currentIndexPath = indexPath;
            cell.showGlass = YES;
            cell.peekInset = UIEdgeInsetsMake(0, 35, 0, 35);
            
            [cell reloadData];            
            [cell selectItemAtIndex:g_currentSlot animated:NO];
            
            return cell;
        } else {
            static NSString* cellIdent = @"MyCellMy";
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
            if (!cell) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdent];
                cell.textLabel.font = [UIFont systemFontOfSize:17.0];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            NSString* saveStatus;
            
            NSFileManager* fm = [NSFileManager defaultManager];
            NSString* savePath = [self saveFilePath:g_currentRom slot:g_currentSlot];
            
            if ([fm fileExistsAtPath:savePath]) {
                NSDictionary* attr = [fm attributesOfItemAtPath:savePath error:nil];
                NSDate* time = [attr objectForKey:NSFileModificationDate];
                
                static NSDateFormatter *dateFormatter = nil;
                if (dateFormatter == nil) {
                    dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
                    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                }
                
                NSString* timestamp = [dateFormatter stringFromDate:time];

                if (g_currentSlot == 0) {
                    saveStatus = [NSString stringWithFormat:@"自动存档: %@", timestamp];
                } else {
                    saveStatus = [NSString stringWithFormat:@"%d 存档位: %@", g_currentSlot - 1, timestamp];
                }
                
            } else {
                if (g_currentSlot == 0) {
                    saveStatus = @"自动存档: 空白";
                } else {
                    saveStatus = [NSString stringWithFormat:@"%d 存档位: 空白", g_currentSlot - 1];
                }
            }
            
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"读档";
                    cell.detailTextLabel.text = saveStatus;
                    break;
                case 1:
                    cell.textLabel.text = @"存档";
                    cell.detailTextLabel.text = saveStatus;
                    break;
                case 3:
                    cell.textLabel.text = @"重置游戏";
                    cell.detailTextLabel.text = @"";
                    break;
                default:
                    break;
            }
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                UISwitch* swh = (UISwitch*)[autosave.contentView viewWithTag:kTagAutoSave];
                swh.on = [[NSUserDefaults standardUserDefaults]boolForKey:USER_DEFAULT_KEY_AUTOSAVE];
                return autosave;
            }
                break;
            case 1:
            {
                UISwitch* swh = (UISwitch*)[smoothScaling.contentView viewWithTag:kTagSmoothScaling];
                swh.on = [[NSUserDefaults standardUserDefaults]boolForKey:USER_DEFAULT_KEY_SMOOTH_SCALING];
                return smoothScaling;
            }
                break;
            case 2:
            {
                UISwitch* swh = (UISwitch*)[enableSound.contentView viewWithTag:kTagSound];
                swh.on = [[NSUserDefaults standardUserDefaults]boolForKey:USER_DEFAULT_KEY_SOUND];
                return enableSound;
            }
                break;
            default:
                break;
        }
    } else if (indexPath.section == 2) {
        static NSString* cellIdent = @"MyCellGongl";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdent];
            cell.textLabel.font = [UIFont systemFontOfSize:17.0];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"意见反馈";
                cell.detailTextLabel.text = @"此非即时通讯，您可以通过微博与我们联系";
                break;
            case 1:
                cell.textLabel.text = @"新浪微博(@BananaStudio)";
                cell.detailTextLabel.text = @"关注我们，了解最新游戏发布及版本更新";
                break;
            case 2:
                cell.textLabel.text = @"腾讯微博(@BananaStudio)";
                cell.detailTextLabel.text = @"关注我们，了解最新游戏发布及版本更新";
                break;
            case 3:
                cell.textLabel.text = @"精品推荐";
                cell.detailTextLabel.text = @"";
                break;
            default:
                break;
        }
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString* savePath = [self saveFilePath:g_currentRom slot:g_currentSlot];
    char szTemp[1024] = {0};
    strlcpy(szTemp, [savePath UTF8String], sizeof(szTemp));

    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [self onClickBack];
                load_game_state(szTemp);
                break;
            case 1:
                [self onClickBack];
                save_game_state(szTemp);
                break;
            case 3:
            {
                UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"" message:@"是否重置游戏?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                alert.tag = 100;
                [alert show];
            }
                break;
            default:
                break;
        }
    } else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0:
                [UMFeedback showFeedback:self withAppkey:kUMengAppKey];
                break;
            case 1:
                openWebsite("http://weibo.com/bananastudi0");
                break;
            case 2:
                openWebsite("http://t.qq.com/BananaStudio");
                break;
            case 3:
                [[DianJinOfferPlatform defaultPlatform]showOfferWall: self delegate:self];
                break;
                break;
            default:
                break;
        }
    }
}

#pragma mark - CPPickerViewCell DataSource
- (NSInteger)numberOfItemsInPickerViewAtIndexPath:(NSIndexPath *)pickerPath {
    if (pickerPath.row == 2) {
        return 11;
    }

    return 0;
}

- (NSString *)pickerViewAtIndexPath:(NSIndexPath *)pickerPath titleForItem:(NSInteger)item {
    if (pickerPath.row == 2) {
        if (item == 0) {
            return @"自动";
        } else {
            return [NSString stringWithFormat:@"%d", item - 1];
        }
    }

    return nil;
}

#pragma mark - CPPickerViewCell Delegate

- (void)pickerViewAtIndexPath:(NSIndexPath *)pickerPath didSelectItem:(NSInteger)item {
    
    if (pickerPath.row == 2) {
        g_currentSlot = item;
    }

    [m_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if (alertView.tag == 100) {
        if (buttonIndex == 1) {
            [self onClickBack];
//            SIReset();
        }
    }
}

@end
