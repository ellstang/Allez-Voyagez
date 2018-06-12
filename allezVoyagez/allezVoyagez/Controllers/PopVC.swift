//
//  PopVC.swift
//  allezVoyagez
//
//  Created by 唐嘉伶 on 2018/6/11.
//  Copyright © 2018 唐嘉伶. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {
  
  @IBOutlet weak var popImageView: UIImageView!
  
  var passedImage: UIImage!
  
  func initImage(forImage image: UIImage) {
    passedImage = image
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    popImageView.image = passedImage
    addDoubleTap()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  func addDoubleTap() {
    let tapRecog = UITapGestureRecognizer(target: self, action: #selector(dismissPopVC))
    tapRecog.numberOfTapsRequired = 2
    tapRecog.delegate = self
    self.view.addGestureRecognizer(tapRecog)
    
  }

  @objc func dismissPopVC() {
    dismiss(animated: true, completion: nil)
  }
}
