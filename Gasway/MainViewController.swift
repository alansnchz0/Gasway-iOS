//
//  MainViewController.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 1/20/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import UIKit
import MapKit
import Font_Awesome_Swift
import AEXML
import Firebase

class MainViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationsTableView: UITableView!
    @IBOutlet weak var tableViewContainer: UIView!
    @IBOutlet weak var trayImage: UIImageView!
    @IBOutlet weak var brandControl: UISegmentedControl!
    @IBOutlet weak var areaSlider: UISlider!
    @IBOutlet weak var areaTextField: UITextField!
    @IBOutlet weak var topTrayConstraint: NSLayoutConstraint!
    
    var trayOriginalCenter: CGFloat!
    var trayDownOffset: CGFloat!
    var trayUp: CGFloat!
    var trayDown: CGFloat!
    
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    let jsonDecoder = JSONDecoder()
    
    var stations: [Station] = []
    var selStations: [Station] = []
    var magna: [Station] = []
    var premium: [Station] = []
    var diesel: [Station] = []
    
    var uid: String?
    
    var last: Int = 0
    
    enum GasType: String {
        case regular = "regular"
        case premium = "premium"
        case diesel = "diesel"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START SignIn]
        Auth.auth().signInAnonymously() { (user, error) in
            if error != nil {
                print(error ?? "Auth error")
            }
            self.uid = user!.uid
        }
        // [END SignIn]

        trayImage.setFAIconWithName(icon: .FAAngleDown, textColor: .darkGray)
        locationManager.delegate = self
        locationsTableView.delegate = self
        locationsTableView.dataSource = self
        tableViewContainer.layer.cornerRadius = 40.0
        trayDownOffset = locationsTableView.frame.size.height
        trayUp = topTrayConstraint.constant
        trayDown = trayUp + trayDownOffset
        mapView.delegate = self
        mapView.register(ArtworkMarkerView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func didPanTray(_ sender: UIPanGestureRecognizer) {
        
        let velocity = sender.velocity(in: view)
        let translation = sender.translation(in: view)
        
        if sender.state == UIGestureRecognizerState.began {
            
            trayOriginalCenter = topTrayConstraint.constant
        } else if sender.state == UIGestureRecognizerState.changed {
            
            topTrayConstraint.constant = trayOriginalCenter + translation.y
        } else if sender.state == UIGestureRecognizerState.ended {
            
            if velocity.y > 0 {
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    //self.tableViewContainer.center = self.trayDown
                    self.topTrayConstraint.constant = self.trayDown
                    self.trayImage.setFAIconWithName(icon: .FAAngleUp, textColor: .darkGray)
                })
            } else {
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    //self.tableViewContainer.center = self.trayUp
                    self.topTrayConstraint.constant = self.trayUp
                    self.trayImage.setFAIconWithName(icon: .FAAngleDown, textColor: .darkGray)
                })
            }
            self.tableViewContainer.layoutIfNeeded()
        }
    }
    
    func moveTrayDown() {
        trayOriginalCenter = topTrayConstraint.constant
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.topTrayConstraint.constant = self.trayDown
            self.trayImage.setFAIconWithName(icon: .FAAngleUp, textColor: .darkGray)
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        geocoder.reverseGeocodeLocation(locations[locations.endIndex-1]) { (placemarks, error) in
            if error != nil {
                print(error ?? "Unknown Error")
            } else {
                // Get the first placemark from the placemarks array.
                // This is your address object
                if let placemark = placemarks?[0] {
                    
                    let latDelta:CLLocationDegrees = 0.05
                    let lonDelta:CLLocationDegrees = 0.05
                    let span = MKCoordinateSpanMake(latDelta, lonDelta)
                    let location = CLLocationCoordinate2DMake((placemark.location?.coordinate.latitude)!, (placemark.location?.coordinate.longitude)!)
                    let region = MKCoordinateRegionMake(location, span)
        
                    self.mapView.setRegion(region, animated: true)
                    self.getStations(String(location.latitude), String(location.longitude),
                        km: String(Int(round(self.areaSlider.value))))
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.distanceFilter = 3000.0
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.distanceFilter = 3000.0
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func didBrandValueChanged(_ sender: Any, forEvent event: UIEvent) {
        selStations.removeAll()
        switch brandControl.selectedSegmentIndex {
            case GasType.regular.hashValue:
                selStations = magna
                break
            case GasType.premium.hashValue:
                selStations = premium
                break
            case GasType.diesel.hashValue:
                selStations = diesel
                break
            default:
                selStations = magna
                break
        }
        last = selStations.count
        mapView.removeAnnotations(mapView.annotations)
        loadArtworks(gasType: brandControl.selectedSegmentIndex)
        self.locationsTableView.reloadData()
    }
    
    @IBAction func didAreaChanged(_ sender: Any, forEvent event: UIEvent) {
        
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
                case .began:
                    break
                case .moved:
                    areaTextField.text = "\(Int(round(areaSlider.value)))km"
                    break
                case .ended:
                    guard let l = locationManager.location else {
                        areaSlider.setValue(7, animated: true)
                        return
                    }
                    mapView.removeAnnotations(mapView.annotations)
                    getStations(String(l.coordinate.latitude), String(l.coordinate.longitude), km: String(Int(round(areaSlider.value))))
                default:
                    break
            }
        }
    }
    
    func loadArtworks(gasType: Int) {
        
        for (i, s) in selStations.enumerated() {
            var priceRange = 1
            if 0 == i {
                priceRange = 0
            } else if last-1 == i {
                priceRange = 2
            }
            
            let artwork = Artwork(station: s,
                                  priceRange: priceRange)
            
            mapView.addAnnotation(artwork)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let l = view.annotation as! Artwork
        let sdv = self.storyboard?.instantiateViewController(withIdentifier: "StationDetailView") as! DetailViewController
        for s in stations {
            if Int(s.placeId) == Int(l.station.placeId) {
                sdv.station = s
                break
            }
        }
        self.navigationController?.pushViewController(
            sdv, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        last = selStations.count
        return last
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "stationcell", for: indexPath) as? StationTableViewCell else {
            fatalError("The dequeued cell is not an instance of StationTableViewCell.")
        }
        
        var station = selStations[indexPath.row]

        cell.brandLabel.text = station.brand
        cell.nameLabel.text = station.name
        cell.priceLabel.text = "$" + String(station.prices[0].price)
        cell.distanceLabel.text = String(format: "%.02f km", (locationManager.location?.distance(from: CLLocation(latitude: station.latitude, longitude: station.longitude)))! / 1000)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let station = selStations[indexPath.row]
        
        let latDelta:CLLocationDegrees = 0.025
        let lonDelta:CLLocationDegrees = 0.025
        let span = MKCoordinateSpanMake(latDelta, lonDelta)
        let location = CLLocationCoordinate2DMake(station.latitude, station.longitude)
        let region = MKCoordinateRegionMake(location, span)
        
        moveTrayDown()
        self.mapView.setRegion(region, animated: true)
    }
    
    func getStations(_ lat: String, _ lng: String, km: String) {
        
        resetArrays()
        
        let urlString = "https://gasway.app/80430b0bd02771d3036d126bf1d460c4?lat=\(lat)&lng=\(lng)&dst=\(km)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            //Implement JSON decoding and parsing
            do {
                //Decode retrived data with JSONDecoder and assing type of Station object
                self.stations = try JSONDecoder().decode([Station].self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    print("address: \(self.stations[0].address)")
                    //TODO: Sort array
                    for station in self.stations {
                        for price in station.prices {
                            var s = station
                            s.prices.removeAll()
                            switch price.type {
                                case GasType.regular.rawValue:
                                    s.prices.append(price)
                                    self.magna.append(s)
                                    break
                                case GasType.premium.rawValue:
                                    s.prices.append(price)
                                    self.premium.append(s)
                                    break
                                case GasType.diesel.rawValue:
                                    s.prices.append(price)
                                    self.diesel.append(s)
                                    break
                                default:
                                    s.prices.append(price)
                                    self.magna.append(s)
                                    break
                            }
                        }
                    }
                    self.magna.sort(by: { $0.prices[0].price < $1.prices[0].price })
                    self.premium.sort(by: { $0.prices[0].price < $1.prices[0].price })
                    self.diesel.sort(by: { $0.prices[0].price < $1.prices[0].price })
                    self.selStations = self.magna
                    self.last = self.selStations.count
                    self.loadArtworks(gasType: GasType.regular.hashValue)
                    self.locationsTableView.reloadData()
                }
            } catch let jsonError {
                print(jsonError)
            }
        }.resume()
    }
    
    func resetArrays() {
        stations.removeAll()
        magna.removeAll()
        premium.removeAll()
        diesel.removeAll()
        selStations.removeAll()
        mapView.removeAnnotations(mapView.annotations)
    }
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
