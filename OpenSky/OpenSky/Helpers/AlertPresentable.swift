//
//  AlertPresentable.swift
//  OpenSky
//
//  Created by Emre Alpago on 8.12.2024.
//

import UIKit

protocol AlertPresentable: AnyObject {
    func showError(title: String, message: String, buttonTitle: String, completion: @escaping () -> ())
}

extension AlertPresentable where Self: UIViewController {
    func showError(title: String, message: String, buttonTitle: String, completion: @escaping () -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .cancel, handler: { action in
            completion()
        }))
        self.present(alert, animated: true)
    }
}
