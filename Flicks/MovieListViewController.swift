//
//  ViewController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/12/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit
import AFNetworking
import ZVProgressHUD

class MovieListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    @IBOutlet weak var movieListTableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var movies : MoviesController!
    var isDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?
    var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set our title
        // self.navigationItem.title = parent?.restorationIdentifier

        
        // Do any additional setup after loading the view, typically from a nib.
        movieListTableView.delegate = self
        movieListTableView.dataSource = self
        movieListTableView.rowHeight = 200
        
        // Initialize the loading indicator
        let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        movieListTableView.addSubview(loadingMoreView!)
        
        // Initialize the Error indicator
        errorLabel!.isHidden = true
        
        var insets = movieListTableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        movieListTableView.contentInset = insets
        
        // Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        movieListTableView.insertSubview(refreshControl!, at: 0)
        loadMovies()
   }
    
    override func viewWillAppear(_ animated: Bool) {
        if !errorLabel.isHidden && movies.count() == 0 {
            loadMovies()
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

    func loadMovies() {
        // Load the list of movies.
        ZVProgressHUD.show()
        movies.loadMovies(onError: { [weak self] (e) in
            print("Failed to load")
            guard let strongSelf = self else {
                return
            }
            ZVProgressHUD.dismiss()
            strongSelf.errorLabel!.isHidden = false
        }) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            ZVProgressHUD.dismiss()
            strongSelf.errorLabel!.isHidden = true
            strongSelf.movieListTableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies.getMovie(i: indexPath.row)
        let cell = movieListTableView.dequeueReusableCell(withIdentifier: "MovieTableViewCell")  as! MovieTableViewCell
        cell.selectionStyle = .none

        cell.movieTitle.text = movie.title
        cell.movieDescription.text = movie.description
        if let url = movie.posterURL {
//            cell.moviePoster.setImageWith(url)
            // fade in images
            let imageRequest = URLRequest(url: url)
            
            cell.moviePoster.setImageWith(
                imageRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
//                        print("Image was NOT cached, fade in image")
                        cell.moviePoster.alpha = 0.0
                        cell.moviePoster.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.moviePoster.alpha = 1.0
                        })
                    } else {
//                        print("Image was cached so just update the image")
                        cell.moviePoster.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
                    print("failed")
            })
        }
        return cell
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isDataLoading && movies.count() > 0 {
            let scrollViewContentHeight = movieListTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - movieListTableView.bounds.size.height
            if scrollView.contentOffset.y > scrollOffsetThreshold && movieListTableView.isDragging {
                isDataLoading = true
                let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                movies.nextPage(onError: {[weak self] (e) in
                    print("Failed to load next page")
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.errorLabel!.isHidden = false
                    strongSelf.loadingMoreView!.stopAnimating()
                    strongSelf.isDataLoading = false
                }, handler: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.movieListTableView.reloadData()
                    strongSelf.loadingMoreView!.stopAnimating()
                    strongSelf.isDataLoading = false
                    strongSelf.errorLabel!.isHidden = true
                })
            }
        }
    }
    
    // MARK: - UIRefreshControl
    

    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        errorLabel!.isHidden = true
        movies.refresh(onError: {[weak self] (e) in
            print("Failed to refresh")
            guard let strongSelf = self else {
                return
            }
            strongSelf.errorLabel!.isHidden = false
            strongSelf.refreshControl?.endRefreshing()
        }, handler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.errorLabel!.isHidden = true
            strongSelf.movieListTableView.reloadData()
            strongSelf.refreshControl?.endRefreshing()
        })
    }
}

