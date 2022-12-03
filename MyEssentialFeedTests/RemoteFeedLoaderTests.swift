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
    
    func complete(withStatusCode: Int, data: Data, at index: Int = 0) {
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
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        action()
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ].reduce(into: [String:Any]()) { (acc,e) in
            if let value = e.value { acc[e.key] = value }
        }
        
        return (item, json)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
            let json = ["items": items]
            return try! JSONSerialization.data(withJSONObject: json)
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
        
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPRespose() {
        let (sut, client) = makeSUT()
        
        let sampleData = [199, 201, 300, 400, 500]
        
        sampleData.enumerated().forEach { index, code in
            
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData), when: {
            let invalidJSON = Data("InvalidJSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
        
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([])) {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let (item1,item1JSON) = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        let (item2,item2JSON) = makeItem(id: UUID(), description: "a description" , location: "a location", imageURL: URL(string: "http://another-url.com")!)
        
        let itemsJSON = [
            "items": [item1JSON, item2JSON]
        ]
        expect(sut, toCompleteWith: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
        
        
    }
    
    
}
