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
    var title: String = ""
    var description: String = ""
    var posterURL: URL?
}

class MoviesController {
    var currentPage = 1
    var totalPages = 1
    var category: String
    var movieList: [[String:Any]] = [[String:Any]]()
    
    init(_ category: MovieListCategory) {
        switch category {
        case .NowPlaying:
            self.category = "now_playing"
        case .TopRated:
            self.category = "top_rated"
        }
    }
    
    private func buildURL(page: Int) -> URL {
        let urlString = String(format:"%@/%@?%@&page=%d",
                               movieDBURL, category, APIKey, page)
        return URL(string: urlString)!
    }

    private func loadData(page: Int, append: Bool, onError: @escaping (Error) -> Void, handler: @escaping () -> Void) {
        let url = buildURL(page: page)
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
                if append {
                    strongSelf.movieList.append(contentsOf: data)
                } else {
                    strongSelf.movieList = data
                }
//                print("loaded \(strongSelf.movieList.count) movies (on page \(strongSelf.currentPage))")
                handler()
            }
        }
        task.resume()
    }
    
    func loadMovies(onError: @escaping (Error) -> Void, handler: @escaping () -> Void) {
        loadData(page: 1, append: false, onError: onError, handler: handler)
    }
    
    func refresh(onError: @escaping (Error) -> Void, handler: @escaping () -> Void) {
        loadData(page: 1, append: false, onError: onError, handler: handler)
    }
    
    func nextPage(onError: @escaping (Error) -> Void, handler: @escaping () -> Void) {
        if (currentPage < totalPages) {
            loadData (page: currentPage + 1, append: true, onError: onError, handler: handler)
        }
    }
    
    func count() -> Int {
        return movieList.count
    }
    
    func getMovie(i: Int) -> Movie {
        let ret = Movie()
        let movie = movieList[i]
        ret.title = movie["title"] as? String ?? "No Title Available"
        ret.description = movie["overview"] as? String ?? "No Description Available"
        if let path = movie["poster_path"] as? String {
            ret.posterURL = URL(string: posterBaseURL + path)
        }
        return ret
    }
}
