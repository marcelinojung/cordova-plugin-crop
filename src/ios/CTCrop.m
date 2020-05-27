#import "CTCrop.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

@interface CTCrop ()
@property (copy) NSString* callbackId;
@property (assign) NSUInteger quality;
@property (assign) NSUInteger targetWidth;
@property (assign) NSUInteger targetHeight;
@property (assign) NSUInteger allowRotate;
@property (assign) NSUInteger keepCropAspectRatio;
@end

@implementation CTCrop

- (void) cropImage: (CDVInvokedUrlCommand *) command {
    UIImage *image;
    NSString *imagePath = [command.arguments objectAtIndex:0];
    NSDictionary *options = [command.arguments objectAtIndex:1];
    
    self.quality = 50;
    self.targetWidth = options[@"targetWidth"] ? [options[@"targetWidth"] intValue] : -1;
    self.targetHeight = options[@"targetHeight"] ? [options[@"targetHeight"] intValue] : -1;
    self.allowRotate = options[@"allowRotate"] ? [options[@"allowRotate"] boolValue] : NO;
    self.keepCropAspectRatio = options[@"keepCropAspectRatio"] ? [options[@"keepCropAspectRatio"] boolValue] : YES;
    NSString *filePrefix = @"file://";
    
    if ([imagePath hasPrefix:filePrefix]) {
        imagePath = [imagePath substringFromIndex:[filePrefix length]];
    }
    
    
    if (!(image = [UIImage imageWithContentsOfFile:imagePath])) {
        NSDictionary *err = @{
                              @"message": @"Image doesn't exist",
                              @"code": @"ENOENT"
                              };
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:err];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    PECropViewController *cropController = [[PECropViewController alloc] init];
    cropController.delegate = self;
    cropController.image = image;
    
    CGFloat width = self.targetWidth > -1 ? (CGFloat)self.targetWidth : image.size.width;
    CGFloat height = self.targetHeight > -1 ? (CGFloat)self.targetHeight : image.size.height;
    CGFloat length = MIN(width, height);
    CGFloat croperWidth;
    CGFloat croperHeight;
    
    if (self.targetWidth == -1 || self.targetHeight == -1){
        croperWidth = width;
        croperHeight = height;
    } else if (self.targetHeight == self.targetWidth){
        croperWidth = length;
        croperHeight = length;
    } else if(self.targetWidth > self.targetHeight) {
        croperWidth = width;
        croperHeight = width * self.targetHeight / self.targetWidth;
    } else {
        croperWidth = height * self.targetWidth / self.targetHeight;
        croperHeight = height;
    }
    
    cropController.keepingCropAspectRatio = self.keepCropAspectRatio;
    cropController.toolbarHidden = YES;
    cropController.rotationEnabled = self.allowRotate;
    cropController.imageCropRect = CGRectMake((width - croperWidth) / 2,
                                              (height - croperHeight) / 2,
                                              croperWidth,
                                              croperHeight);
    
    self.callbackId = command.callbackId;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:cropController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    [self.viewController presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - PECropViewControllerDelegate

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage {
    [controller dismissViewControllerAnimated:YES completion:nil];
    if (!self.callbackId) return;
    
    UIImage *resizedImage = [self resizeImage:croppedImage];
    NSData *data = UIImageJPEGRepresentation(resizedImage, ((CGFloat)self.quality)/100);
    NSString* filePath = [self tempFilePath:@"jpg"];
    CDVPluginResult *result;
    NSError *err;
    
    // save file
    if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
    }
    else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[NSURL fileURLWithPath:filePath] absoluteString]];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    self.callbackId = nil;
}

- (void)cropViewControllerDidCancel:(PECropViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *err = @{
                          @"message": @"User cancelled",
                          @"code": @"userCancelled"
                          };
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:err];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    self.callbackId = nil;
}

#pragma mark - Utilites

-(UIImage *)resizeImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = self.targetHeight;
    float maxWidth = self.targetWidth;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, 1.0);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
    
}

- (NSString*)tempFilePath:(NSString*)extension
{
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSFileManager* fileMgr = [[NSFileManager alloc] init]; // recommended by Apple (vs [NSFileManager defaultManager]) to be threadsafe
    NSString* filePath;
    
    // generate unique file name
    int i = 1;
    do {
        filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, extension];
    } while ([fileMgr fileExistsAtPath:filePath]);
    
    return filePath;
}

@end
