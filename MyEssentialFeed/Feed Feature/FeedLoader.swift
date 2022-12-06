//
//  FeedLoader.swift
//  MyEssentialFeed
//
//  Created by Naveen Keerthy on 10/27/22.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    
    associatedtype Error: Swift.Error
    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
