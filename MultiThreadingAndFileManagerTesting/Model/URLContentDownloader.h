//
//  URLContentDownloader.h
//  IBM-WorklgihtTest
//
//  Created by Gil Polak on 1/28/15.
//  Copyright (c) 2015 Gregori Polak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLContentDownloader : NSObject

- (void) startDownloadingContent: (NSArray*)urls;

- (void) waitUntilContentIsDownloaded;

- (NSString*) getPathPerUrl: (NSURL*)url;

@property (nonatomic, readonly) NSInteger counterDownloadsInSession;
@property (nonatomic, readonly) NSInteger counterDownloadsComplete;

@property (strong, nonatomic, readonly) NSMutableDictionary *URLtoFileDictionary;

@end
