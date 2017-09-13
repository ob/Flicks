//
//  ViewController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/12/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit
import AFNetworking

class MovieListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    @IBOutlet weak var movieListTableView: UITableView!
    var movies : MoviesController!
    var isDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        movieListTableView.delegate = self
        movieListTableView.dataSource = self
        movieListTableView.rowHeight = 200
        
        // Initialize the loading indicator
        let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        movieListTableView.addSubview(loadingMoreView!)
        
        var insets = movieListTableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        movieListTableView.contentInset = insets
        
        // Load the list of movies.
        movies.loadMovies(onError: { (e) in
            print("Failed to load: \(e)")
        }) { [weak self] in
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
            vc.movie = self.movies.getMovie(i: indexPath.row)
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
        cell.movieTitle.text = movie.title
        cell.movieDescription.text = movie.description
        if let url = movie.posterURL {
            cell.moviePoster.setImageWith(url)
        }
        return cell
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isDataLoading {
            let scrollViewContentHeight = movieListTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - movieListTableView.bounds.size.height
            if scrollView.contentOffset.y > scrollOffsetThreshold && movieListTableView.isDragging {
                isDataLoading = true
                let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                movies.nextPage(onError: {(e) in
                    print("Failed to load next page: \(e)")
                }, handler: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.movieListTableView.reloadData()
                    strongSelf.loadingMoreView!.stopAnimating()
                    strongSelf.isDataLoading = false
                })
            }
        }
    }
}

