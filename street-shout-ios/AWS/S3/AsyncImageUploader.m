/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "AsyncImageUploader.h"
#import "AmazonClientManager.h"
#import "Constants.h"

@implementation AsyncImageUploader

#pragma mark - Class Lifecycle

-(id)initWithImage:(UIImage *)image AndName:(NSString *)imageName {
    self = [super init];
    
    if (self) {
        shoutImage = image;
        shoutImageName = imageName;
        isExecuting = NO;
        isFinished  = NO;
    }
    
    return self;
}

#pragma mark - Overwriding NSOperation Methods

/*
 * For concurrent operations, you need to override the following methods:
 * start, isConcurrent, isExecuting and isFinished.
 *
 * Please refer to the NSOperation documentation for more details.
 * http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html
 */

-(void)start
{
    // Makes sure that start method always runs on the main thread.
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSString *bucketName = S3_BUCKET;
    NSString *keyName = [shoutImageName stringByAppendingFormat:@"--%lu", (unsigned long)kShoutImageWidth];

    NSData *imageData = UIImageJPEGRepresentation (shoutImage, 0.8);
    
    // Puts the file as an object in the bucket.
    S3PutObjectRequest *putObjectRequest = [[S3PutObjectRequest alloc] initWithKey:keyName inBucket:bucketName];
    putObjectRequest.contentType = @"image/jpeg";
    putObjectRequest.data = imageData;
    putObjectRequest.delegate = self;
    
    [[AmazonClientManager s3] putObject:putObjectRequest];
}

-(BOOL)isConcurrent
{
    return YES;
}

-(BOOL)isExecuting
{
    return isExecuting;
}

-(BOOL)isFinished
{
    return isFinished;
}

#pragma mark - AmazonServiceRequestDelegate Implementations

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    self.uploadImageSuccessBlock();
    
    [self finish];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    self.uploadImageFailureBlock();
    
    [self finish];
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    self.uploadImageFailureBlock();
    
    [self finish];
}

#pragma mark - Helper Methods

-(void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished  = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark -

@end
