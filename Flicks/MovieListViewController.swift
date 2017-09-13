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
    var movies : MoviesController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        movieListTableView.delegate = self
        movieListTableView.dataSource = self
        movieListTableView.rowHeight = 200
        
        // Load the list of movies.
        movies.loadMovies { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.movieListTableView.reloadData()
        }
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MovieDetailsViewController {
            let indexPath = movieListTableView.indexPath(for: sender as! MovieTableViewCell)!
            vc.movies = self.movies
            vc.movieIndex = indexPath.row
            
        } else {
            print("Failed to cast to MovieDetailsViewController")
        }
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies.getMovie(i: indexPath.row)
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

