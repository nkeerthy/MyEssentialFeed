//
//  RemoteFeedLoader.swift
//  MyEssentialFeed
//
//  Created by Naveen Keerthy on 11/2/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL) -> Void
}

public final class RemoteFeedLoader {
    
    private let url: URL
    private let client: HTTPClient
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.get(from: url)
    }
}
