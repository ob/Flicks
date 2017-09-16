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
let posterBaseURL: String = "https://image.tmdb.org/t/p/w500"
let posterLowResBaseURL: String = "https://image.tmdb.org/t/p/w45"
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
    
    private func buildSearchURL(page: Int, query: String) -> URL {
        let urlString = String(format:"%@?%@&query=%@&&page=%d",
                               searchBaseURL, APIKey, query, page)
        print("urlString = \(urlString)")
        return URL(string: urlString)!
    }
    
    func loadMovies(page: Int, onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        if page > totalPages {
            handler([])
            return
        }
        let url = buildLoadURL(page: page)
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
//                print(dataDictionary)
                if let total_pages = dataDictionary["total_pages"] as? Int {
                    strongSelf.totalPages = total_pages
                }
                let data = dataDictionary["results"] as! [[String:Any]]
                var newMovies: [Movie] = []
                for movie in data {
                    let m = Movie()
                    m.id = movie["id"] as? Int
                    m.title = movie["title"] as? String ?? "No title available"
                    m.description = movie["overview"] as? String ?? "No description available"
                    if let path = movie["poster_path"] as? String {
                        m.posterURL = URL(string: posterBaseURL + path)
                    }
                    newMovies.append(m)
                }
//                print("loaded \(strongSelf.movieList.count) movies (on page \(strongSelf.currentPage))")
                handler(newMovies)
            }
        }
        task.resume()
    }
    
    func searchMovies(page: Int, query: String, onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        let url = buildSearchURL(page: page, query: query)
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
                //                print(dataDictionary)
                if let total_pages = dataDictionary["total_pages"] as? Int {
                    strongSelf.totalPages = total_pages
                }
                guard let data = dataDictionary["results"] as? [[String:Any]] else {
                    print("Failed to find results in JSON: \(dataDictionary)")
                    handler([])
                    return
                }
                var newMovies: [Movie] = []
                for movie in data {
                    let m = Movie()
                    m.id = movie["id"] as? Int
                    m.title = movie["title"] as? String ?? "No title available"
                    m.description = movie["overview"] as? String ?? "No description available"
                    if let path = movie["poster_path"] as? String {
                        m.posterURL = URL(string: posterBaseURL + path)
                    }
                    newMovies.append(m)
                }
                //                print("loaded \(strongSelf.movieList.count) movies (on page \(strongSelf.currentPage))")
                handler(newMovies)
            }
        }
        task.resume()

    }
    
}
