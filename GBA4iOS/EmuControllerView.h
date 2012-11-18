#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <QuartzCore/CALayer.h>
#import "DView.h"

#import <pthread.h>
#import <sched.h>
#import <unistd.h>
#import <sys/time.h>

#import "ScreenView.h"

#define NUM_BUTTONS 10

enum  { GP2X_UP=0x1,       GP2X_LEFT=0x4,       GP2X_DOWN=0x10,  GP2X_RIGHT=0x40,
	GP2X_START=1<<8,   GP2X_SELECT=1<<9,    GP2X_L=1<<10,    GP2X_R=1<<11,
	GP2X_A=1<<12,      GP2X_B=1<<13,        GP2X_X=1<<14,    GP2X_Y=1<<15,
	GP2X_VOL_UP=1<<23, GP2X_VOL_DOWN=1<<22, GP2X_PUSH=1<<27 };

@interface EmuControllerView : UIView
{
  ScreenView		* screenView;

  UIImageView	    * imageBack;
  UIImageView	    * imageOverlay;
  DView             * dview;

  UIImageView	    * dpadView;
  UIImageView	    * buttonViews[NUM_BUTTONS];

  //joy controller
  CGRect ButtonUp;
  CGRect ButtonLeft;
  CGRect ButtonDown;
  CGRect ButtonRight;
  CGRect ButtonUpLeft;
  CGRect ButtonDownLeft;
  CGRect ButtonUpRight;
  CGRect ButtonDownRight;
  CGRect Up;
  CGRect Left;
  CGRect Down;
  CGRect Right;
  CGRect UpLeft;
  CGRect DownLeft;
  CGRect UpRight;
  CGRect DownRight;
  CGRect Select;
  CGRect Start;
  CGRect LPad;
  CGRect RPad;
  CGRect LPad2;
  CGRect RPad2;
  CGRect Menu;

  //buttons & Dpad images
  CGRect rDPad_image;
  NSString *nameImgDPad[9];

  CGRect rButton_image[NUM_BUTTONS];

  NSString *nameImgButton_Press[NUM_BUTTONS];
  NSString *nameImgButton_NotPress[NUM_BUTTONS];
}

@property (strong, nonatomic) NSMutableSet *sustainedButtons;
@property (nonatomic) BOOL readyToSustain;
@property(nonatomic, retain) ScreenView* screenView;

- (void)getControllerCoords:(int)orientation;

- (void)getConf;
- (void)filldrectsController;

- (void)removeDPadView;
- (void)buildDPadView;

- (void)changeUI : (UIInterfaceOrientation)interfaceOrientation;

- (void)buildPortrait;
- (void)buildLandscape;

- (void)handle_DPAD;
@end
