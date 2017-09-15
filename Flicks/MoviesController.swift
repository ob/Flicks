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

enum MovieListCategory {
    case NowPlaying
    case TopRated
}

class Movie {
    var id: Int?
    var title: String = ""
    var description: String = ""
    var voteAverage: Float?
    var popularity: Float?
    var originalLanguage: String?
    var releaseDate: Date?
    var posterURL: URL?
    var budget: Int?
    var runtime: Int?
    var tagline: String?
    
    private func buildMovieURL() -> URL {
        let urlString = String(format:"%@/%d?%@", movieDBURL, id!, APIKey)
        return URL(string: urlString)!
    }
    
    func getExtraDetails(onError: @escaping (Error) -> Void, onSuccess: @escaping () -> Void) {
        let url = buildMovieURL()
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) {[weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                onError(error)
            } else if let data = data,
                let movieInfo = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                strongSelf.originalLanguage = movieInfo["original_language"] as? String
                strongSelf.popularity = movieInfo["popularity"] as? Float
                strongSelf.voteAverage = movieInfo["vote_average"] as? Float
                strongSelf.budget = movieInfo["budget"] as? Int
                strongSelf.runtime = movieInfo["runtime"] as? Int
                strongSelf.tagline = movieInfo["tagline"] as? String
                if let release_date = movieInfo["release_date"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    strongSelf.releaseDate = formatter.date(from: release_date)
                }
                onSuccess()
            }
        }
        task.resume()
        
    }
}

class MoviesController {
    var currentPage = 1
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
    
    private func buildSearchURL(page: Int) -> URL {
        let urlString = String(format:"%@/%@?%@&page=%d",
                               movieDBURL, category, APIKey, page)
        return URL(string: urlString)!
    }
    
    private func loadData(page: Int, onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        let url = buildSearchURL(page: page)
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
                if let page = dataDictionary["page"] as? Int {
                    strongSelf.currentPage = page
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
    
    func loadMovies(onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        loadData(page: 1, onError: onError, handler: handler)
    }
    
    func refresh(onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        loadData(page: 1, onError: onError, handler: handler)
    }
    
    func nextPage(onError: @escaping (Error) -> Void, handler: @escaping ([Movie]) -> Void) {
        if (currentPage < totalPages) {
            loadData (page: currentPage + 1, onError: onError, handler: handler)
        }
    }
    
}
