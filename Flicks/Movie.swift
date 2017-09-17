//
//  Movie.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/15/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import Foundation
class Movie {
    var id: Int?
    var title: String = ""
    var description: String = ""
    var voteAverage: Float?
    var popularity: Float?
    var originalLanguage: String?
    var releaseDate: Date?
    var posterURL: URL?
    var posterLowResURL: URL?
    var budget: Int?
    var runtime: Int?
    var tagline: String?
    
    private func buildMovieURL() -> URL {
        let urlString = String(format:"%@/%d?%@", movieDBURL, id!, APIKey)
        return URL(string: urlString)!
    }

    convenience init(map: [String:Any]) {
        self.init()
        id = map["id"] as? Int
        title = map["title"] as? String ?? "No title available"
        description = map["overview"] as? String ?? "No description available"
        if let path = map["poster_path"] as? String {
            posterURL = URL(string: posterBaseURL + path)
            posterLowResURL = URL(string: posterLowResBaseURL + path)
        }
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
