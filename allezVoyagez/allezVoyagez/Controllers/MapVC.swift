//  ViewController.swift
//  allezVoyagez
//  Created by 唐嘉伶 on 2018/6/9.
//  Copyright © 2018 唐嘉伶. All rights reserved.

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate, UISearchBarDelegate {
  
  // MARK: - properties
  var locationManager = CLLocationManager()
  var locationAuthStatus = CLLocationManager.authorizationStatus()
  var coordinateRadius: Double = 100.0
  var spinner: UIActivityIndicatorView?
  var progressLabel: UILabel?
  var screenSize = UIScreen.main.bounds
  var photoURLArray = [String]()
  var imageArray = [UIImage]()
  
  // MARK: - image displaying collection view
  var collectionView: UICollectionView?
  var flowLayout = UICollectionViewFlowLayout()
  
  // MARK: - outlet and action set
  @IBOutlet weak var bounceUpView: UIView!
  @IBOutlet weak var centerMapBtn: UIButton!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var bounceUpViewHeightConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var bounceUpViewTopConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var searchBtn: UIBarButtonItem!
  
  //rewrite here: add selected location to collection
  @IBAction func centerMap(_ sender: UIButton) {
    //print(mapView.annotations.count, mapView.annotations.forEach({$0.coordinate.latitude}))
    
      if locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse {
      centerMapOnUserLocation()
    }
  }
  
  @IBAction func searchLocation(_ sender: UIBarButtonItem) {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchBar.delegate = self
    self.present(searchController, animated: true, completion: nil)
    
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    UIApplication.shared.beginIgnoringInteractionEvents()
    
    //show activity indicator
    let activityIndicator = UIActivityIndicatorView()
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
    activityIndicator.frame.size = CGSize(width: 50, height: 50)
    activityIndicator.center = self.mapView.center
    activityIndicator.hidesWhenStopped = true
    activityIndicator.startAnimating()
    self.mapView.addSubview(activityIndicator)
    
    //hide searchBar
    searchBar.resignFirstResponder()
    dismiss(animated: true, completion: nil)
    
    //create search request
    let searchRequest = MKLocalSearchRequest()
    guard let searchText = searchBar.text , searchText != "" else {
      return
    }
    
    searchRequest.naturalLanguageQuery = searchText
    let activeSearch = MKLocalSearch(request: searchRequest)
    activeSearch.start { (response, err) in
      activityIndicator.stopAnimating()
      UIApplication.shared.endIgnoringInteractionEvents()
      if err != nil {
        if let errContent = err?.localizedDescription {
          let alert = UIAlertController(title: "ohoh", message: "\(errContent)", preferredStyle: .alert)
          let alertAct = UIAlertAction(title: "ok lets try later", style: .default, handler: nil)
          alert.addAction(alertAct)
          self.present(alert, animated: true, completion: nil)
        }
       
      } else {
        //remove annotations
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        print(self.mapView.annotations.count)
        
        //getting data
        guard let lat = response?.boundingRegion.center.latitude else { return }
        guard let long = response?.boundingRegion.center.longitude else { return }
        print("lat is \(lat), long is \(long)")
        let annotation = MKPointAnnotation()
        annotation.title = searchText
        annotation.coordinate = CLLocationCoordinate2DMake(lat, long)
        print(annotation)
        self.mapView.addAnnotation(annotation)
        
        //zoom in
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        print(coordinate.latitude, coordinate.longitude)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.setRegion(region, animated: true)
      }
    }
  }
  
  // MARK: - viewDidLoad
  override func viewDidLoad() {
    mapView.delegate = self
    locationManager.delegate = self
    
    // MARK: - configure collectionView
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
    collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "cell")
    collectionView?.delegate = self
    collectionView?.dataSource = self
    collectionView?.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    registerForPreviewing(with: self, sourceView: collectionView!)
    
    configureLocation()
    addDoubleTap()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - double tap func
  func addDoubleTap() {
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    mapView.addGestureRecognizer(doubleTap)
  }

  // MARK: - animation bounceUpView
  func animateViewUp() {
    bounceUpViewHeightConstraint.constant = 300
    UIView.animate(withDuration: 0.4) {
      //redraw the layout on VC
      self.view.layoutIfNeeded()
    }
    bounceUpView.addSubview(collectionView!)
  }
  
}


// MARK: - MapVC extension
extension MapVC: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //prevents drop redundant pin to the current user location
    if annotation is MKUserLocation { return nil }

    let customPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: droppablePinId)
    customPin.pinTintColor = #colorLiteral(red: 0.9921568627, green: 0.7647058824, blue: 0.2549019608, alpha: 1)
    customPin.animatesDrop = true

    return customPin
  }
  
  func addSwipe() {
    let swipeGestureRecog = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
   swipeGestureRecog.direction = .down
    self.bounceUpView.addGestureRecognizer(swipeGestureRecog)
  }
  
  @objc func animateViewDown() {
    cancelURLSession()
    bounceUpViewHeightConstraint.constant = 0
    UIView.animate(withDuration: 0.4) {
      self.view.layoutIfNeeded()
    }
  }
  
  func addSpinner() {
    spinner = UIActivityIndicatorView()
    spinner?.center = CGPoint(x: (screenSize.width - (spinner?.frame.width)!)/2, y: 150)
    spinner?.activityIndicatorViewStyle = .whiteLarge
    spinner?.color = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    spinner?.startAnimating()
    collectionView?.addSubview(spinner!)
  }
  
  func removeSpinner() {
    if spinner != nil {
      spinner?.removeFromSuperview()
    }
  }
  
  func addProgressLabel() {
    progressLabel = UILabel()
    progressLabel?.frame = CGRect(x: (screenSize.width)/2-100, y: 170, width: 200, height: 40)
    progressLabel?.textAlignment = .center
    progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
    progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    progressLabel?.text = "Bravo!"
    collectionView?.addSubview(progressLabel!)
  }
  func removeProgressLabel() {
    if progressLabel != nil {
      progressLabel?.removeFromSuperview()
    }
  }
  
  func centerMapOnUserLocation() {
    //check theres a retrieved location
    guard let coordinate = locationManager.location?.coordinate else { return }
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, coordinateRadius * 2, coordinateRadius * 2)
    //let coordinateRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: coordinateRadius, longitudeDelta: coordinateRadius))
    mapView.setRegion(coordinateRegion, animated: true)
  }
  
  @objc func dropPin(sender: UIGestureRecognizer) {
    removePin()
    removeSpinner()
    removeProgressLabel()
    cancelURLSession()
    
    //empty the previous image data
    photoURLArray = []
    imageArray = []
    collectionView?.reloadData()
    
    addSpinner()
    addSwipe()
    addProgressLabel()
    animateViewUp()
    
    let touchPoint = sender.location(in: mapView)
    let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    print(touchCoordinate)
    
    //drop pin to map
    let annotation = DroppablePin(coordinate: touchCoordinate, identifier: droppablePinId)
    //returnFlickrURL(forAPIKey: flickrAPIKey, withAnnotation: annotation, NumberOfPhoto: 12)
    mapView.addAnnotation(annotation)
    
    //center the annotation to the map
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, coordinateRadius * 2, coordinateRadius * 2)
    mapView.setRegion(coordinateRegion, animated: true)
    
    retrieveURL(forAnnotation: annotation) { (isFinished) in
      print(self.photoURLArray)
      if isFinished {
        self.retrieveImages(handler: {(isFinished) in
          if isFinished {
            //hide spinner & progress label
            self.removeSpinner()
            self.removeProgressLabel()
            
            //reload collectionVIew
            self.collectionView?.reloadData()
          } else {
            print("retrieveURL failed")
          }
        }
      )}
    }
  }
  
  func removePin() {
    for annonation in mapView.annotations {
      mapView.removeAnnotation(annonation)
    }
  }
  
  func retrieveURL(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) ->()) {
    
    Alamofire.request(returnFlickrURL(forAPIKey: flickrAPIKey, withAnnotation: annotation, NumberOfPhoto: 30)).responseJSON { (response) in
      print("response is \(response)")
      guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
      let photoDict = json["photos"] as! Dictionary<String, AnyObject>
      let photoDictArray = photoDict["photo"] as! [Dictionary<String, AnyObject>]
      
      for photo in photoDictArray {
        let postURL = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
        self.photoURLArray.append(postURL)
      }
      handler(true)
    }
  }
  
  func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
    for url in photoURLArray {
      DispatchQueue.main.async {
        Alamofire.request(url).responseImage(completionHandler: { (responseImage) in
          print(responseImage, "===========", responseImage.result,"===========", responseImage.result.value)
          guard let image = responseImage.result.value else { return }
          self.imageArray.append(image)
          self.progressLabel?.text = "\(self.imageArray.count)/30 images are downloading"
          self.progressLabel?.adjustsFontSizeToFitWidth = true
          
          //tells us if all image downloading tasks are done
          if self.photoURLArray.count == self.imageArray.count {
            handler(true)
          }
        })
      }
    }
  }
  
  func cancelURLSession() {
    Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadDataTask, downloadDataTask) in
      sessionDataTask.forEach({ $0.cancel()})
      uploadDataTask.forEach({ $0.cancel()})
      downloadDataTask.forEach({ $0.cancel()})
      print("previous URLSessions canceled")
    }
  }
  
}

extension MapVC: CLLocationManagerDelegate {
  // MARK: - configure location auth status
  func configureLocation() {
    if locationAuthStatus == .notDetermined {
      locationManager.requestAlwaysAuthorization()
    } else {
      return
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    centerMapOnUserLocation()
  }
  
}

// methods for collectionView
extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageArray.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
    cell.frame.size = CGSize(width: 70, height: 70)
    let imageView = UIImageView(image: imageArray[indexPath.row])
    imageView.contentMode = .scaleAspectFill
    cell.addSubview(imageView)
    cell.contentView.backgroundColor = #colorLiteral(red: 0.9921568627, green: 0.7647058824, blue: 0.2549019608, alpha: 1)
    
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    guard let popVC = storyboard.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
    popVC.initImage(forImage: imageArray[indexPath.row])
    present(popVC, animated: true, completion: nil)
    
  }
}



extension MapVC: UIViewControllerPreviewingDelegate {
  func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
    guard let pressedIndexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: pressedIndexPath) else { return nil }
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    guard let popVC = storyboard.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
    popVC.initImage(forImage: imageArray[pressedIndexPath.row])
    previewingContext.sourceRect = cell.contentView.frame
    
    
    return popVC
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    show(viewControllerToCommit, sender: self)
  }

}
