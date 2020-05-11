//
//  UIImage+PECrop.m
//  PhotoCropEditor
//
//  Created by Ernesto Rivera on 2013/07/29.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "UIImage+PECrop.h"

@implementation UIImage (PECrop)

- (UIImage *)rotatedImageWithtransform:(CGAffineTransform)rotation
                         croppedToRect:(CGRect)rect
{
    UIImage *rotatedImage = [self pe_rotatedImageWithtransform:rotation];

    // just crop, image normalization is already done together with rotation
    UIImage *croppedImage = [rotatedImage pe_croppedImageWithRect:rect preferredScale:self.scale];
    
    return croppedImage;
}

- (UIImage *)pe_croppedImageWithRect:(CGRect)rect
{
    return [[self pe_normalizedImage] pe_croppedImageWithRect:rect preferredScale:self.scale];
}

#pragma mark - private methods and helpers

- (UIImage *)pe_croppedImageWithRect:(CGRect)rect
                      preferredScale:(CGFloat)preferredScale
{
    CGFloat scale = self.scale;
    CGRect cropRect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(scale, scale));
    
    CGImageRef croppedImage = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage *image = [UIImage imageWithCGImage:croppedImage scale:preferredScale orientation:self.imageOrientation];
    CGImageRelease(croppedImage);
    
    return image;
}

- (UIImage *)pe_rotatedImageWithtransform:(CGAffineTransform)transform
{
    CGSize size = self.size;
    
    UIGraphicsBeginImageContextWithOptions(size,
                                           YES,                     // Opaque
                                           self.scale);             // Use image scale
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, size.width / 2, size.height / 2);
    CGContextConcatCTM(context, transform);
    CGContextTranslateCTM(context, size.width / -2, size.height / -2);
    [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return rotatedImage;
}

- (UIImage *)pe_normalizedImage
{
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    CGSize size = self.size;
    
    UIGraphicsBeginImageContextWithOptions(size, YES, self.scale);
    [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return normalizedImage;
}

@end
