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

        movie.getExtraDetails(onError: {(e) in
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
        if let url = movie.posterURL {
            moviePoster.setImageWith(url)
        }
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
        scrollView.setContentOffset(bottomOffset, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear details for \(movie.title)")
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
