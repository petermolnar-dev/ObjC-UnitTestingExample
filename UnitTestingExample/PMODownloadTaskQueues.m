//
//  PMODownloadTaskQueueManager.m
//  PMODownloadManager
//
//  Created by Peter Molnar on 10/04/2016.
//  Copyright © 2016 Peter Molnar. All rights reserved.
//

#import "PMODownloadTaskQueues.h"

@interface PMODownloadTaskQueues()

@property (strong, nonatomic) NSMutableDictionary *normalPriorityQueue;
@property (strong, nonatomic) NSMutableDictionary *highPriorityQueue;

@end

@implementation PMODownloadTaskQueues

#pragma mark - Accessors

- (NSMutableDictionary *)normalPriorityQueue
{
    if (!_normalPriorityQueue) {
        _normalPriorityQueue = [[NSMutableDictionary alloc] init];
    }
    
    return _normalPriorityQueue;
}

- (NSMutableDictionary *)highPriorityQueue {
    
    if (!_highPriorityQueue) {
        _highPriorityQueue = [[NSMutableDictionary alloc] init];
    }
    
    return _highPriorityQueue;
}

- (NSUInteger)normalQueueTaskCount {
    
    return [self.normalPriorityQueue count];
}

- (NSUInteger)priorityQueueTaskCount {
    
    return [self.highPriorityQueue count];
}

#pragma mark - Public interface implementation

- (void)addDownloadTaskToNormalPriorityQueue:(NSURLSessionTask *)task {
    NSURLSessionTask *exisitingTask = [self findTaskInAllQueues:task];
    if (exisitingTask) {
        task = exisitingTask;
        [self moveTask:task fromQueue:self.highPriorityQueue
               toQueue:self.normalPriorityQueue
          withPRiority:NSURLSessionTaskPriorityDefault];
    } else {
        [self addTask:task toQueue:self.normalPriorityQueue];
    }
    
    if ([self isQueueCanBeStarted:self.normalPriorityQueue]) {
        [self resumeQueue:self.normalPriorityQueue];
    }
}

- (void)addDownloadTaskToHighPriorityQueue:(NSURLSessionTask *)task {
    NSURLSessionTask *exisitingTask = [self findTaskInAllQueues:task];
    if (exisitingTask) {
        task = exisitingTask;
        [self moveTask:task fromQueue:self.normalPriorityQueue
               toQueue:self.highPriorityQueue
          withPRiority:NSURLSessionTaskPriorityHigh];
    } else {
        [self addTask:task toQueue:self.highPriorityQueue];
        task.priority = NSURLSessionTaskPriorityHigh;
    }
    
    [self suspendQueue:self.normalPriorityQueue];
    [self resumeQueue:self.highPriorityQueue];
    
    
}


- (void)removeDownloadTask:(NSURLSessionTask *)task fromQueue:(NSMutableDictionary *)queue {
    
    [queue removeObjectForKey:task.currentRequest.URL];
    
}

- (void)removeDownloadTaskFromAllQueues:(NSURLSessionTask *)task {
    
    NSURLSessionTask *exisitingtask = [self findTaskInAllQueues:task];
    if (exisitingtask) {
        [self removeDownloadTask:task fromQueue:self.normalPriorityQueue];
        [self removeDownloadTask:task fromQueue:self.highPriorityQueue];
    }
    
}


- (void)changeDownloadTaskToHighPriorityQueueFromURL:(NSURL *)downloadURL {
    
    NSURLSessionTask *foundTask = [self findTaskByURL:downloadURL inQueue:self.normalPriorityQueue];
    if (foundTask) {
        [self addDownloadTaskToHighPriorityQueue:foundTask];
    }
}

- (void)changeDownloadTaskToNormalPriorityQueueFromURL:(NSURL *)downloadURL {
    
    NSURLSessionTask *foundTask = [self findTaskByURL:downloadURL inQueue:self.highPriorityQueue];
    if (foundTask) {
        [self addDownloadTaskToNormalPriorityQueue:foundTask];
    }
    
}



#pragma mark - Private functions

- (BOOL)isHighPriorityQueueEmpty {
    BOOL result = true;
    if (self.highPriorityQueue.count == 0) {
        return result;
    } else {
        NSArray *keys = [self.highPriorityQueue  allKeys];
        for (NSURL *currentTaskKey in keys) {
            NSURLSessionTask *currentTask =[self.highPriorityQueue objectForKey:currentTaskKey];
            if (currentTask.state == NSURLSessionTaskStateRunning || currentTask.state == NSURLSessionTaskStateSuspended) {
                result = false;
                return result;
            }
        }
    }
    
    return result;
}

- (BOOL)isQueueCanBeStarted:(NSMutableDictionary *)queue {
    if ( [queue isEqual:self.highPriorityQueue] || ([queue isEqual:self.normalPriorityQueue] && [self isHighPriorityQueueEmpty])) {
        return true;
    } else {
        return false;
    }
}

- (NSURLSessionTask *)addTask:(NSURLSessionTask *)task toQueue: (NSMutableDictionary *)queue {
    queue[task.currentRequest.URL] = task;
    return task;
}

// Search for a task by URL in a given queue
- (NSURLSessionTask *)findTaskByURL:(NSURL *)url inQueue:(NSMutableDictionary *)queue {
    
    return [queue objectForKey:url];
}

// Search for a task in a given queue
- (NSURLSessionTask *)findTask:(NSURLSessionTask *)task inQueue:(NSMutableDictionary *)queue {
    NSURLSessionTask *foundTaskByURL = [self findTaskByURL:task.currentRequest.URL inQueue:queue];
    if (foundTaskByURL) {
        return foundTaskByURL;
    } else {
        return nil;
    }
}

// Search for a task in all queues
- (NSURLSessionTask *)findTaskInAllQueues:(NSURLSessionTask *)task {
    return [self findTask:task inQueue:self.normalPriorityQueue] ? [self findTask:task inQueue:self.normalPriorityQueue] : [self findTask:task inQueue:self.highPriorityQueue];
}



#pragma mark - Queue operations

- (void)suspendQueue:(NSMutableDictionary *)queue
{
    NSArray *keys = [queue allKeys];
    for (NSURL *currentTaskKey in keys) {
        [self suspendTask:[queue objectForKey:currentTaskKey]];
    }
}

- (void)resumeQueue:(NSMutableDictionary *)queue {
    if ([self isQueueCanBeStarted:queue]) {
        NSArray *keys = [queue allKeys];
        for (NSURL *currentTaskKey in keys) {
           [self startTask:[queue objectForKey:currentTaskKey]];
        }
    }
    
}

- (void)cancelQueue:(NSMutableDictionary *)queue {
    NSArray *keys = [queue allKeys];
    for (NSURL *currentTaskKey in keys) {
        [self cancelTask:[queue objectForKey:currentTaskKey]];
    }
    
}



- (void)resetPrioritiesInQueue:(NSMutableDictionary *)queue {
    NSArray *keys = [queue allKeys];
    for (NSURL *currentTaskKey in keys) {
        [[queue objectForKey:currentTaskKey] setPriority:NSURLSessionTaskPriorityDefault];
    }
    
}

- (void)moveTask:(NSURLSessionTask *)task fromQueue:(NSMutableDictionary *)sourceQueue toQueue:(NSMutableDictionary *)destinationQueue withPRiority:(float)priority {
    
    [self suspendTask:task];
    if (!destinationQueue[task.currentRequest.URL]) {
        destinationQueue[task.currentRequest.URL] = task;
    }
    if (sourceQueue[task.currentRequest.URL]) {
        [sourceQueue removeObjectForKey:task.currentRequest.URL];
    }
    [task setPriority:priority];
    if ([self isQueueCanBeStarted:destinationQueue]) {
        [self startTask:task];
    }
    
}


- (void)moveAllTasksFromQueue:(NSMutableDictionary *)sourceQueue toQueue:(NSMutableDictionary *)destinationQueue withPriority:(float)priority {
    
    NSArray *sourceTasks = [sourceQueue allValues];
    NSURLSessionTask *currTask = [sourceTasks firstObject];
    while (currTask) {
        [self moveTask:currTask fromQueue:sourceQueue toQueue:destinationQueue withPRiority:priority];
        currTask = [sourceTasks firstObject];
    }
}

- (void)clearQueue:(NSMutableDictionary *)queue {
    NSArray *keys = [queue allKeys];
    for (NSURL *currentTaskKey in keys) {
        [self cancelTask:[queue objectForKey:currentTaskKey]];
    }
    
}


#pragma mark - Task state manipulation

- (void)startTask:(NSURLSessionTask *)task
{
    if (self.isDebug) {
        NSLog(@"Task started: %@",task.currentRequest.URL);
    }
    [task resume];
    
}

- (void)suspendTask:(NSURLSessionTask *)task
{
    if (self.isDebug) {
        NSLog(@"Task suspended: %@",task.currentRequest.URL);
    }
    [task suspend];
}

- (void)cancelTask:(NSURLSessionTask *)task
{
    if (self.isDebug) {
        NSLog(@"Task cancelled: %@",task.currentRequest.URL);
    }
    [task cancel];
}


- (void)clearAllQueue {

    [self clearQueue:self.normalPriorityQueue];
    self.normalPriorityQueue = nil;
    [self resetPrioritiesInQueue:self.highPriorityQueue];
    [self clearQueue:self.highPriorityQueue];
    self.highPriorityQueue = nil;
    
}


@end
