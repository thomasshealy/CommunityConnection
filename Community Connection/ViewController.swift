//
//  ViewController.swift
//  Community Connection
//
//  Created by Thomas Shealy on 11/5/16.
//  Copyright © 2016 Community Connection. All rights reserved.
//


//This is a beta made for a proof of concept test, some functionality will be implemented later

//***** For location in simulator use: latitude: 35.925942 longitude: -79.038271*****

import Firebase
import FirebaseDatabase
import UIKit
import MapKit
import CoreLocation

struct pin{
    let lat : Double!
    let long : Double!
    let username: String!
    let title: String!
    let description : String!
}

protocol HandleMapSearch {
    func dropPinZoomIn(_ placemark:MKPlacemark)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    var isFoodBank: Int!
    var tempPin: Pin!
    var colors = [Int]()
    var counter: Int!
    var segResult: Int!
    var pickedImage: UIImage!
    let imagePicker = UIImagePickerController()
    var picLink: String?
    var downLink: String?
    var tempString: String!
    let locationMgr = CLLocationManager()
    
    //References to mapView and textfield objects (see Main.storyboard)
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var text0: UITextField!
    @IBOutlet weak var text1: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.counter = 0
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        hasRan = false
        mapView.delegate = self
        imagePicker.delegate = self
        downLink = "fill link"
        self.locationMgr.delegate = self
       self.locationMgr.requestWhenInUseAuthorization()
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        self.locationMgr.requestLocation();
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as!
        LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter Address"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        ref = FIRDatabase.database().reference()
        
        //Reads in pins stored on the Firebase server, and listens/adds when other users create pins.
        //Pins are read in as DictPin objects (see DictPin class for more info), and added to the maps as Pin objects
        //(see pin class for more info.
        ref.child("Pins").observe(FIRDataEventType.value, with: { snapshot in
            self.pinList = []
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshots {
                    if let postDictionary = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let pinDict = DictPin(key: key, dictionary: postDictionary)
                        self.pinList.insert(pinDict, at: 0)
                        if(pinDict.pinLink == nil){
                            self.tempString = "placeholder"
                        }
                        else{
                            self.tempString = pinDict.pinLink
                        }
                        self.tempPin = Pin(lat: pinDict.pinLat, long: pinDict.pinLong, username: pinDict.pinUsername, title: pinDict.pinTitle, description: pinDict.pinDescription, link: self.tempString)
                        self.picLink = pinDict.pinLink
                        self.markMap(self.tempPin)
                    }
                }
                
                
            }
    
            //self.hasRan = true
           
        })
        
    }
    
    //Called whenever a pin is added to the map.  Creates an annotation, which is then added to the map (placement determined by the latitude and longitude)
    //Also creates a mapItem which is used to obtain driving directions (further explained in the following method).
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        //print("was called")
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
    //Creates the annotation view that pops up when a pin on the map is clicked, called whenever a pin is added to the map.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        //This is case causes the blue dot to be drawn for current user location rather than a pin
       if annotation is MKUserLocation {
            return nil
        }
        //This is a standard AnnotationView except the color of the pins are orange and a button is created that
        //links to a method (directionfromPin) which gets directions from the users current location to the selected pin
        let identifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 60, height: 60)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: UIControlState())
        pinView?.leftCalloutAccessoryView = button

        return pinView
    }
    
    //This has been left here in case it is needed for future implementation.  Can be used to fill in the address when 
    //the users gets driving directions
    
   /* func getDirections(){
        print("Enters getDirections")
        if let selectedPin = selectedPin {
            print("Enters if statement")
            let mapItem = MKMapItem(placemark: selectedPin)
            let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    } */
    
    //Called whenever a pin's get directions button is pressed.  Uses the pin's coordinates to create a placemark object which is used as the destination when it opens maps.
     func directionsfromPin(_ pin: DictPin){
        let lat = pin.pinLat
        let long = pin.pinLong
        let coordinates = CLLocationCoordinate2DMake(lat!, long!)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    
    }
    
    //This has been left here in case it is needed for future implementation.  Allows a user to select a picture from their photo library to upload.
    
   /* @IBAction func picAdded(_ sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
        
    }
 */
 
    //Default Swift auto-generated method.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //This has been left here in case it is needed for future implementation.  Allows users to mark a location tapping the map.
   
    /*@IBAction func dropPin(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self.mapView)
        let coord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coord
        annotation.title = "Title"
        annotation.subtitle = "location of pin"
        
        self.mapView.addAnnotation(annotation)
        
    } */
    
    //Adds pins to the map (causes mapView to be called).  Coordinates and subtitles are read in from the Firebase backend.
    func markMap(_ pin: Pin){
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = pin.lat
        annotation.coordinate.longitude = pin.long
        annotation.title = pin.title
        annotation.subtitle = pin.description
        mapView.addAnnotation(annotation)
    
    }
    
    //This has been left here in case it is needed for future implementation.  Helper methods for selection a picture for upload.
    
    /*
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            pickedImage = image
        }
        dismiss(animated: true, completion: nil)
    }
   
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    */
    
    //Dismisses the keyboard when a user is done entering information into the textViews.
    func dismissKeyboard(){
        view.endEditing(true)
    }

    //Called when the top textField object is pressed, moves the textField up so users can see what they type.
    @IBAction func fieldPressed(_ sender: UITextField) {
        self.view.frame.origin.y = -150
    }
    
    //Resets the app to its normal position after the textField is no longer in use.
    @IBAction func doneEdit(_ sender: UITextField) {
        self.view.frame.origin.y = 0
    }
    
    //same as fieldPressed but for bottom textField.
    @IBAction func fieldPressed1(_ sender: UITextField) {
        self.view.frame.origin.y = -240
    }
    
    //same as doneEdit but for bottom textField.
    @IBAction func donEdit1(_ sender: UITextField) {
        self.view.frame.origin.y = 0
    }
  
}


extension ViewController{
    //tracks the users location and monitors for a change in location authorization (the user disables location services, etc.).
    func locationManager(_ manager:CLLocationManager, didChangeAuthorization status:
        CLAuthorizationStatus){
        if status == .authorizedWhenInUse{
            locationMgr.requestLocation()
        }
    }
    //Sets where the map initially zooms into and determines how far in the zoom is.
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
//Handles when a user marks a location on the map.
extension ViewController: HandleMapSearch{
    //called when a user chooses a location from the search bar, this is passed in as an MKPlacemark object.
    func dropPinZoomIn(_ placemark:MKPlacemark){
        //this if statement prevents the user from entering a location without filling in both fields.
        if((text0.text?.isEmpty)! || (text1.text?.isEmpty)!){
        print("Fill both fields")
        }
        else{
        //cach pin
        selectedPin = placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = self.text0.text!
        annotation.subtitle = self.text1.text!
        mapView.addAnnotation(annotation)
            //Causes the map to zoom in on the pin that was just added
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
            //Stores the information into a pinDict to add into Firebase.
                let pinDict : Dictionary<String, AnyObject> = [
                "lat": placemark.coordinate.latitude as AnyObject,
                "long": placemark.coordinate.longitude as AnyObject,
                "username": self.text0.text! as AnyObject,
                "description": self.text1.text! as AnyObject,
                "title": self.text0.text! as AnyObject,
                "link": downLink! as AnyObject
            ]
            //Stores the pin into Firebase
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("Pins").childByAutoId().setValue(pinDict)
    }
    }
    
    }
