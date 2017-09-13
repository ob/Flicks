//
//  ViewController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/12/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit
import AFNetworking

class MovieListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var movieListTableView: UITableView!
    var movieList: [[String: Any]] = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        movieListTableView.delegate = self
        movieListTableView.dataSource = self
        movieListTableView.rowHeight = 200
        
        // Load the list of movies.
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
                strongSelf.movieListTableView.reloadData()
            }
        }
        task.resume()
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movieList[indexPath.row]
        let cell = movieListTableView.dequeueReusableCell(withIdentifier: "MovieTableViewCell")  as! MovieTableViewCell
        cell.movieTitle.text = movie["title"] as? String
        cell.movieDescription.text = movie["overview"] as? String
        if let path = movie["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w500"
            let posterURL = URL(string: baseURL + path)!
            cell.moviePoster.setImageWith(posterURL)
        }
        return cell
    }
}

