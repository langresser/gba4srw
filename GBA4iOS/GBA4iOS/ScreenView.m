/*

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#import "../../iGBA/Frameworks/GraphicsServices.h"
#import "../../iGBA/Frameworks/UIKit-Private/UIView-Geometry.h"
#import "../../iGBA/Frameworks/CoreSurface.h"
#import "ScreenView.h"
#import "../../iGBA/iphone/gpSPhone/src/gpSPhone_iPhone.h"
#import "SettingViewController.h"

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

CoreSurfaceBufferRef screenSurface;
static ScreenView *sharedInstance = nil;

void updateScreen() {
	[ sharedInstance performSelectorOnMainThread:@selector(updateScreen) withObject:nil waitUntilDone: NO ];
}

@implementation ScreenView 
- (id)initWithFrame:(CGRect)frame {
    LOGDEBUG("ScreenView.initWithFrame()");

    rect = frame;
    if (self == [ super initWithFrame:frame ]) {
        sharedInstance = self;
        [ self initializeGraphics ]; 
    }
    return self;
}

- (void)updateScreen {
    [ self setNeedsDisplay ];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    LOGDEBUG("ScreenView.dealloc()");
//    [ timer invalidate];
    [ screenLayer release ];
    [ super dealloc ];
}

- (void)drawRect:(CGRect)rect {
}

- (void)initializeGraphics {

    CFMutableDictionaryRef dict;
    int w, h;

    LOGDEBUG("ScreenView.initGraphics()");

    /* Landscape Resolutions */
    if(preferences.landscape)
    {
        w = 240;
        h = 160;
	}
	else
	{
        w = 240;
        h = 160;	
	}
    int pitch = w * 2, allocSize = 2 * w * h;
    LOGDEBUG("ScreenView.initializeGraphics: Allocating for %d x %d", w, h);
    char *pixelFormat = "565L";

    LOGDEBUG("ScreenView.initGraphics(): Initializing dictionary");
    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal, kCFBooleanTrue);
    CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,
        CFSTR("PurpleGFXMem"));
    CFDictionarySetValue(dict, kCoreSurfaceBufferPitch,
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
    CFDictionarySetValue(dict, kCoreSurfaceBufferWidth,
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &w));
    CFDictionarySetValue(dict, kCoreSurfaceBufferHeight,
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &h));
    CFDictionarySetValue(dict, kCoreSurfaceBufferPixelFormat,
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
    CFDictionarySetValue(dict, kCoreSurfaceBufferAllocSize,
        CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize));

    LOGDEBUG("ScreenView.initGraphics(): Creating CoreSurface buffer");
    screenSurface = CoreSurfaceBufferCreate(dict);

    LOGDEBUG("ScreenView.initGraphics(): Locking CoreSurface buffer");
    CoreSurfaceBufferLock(screenSurface, 3);

    LOGDEBUG("ScreenView.initGraphics(): Creating screen layer");
    screenLayer = [[CALayer layer] retain];
    [screenLayer setContents: screenSurface];
    [screenLayer setOpaque: YES];
    
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey:USER_DEFAULT_KEY_SMOOTH_SCALING] == YES)
    {
        self.layer.minificationFilter = kCAFilterLinear;
        self.layer.magnificationFilter = kCAFilterLinear;
    }
    else
    {
        self.layer.minificationFilter = kCAFilterNearest;
        self.layer.magnificationFilter = kCAFilterNearest;
    }

    LOGDEBUG("ScreenView.initGraphics(): Adding layer as sublayer");
    [self.layer addSublayer: screenLayer ];

    LOGDEBUG("ScreenView.initGraphics(): Unlocking CoreSurface buffer");
    CoreSurfaceBufferUnlock(screenSurface);

    BaseAddress = CoreSurfaceBufferGetBaseAddress(screenSurface);
    LOGDEBUG("ScreenView.initializeGraphics: New base address %p", BaseAddress);             
    LOGDEBUG("ScreenView.initGraphics(): Done");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:@"SettingsChanged" object:nil];
}

- (void)settingsChanged
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if([defaults boolForKey:USER_DEFAULT_KEY_SMOOTH_SCALING] == YES)
    {
        self.layer.minificationFilter = kCAFilterLinear;
        self.layer.magnificationFilter = kCAFilterLinear;
    }
    else
    {
        self.layer.minificationFilter = kCAFilterNearest;
        self.layer.magnificationFilter = kCAFilterNearest;
    }
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    screenLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}
@end
