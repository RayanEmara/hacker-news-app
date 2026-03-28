//
//  HNService.swift
//  hnr-reader
//

import Foundation

// MARK: - Algolia Response Types

struct AlgoliaResponse: Decodable {
    let hits: [AlgoliaHit]
    let nbPages: Int
    let page: Int
}

struct AlgoliaHit: Decodable {
    let objectID: String
    let title: String?
    let url: String?
    let points: Int?
    let author: String?
    let createdAtI: Int?
    let numComments: Int?
    let storyText: String?

    enum CodingKeys: String, CodingKey {
        case objectID, title, url, points, author
        case createdAtI = "created_at_i"
        case numComments = "num_comments"
        case storyText = "story_text"
    }
}

struct AlgoliaItemResponse: Decodable {
    let id: Int
    let children: [AlgoliaItemChild]?
}

struct AlgoliaItemChild: Decodable {
    let id: Int
    let author: String?
    let text: String?
    let createdAtI: Int?
    let children: [AlgoliaItemChild]?

    enum CodingKeys: String, CodingKey {
        case id, author, text, children
        case createdAtI = "created_at_i"
    }
}

// MARK: - Errors

enum HNError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let error): return error.localizedDescription
        case .decodingError: return "Failed to parse response"
        }
    }
}

// MARK: - Service

struct HNService {
    private static let baseURL = "https://hn.algolia.com/api/v1"

    static func fetchStories(feed: StoryFeed, page: Int = 0) async throws -> (stories: [HNStory], hasMore: Bool) {
        let endpoint: String
        switch feed {
        case .top:  endpoint = "search?tags=front_page&page=\(page)"
        case .new:  endpoint = "search_by_date?tags=story&page=\(page)"
        case .ask:  endpoint = "search?tags=ask_hn&page=\(page)"
        case .show: endpoint = "search?tags=show_hn&page=\(page)"
        }

        let response = try await request(endpoint: endpoint)
        let stories = response.hits.compactMap { HNStory.from($0, feed: feed) }
        return (stories, response.page + 1 < response.nbPages)
    }

    static func searchStories(query: String, page: Int = 0) async throws -> (stories: [HNStory], hasMore: Bool) {
        guard !query.isEmpty else { return ([], false) }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let endpoint = "search?query=\(encoded)&tags=story&page=\(page)"
        let response = try await request(endpoint: endpoint)
        let stories = response.hits.compactMap { HNStory.from($0, feed: .top) }
        return (stories, response.page + 1 < response.nbPages)
    }

    static func fetchComments(storyID: Int) async throws -> [HNComment] {
        guard let url = URL(string: "\(baseURL)/items/\(storyID)") else {
            throw HNError.invalidURL
        }
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw HNError.networkError(error)
        }
        do {
            let response = try JSONDecoder().decode(AlgoliaItemResponse.self, from: data)
            return flatten(response.children ?? [], depth: 0)
        } catch {
            throw HNError.decodingError(error)
        }
    }

    private static func flatten(_ children: [AlgoliaItemChild], depth: Int) -> [HNComment] {
        children.flatMap { child -> [HNComment] in
            var result: [HNComment] = []
            if let comment = HNComment.from(child, depth: depth) {
                result.append(comment)
            }
            result += flatten(child.children ?? [], depth: depth + 1)
            return result
        }
    }

    private static func request(endpoint: String) async throws -> AlgoliaResponse {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw HNError.invalidURL
        }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw HNError.networkError(error)
        }

        do {
            return try JSONDecoder().decode(AlgoliaResponse.self, from: data)
        } catch {
            throw HNError.decodingError(error)
        }
    }
}
