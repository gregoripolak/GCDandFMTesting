//
//  URLContentDownloader.m
//  IBM-WorklgihtTest
//
//  Created by Gil Polak on 1/28/15.
//  Copyright (c) 2015 Gregori Polak. All rights reserved.
//

#import "URLContentDownloader.h"
#import <CommonCrypto/CommonDigest.h>
#import "NotifcationCenterNames.h"

#define OFFLINE_EXTENSION ".offline"
#define TIMEOUT_INTERVAL 30

@interface URLContentDownloader()

// Logic proprties
@property (strong, nonatomic, readwrite) NSMutableDictionary *URLtoFileDictionary;
@property (strong, nonatomic) NSArray *arrayOfUrls;
// Dispatch contentDispatchGroup
@property (strong, nonatomic) dispatch_queue_t contentDispatchQueue;
@property (strong, nonatomic) dispatch_group_t contentDispatchGroup;
@property (nonatomic, readwrite) NSInteger counterDownloadsInSession;
@property (nonatomic, readwrite) NSInteger counterDownloadsComplete;

@end

@implementation URLContentDownloader

#pragma mark - Initalizer

- (dispatch_queue_t) contentDispatchQueue
{
    if (!_contentDispatchQueue) {
        _contentDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return _contentDispatchQueue;
}

- (dispatch_group_t) contentDispatchGroup
{
    if (!_contentDispatchGroup)
    {
        _contentDispatchGroup = dispatch_group_create();
    }
    return _contentDispatchGroup;
}


- (NSMutableDictionary *)URLtoFileDictionary
{
    if (_URLtoFileDictionary == nil)
    {
        _URLtoFileDictionary = [[NSMutableDictionary alloc] init];
    }
    return _URLtoFileDictionary;
}

- (instancetype) initWithArrayOfURLs:(NSArray *)urlsArray
{
    self = [super init];
    
    if (self != nil)
    {
        self.arrayOfUrls = urlsArray;
    }
    
    return self;
}

#pragma mark - Required test methods

- (void) startDownloadingContent: (NSArray*)urls
{
    for (NSURL* urlToPerformAsyncDownloadOn in urls)
    {
        [self downloadInSessionNotification];
        
        dispatch_group_async(self.contentDispatchGroup, self.contentDispatchQueue, ^{ // Launch block to async contentDispatchGroup to download and save file
            NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:urlToPerformAsyncDownloadOn cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:TIMEOUT_INTERVAL];
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:downloadRequest
                   completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                       if (!error) {
                           NSString *filePath = [self moveFileToDocumentDirReturnFilePath:location andHashNameByURL:urlToPerformAsyncDownloadOn];
                           if (filePath != nil)
                           {
                               dispatch_async(dispatch_get_main_queue(),
                                ^{
                                    [self.URLtoFileDictionary setValue:[NSURL URLWithString:filePath] forKey:[urlToPerformAsyncDownloadOn absoluteString]];
                                });
                           }
                       }
                       dispatch_async(dispatch_get_main_queue(), ^{ [self downloadCompletedSessionNotification]; });
                   }];
            [downloadTask resume];
        });
    }
}

- (void) waitUntilContentIsDownloaded
{
    dispatch_group_wait(self.contentDispatchGroup, DISPATCH_TIME_FOREVER);
}

- (NSString*) getPathPerUrl: (NSURL*)url
{
    NSURL *pathInFileSystemForUrl = [self.URLtoFileDictionary objectForKey:[url absoluteString]];
    
    return (pathInFileSystemForUrl != nil) ? [pathInFileSystemForUrl absoluteString] : nil;
}

- (NSString *) moveFileToDocumentDirReturnFilePath:(NSURL *)fileURLToMove andHashNameByURL: (NSURL *)urlToHash
{
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *hashedFileName = [self getSHA1HashStringByURL:urlToHash];
    NSString *hashedFilePath = [NSString stringWithFormat:@"%@/%@%s", dirPath, hashedFileName, OFFLINE_EXTENSION];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    
    bool didSavingFileSucced = [fileManager moveItemAtURL:fileURLToMove toURL:[NSURL fileURLWithPath:hashedFilePath] error:&error];
    if (!didSavingFileSucced)
    {
        NSLog(@"Changing file name after download didn't succed %@", error);
    }
    
    return didSavingFileSucced ? hashedFilePath : nil;
}

// Gets SHA1 Hash as file name.
- (NSString *) getSHA1HashStringByURL: (NSURL *)requestPathURL
{
    NSData *encodedDataFromRequestPathURL = [[requestPathURL absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hashedBytesNameResult[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(encodedDataFromRequestPathURL.bytes, (CC_LONG)encodedDataFromRequestPathURL.length, hashedBytesNameResult);
    NSMutableString *fileHashedName = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [fileHashedName appendFormat:@"%02x", hashedBytesNameResult[i]];
    }
    
    return [NSString stringWithString:fileHashedName];
}

#pragma mark - Notifications

- (void) downloadInSessionNotification
{
    self.counterDownloadsInSession++;
    [self notifyChangeInSession];
}

- (void) downloadCompletedSessionNotification
{
    self.counterDownloadsComplete++;
    self.counterDownloadsInSession--;
    [self notifyChangeInSession];

}

- (void) notifyChangeInSession
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadingSessionNotification object:self];
}

@end
