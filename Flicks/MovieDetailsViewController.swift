//
//  MovieDetailsViewController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/13/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {

    var movies : MoviesController!
    var movieIndex: Int = 0
    
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieDetails: UILabel!
    @IBOutlet weak var moviePoster: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let movie = movies.getMovie(i: movieIndex)
        let title = movie["title"] as? String
        let description = movie["overview"] as? String
        movieTitle.text = title
        movieDetails.text = description
        if let path = movie["poster_path"] as? String {
            let baseURL = "https://image.tmdb.org/t/p/w500"
            let posterURL = URL(string: baseURL + path)!
            moviePoster.setImageWith(posterURL)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
