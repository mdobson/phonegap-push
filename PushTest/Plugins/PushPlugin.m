/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PushPlugin.h"
#import "UGClient.h"
#import "UGClientResponse.h"

@implementation PushPlugin

@synthesize notificationMessage;

@synthesize callbackId;
@synthesize notificationCallbackId;
@synthesize callback;


//NSString * orgName = @"mdobson";
//NSString * appName = @"sandbox";
NSString * notifier = @"apple";

//NSString * baseURL = @"http://ug-stress.elasticbeanstalk.com/";

- (void)dealloc
{
    [notificationMessage release];
    self.notificationCallbackId = nil;
    self.callback = nil;

    [super dealloc];
}

- (void)unregister:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
	self.callbackId = [arguments pop];

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [self successWithMessage:@"unregistered"];
}

-(void)registerWithPushProvider:(NSMutableArray*)arguments withDict:(NSMutableDictionary *)options {
    NSLog(@"EQ:%@",[options objectForKey:@"provider"]);
    self.callbackId = [arguments pop];
    if([[options objectForKey:@"provider"] isEqualToString:@"apigee"]) {
        
        NSString * orgName = [options objectForKey:@"orgName"];
        NSString * appName = [options objectForKey:@"appName"];
        NSString * baseUrl = @"https://api.usergrid.com/";
        if([options objectForKey:@"baseUrl"] != nil) {
            baseUrl = [options objectForKey:@"baseUrl"];
        }
        NSLog(@"UG Init");
        
        UGClient * usergridClient = [[UGClient alloc] initWithOrganizationId:orgName withApplicationID:appName baseURL:baseUrl];
        NSLog(@"Registering for push w/apigee");
        UGClientResponse *response = [usergridClient setDevicePushToken: [options objectForKey:@"token"] forNotifier: notifier];
        if (response.transactionState != kUGClientResponseSuccess) {
            [self failWithMessage:response.rawResponse withError:nil];
        } else {
            [self successWithMessage:@"device linked"];
        }
        
    }

}

-(void)pushNotificationToSelf:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    NSString * orgName = [options objectForKey:@"orgName"];
    NSString * appName = [options objectForKey:@"appName"];
    NSString * baseUrl = @"https://api.usergrid.com/";
    if([options objectForKey:@"baseUrl"] != nil) {
        baseUrl = [options objectForKey:@"baseUrl"];
    }
    NSLog(@"UG Init");
    
    UGClient * usergridClient = [[UGClient alloc] initWithOrganizationId:orgName withApplicationID:appName baseURL:baseUrl];
    NSString *deviceId = [UGClient getUniqueDeviceID];
    NSString *thisDevice = [@"devices/" stringByAppendingString: deviceId];
    NSString *message = @"Hello, world! From Phonegap!";
    UGClientResponse *response = [usergridClient pushAlert: message
                                                 withSound: @"chime"
                                                        to: thisDevice
                                             usingNotifier: notifier];
    
    if (response.transactionState != kUGClientResponseSuccess) {
        [self failWithMessage:response.rawResponse withError:nil];
    } else {
        [self successWithMessage:@"Message pushed"];
    }
}


- (void)register:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
	self.callbackId = [arguments pop];

    UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
    
    
    
    
    if ([[options objectForKey:@"badge"] isEqualToString:@"true"])
        notificationTypes |= UIRemoteNotificationTypeBadge;

    if ([[options objectForKey:@"sound"] isEqualToString:@"true"])
        notificationTypes |= UIRemoteNotificationTypeSound;

    if ([[options objectForKey:@"alert"] isEqualToString:@"true"])
        notificationTypes |= UIRemoteNotificationTypeAlert;
    
    self.callback = [options objectForKey:@"ecb"];

    if (notificationTypes == UIRemoteNotificationTypeNone)
        NSLog(@"PushPlugin.register: Push notification type is set to none");

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
}

- (void)isEnabled:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
    UIRemoteNotificationType type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    NSString *jsStatement = [NSString stringWithFormat:@"navigator.PushPlugin.isEnabled = %d;", type != UIRemoteNotificationTypeNone];
    NSLog(@"JSStatement %@",jsStatement);
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    
    
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    [results setValue:token forKey:@"deviceToken"];
    
    #if !TARGET_IPHONE_SIMULATOR
        // Get Bundle Info for Remote Registration (handy if you have more than one app)
        [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"appName"];
        [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
        
        // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
        NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];

        // Set the defaults to disabled unless we find otherwise...
        NSString *pushBadge = @"disabled";
        NSString *pushAlert = @"disabled";
        NSString *pushSound = @"disabled";

        // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
        // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
        // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
        // true if those two notifications are on.  This is why the code is written this way
        if(rntypes == UIRemoteNotificationTypeBadge){
          pushBadge = @"enabled";
        }
        else if(rntypes == UIRemoteNotificationTypeAlert){
          pushAlert = @"enabled";
        }
        else if(rntypes == UIRemoteNotificationTypeSound){
          pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)){
          pushBadge = @"enabled";
          pushAlert = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)){
          pushBadge = @"enabled";
          pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
          pushAlert = @"enabled";
          pushSound = @"enabled";
        }
        else if(rntypes == ( UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)){
          pushBadge = @"enabled";
          pushAlert = @"enabled";
          pushSound = @"enabled";
        }

        [results setValue:pushBadge forKey:@"pushBadge"];
        [results setValue:pushAlert forKey:@"pushAlert"];
        [results setValue:pushSound forKey:@"pushSound"];

        // Get the users Device Model, Display Name, Unique ID, Token & Version Number
        UIDevice *dev = [UIDevice currentDevice];
        [results setValue:dev.uniqueIdentifier forKey:@"deviceUuid"];
        [results setValue:dev.name forKey:@"deviceName"];
        [results setValue:dev.model forKey:@"deviceModel"];
        [results setValue:dev.systemVersion forKey:@"deviceSystemVersion"];

    
		[self successWithMessage:[NSString stringWithFormat:@"%@", token]];
    #endif
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	[self failWithMessage:@"" withError:error];
}

- (void)notificationReceived {
    NSLog(@"Notification received");
    NSLog(@"Msg: %@", [notificationMessage descriptionWithLocale:[NSLocale currentLocale] indent:4]);

    if (notificationMessage) {
        NSMutableString *jsonStr = [NSMutableString stringWithString:@"{"];
        if ([notificationMessage objectForKey:@"alert"])
            [jsonStr appendFormat:@"alert:'%@',", [[notificationMessage objectForKey:@"alert"] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];

        if ([notificationMessage objectForKey:@"badge"])
            [jsonStr appendFormat:@"badge:%d,", [[notificationMessage objectForKey:@"badge"] intValue]];

        if ([notificationMessage objectForKey:@"sound"])
            [jsonStr appendFormat:@"sound:'%@',", [notificationMessage objectForKey:@"sound"]];

        [jsonStr appendString:@"}"];

        NSString * jsCallBack = [NSString stringWithFormat:@"%@(%@);", self.callback, jsonStr];
        [self.webView stringByEvaluatingJavaScriptFromString:jsCallBack];
        
        self.notificationMessage = nil;
    }
}

- (void)setApplicationIconBadgeNumber:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
	DLog(@"setApplicationIconBadgeNumber:%@\n withDict:%@", arguments, options);
    
	self.callbackId = [arguments pop];
    
    int badge = [[options objectForKey:@"badge"] intValue] ?: 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    
    [self successWithMessage:[NSString stringWithFormat:@"app badge count set to %d", badge]];
}

-(void)successWithMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    
    [self writeJavascript:[commandResult toSuccessCallbackString:self.callbackId]];
}

-(void)failWithMessage:(NSString *)message withError:(NSError *)error
{
    NSString        *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
    
    [self writeJavascript:[commandResult toErrorCallbackString:self.callbackId]];
}

@end
