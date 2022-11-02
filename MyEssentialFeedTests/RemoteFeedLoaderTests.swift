//
//  RemoteFeedLoaderTests.swift
//  MyEssentialFeedTests
//
//  Created by Naveen Keerthy on 11/2/22.
//

import XCTest
import MyEssentialFeed

private class HTTPClientSpy: HTTPClient {
    var requestedURLs = [URL]()
    func get(from url: URL) {
        requestedURLs.append(url)
    }
    
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        //GIVEN
        let url = URL(string: "https://a-given-url.com")
        let client = HTTPClientSpy()
        let _ = RemoteFeedLoader(url: url!, client: client)
        
        //THEN
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        //GIVEN
        let url = URL(string: "https://a-given-url.com")
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url!, client: client)
        
        //WHEN
        sut.load()
        
        //THEN
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    
    func test_load_requestsDataFromURLTwice() {
        //GIVEN
        let url = URL(string: "https://a-given-url.com")
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url!, client: client)
        
        //WHEN
        sut.load()
        sut.load()
        
        //THEN
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
}
