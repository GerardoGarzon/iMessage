//
//  LocationPickerViewController.swift
//  iMessages
//
//  Created by Gerardo Garzon on 05/09/22.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> (Void))?
    public var coordinates: CLLocationCoordinate2D?
    private let locationManager = CLLocationManager()
    private var isSendingLocation = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinates = coordinates
        self.isSendingLocation = coordinates == nil
        if !isSendingLocation {
            self.createPinAtLocation()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Pick location"
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        self.tabBarController?.tabBar.isTranslucent = false
        self.tabBarController?.tabBar.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        
        view.backgroundColor = UIColor(named: K.Colors.backgroundColor)
        view.addSubview(map)
        map.showsUserLocation = true
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        if isSendingLocation {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTap))
            let gesture = UITapGestureRecognizer(target: self,
                                                 action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        map.frame = view.bounds
    }
    
    @objc func sendButtonTap() {
        if let selectedCoordinates = self.coordinates {
            completion?(selectedCoordinates)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: map)
        self.coordinates = map.convert(location, toCoordinateFrom: map)
        
        if let selectedCoordinates = self.coordinates {
            let pin = MKPointAnnotation()
            pin.coordinate = selectedCoordinates
            for annotation in map.annotations {
                map.removeAnnotation(annotation)
            }
            map.addAnnotation(pin)
        }
    }
    
    func createPinAtLocation() {
        if let coordinates = self.coordinates {
            let pin = MKPointAnnotation()
            let viewRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 200, longitudinalMeters: 200)
    
            pin.coordinate = coordinates
            map.addAnnotation(pin)
            map.setRegion(viewRegion, animated: true)
        }
    }
    
}

extension LocationPickerViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, isSendingLocation {
            let userCoordinates = location.coordinate
            let pin = MKPointAnnotation()
            let viewRegion = MKCoordinateRegion(center: userCoordinates, latitudinalMeters: 200, longitudinalMeters: 200)
            
            pin.coordinate = userCoordinates
            map.addAnnotation(pin)
            map.setRegion(viewRegion, animated: true)
            self.coordinates = userCoordinates
        }
        
    }
}
