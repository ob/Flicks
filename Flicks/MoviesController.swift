//
//  MoviesController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/13/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import Foundation
import UIKit

class MoviesController {
    var movieList: [[String:Any]] = [[String:Any]]()

    func loadMovies(handler: @escaping () -> Void) {
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed")!
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
                print(dataDictionary)
                strongSelf.movieList = dataDictionary["results"] as! [[String:Any]]
                handler()
            }
        }
        task.resume()
    }
    
    func count() -> Int {
        return movieList.count
    }
    
    func getMovie(i: Int) -> [String: Any] {
        return movieList[i]
    }
}
