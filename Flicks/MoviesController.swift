//
//  MoviesController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/13/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import Foundation
import UIKit

let movieDBURL: String = "https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"
let posterBaseURL: String = "https://image.tmdb.org/t/p/w500"

class Movie {
    var title: String = ""
    var description: String = ""
    var posterURL: URL?
}

class MoviesController {
    var currentPage = 1
    var totalPages = 1
    var movieList: [[String:Any]] = [[String:Any]]()

    func loadMovies(_ page: Int = 1, handler: @escaping () -> Void) {
        let urlString = String(format: "%@&page=%d", movieDBURL, page)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                print("Error fetching URL: \(error)")
            } else if let data = data,
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                // print(dataDictionary)
                if let total_pages = dataDictionary["total_pages"] as? String,
                    let totalPages = Int(total_pages) {
                        strongSelf.totalPages = totalPages
                }
                if let page = dataDictionary["page"] as? String,
                    let currentPage = Int(page) {
                        strongSelf.currentPage = currentPage
                }
                strongSelf.movieList = dataDictionary["results"] as! [[String:Any]]
                handler()
            }
        }
        task.resume()
    }
    
    func nextPage(handler: @escaping () -> Void) {
        if (currentPage < totalPages) {
            loadMovies (currentPage + 1, handler: handler)
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
