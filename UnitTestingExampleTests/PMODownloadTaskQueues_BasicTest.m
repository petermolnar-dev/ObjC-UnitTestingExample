//
//  PMODownloadTaskQueues_BasicTest.m
//  UnitTestingExample
//
//  Created by Peter Molnar on 17/07/2016.
//  Copyright © 2016 Peter Molnar. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PMODownloadTaskQueues.h"

@interface PMODownloadTaskQueues_BasicTest : XCTestCase
@property (strong, nonatomic) PMODownloadTaskQueues *queues;
@end

@implementation PMODownloadTaskQueues_BasicTest

- (void)setUp {
    [super setUp];
    self.queues = [[PMODownloadTaskQueues alloc] init];
}


- (void)testAccessorisDebug {
    self.queues.isDebug = true;
    
    XCTAssertTrue(self.queues.isDebug);
}

- (void)tearDown {
    self.queues = nil;
    [super tearDown];
}

@end
