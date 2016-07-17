//
//  PMODownloadTaskQueueManager.h
//  PMODownloadManager
//
//  Created by Peter Molnar on 10/04/2016.
//  Copyright © 2016 Peter Molnar. All rights reserved.
//

@import Foundation;

@interface PMODownloadTaskQueues : NSObject

@property (assign, nonatomic) BOOL isDebug;

@property (unsafe_unretained, nonatomic, readonly) NSUInteger normalQueueTaskCount;
@property (unsafe_unretained, nonatomic, readonly) NSUInteger priorityQueueTaskCount;

- (void)addDownloadTaskToNormalPriorityQueue:(NSURLSessionTask *)task;
- (void)addDownloadTaskToHighPriorityQueue:(NSURLSessionTask *)task;
- (void)changeDownloadTaskToHighPriorityQueueFromURL:(NSURL *)downloadURL;
- (void)changeDownloadTaskToNormalPriorityQueueFromURL:(NSURL *)downloadURL;

- (void)clearAllQueue;

@end
