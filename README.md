# MultiThreadingAndFileManagerTesting

This is my objective-c Multi-Tasking & FileManaging project.

I have implemented a simple few methods that

1) - (void) startDownloadingContent: (NSArray*)urls
Run through an array of urls and downloads all from web on a dispatch group.

2) - (NSString *) saveDataToFileAndReturnFilePath: (NSData *)dataFromURL andHashByURL: (NSURL *)urlToHash
Saves each downloaded file to Application document folder.

3) - (void) waitUntilContentIsDownloaded
Waits for all files to finish download, blocks main queue while doing so.

3) - (NSString*) getPathPerUrl: (NSURL*)url
Returns FileSystem path for each URL downloaded.

5) Simple UI testing.
