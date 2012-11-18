#import "EmuControllerView.h"
#import <pthread.h>
#import "iosUtil.h"
#import "GBAAppDelegate.h"
#import "../iGBA/iphone/gpSPhone/src/gpSPhone_iPhone.h"

#define MyCGRectContainsPoint(rect, point)						\
	(((point.x >= rect.origin.x) &&								\
		(point.y >= rect.origin.y) &&							\
		(point.x <= rect.origin.x + rect.size.width) &&			\
		(point.y <= rect.origin.y + rect.size.height)) ? 1 : 0)  
		
#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

unsigned long gp2x_pad_status11;
int num_of_joys;

extern CGRect drects[100];
extern int ndrects;

unsigned long btUsed = 0;

CGRect rEmulatorFrame;
static CGRect rPortraitViewFrame;
static CGRect rPortraitViewFrameNotFull;

static CGRect rPortraitImageBackFrame;
static CGRect rPortraitImageOverlayFrame;

static CGRect rLandscapeViewFrame;
static CGRect rLandscapeViewFrameFull;
static CGRect rLandscapeViewFrameNotFull;
static CGRect rLandscapeImageBackFrame;

static CGRect rShowKeyboard;

CGRect rExternal;

extern int nativeTVOUT;
extern int overscanTVOUT;

int iphone_controller_opacity = 50;
int iphone_is_landscape = 0;
int iphone_keep_aspect_ratio_land = 0;
int iphone_keep_aspect_ratio_port = 0;

int safe_render_path = 1;
int enable_dview = 0;
     
/////
int iOS_4buttonsLand = 0;
int iOS_full_screen_land = 0;
int iOS_full_screen_port = 0;
int emulated_width = 320;
int emulated_height = 240;

extern int iOS_landscape_buttons;
int iOS_hide_LR=0;
int iOS_BplusX=0;
int iOS_landscape_buttons=4;
int iOS_skin_data = 1;

#define TOUCH_INPUT_DIGITAL 0

int iOS_inputTouchType = 0;
int iOS_analogDeadZoneValue = 2;
int iOS_waysStick = 4;

#define STICK4WAY (iOS_waysStick == 4 && iOS_inGame)
#define STICK2WAY (iOS_waysStick == 2 && iOS_inGame)
        
enum { DPAD_NONE=0,DPAD_UP=1,DPAD_DOWN=2,DPAD_LEFT=3,DPAD_RIGHT=4,DPAD_UP_LEFT=5,DPAD_UP_RIGHT=6,DPAD_DOWN_LEFT=7,DPAD_DOWN_RIGHT=8};    

enum { BTN_B=0,BTN_X=1,BTN_A=2,BTN_Y=3,BTN_SELECT=4,BTN_START=5,BTN_L1=6,BTN_R1=7,BTN_L2=8,BTN_R2=9};

enum { BUTTON_PRESS=0,BUTTON_NO_PRESS=1};

//states
static int dpad_state;
static int old_dpad_state;

static int btnStates[NUM_BUTTONS];
static int old_btnStates[NUM_BUTTONS];

static unsigned long pressedButtons;
static unsigned long newtouches[NUM_BUTTONS];
static unsigned long oldtouches[NUM_BUTTONS];

extern void reset_sound();
extern void sound_exit();
extern void init_sound();

@implementation EmuControllerView
@synthesize screenView;
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor yellowColor];
        
        nameImgButton_NotPress[BTN_B] = @"button_NotPress_B.png";
        nameImgButton_NotPress[BTN_X] = @"button_NotPress_X.png";
        nameImgButton_NotPress[BTN_A] = @"button_NotPress_A.png";
        nameImgButton_NotPress[BTN_Y] = @"button_NotPress_Y.png";
        nameImgButton_NotPress[BTN_START] = @"button_NotPress_start.png";
        nameImgButton_NotPress[BTN_SELECT] = @"button_NotPress_select.png";
        nameImgButton_NotPress[BTN_L1] = @"button_NotPress_R_L1.png";
        nameImgButton_NotPress[BTN_R1] = @"button_NotPress_R_R1.png";
        nameImgButton_NotPress[BTN_L2] = @"button_NotPress_R_L2.png";
        nameImgButton_NotPress[BTN_R2] = @"button_NotPress_R_R2.png";
        
        nameImgButton_Press[BTN_B] = @"button_Press_B.png";
        nameImgButton_Press[BTN_X] = @"button_Press_X.png";
        nameImgButton_Press[BTN_A] = @"button_Press_A.png";
        nameImgButton_Press[BTN_Y] = @"button_Press_Y.png";
        nameImgButton_Press[BTN_START] = @"button_Press_start.png";
        nameImgButton_Press[BTN_SELECT] = @"button_Press_select.png";
        nameImgButton_Press[BTN_L1] = @"button_Press_R_L1.png";
        nameImgButton_Press[BTN_R1] = @"button_Press_R_R1.png";
        nameImgButton_Press[BTN_L2] = @"button_Press_R_L2.png";
        nameImgButton_Press[BTN_R2] = @"button_Press_R_R2.png";
        
        nameImgDPad[DPAD_NONE]=@"DPad_NotPressed.png";
        nameImgDPad[DPAD_UP]= @"DPad_U.png";
        nameImgDPad[DPAD_DOWN]= @"DPad_D.png";
        nameImgDPad[DPAD_LEFT]= @"DPad_L.png";
        nameImgDPad[DPAD_RIGHT]= @"DPad_R.png";
        nameImgDPad[DPAD_UP_LEFT]= @"DPad_UL.png";
        nameImgDPad[DPAD_UP_RIGHT]= @"DPad_UR.png";
        nameImgDPad[DPAD_DOWN_LEFT]= @"DPad_DL.png";
        nameImgDPad[DPAD_DOWN_RIGHT]= @"DPad_DR.png";
        
        [self getConf];
        
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO; //Performance?
        
        self.userInteractionEnabled = YES;
        
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = NO;
        
        imageBack = [[UIImageView alloc]initWithFrame:frame];
        imageBack.userInteractionEnabled = NO;
        imageBack.multipleTouchEnabled = NO;
        imageBack.clearsContextBeforeDrawing = NO;
        [self addSubview:imageBack];
        
        screenView = [[ScreenView alloc]initWithFrame:frame];
        [self addSubview:screenView];
        
        dpadView = [[UIImageView alloc]initWithFrame:frame];
        [self addSubview:dpadView];
        
        for(int i=0; i<NUM_BUTTONS;i++) {
            buttonViews[i] = [[UIImageView alloc]initWithFrame:frame];
            [self addSubview:buttonViews[i]];
        }
    }
    
    return self;
}

-(void)autoDimiss:(id)sender {

     UIAlertView *alert = (UIAlertView *)sender;
     [alert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)drawRect:(CGRect)rect
{
    
}

- (void)changeUI : (UIInterfaceOrientation)interfaceOrientation {
    [self getConf];

    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        [self buildLandscape : YES];
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self buildLandscape : NO];
    } else if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        [self buildPortrait : NO];
    } else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self buildPortrait : YES];
    }

   [self setNeedsDisplay];
}

- (void)removeDPadView{
   
   int i;
   
   if(dpadView!=nil)
   {
      [dpadView removeFromSuperview];
      dpadView=nil;
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {
      if(buttonViews[i]!=nil)
      {
         [buttonViews[i] removeFromSuperview];
         buttonViews[i] = nil; 
      }
   }
}

- (void)buildDPadView {

   int i;
    
   btUsed = num_of_joys!=0; 
   
   if(btUsed && ((!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land)))
     return;
   
   NSString *name;    
   
   if(iOS_inputTouchType == TOUCH_INPUT_DIGITAL)
   {
	   name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin_data,nameImgDPad[DPAD_NONE]];
       dpadView.image = [UIImage imageNamed:name];
	   dpadView.frame = rDPad_image;
	   if( (!iphone_is_landscape && iOS_full_screen_port) || (iphone_is_landscape && iOS_full_screen_land))
	         [dpadView setAlpha:((float)iphone_controller_opacity / 100.0f)];
	   dpad_state = old_dpad_state = DPAD_NONE;
   }
   else
   {   
       //analogStickView
//	   analogStickView = [[AnalogStickView alloc] initWithFrame:rStickWindow];	  
//	   [self addSubview:analogStickView];  
//	   [analogStickView setNeedsDisplay];
   }
   
   for(i=0; i<NUM_BUTTONS;i++)
   {

      if(iphone_is_landscape || (!iphone_is_landscape && iOS_full_screen_port))
      {
          if(i==BTN_Y && iOS_landscape_buttons < 4)continue;
          if(i==BTN_A && iOS_landscape_buttons < 3)continue;
          if(i==BTN_X && iOS_landscape_buttons < 2)continue;
          if(i==BTN_B && iOS_landscape_buttons < 1)continue;  
                            
          if(i==BTN_L1 && iOS_hide_LR)continue;
          if(i==BTN_R1 && iOS_hide_LR)continue;
      }

      name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin_data,nameImgButton_NotPress[i]];
      buttonViews[i].image = [UIImage imageNamed:name];
      buttonViews[i].frame = rButton_image[i];
      if((iphone_is_landscape && (iOS_full_screen_land /*|| i==BTN_Y || i==BTN_A*/)) || (!iphone_is_landscape && iOS_full_screen_port))      
         [buttonViews[i] setAlpha:((float)iphone_controller_opacity / 100.0f)];
      btnStates[i] = old_btnStates[i] = BUTTON_NO_PRESS; 
   }
       
}

- (void)buildPortrait : (BOOL)isUpsidedown {

   iphone_is_landscape = 0;
   [ self getControllerCoords:0 ];
   
    if(!iOS_full_screen_port)
    {
        if(isPad())
            imageBack.image = [UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPad.png",iOS_skin_data]];
        else
            imageBack.image = [UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_portrait_iPhone.png",iOS_skin_data]];
        
        imageBack.frame = rPortraitImageBackFrame; // Set the frame in which the UIImage should be drawn in.
    }
   
   CGRect r;
   
   if(!iOS_full_screen_port)
   {
	    r = rPortraitViewFrameNotFull;	
   }		  
   else
   {
        r = rPortraitViewFrame;
   }
   
    if(iphone_keep_aspect_ratio_port)
    {

       int tmp_height = r.size.height;// > emulated_width ?
       int tmp_width = ((((tmp_height * emulated_width) / emulated_height)+7)&~7);
       		       
       if(tmp_width > r.size.width) //y no crop
       {
          tmp_width = r.size.width;
          tmp_height = ((((tmp_width * emulated_height) / emulated_width)+7)&~7);
       }   
       
       r.origin.x = r.origin.x + ((r.size.width - tmp_width) / 2);      
       
       if(!iOS_full_screen_port || btUsed)
       {
          r.origin.y = r.origin.y + ((r.size.height - tmp_height) / 2);
       }
       else
       {
          int tmp = r.size.height - (r.size.height/5);
          if(tmp_height < tmp)                                
             r.origin.y = r.origin.y + ((tmp - tmp_height) / 2);
       }
       
       if(tmp_width==320 && !safe_render_path)
       {
          tmp_width = 319;
       }
       
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   
   }
    screenView.frame = r;
    
    //DPAD---
    [self buildDPadView];
    
    if(enable_dview)
    {
        if(dview!=nil)
        {
            [dview removeFromSuperview];
        }
        
        dview = [[DView alloc] initWithFrame:self.bounds];
        
        [self addSubview:dview];
        
        [self filldrectsController];
        
        [dview setNeedsDisplay];
    }
}

- (void)buildLandscape : (BOOL)isLeft{
	
   iphone_is_landscape = 1;
      
   [self getControllerCoords:1 ];
   
    if(!iOS_full_screen_land)
    {
        if(isPad())
            imageBack.image = [UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPad.png",iOS_skin_data]];
        else
            imageBack.image = [UIImage imageNamed:[NSString stringWithFormat:@"./SKIN_%d/back_landscape_iPhone.png",iOS_skin_data]];
        
        imageBack.frame = rLandscapeImageBackFrame; // Set the frame in which the UIImage should be drawn in.
    }
        
   CGRect r;
   
   if(!iOS_full_screen_land) {
        r = rLandscapeViewFrameNotFull;
   } else {
        r = rLandscapeViewFrameFull;
   }     
   
   if(iphone_keep_aspect_ratio_land)
   {
       int tmp_width = r.size.width;// > emulated_width ?
       int tmp_height = ((((tmp_width * emulated_height) / emulated_width)+7)&~7);
       
       //printf("%d %d\n",tmp_width,tmp_height);
       
       if(tmp_height > r.size.height) //y no crop
       {
          tmp_height = r.size.height;
          tmp_width = ((((tmp_height * emulated_width) / emulated_height)+7)&~7);
       }   
       

       r.origin.x = r.origin.x +(((int)r.size.width - tmp_width) / 2);             
       r.origin.y = r.origin.y +(((int)r.size.height - tmp_height) / 2);
       r.size.width = tmp_width;
       r.size.height = tmp_height;
   }
    
    screenView.frame = r;

    [self buildDPadView];
    
    if(enable_dview)
    {
        if(dview!=nil)
        {
            [dview removeFromSuperview];
        }
        
        dview = [[DView alloc] initWithFrame:self.bounds];
        
        [self filldrectsController];
        
        [self addSubview:dview];
        [dview setNeedsDisplay];	 
    }
}

- (void)handle_DPAD{
    if(dpad_state!=old_dpad_state) {
       NSString *imgName; 
       imgName = nameImgDPad[dpad_state];
       if(imgName!=nil)
       {  
         NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin_data,imgName];   
         //printf("%s\n",[name UTF8String]);
         UIImage *img = [UIImage imageNamed:name]; 
         [dpadView setImage:img];
         [dpadView setNeedsDisplay];
       }           
       old_dpad_state = dpad_state;
    }
    
    int i = 0;
    for(i=0; i< NUM_BUTTONS;i++)
    {
        if(btnStates[i] != old_btnStates[i])
        {
           NSString *imgName;
           if(btnStates[i] == BUTTON_PRESS)
           {
               imgName = nameImgButton_Press[i];
           }
           else
           {
               imgName = nameImgButton_NotPress[i];
           } 
           if(imgName!=nil)
           {  
              NSString *name = [NSString stringWithFormat:@"./SKIN_%d/%@",iOS_skin_data,imgName];
              UIImage *img = [UIImage imageNamed:name]; 
              [buttonViews[i] setImage:img];
              [buttonViews[i] setNeedsDisplay];              
           }
           old_btnStates[i] = btnStates[i]; 
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	int touchstate[NUM_BUTTONS];
	//Get all the touches.
	int i;
	NSSet *allTouches = [event allTouches];
	int touchcount = [allTouches count];
    
    if (self.readyToSustain) {
        pressedButtons = 0;
        [self.sustainedButtons removeAllObjects];
    }
	
	for (i = 0; i < NUM_BUTTONS; i++)
	{
		touchstate[i] = 0;
		oldtouches[i] = newtouches[i];
        btnStates[i] = BUTTON_NO_PRESS;
	}
    
    dpad_state = DPAD_NONE;
	
	for (i = 0; i < touchcount; i++)
	{
		UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
		
		if( touch != nil &&
		   ( touch.phase == UITouchPhaseBegan ||
			touch.phase == UITouchPhaseMoved ||
			touch.phase == UITouchPhaseStationary) )
		{
			struct CGPoint point;
			point = [touch locationInView:self];
            
            /*if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
             point = CGPointMake(480 - point.x, point.y);//Fixes offset touches due to the transformation of the controller
             }*/
            
			touchstate[i] = 1;
            
			if (MyCGRectContainsPoint(Left, point))
			{
                dpad_state = DPAD_LEFT;

				pressedButtons |= BIT_L;
				newtouches[i] = BIT_L;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_L]];
                }
			}
			else if (MyCGRectContainsPoint(Right, point))
			{
                dpad_state = DPAD_RIGHT;

				pressedButtons |= BIT_R;
				newtouches[i] = BIT_R;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_R]];
                }
			}
			else if (MyCGRectContainsPoint(Up, point))
			{
                dpad_state = DPAD_UP;

				pressedButtons |= BIT_U;
				newtouches[i] = BIT_U;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_U]];
                }
			}
			else if (MyCGRectContainsPoint(Down, point))
			{
                dpad_state = DPAD_DOWN;

				pressedButtons |= BIT_D;
				newtouches[i] = BIT_D;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_D]];
                }
			}
			else if (MyCGRectContainsPoint(UpLeft, point))
			{
                dpad_state = DPAD_UP_LEFT;

				pressedButtons |= BIT_U | BIT_L;
				newtouches[i] = BIT_U | BIT_L;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_U]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_L]];
                }
			}
			else if (MyCGRectContainsPoint(DownLeft, point))
			{
                dpad_state = DPAD_DOWN_LEFT;

				pressedButtons |= BIT_D | BIT_L;
				newtouches[i] = BIT_D | BIT_L;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_D]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_L]];
                }
			}
			else if (MyCGRectContainsPoint(UpRight, point))
			{
                dpad_state = DPAD_UP_RIGHT;

				pressedButtons |= BIT_U | BIT_R;
				newtouches[i] = BIT_U | BIT_R;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_U]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_R]];
                }
			}
			else if (MyCGRectContainsPoint(DownRight, point))
			{
                dpad_state = DPAD_DOWN_RIGHT;

				pressedButtons |= BIT_D | BIT_R;
				newtouches[i] = BIT_D | BIT_R;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_D]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_R]];
                }
			}
            else if (MyCGRectContainsPoint(ButtonLeft, point))
			{
                btnStates[BTN_A] = BUTTON_PRESS;

				pressedButtons |= BIT_A;
				newtouches[i] = BIT_A;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_A]];
                }
			}
            else if (MyCGRectContainsPoint(ButtonRight, point))
			{
                btnStates[BTN_B] = BUTTON_PRESS;

				pressedButtons |= BIT_B;
				newtouches[i] = BIT_B;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_B]];
                }
			}
            else if (MyCGRectContainsPoint(ButtonDownLeft, point))
			{
                btnStates[BTN_A] = BUTTON_PRESS;
                btnStates[BTN_B] = BUTTON_PRESS;

				pressedButtons |= BIT_A | BIT_B;
				newtouches[i] = BIT_A | BIT_B;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_A]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_B]];
                }
			}
			else if (MyCGRectContainsPoint(LPad, point))
			{
                btnStates[BTN_L1] = BUTTON_PRESS;
                
				pressedButtons |= BIT_LPAD;
				newtouches[i] = BIT_LPAD;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_LPAD]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_LPAD]];
                }
			}
			else if (MyCGRectContainsPoint(RPad, point))
			{
                btnStates[BTN_R1] = BUTTON_PRESS;

				pressedButtons |= BIT_RPAD;
				newtouches[i] = BIT_RPAD;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_RPAD]];
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_RPAD]];
                }
			}
			else if (MyCGRectContainsPoint(Select, point))
			{
                btnStates[BTN_SELECT] = BUTTON_PRESS;

				pressedButtons |= BIT_SEL;
				newtouches[i] = BIT_SEL;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_SEL]];
                }
			}
			else if (MyCGRectContainsPoint(Start, point))
			{
                btnStates[BTN_START] = BUTTON_PRESS;

				pressedButtons |= BIT_ST;
				newtouches[i] = BIT_ST;
                if (self.readyToSustain) {
                    [self.sustainedButtons addObject:[NSNumber numberWithUnsignedInt:BIT_ST]];
                }
			}
			else if (MyCGRectContainsPoint(LPad2, point))
			{
                [AppDelegate() showSettingPopup:YES];
//                [emulatorViewController pauseMenu];
			}
			
			if(oldtouches[i] != newtouches[i])
			{
				pressedButtons &= ~(oldtouches[i]);
			}
		}
	}
    
	for (i = 0; i < 10; i++)
	{
		if(touchstate[i] == 0)
		{
			pressedButtons &= ~(newtouches[i]);
			newtouches[i] = 0;
			oldtouches[i] = 0;
		}
	}
    
    [self handle_DPAD];
    
    if (!self.readyToSustain) {//This way it doesn't re-add the objects when sustaining the button
        NSArray *objects = [self.sustainedButtons allObjects];
        for (int i = 0; i < objects.count; i++) {
            pressedButtons |= [[objects objectAtIndex:i] unsignedIntValue];
        }
    }
    else {
        self.readyToSustain = NO;
    }
    
    cPad1 = pressedButtons;
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)getControllerCoords:(int)orientation {
    char string[256];
    FILE *fp;
	
	if(!orientation)
	{
		if(isPad())
		{
 		   if(iOS_full_screen_port)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_full_iPad.txt",  get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_iPad.txt",  get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}  
		else
		{
		   if(iOS_full_screen_port)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_full_iPhone.txt", get_resource_path("/"),  iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_portrait_iPhone.txt", get_resource_path("/"),  iOS_skin_data] UTF8String], "r");  
		}
    }
	else
	{
		if(isPad())
		{
		   if(iOS_full_screen_land)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_full_iPad.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_iPad.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}
		else
		{
		   if(iOS_full_screen_land)
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_full_iPhone.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		   else
		     fp = fopen([[NSString stringWithFormat:@"%s/SKIN_%d/controller_landscape_iPhone.txt", get_resource_path("/"), iOS_skin_data] UTF8String], "r");
		}
	}
	
	if (fp) 
	{

		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 39) 
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
			
			switch(i)
			{
    		case 0:    DownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 1:    Down   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 2:    DownRight    = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 3:    Left  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 4:    Right  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 5:    UpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 6:    Up     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 7:    UpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 8:    Select = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 9:    Start  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 10:   LPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 11:   RPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 12:   Menu   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 13:   ButtonDownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 14:   ButtonDown   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 15:   ButtonDownRight    	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 16:   ButtonLeft  		= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 17:   ButtonRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 18:   ButtonUpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 19:   ButtonUp     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 20:   ButtonUpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 21:   LPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 22:   RPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 23:   rShowKeyboard  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		
    		case 24:   rButton_image[BTN_B] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 25:   rButton_image[BTN_X]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 26:   rButton_image[BTN_A]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 27:   rButton_image[BTN_Y]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 28:   rDPad_image  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 29:   rButton_image[BTN_SELECT]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 30:   rButton_image[BTN_START]  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 31:   rButton_image[BTN_L1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 32:   rButton_image[BTN_R1] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 33:   rButton_image[BTN_L2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            case 34:   rButton_image[BTN_R2] = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
            
            case 35:   break;
            case 36:   break;
            case 37:   break;
            case 38:   iphone_controller_opacity= coords[0]; break;
			}
      i++;
    }
    fclose(fp);
    
        // iOS_touchDeadZone
    if(1)
    {
        //ajustamos
        if(!isPad())
        {
           if(!orientation)
           {
             Left.size.width -= 17;//Left.size.width * 0.2;
             Right.origin.x += 17;//Right.size.width * 0.2;
             Right.size.width -= 17;//Right.size.width * 0.2;
           }
           else
           {
             Left.size.width -= 14;
             Right.origin.x += 20;
             Right.size.width -= 20;
           }
        }
        else
        {
           if(!orientation)
           {
             Left.size.width -= 22;//Left.size.width * 0.2;
             Right.origin.x += 22;//Right.size.width * 0.2;
             Right.size.width -= 22;//Right.size.width * 0.2;
           }
           else
           {
             Left.size.width -= 22;
             Right.origin.x += 22;
             Right.size.width -= 22;
           }
        }    
    }
  }
}

- (void)getConf{
    char string[256];
    FILE *fp;
	
	if(isPad())
	   fp = fopen([[NSString stringWithFormat:@"%sconfig_iPad.txt", get_resource_path("/")] UTF8String], "r");
	else
	   fp = fopen([[NSString stringWithFormat:@"%sconfig_iPhone.txt", get_resource_path("/")] UTF8String], "r");
	   	
	if (fp) 
	{

		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 12) 
       {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				result = strtok(NULL, ",");
				i2++;
			}
						
			switch(i)
			{
    		case 0:    rEmulatorFrame   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 1:    rPortraitViewFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 2:    rPortraitViewFrameNotFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		
    		case 3:    rPortraitImageBackFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 4:    rPortraitImageOverlayFrame     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		    		
    		case 5:    rLandscapeViewFrame = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
    		case 6:    rLandscapeViewFrameFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;      		    		    		
    		case 7:    rLandscapeViewFrameNotFull = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;    		
    		case 8:    rLandscapeImageBackFrame  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
                case 9:    break;
            case 10:    break;
            case 11:   enable_dview = coords[0]; break;
			}
      i++;
    }
    fclose(fp);
  }
}

- (void)filldrectsController {
    drects[0]=ButtonDownLeft;
    drects[1]=ButtonDown;
    drects[2]=ButtonDownRight;
    drects[3]=ButtonLeft;
    drects[4]=ButtonRight;
    drects[5]=ButtonUpLeft;
    drects[6]=ButtonUp;
    drects[7]=ButtonUpRight;
    drects[8]=Select;
    drects[9]=Start;
    drects[10]=LPad;
    drects[11]=RPad;
    drects[12]=Menu;
    drects[13]=LPad2;
    drects[14]=RPad2;
    drects[15]=rShowKeyboard;
    
    if(iOS_inputTouchType==TOUCH_INPUT_DIGITAL)
    {
        drects[16]=DownLeft;
        drects[17]=Down;
        drects[18]=DownRight;
        drects[19]=Left;
        drects[20]=Right;
        drects[21]=UpLeft;
        drects[22]=Up;
        drects[23]=UpRight;
        
        ndrects = 24;     
    }
    else
    {
    }   
}

@end
