//
//  FeedLoader.swift
//  MyEssentialFeed
//
//  Created by Naveen Keerthy on 10/27/22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    
    associatedtype Error: Swift.Error
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
