//
//  SkyS3ManagerTests.swift
//  S3SyncTests
//
//  Created by Eugene Dorfman on 11/18/16.
//
//

import XCTest
import OHHTTPStubs
import SkyS3Sync

class SkyS3ManagerTests: XCTestCase {
    var documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    var originalResourcesDir: URL?
    var manager: SkyS3SyncManager?
    
    override func setUp() {
        super.setUp()

        originalResourcesDir = documentsDir?.appendingPathComponent("test_dir")
        createDir(originalResourcesDir)
        manager = SkyS3SyncManager(s3AccessKey:"test_access_key", secretKey:"test_secret_key", bucketName:"test_bucket_name", originalResourcesDirectory:originalResourcesDir!)
    }
    
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
        delete(originalResourcesDir)
    }

    func test3RetriesListBucket() {
        let notificationExpectation = expectation(description: "notification that manager did fail to list bucket")
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SkyS3SyncDidFailToListBucket), object: manager, queue: nil) { notification in
            notificationExpectation.fulfill()
        }

        let managerDidFailToSync3TimesExpectation = expectation(description: "testing manager sync failed 3 times")

        var count = 3
        OHHTTPStubs.stubRequests(passingTest: { request in
            if request.url?.absoluteString == "https://test_bucket_name.s3.amazonaws.com/" && count >= 0 {
                count -= 1
                return true
            }
            return false
        }, withStubResponse: { request in
            if count == -1 {
                managerDidFailToSync3TimesExpectation.fulfill()
            }
            return self.errorResponse()
        })

        manager?.sync()

        waitForExpectations(timeout: 1.0) {
            error in        
        }
    }
    
    func test3RetriesDownloadingArbitraryFiles() {
        let notificationTest1Expectation = expectation(description: "notification that manager did fail to download test1 file")
        let notificationTest2Expectation = expectation(description: "notification that manager did fail to download test2 file")

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SkyS3SyncDidFailToDownloadResource), object: manager, queue: nil) { notification in
            let userInfo = notification.userInfo
            if userInfo![SkyS3ResourceFileName]! as! String == "test1.txt" {
                notificationTest1Expectation.fulfill()
            } else if userInfo![SkyS3ResourceFileName]! as! String == "test2.txt" {
                notificationTest2Expectation.fulfill()
            }
        }

        let countExpectation = expectation(description: "the number of retries for both files is 6")

        var count = 0
        OHHTTPStubs.stubRequests(passingTest: { request in
            return true
        }, withStubResponse: { request in
            if request.url?.absoluteString == "https://test_bucket_name.s3.amazonaws.com/" {

                let bundle = Bundle(for: self.classForCoder)

                let xmlURL = bundle.url(forResource: "list-bucket-2-new-files", withExtension: "xml")

                let xmlData = try! Data(contentsOf: xmlURL!)
                
                return OHHTTPStubsResponse(data: xmlData, statusCode: 200, headers: ["Content-Type":"application/xml"])
            } else {
                count += 1
                if count == 6 {
                    countExpectation.fulfill()
                }
                return self.errorResponse()
            }
        })
        
        manager?.sync() //first will copy original directory
        
        waitForExpectations(timeout: 1.0) { error in
            
        }
    }
    
    
    func errorResponse() -> OHHTTPStubsResponse {
        return OHHTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: -1001, userInfo: [:]))
    }
    
}
