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

class MovieListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate {
    @IBOutlet weak var movieListTableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var movieController : MoviesController!
    var movies: [Movie] = []
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
        movieListTableView.rowHeight = 200
        if !errorLabel.isHidden && movies.count == 0 {
            loadMovies()
        }
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? MovieDetailsViewController {
            let indexPath = movieListTableView.indexPath(for: sender as! MovieTableViewCell)!
            vc.movie = self.movies[indexPath.row]
        } else {
            print("Failed to cast to MovieDetailsViewController")
        }
    }

    func loadMovies() {
        // Load the list of movies.
        ZVProgressHUD.show()
        movieController.loadMovies(onError: { [weak self] (e) in
            print("Failed to load")
            guard let strongSelf = self else {
                return
            }
            ZVProgressHUD.dismiss()
            strongSelf.errorLabel!.isHidden = false
        }) { [weak self] (movies) in
            guard let strongSelf = self else {
                return
            }
            ZVProgressHUD.dismiss()
            strongSelf.errorLabel!.isHidden = true
            strongSelf.movies = movies
            strongSelf.movieListTableView.reloadData()
            strongSelf.movieListTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: false)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies[indexPath.row]
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
        if !isDataLoading && movies.count > 0 {
            let scrollViewContentHeight = movieListTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - movieListTableView.bounds.size.height
            if scrollView.contentOffset.y > scrollOffsetThreshold && movieListTableView.isDragging {
                isDataLoading = true
                let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                movieController.nextPage(onError: {[weak self] (e) in
                    print("Failed to load next page")
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.errorLabel!.isHidden = false
                    strongSelf.loadingMoreView!.stopAnimating()
                    strongSelf.isDataLoading = false
                }, handler: { [weak self] (movies) in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.movies.append(contentsOf: movies)
                    strongSelf.loadingMoreView!.stopAnimating()
                    strongSelf.isDataLoading = false
                    strongSelf.errorLabel!.isHidden = true
                    strongSelf.movieListTableView.reloadData()
                })
            }
        }
    }
    
    // MARK: - UIRefreshControl
    

    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        errorLabel!.isHidden = true
        movieController.refresh(onError: {[weak self] (e) in
            print("Failed to refresh")
            guard let strongSelf = self else {
                return
            }
            strongSelf.errorLabel!.isHidden = false
            strongSelf.refreshControl?.endRefreshing()
        }, handler: { [weak self] (movies) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.errorLabel!.isHidden = true
            strongSelf.refreshControl?.endRefreshing()
            strongSelf.movies = movies
            strongSelf.movieListTableView.reloadData()
        })
    }
}

