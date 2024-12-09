//
//  ProgressIndicatorPresentable.swift
//  OpenSky
//
//  Created by Emre Alpago on 8.12.2024.
//

import UIKit.UIView

//II am using AnyObject here because I know that I will only Comform this protocol to UIViewController which is like a FlightViewController
protocol ProgressIndicatorPresentable: AnyObject {
    func showLoadingIndicator()
    func hideLoadingIndicator()
}

extension ProgressIndicatorPresentable where Self: UIViewController {
    func showLoadingIndicator() {
        DispatchQueue.main.async {
            let loadingViewTag = 999
            if self.view.viewWithTag(loadingViewTag) == nil {
                let loadingView = UIView(frame: self.view.bounds)
                loadingView.tag = loadingViewTag
                loadingView.backgroundColor = UIColor(white: 0, alpha: 0.7)
                let activityIndicator = UIActivityIndicatorView(style: .large)
                activityIndicator.center = loadingView.center
                activityIndicator.startAnimating()
                loadingView.addSubview(activityIndicator)
                self.view.addSubview(loadingView)
            }
        }
    }

    func hideLoadingIndicator() {
        DispatchQueue.main.async {
            let loadingViewTag = 999
            if let loadingView = self.view.viewWithTag(loadingViewTag) {
                loadingView.removeFromSuperview()
            }
        }
    }
}
