//
//  Utility.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "Utility.h"
#import "AppDelegate.h"
#import "NavigationViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UserAccount.h"
#import "Constants.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"
#import "UniversalDevice.h"
#import "ContainerViewController.h"


static NSDictionary *smallIconMappings;
static NSDictionary *largeIconMappings;
static NSDateFormatter *dateFormatter;
static CGFloat const kZoomAnimationSpeed = 0.2f;

/**
 * TaskPriority lightweight class
 */
@implementation TaskPriority
+ (id)taskPriorityWithImageName:(NSString *)imageName summary:(NSString *)summary
{
    TaskPriority *taskPriority = [TaskPriority new];
    taskPriority.image = [UIImage imageNamed:imageName];
    taskPriority.summary = summary;
    return taskPriority;
}
@end


@interface Utility ()

+ (NSDateFormatter *)dateFormatter;

@end

/**
 * Notice Messages
 */
SystemNotice *displayErrorMessage(NSString *message)
{
    return displayErrorMessageWithTitle(message, nil);
}

SystemNotice *displayErrorMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showErrorNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayWarningMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showWarningNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayInformationMessage(NSString *message)
{
    return [SystemNotice showInformationNoticeInView:activeView() message:message];
}

SystemNotice *displayInformationMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showInformationNoticeInView:activeView() message:message title:title];
}

UIView *activeView(void)
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ContainerViewController *containerController = (ContainerViewController *)appDelegate.window.rootViewController;
    
    if (appDelegate.window.rootViewController.presentedViewController)
    {
        //To work around a system notice that is tried to be presented in a modal view controller
        return appDelegate.window.rootViewController.presentedViewController.view;
    }
    else if (IS_IPAD)
    {
        return containerController.view;
    }
    return appDelegate.window.rootViewController.view;
}

UIImage *smallImageForType(NSString *type)
{
    type = [type lowercaseString];
    
    if (!smallIconMappings)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:kSmallThumbnailImageMappingPlist ofType:@"plist"];
        smallIconMappings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    NSString *imageName = [smallIconMappings objectForKey:type];
    
    if (!imageName)
    {
        imageName = @"small_document.png";
    }
    
    return [UIImage imageNamed:imageName];
}

UIImage *largeImageForType(NSString *type)
{
    type = [type lowercaseString];
    
    if (!largeIconMappings)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:kLargeThumbnailImageMappingPlist ofType:@"plist"];
        largeIconMappings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    NSString *imageName = [largeIconMappings objectForKey:type];
    
    if (!imageName)
    {
        imageName = @"large_document.png";
    }
    
    return [UIImage imageNamed:imageName];
}

/*
 * resize image to a different size
 * @param image: image to be resized
 * @param size:  resizing size
 */
UIImage *resizeImage(UIImage *image, CGSize size)
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

NSString *relativeDateFromDate(NSDate *date)
{
    if (nil == date)
    {
		return @"";
	}

    NSDate *today = [NSDate date];
    NSDate *earliest = [today earlierDate:date];
    BOOL isTodayEarlierDate = (today == earliest);
    NSDate *latest = isTodayEarlierDate ? date : today;

    NSString *(^relativeDateString)(NSString *key, NSInteger param) = ^NSString *(NSString *key, NSInteger param) {
        NSString *dateKey = [NSString stringWithFormat:@"relative.date.%@.%@", isTodayEarlierDate ? @"future" : @"past", key];
        return [NSString stringWithFormat:NSLocalizedString(dateKey, @"Date string"), param];
    };

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *components = [calendar components:unitFlags fromDate:earliest toDate:latest options:0];
    
    if (components.year >= 2)
    {
        return relativeDateString(@"n-years", components.year);
    }
    else if (components.year >= 1)
    {
        return relativeDateString(@"one-year", components.year);
    }
    else if (components.month >= 2)
    {
        return relativeDateString(@"n-months", components.month);
    }
    else if (components.month >= 1)
    {
        return relativeDateString(@"one-month", components.month);
    }
    else if (components.week >= 2)
    {
        return relativeDateString(@"n-weeks", components.week);
    }
    else if (components.week >= 1)
    {
        return relativeDateString(@"one-week", components.week);
    }
    else if (components.day >= 2)
    {
        return relativeDateString(@"n-days", components.day);
    }
    else if (components.day >= 1)
    {
        return relativeDateString(@"one-day", components.day);
    }
    else if (components.hour >= 2)
    {
        return relativeDateString(@"n-hours", components.hour);
    }
    else if (components.hour >= 1)
    {
        return relativeDateString(@"one-hour", components.hour);
    }
    else if (components.minute >= 2)
    {
        return relativeDateString(@"n-minutes", components.minute);
    }
    else if (components.minute >= 1)
    {
        return relativeDateString(@"one-minute", components.minute);
    }
    else if (components.second >= 2)
    {
        return relativeDateString(@"n-seconds", components.second);
    }

    return NSLocalizedString(@"relative.date.just-now", @"Just now");
}

NSString *stringForLongFileSize(unsigned long long size)
{
	double floatSize = size;
	if (size < 1023)
    {
        return([NSString stringWithFormat:@"%llu %@", size, NSLocalizedString(@"file.size.bytes", @"file bytes, used as follows: '100 bytes'")]);
    }
    
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
    {
        return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.kilobytes", @"Abbreviation for Kilobytes, used as follows: '17KB'")]);
    }
    
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
    {
        return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.megabytes", @"Abbreviation for Megabytes, used as follows: '2MB'")]);
    }
    
	floatSize = floatSize / 1024;
	
    return ([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.gigabytes", @"Abbrevation for Gigabyte, used as follows: '1GB'")]);
}

NSString *stringByRemovingHTMLTagsFromString(NSString *htmlString)
{
    if (!htmlString)
    {
        return nil;
    }
    
    NSRange range;
    NSString *string = htmlString;
    
    while ((range = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    }
    
    // also replace &nbsp; with " "
    return [string stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
}

NSString *uniqueFileNameForNode(AlfrescoNode *node)
{
    NSString *lastModificationDateString = [[Utility dateFormatter] stringFromDate:node.modifiedAt];
    NSString *nodeIdentifier = node.identifier;
    
    NSRange versionNumberRange = [node.identifier rangeOfString:@";"];
    if (versionNumberRange.location != NSNotFound)
    {
        nodeIdentifier = [node.identifier substringToIndex:versionNumberRange.location];
    }
    NSString *nodeUniqueIdentifier = [NSString stringWithFormat:@"%@%@", nodeIdentifier, lastModificationDateString];
    
    NSMutableCharacterSet *wantedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [wantedCharacters invert];
    NSString *fileNameString = [[nodeUniqueIdentifier componentsSeparatedByCharactersInSet:wantedCharacters] componentsJoinedByString:@""];
    
    return fileNameString;
}

NSData *jsonDataFromDictionary(NSDictionary *dictionary)
{
    NSData *jsonData = nil;
    
    if ([NSJSONSerialization isValidJSONObject:dictionary])
    {
        NSError *jsonError = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&jsonError];
        if (jsonError == nil)
        {
            jsonData = data;
        }
    }
    return jsonData;
}

NSDictionary *dictionaryOfVariableBindingsWithArray(NSArray *views)
{
    NSMutableDictionary *returnDictionary = nil;
    
    if (views)
    {
        returnDictionary = [NSMutableDictionary dictionaryWithCapacity:views.count];
        
        NSString *keyTemplateFormat = @"view%d";
        for (int i = 0; i < views.count; i++)
        {
            UIView *currentView = views[i];
            NSString *keyForCurrentView = [NSString stringWithFormat:keyTemplateFormat, i];
            [returnDictionary setObject:currentView forKey:keyForCurrentView];
        }
    }
    
    return returnDictionary;
}

/*
 * appends current timestamp to name
 * @param name: current filename
 */
NSString *fileNameAppendedWithDate(NSString *name)
{
    NSString *dateString = [[Utility dateFormatter] stringFromDate:[NSDate date]];
    NSString *fileExtension = name.pathExtension;
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", name.stringByDeletingPathExtension, dateString];
    
    if (fileExtension && ![fileExtension isEqualToString:@""])
    {
        fileName = [fileName stringByAppendingPathExtension:fileExtension];
    }
    
    return fileName;
}

NSString *filenameAppendedWithDateModified(NSString *filenameOrPath, AlfrescoNode *node)
{
    NSString *dateString = [[Utility dateFormatter] stringFromDate:node.modifiedAt];
    NSString *fileExtension = filenameOrPath.pathExtension;
    NSString *filePathOrName = [NSString stringWithFormat:@"%@_%@", filenameOrPath.stringByDeletingPathExtension, dateString];
    if (fileExtension.length > 0)
    {
        filePathOrName = [filePathOrName stringByAppendingPathExtension:fileExtension];
    }
    return filePathOrName;
}

//void clearOutdatedCacheFiles()
//{
//    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
//    
//    void (^removeOldCachedDataBlock)(NSString *filePath) = ^(NSString *filePath) {
//        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
//        
//        NSDate *lastModifiedDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
//        
//        NSDate *today = [NSDate date];
//        NSCalendar *gregorianCalender = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
//        [offsetComponents setDay:-kNumberOfDaysToKeepCachedData];
//        NSDate *oldestCacheDate = [gregorianCalender dateByAddingComponents:offsetComponents toDate:today options:0];
//        
//        if ([lastModifiedDate compare:oldestCacheDate] == NSOrderedAscending)
//        {
//            NSError *deleteError = nil;
//            [fileManager removeItemAtPath:filePath error:&deleteError];
//            
//            if (deleteError)
//            {
//                AlfrescoLogError([deleteError localizedDescription]);
//            }
//        }
//    };
//    
//    NSString *tmpFolderPath = [fileManager temporaryDirectory];
//    NSString *thumbnailFolderPath = [[fileManager homeDirectory] stringByAppendingPathComponent:kThumbnailMappingFolder];
//    
//    NSError *tmpFolderEnumerationError = nil;
//    [fileManager enumerateThroughDirectory:tmpFolderPath includingSubDirectories:YES withBlock:removeOldCachedDataBlock error:&tmpFolderEnumerationError];
//    
//    if (tmpFolderEnumerationError)
//    {
//        AlfrescoLogError([tmpFolderEnumerationError localizedDescription]);
//    }
//    
//    NSError *thumbnailEnumerationError = nil;
//    [fileManager enumerateThroughDirectory:thumbnailFolderPath includingSubDirectories:YES withBlock:removeOldCachedDataBlock error:&thumbnailEnumerationError];
//    
//    if (thumbnailEnumerationError)
//    {
//        AlfrescoLogError([thumbnailEnumerationError localizedDescription]);
//    }
//}
//
//void uncaughtExceptionHandler(NSException *exception)
//{
//    [Utility clearDefaultFileSystem];
//    
//    NSLog(@"Stack: %@", [exception callStackReturnAddresses]);
//}

@implementation Utility

+ (NSDateFormatter *)dateFormatter
{
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    }
    return dateFormatter;
}

+ (BOOL)isValidEmail:(NSString *)emailAddress
{
    BOOL isEmail = NO;
    
    NSUInteger locationOfAtSymbol = [emailAddress rangeOfString:@"@"].location;
    if (emailAddress.length > 0 && locationOfAtSymbol != NSNotFound && locationOfAtSymbol < emailAddress.length - 1)
    {
        isEmail = YES;
    }
    
    return isEmail;
}

+ (BOOL)isVideo:(NSString *)filePath
{
    BOOL filePathIsVideo = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTI != NULL)
    {
        if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.movie"))
        {
            filePathIsVideo = YES;
        }
        CFRelease(UTI);
    }
    
    return filePathIsVideo;
}

+ (BOOL)isAudio:(NSString *)filePath
{
    BOOL filePathIsAudio = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTI != NULL)
    {
        if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.audio"))
        {
            filePathIsAudio = YES;
        }
        CFRelease(UTI);
    }
    
    return filePathIsAudio;
}

+ (BOOL)isAudioOrVideo:(NSString *)filePath
{
    return [self isAudio:filePath] || [self isVideo:filePath];
}

+ (void)writeInputStream:(NSInputStream *)inputStream toOutputStream:(NSOutputStream *)outputStream completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if (!inputStream || !outputStream)
    {
        NSError *error = [NSError errorWithDomain:@"Provided a nil input or output stream" code:-1 userInfo:nil];
        if (completionBlock != NULL)
        {
            completionBlock(NO, error);
        }
        return;
    }
    
    [inputStream open];
    [outputStream open];
    
    NSUInteger bufferReadSize = 64 * 1024;
    while ([inputStream hasBytesAvailable])
    {
        NSInteger nRead;
        uint8_t buffer[bufferReadSize];
        nRead = [inputStream read:buffer maxLength:bufferReadSize];
        
        [outputStream write:buffer maxLength:nRead];
    }
    
    [inputStream close];
    [outputStream close];
    
    if (completionBlock != NULL)
    {
        completionBlock(YES, nil);
    }
}

+ (NSString *)randomAlphaNumericStringOfLength:(NSUInteger)length
{
    NSString *alphaNumerics = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSUInteger alphaNumericLength = [alphaNumerics length];
        
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
        
    for (int i = 0; i < length; i++)
    {
        int randomIndex = arc4random() % alphaNumericLength;
        [randomString appendFormat:@"%C", [alphaNumerics characterAtIndex:randomIndex]];
    }
        
    return randomString;
}

+ (NSString *)mimeTypeForFileExtension:(NSString *)extension
{
    CFStringRef pathExtension = (__bridge_retained CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (NULL != type)
    {
        CFRelease(type);
    }
    if (NULL != pathExtension)
    {
        CFRelease(pathExtension);
    }
    
    if (!mimeType || [mimeType isEqualToString:@""])
    {
        mimeType = @"application/octet-stream";
    }

    /**
     * Force the mimetype to audio/mp4 it iOS determined it should be audio/x-m4a
     * Otherwise the repo applies both audio and exif aspects to the node
     */
    if ([mimeType isEqualToString:@"audio/x-m4a"])
    {
        mimeType = @"audio/mp4";
    }

    return mimeType;
}

+ (NSString *)fileExtensionFromMimeType:(NSString *)mimeType
{
    CFStringRef MIMEType = (__bridge CFStringRef)mimeType;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, NULL);
    NSString *fileExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
    
    if (uti != NULL)
    {
        CFRelease(uti);
    }
    
    return fileExtension;
}

+ (NSString *)serverURLStringFromAccount:(UserAccount *)account
{
    return [NSString stringWithFormat:kAlfrescoOnPremiseServerURLTemplate, account.protocol, account.serverAddress, account.serverPort];
}

+ (void)zoomAppLevelOutWithCompletionBlock:(void (^)(void))completionBlock
{
    [UIView animateWithDuration:kZoomAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        RootRevealControllerViewController *revealViewController = (RootRevealControllerViewController *)[UniversalDevice revealViewController];
        UIView *revealView = revealViewController.view;
        revealView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
    } completion:^(BOOL finished) {
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

+ (void)resetAppZoomLevelWithCompletionBlock:(void (^)(void))completionBlock
{
    [UIView animateWithDuration:kZoomAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        RootRevealControllerViewController *revealViewController = (RootRevealControllerViewController *)[UniversalDevice revealViewController];
        UIView *revealView = revealViewController.view;
        revealView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}
    
+ (void)colorButtonsForActionSheet:(UIActionSheet *)actionSheet tintColor:(UIColor *)tintColor
{
    NSArray *actionSheetButtons = actionSheet.subviews;
    for (UIView *view in actionSheetButtons)
    {
        if ([view isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)view;
            [button setTitleColor:tintColor forState:UIControlStateNormal];
        }
    }
}

+ (TaskPriority *)taskPriorityForPriority:(NSNumber *)priority
{
    TaskPriority *taskPriority = nil;
    
    switch (priority.integerValue)
    {
        case 1:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_high.png" summary:NSLocalizedString(@"tasks.priority.high", @"High Priority")];
            break;
            
        case 2:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_medium.png" summary:NSLocalizedString(@"tasks.priority.medium", @"Medium Priority")];
            break;

        case 3:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_low.png" summary:NSLocalizedString(@"tasks.priority.low", @"Low Priority")];
            break;
            
        default:
            break;
    }
    
    return taskPriority;
}

+ (NSString *)displayNameForProcessDefinition:(NSString *)processDefinitionIdentifier
{
    NSString *displayNameKey = @"tasks.process.unnamed";
    
    if ([processDefinitionIdentifier hasPrefix:kAlfrescoWorkflowJBPMEngine])
    {
        displayNameKey = [NSString stringWithFormat:@"tasks.process.%@", processDefinitionIdentifier];
    }
    else
    {
        NSArray *components = [processDefinitionIdentifier componentsSeparatedByString:@":"];
        if (components.count == 3)
        {
            displayNameKey = [NSString stringWithFormat:@"tasks.process.%@", components[0]];
        }
    }
    
    return NSLocalizedString(displayNameKey, @"Localized process name");
}

+ (UIImage *)cropImageIntoSquare:(UIImage *)originalImage
{
    UIImage *croppedImage = nil;
    
    float originalImageWidth = originalImage.size.width;
    float originalImageHeight = originalImage.size.height;
    
    float cropWidthHeight = fminf(originalImageWidth, originalImageHeight);
    
    float startXPosition = (originalImageWidth - cropWidthHeight) / 2;
    float startYPosition = (originalImageHeight - cropWidthHeight) / 2;
    
    CGRect cropRect = CGRectMake(startXPosition, startYPosition, cropWidthHeight, cropWidthHeight);
    
    CGImageRef image = CGImageCreateWithImageInRect([originalImage CGImage], cropRect);
    
    if (image != NULL)
    {
        croppedImage = [UIImage imageWithCGImage:image scale:originalImage.scale orientation:originalImage.imageOrientation];
        CGImageRelease(image);
    }
    
    return croppedImage;
}

@end
