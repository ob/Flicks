//
//  MovieDetailsViewController.swift
//  Flicks
//
//  Created by Oscar Bonilla on 9/13/17.
//  Copyright © 2017 Oscar Bonilla. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {

    var movie : Movie!
    
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieDetails: UILabel!
    @IBOutlet weak var moviePoster: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var releaseDate: UILabel!
    @IBOutlet weak var runningTime: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var tagline: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize Navigation Bar
        if let navigationBar = navigationController?.navigationBar {
            print("Cusomizing Nav Controller")
            navigationBar.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.2)
        }
        movie.getExtraDetails(onError: {(e) in
            // Ignore this error since all we miss are extra details
            print("Network Error")
        }, onSuccess: {[weak self] in
            guard let strongSelf = self else {
                return
            }
            if let runtime = strongSelf.movie.runtime {
                let hours = runtime / 60
                let minutes = runtime % 60
                if minutes > 0 && hours > 0 {
                    strongSelf.runningTime.text = String(format: "%d hr %d mins", hours, minutes)
                    strongSelf.runningTime.isHidden = false
                } else if hours > 0 {
                    strongSelf.runningTime.text = String(format: "%d hours", hours)
                    strongSelf.runningTime.isHidden = false
                }
            }
            if let rdate = strongSelf.movie.releaseDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                formatter.locale = Locale(identifier: "en_US")
                strongSelf.releaseDate.text = formatter.string(from: rdate)
                strongSelf.releaseDate.isHidden = false
            }
            if let r = strongSelf.movie.voteAverage {
                strongSelf.rating.text = String(format: "%.1f", r)
                strongSelf.rating.isHidden = false
            }
            if let t = strongSelf.movie.tagline {
                strongSelf.tagline.text = t
                strongSelf.tagline.sizeToFit()
                strongSelf.tagline.isHidden = false
            }
        })
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width,
                                        height: contentView.frame.origin.y + contentView.frame.size.height)
        movieTitle.text = movie.title
        movieDetails.text = movie.description
        movieDetails.sizeToFit()
        if let url = movie.posterLowResURL {
            // fade in images
            let imageRequest = URLRequest(url: url)

//            print("Loading low res image")
            moviePoster.setImageWith(
                imageRequest,
                placeholderImage: nil,
                success: { [weak self] (imageRequest, imageResponse, image) -> Void in
                    guard let strongSelf = self else {
                        // Set placeholder poster here?
                        return
                    }
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        // not cached, fade in
                        strongSelf.moviePoster.alpha = 0.0
                        strongSelf.moviePoster.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            strongSelf.moviePoster.alpha = 1.0
                        })
                    } else {
                        // cached
                        strongSelf.moviePoster.image = image
                    }
                    strongSelf.loadHighResImage()
            },
                failure: { [weak self] (imageRequest, imageResponse, error) -> Void in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.moviePoster.image = #imageLiteral(resourceName: "poster-placeholder")
            })
        } else {
            moviePoster.image = #imageLiteral(resourceName: "poster-placeholder")
        }

        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        print("viewWillAppear details for \(movie.title)")
    }
    
    func loadHighResImage() {
        if let url = movie.posterURL {
            // fade in images
            let imageRequest = URLRequest(url: url)

//            print("Loading high-res image")
            moviePoster.setImageWith(
                imageRequest,
                placeholderImage: nil,
                success: { [weak self] (imageRequest, imageResponse, image) -> Void in
                    guard let strongSelf = self else {
                        // Set placeholder poster here?
                        return
                    }
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        // not cached, fade in
                        strongSelf.moviePoster.alpha = 0.0
                        strongSelf.moviePoster.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            strongSelf.moviePoster.alpha = 1.0
                        })
                    } else {
                        // cached
                        strongSelf.moviePoster.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // if this fails, it's fine to leave the low-res poster as the image
            })
        } else {
            moviePoster.image = #imageLiteral(resourceName: "poster-placeholder")
        }
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
