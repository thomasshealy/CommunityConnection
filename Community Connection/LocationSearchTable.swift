//
//  LocationSearchTable.swift
//  Community Connection
//
//  Created by Thomas Shealy on 11/19/16.
//  Copyright © 2016 Community Connection. All rights reserved.
//


import UIKit
import MapKit

//This class handles the data displayed when searching on the map.

class LocationSearchTable : UITableViewController{
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    var handleMapSearchDelegate:HandleMapSearch? = nil
    
    //credit: https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
    func parseAddress(_ selectedItem:MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

extension LocationSearchTable : UISearchResultsUpdating {
    //updates the search table as you type.
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else {return}
        //creates search request object to preform search
        let request = MKLocalSearchRequest()
        //gives the search request object data from the search bar
        request.naturalLanguageQuery = searchBarText
        //obtains search region from mapView
        request.region = mapView.region
        //Searches using the user entered data
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTable {
    //handles displaying potential matches as the user types.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        //gets number of matches for the entered information.
        return matchingItems.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //cell is created and added to the tableview to store information
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        // creates a reference to item in order to retrieve data
        let selectedItem = matchingItems[indexPath.row].placemark
        //populates the cell with information from the selectedItem object, returns the cell that was just created. 
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem)
        return cell
    }
}

extension LocationSearchTable {
    //sends the chosen address over to ViewController to so it can display it on the map.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        //delegate calls dropPinZoomIn from ViewController
        handleMapSearchDelegate?.dropPinZoomIn(selectedItem)
        //dismisses the search table that was just over the map.
        dismiss(animated: true, completion: nil)
    }
}


