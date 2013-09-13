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

#import "AmazonClientManager.h"

#import <AWSRuntime/AWSRuntime.h>

#import "AmazonKeyChainWrapper.h"
#import "AmazonTVMClient.h"

static AmazonS3Client       *s3  = nil;
static AmazonTVMClient      *tvm = nil;

@implementation AmazonClientManager

+(AmazonS3Client *)s3
{
    [AmazonClientManager validateCredentials];
    return s3;
}

+(AmazonTVMClient *)tvm
{
    if (tvm == nil) {
        tvm = [[AmazonTVMClient alloc] initWithEndpoint:TOKEN_VENDING_MACHINE_URL useSSL:USE_SSL];
    }

    return tvm;
}

+(bool)hasCredentials
{
    return ![TOKEN_VENDING_MACHINE_URL isEqualToString:@"http://shouttvm.elasticbeanstalk.com"];
}

+(Response *)validateCredentials
{
    Response *ableToGetToken = [[Response alloc] initWithCode:200 andMessage:@"OK"];
    
    if ([AmazonKeyChainWrapper areCredentialsExpired]) {
        
        @synchronized(self)
        {
            if ([AmazonKeyChainWrapper areCredentialsExpired]) {
                
                ableToGetToken = [[AmazonClientManager tvm] anonymousRegister];
                
                if ( [ableToGetToken wasSuccessful])
                {
                    ableToGetToken = [[AmazonClientManager tvm] getToken];
                    
                    if ( [ableToGetToken wasSuccessful])
                    {
                        [AmazonClientManager initClients];
                    }
                }
            }
        }
    }
    else if (s3 == nil)
    {
        @synchronized(self)
        {
            if (s3 == nil)
            {
                [AmazonClientManager initClients];
            }
        }
    }
    
    return ableToGetToken;
}

+(void)initClients
{
    AmazonCredentials *credentials = [AmazonKeyChainWrapper getCredentialsFromKeyChain];

    s3  = [[AmazonS3Client alloc] initWithCredentials:credentials];
    s3.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
}

+(void)wipeAllCredentials
{
    @synchronized(self)
    {
        [AmazonKeyChainWrapper wipeCredentialsFromKeyChain];
        
        s3  = nil;
    }
}

+ (BOOL)wipeCredentialsOnAuthError:(NSError *)error
{
    id exception = [error.userInfo objectForKey:@"exception"];
    
    if([exception isKindOfClass:[AmazonServiceException class]])
    {
        AmazonServiceException *e = (AmazonServiceException *)exception;
        
        if(
           // STS http://docs.amazonwebservices.com/STS/latest/APIReference/CommonErrors.html
           [e.errorCode isEqualToString:@"IncompleteSignature"]
           || [e.errorCode isEqualToString:@"InternalFailure"]
           || [e.errorCode isEqualToString:@"InvalidClientTokenId"]
           || [e.errorCode isEqualToString:@"OptInRequired"]
           || [e.errorCode isEqualToString:@"RequestExpired"]
           || [e.errorCode isEqualToString:@"ServiceUnavailable"]
           
           // For S3 http://docs.amazonwebservices.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
           || [e.errorCode isEqualToString:@"AccessDenied"]
           || [e.errorCode isEqualToString:@"BadDigest"]
           || [e.errorCode isEqualToString:@"CredentialsNotSupported"]
           || [e.errorCode isEqualToString:@"ExpiredToken"]
           || [e.errorCode isEqualToString:@"InternalError"]
           || [e.errorCode isEqualToString:@"InvalidAccessKeyId"]
           || [e.errorCode isEqualToString:@"InvalidPolicyDocument"]
           || [e.errorCode isEqualToString:@"InvalidToken"]
           || [e.errorCode isEqualToString:@"NotSignedUp"]
           || [e.errorCode isEqualToString:@"RequestTimeTooSkewed"]
           || [e.errorCode isEqualToString:@"SignatureDoesNotMatch"]
           || [e.errorCode isEqualToString:@"TokenRefreshRequired"])
           
        {
            [AmazonClientManager wipeAllCredentials];
            
            return YES;
        }
    }
    
    return NO;
}


@end
