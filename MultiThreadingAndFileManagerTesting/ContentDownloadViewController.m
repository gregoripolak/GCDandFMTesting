//
//  ContentDownloadViewController.m
//  MultiThreadingAndFileManagerTesting
//
//  Created by Gil Polak on 1/27/15.
//  Copyright (c) 2015 Gregori Polak. All rights reserved.
//

#import "ContentDownloadViewController.h"
#import "URLContentDownloader.h"
#import "NotifcationCenterNames.h"

@interface ContentDownloadViewController ()

// UI Proprties
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *startDownloadAndWaitButton;
@property (weak, nonatomic) IBOutlet UIButton *waitWhileRunning;
@property (weak, nonatomic) IBOutlet UIButton *showPathButton;
@property (weak, nonatomic) IBOutlet UILabel *downloadsInSessionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *downloadsCompletedLabel;
//Model Property
@property (strong, nonatomic) URLContentDownloader *contetnDownloader;
@property (strong, nonatomic) NSArray *arrayOfURLs;

@end

@implementation ContentDownloadViewController

#pragma mark - init

- (URLContentDownloader *)contetnDownloader
{
    if (_contetnDownloader == nil)
    {
        _contetnDownloader = [[URLContentDownloader alloc] init];
    }
    
    return _contetnDownloader;
}

- (NSArray *) arrayOfURLs
{
    if (_arrayOfURLs == nil)
    {
        NSURL *url1 = [NSURL URLWithString:@"https://lh5.googleusercontent.com/-qarwxckwHNA/AAAAAAAAAAI/AAAAAAAAAAA/TxvBRbTMcBk/photo.jpg"];
        NSURL *url2 = [NSURL URLWithString:@"http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/swift_tut.jpg"];
        NSURL *url3 = [NSURL URLWithString:@"http://insolitebuzz.fr/wp-content/uploads/2014/10/test-all-the-things.jpg"];
        NSURL *url4 = [NSURL URLWithString:@"http://upload.wikimedia.org/wikipedia/commons/9/94/Large.mc.arp.750pix.jpg"];
        NSURL *url5 = [NSURL URLWithString:@"http://apod.nasa.gov/apod/image/9712/orionfull_jcc_big.jpg"];
        
        _arrayOfURLs = @[url1, url2, url3, url4, url5];
    }
    
    return _arrayOfURLs;
}

#pragma mark - View session

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Regisiting
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI)
                                                 name:DownloadingSessionNotification object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DownloadingSessionNotification object:nil];
}

#pragma mark - User interaction.

- (IBAction)downloadButtonPressed:(id)sender // Will start downloading content for all URLs in array, and wait until finished
{
    [self.contetnDownloader startDownloadingContent:self.arrayOfURLs];
}


- (IBAction)presentFilePathButton:(id)sender // Will show path for each URL downloaded(if download succed) at textView.
{
    if([[self.contetnDownloader URLtoFileDictionary] count] != 0){
        int randomLinkToPresent = rand() % [[self.contetnDownloader URLtoFileDictionary] count];
        NSString *valueForPath = [self.contetnDownloader getPathPerUrl:[self.arrayOfURLs objectAtIndex:randomLinkToPresent]];

        self.textView.text = [NSString stringWithFormat:@"URL Path: %@\n\nFile path: %@",
                          [(NSURL *)[self.arrayOfURLs objectAtIndex:randomLinkToPresent] absoluteString],
                          (valueForPath != nil) ? valueForPath : @"file path unavilable"];
    }
    else
    {
        self.textView.text = @"No paths to show.";
    }
}

- (IBAction)waitButton:(id)sender
{
    [self.contetnDownloader waitUntilContentIsDownloaded];
}

- (void) updateUI
{
    NSInteger downloadsInSession = self.contetnDownloader.counterDownloadsInSession;
    NSInteger downloadsCompleted = self.contetnDownloader.counterDownloadsComplete;
    NSInteger totalDownloads = downloadsInSession + downloadsCompleted;
    NSNumber *downloadsSuccesfull = [NSNumber numberWithInteger:self.contetnDownloader.URLtoFileDictionary.count];
    
    BOOL isDownloading = (downloadsInSession > 0);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:isDownloading];
    self.downloadsInSessionNumberLabel.text = [NSString stringWithFormat:@"%ld\\%ld Complete", (long)downloadsCompleted, (long)totalDownloads];
    self.showPathButton.enabled = !isDownloading && (self.contetnDownloader.URLtoFileDictionary != nil);
    self.waitWhileRunning.enabled = isDownloading;
    self.startDownloadAndWaitButton.enabled = (downloadsInSession == 0);
    self.downloadsCompletedLabel.text = [NSString stringWithFormat:@"Successful: %@", (downloadsSuccesfull.integerValue > 0) ?
                                         downloadsSuccesfull.stringValue : @"none"];
    self.textView.text = @"";
}


@end
