//
//  MoviesController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/13/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import Foundation
import UIKit

let movieDBURL: String = "https://api.themoviedb.org/3/movie"
let APIKey: String = "api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"
let searchBaseURL: String = "https://api.themoviedb.org/3/search/movie"

enum MovieListCategory {
    case NowPlaying
    case TopRated
}

class MoviesController {
    var totalPages = 1
    var category: String
    
    init(_ category: MovieListCategory) {
        switch category {
        case .NowPlaying:
            self.category = "now_playing"
        case .TopRated:
            self.category = "top_rated"
        }
    }
    
    private func buildLoadURL(page: Int) -> URL {
        let urlString = String(format:"%@/%@?%@&page=%d",
                               movieDBURL, category, APIKey, page)
        return URL(string: urlString)!
    }
    
    private func buildSearchURL(page: Int, query: String) -> URL? {
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        if escapedQuery == nil {
            return nil
        }
        let urlString = String(format:"%@?%@&query=%@&&page=%d",
                               searchBaseURL, APIKey, escapedQuery!, page)
        return URL(string: urlString)
    }

    func loadMovies(page: Int, query: String?, onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        var url: URL
        if let query = query {
            url = buildSearchURL(page: page, query: query) ?? buildLoadURL(page: page) // lame, maybe this should error but how to tell the user?
        } else {
            url = buildLoadURL(page: page)
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                onError(error)
            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                if let total_pages = dataDictionary["total_pages"] as? Int {
                    strongSelf.totalPages = total_pages
                }
                let data = dataDictionary["results"] as! [[String:Any]]
                var newMovies: [Movie] = []
                for movie in data {
                    let m = Movie(map: movie)
                    newMovies.append(m)
                }
                handler(newMovies)
            }
        }
        task.resume()
    }
}
