//
//  FeedLoader.swift
//  MyEssentialFeed
//
//  Created by Naveen Keerthy on 10/27/22.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
