#pragma once
#include "platform_util.h"

#ifdef __cplusplus
extern "C"
#endif
int isPad();

void getScreenSize(int* width, int* height);

void showJoystick();
void hideJoystick();

void showAds();
void closeAds();

void showSetting();
void changeSettingOrientation(int o);

#ifdef __cplusplus
extern "C"
#endif
const char* get_resource_path(char* file);
#define kRemoveAdsFlag @"bsrmads"