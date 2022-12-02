//
//  FeedItem.swift
//  MyEssentialFeed
//
//  Created by Naveen Keerthy on 10/27/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
