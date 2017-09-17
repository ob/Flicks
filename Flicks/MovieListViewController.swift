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

class MovieListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var movieListTableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var movieController : MoviesController!
    var movies: [Movie] = []
    var searchResults: [Movie] = []
    var isDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?
    var refreshControl: UIRefreshControl?
    var searchString: String? = nil
    var timer = Timer()
    var currentPage = 1
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set our title
        // self.navigationItem.title = parent?.restorationIdentifier

        // This is needed to avoid a black screen when coming back here
        definesPresentationContext = true

        // do search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        movieListTableView.tableHeaderView = searchController.searchBar

        
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
        if searchString != nil {
            searchController.searchBar.isHidden = false
        }
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
        guard let vc = segue.destination as? MovieDetailsViewController else {
            return
        }
        let indexPath = movieListTableView.indexPath(for: sender as! MovieTableViewCell)!
        if searchString != nil {
            vc.movie = searchResults[indexPath.row]
            searchController.searchBar.isHidden = true
            searchController.searchBar.endEditing(true)
        } else {
            vc.movie = movies[indexPath.row]
        }
    }

    func loadMovies() {
        // Load the list of movies.
        ZVProgressHUD.show()
        currentPage = 1
        movieController.loadMovies(page: currentPage, query: nil, onError: { [weak self] (e) in
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
        if searchString != nil {
            print("searchResults \(searchResults.count)")
            return searchResults.count
        }
        print("movies.count \(movies.count)")
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var movie: Movie

        if searchString != nil {
            movie = searchResults[indexPath.row]
        } else {
            movie = movies[indexPath.row]
        }
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
        if !isDataLoading && ((searchString == nil && movies.count > 0) || (searchString != nil && searchResults.count > 0)) {
            let scrollViewContentHeight = movieListTableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - movieListTableView.bounds.size.height
            if scrollView.contentOffset.y > scrollOffsetThreshold && movieListTableView.isDragging {
                isDataLoading = true
                if searchString != nil {
                    searchController.searchBar.endEditing(true)
                }
                let frame = CGRect(x: 0, y: movieListTableView.contentSize.height, width: movieListTableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
                movieController.loadMovies(page: currentPage + 1, query: searchString, onError: {[weak self] (e) in
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
                    strongSelf.currentPage += 1
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
        if searchString != nil {
            return
        }
        errorLabel!.isHidden = true
        currentPage = 1
        movieController.loadMovies(page: currentPage, query: nil, onError: {[weak self] (e) in
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
    
    // MARK: - Search
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MovieListViewController.doSearch), userInfo: searchText, repeats: false)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchString = nil
        movieListTableView.reloadData()
    }
    
    // MARK: - Delete maybe from here onwards
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    }
    
    @objc func doSearch() {
        guard let query = timer.userInfo as? String,
            query != "" else {
                timer.invalidate()
                return
        }
        timer.invalidate()
        searchString = query
        searchResults = []
        movieListTableView.reloadData()
        ZVProgressHUD.show()
        movieController.loadMovies(page: 1, query: query , onError: { [weak self] (e) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.errorLabel!.isHidden = false
            ZVProgressHUD.dismiss()
            }, handler: {[weak self] (movies) in
                guard let strongSelf = self else {
                    return
                }
                ZVProgressHUD.dismiss()
                strongSelf.errorLabel!.isHidden = true
                strongSelf.refreshControl?.endRefreshing()
                strongSelf.searchResults = movies
                print("Got \(movies.count) search results for: \(query)")
                strongSelf.movieListTableView.reloadData()
        })
    }
}


