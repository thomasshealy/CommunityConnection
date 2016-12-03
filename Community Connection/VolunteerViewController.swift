//
//  VolunteerViewController.swift
//  Community Connection
//
//  Created by Thomas Shealy on 11/27/16.
//  Copyright © 2016 Community Connection. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import MapKit
import CoreLocation
/****************************************************************************
 *This class is exactly the same as ViewController, minus some functionality.
 *See ViewController for details of how this class works.
 ****************************************************************************
 ****************************************************************************
 */
class VolunteerViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var searchController:UISearchController!
    var localSearchRequest: MKLocalSearchRequest!
    var localSearch:MKLocalSearch!
    var localSearchResponse:MKLocalSearchResponse!
    var error: NSError!
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    var ref: FIRDatabaseReference!
    var pins = [Pin]()
    var retRef: FIRDatabaseReference!
    var refHandle: UInt!
    var dict: NSDictionary!
    var pinList = [DictPin]()
    var hasRan: Bool!
    let BASE_URL = "https://community-connection.firebaseio.com/"
    //  let baseRef = FIRDatabase.database().referenceFromURL("https://community-connection.firebaseio.com/")
    var picLink: String!
    var tempPin: Pin!
    var colors = [Int]()
    var counter: Int!
    var segResult: Int!


   
    @IBOutlet weak var mapView: MKMapView!
    
    let locationMgr = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.locationMgr.delegate = self
        self.locationMgr.requestWhenInUseAuthorization()
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.requestLocation();
        ref = FIRDatabase.database().reference()
        mapView.delegate = self
        self.hasRan = false
        ref.child("Pins").observe(.value, with: { snapshot in
            // print(snapshot.value)
            self.pinList = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                
                for snap in snapshots {
                    if let postDictionary = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let pinDict = DictPin(key: key, dictionary: postDictionary)
                        self.pinList.insert(pinDict, at: 0)
                        if(pinDict.pinLink == nil){
                            pinDict.pinLink = "filler string"
                        }
                        self.tempPin = Pin(lat: pinDict.pinLat, long: pinDict.pinLong, username: pinDict.pinUsername, title: pinDict.pinTitle, description: pinDict.pinDescription, link: pinDict.pinLink)
                            self.markMap(self.tempPin)
                            print(self.pinList[0].pinLat)
                    }
                }
                
                
            }
            
        })

        
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        print("was called")
        if(view.annotation != nil){
            var annotation: MKAnnotation
            annotation = view.annotation!
            let lat = annotation.coordinate.latitude
            let long = annotation.coordinate.longitude
            let coordinates = CLLocationCoordinate2DMake(lat, long)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = "Selected Location"
            mapItem.openInMaps(launchOptions: launchOptions)
           
        }
        
        
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        print("mapView gets caled")
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 60, height: 60)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: UIControlState())
        //button.addTarget(self, action:#selector(ViewController.getDirections), forControlEvents: .TouchUpInside)
        pinView?.leftCalloutAccessoryView = button
        

        return pinView
      
        
        
    }
    func getDirections(){
        print("Enters getDirections")
        if let selectedPin = selectedPin {
            print("Enters if statement")
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    func directionsfromPin(_ pin: DictPin){
        let lat = pin.pinLat
        let long = pin.pinLong
        let coordinates = CLLocationCoordinate2DMake(lat!, long!)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func markMap(_ pin: Pin){
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.lat
        annotation.coordinate.longitude = pin.long
        annotation.title = pin.title
        annotation.subtitle = pin.description
        mapView.addAnnotation(annotation)
        
        
    }
    

}
extension VolunteerViewController{
    func locationManager(_ manager:CLLocationManager, didChangeAuthorization status:
        CLAuthorizationStatus){
        if status == .authorizedWhenInUse{
            locationMgr.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        if let location = locations.first{
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            
            self.mapView.setRegion(region, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("error:: (error)")
    }
}
