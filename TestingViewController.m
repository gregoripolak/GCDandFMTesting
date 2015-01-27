//
//  TestingViewController.m
//  MultiThreadingAndFileManagerTesting
//
//  Created by Gil Polak on 1/27/15.
//  Copyright (c) 2015 Gregori Polak. All rights reserved.
//

#include "TestingViewController.h"
#include <CommonCrypto/CommonDigest.h>
#define OFFLINE_EXTENSION ".offline"

@interface TestingViewController ()

// Logic proprties
@property (strong, nonatomic) NSMutableDictionary *URLtoFileDictionary;
@property (strong, nonatomic) NSArray *arrayOfUrls;
// Dispatch contentDispatchGroup
@property (strong, nonatomic) dispatch_queue_t contentDispatchQueue;
@property (strong, nonatomic) dispatch_group_t contentDispatchGroup;
// UI Proprties
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *startDownloadAndWaitButton;
@property (weak, nonatomic) IBOutlet UIButton *showPathButton;

@end

@implementation TestingViewController

#pragma mark - init

- (NSArray *) arrayOfUrls
{
    if (_arrayOfUrls == nil)
    {
        NSURL *url1 = [NSURL URLWithString:@"https://lh5.googleusercontent.com/-qarwxckwHNA/AAAAAAAAAAI/AAAAAAAAAAA/TxvBRbTMcBk/photo.jpg"];
        NSURL *url2 = [NSURL URLWithString:@"http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/swift_tut.jpg"];
        NSURL *url3 = [NSURL URLWithString:@"http://insolitebuzz.fr/wp-content/uploads/2014/10/test-all-the-things.jpg"];
        NSURL *url4 = [NSURL URLWithString:@"http://upload.wikimedia.org/wikipedia/commons/9/94/Large.mc.arp.750pix.jpg"];
        NSURL *url5 = [NSURL URLWithString:@"http://apod.nasa.gov/apod/image/9712/orionfull_jcc_big.jpg"];
        
        self.arrayOfUrls = @[url1, url2, url3, url4, url5];
    }
    
    return _arrayOfUrls;
}

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

#pragma mark - Required test methods

- (void) startDownloadingContent: (NSArray*)urls
{
    for (NSURL* urlToPerformAsyncDownloadOn in urls)
    {
        dispatch_group_async(self.contentDispatchGroup, self.contentDispatchQueue, ^{ // Launch block to async contentDispatchGroup to download and save file
            NSData *dataFromURL = [NSData dataWithContentsOfURL:urlToPerformAsyncDownloadOn];
            NSString *filePathURL = [self saveDataToFileAndReturnFilePath:dataFromURL andHashByURL:urlToPerformAsyncDownloadOn];
            if (filePathURL != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.URLtoFileDictionary setObject:filePathURL forKey:[urlToPerformAsyncDownloadOn absoluteString]];
                });
            }
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
    
    return pathInFileSystemForUrl ? [pathInFileSystemForUrl absoluteString] : nil;
}

- (NSString *) saveDataToFileAndReturnFilePath: (NSData *)dataFromURL andHashByURL: (NSURL *)urlToHash
{
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *hashedFileName = [self getSHA1HashStringByURL:urlToHash];
    NSString *hashedFilePath = [NSString stringWithFormat:@"%@/%@%s", dirPath, hashedFileName, OFFLINE_EXTENSION];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    bool didSavingFileSucced = [fileManager createFileAtPath:hashedFilePath contents:dataFromURL attributes:nil];
    
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




#pragma mark - User interaction.

- (IBAction)downloadButtonPressed:(id)sender // Will start downloading content for all URLs in array, and wait until finished
{
    self.startDownloadAndWaitButton.enabled = NO;
    [self startDownloadingContent:self.arrayOfUrls];
    [self waitUntilContentIsDownloaded];
    self.showPathButton.enabled = YES;
}


- (IBAction)presentFilePathButton:(id)sender // Will show path for each URL downloaded(if download succed) at textView.
{
    int randomLinkToPresent = rand() % self.arrayOfUrls.count;
    NSString *pathFromArrayByRandomNumber = [(NSURL *)[self.arrayOfUrls objectAtIndex:randomLinkToPresent] absoluteString];
    NSString *valueForPath = [self.URLtoFileDictionary valueForKey:pathFromArrayByRandomNumber];
    
    self.textView.text = [NSString stringWithFormat:@"URL Path: %@\n\nFile path: %@", pathFromArrayByRandomNumber,
                          (valueForPath != nil) ? valueForPath : @"file path unavilable"];
}


@end
