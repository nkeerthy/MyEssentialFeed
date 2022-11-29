//
//  RemoteFeedLoaderTests.swift
//  MyEssentialFeedTests
//
//  Created by Naveen Keerthy on 11/2/22.
//

import XCTest
import MyEssentialFeed

private class HTTPClientSpy: HTTPClient {
        
    private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    
    var requestedURLs: [URL] {
        return messages.map { $0.url }
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        messages.append((url, completion))
    }
    
    //This complete is only for the spy to add the errors/success results as we are not doing the actual API calls
    //So the messages will have the values only when we explicitly call the complete method from the test to simulate that
    //The api call completed and we got the error/succeess based on the tests
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode: Int, data: Data = Data(), at index: Int = 0) {
        let response = HTTPURLResponse(url: requestedURLs[index],
                                       statusCode: withStatusCode,
                                       httpVersion: nil,
                                       headerFields: nil)!
        
        messages[index].completion(.success(data, response))
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy){
        let url = url
        let client = HTTPClientSpy()
        
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        action()
        XCTAssertEqual(capturedErrors, [.invalidData])
    }
    
    func test_init_doesNotRequestDataFromURL() {
        //GIVEN
//        let url = URL(string: "https://a-given-url.com")
//        let _ = RemoteFeedLoader(url: url!, client: client)ffaaaaffsf
        let (_, client) = makeSUT()
        
        //THEN
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        //GIVEN
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //WHEN
        sut.load{ _ in }
        
        //THEN
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    
    func test_load_requestsDataFromURLTwice() {
        //GIVEN
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //WHEN
        sut.load{ _ in }
        sut.load{ _ in }
        
        //THEN
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
//        This is stubbing as we are putting some behaviour into the client but thats incorrect way as we are spying the client too
//        client.error = NSError(domain: "Test", code: 0)
        
//        var capturedError: RemoteFeedLoader.Error?
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }
        let clientError = NSError(domain: "Test", code: 0)
        
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    func test_load_deliversErrorOnNon200HTTPRespose() {
        let (sut, client) = makeSUT()
        
        let sampleData = [199, 201, 300, 400, 500]
        
        sampleData.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load { capturedErrors.append($0) }
            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseJSON() {
        let (sut, client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        expect(sut, toCompleteWithError: .invalidData, when: {
            let invalidJSON = Data(bytes: "InvalidJSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
        
    }
    

}
