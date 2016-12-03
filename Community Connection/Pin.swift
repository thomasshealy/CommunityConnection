//
//  Pin.swift
//  Community Connection
//
//  Created by Thomas Shealy on 11/21/16.
//  Copyright © 2016 Community Connection. All rights reserved.
//

import Foundation

//Pin class, capable of storing coordinates, picture link (future implementation), title, and subtitle for making or storing
//map annotations

class Pin{
    
    var lat: Double
    var long: Double
    var username: String
    var description: String
    var title: String
    var link: String
    init(lat: Double, long: Double, username: String, title: String, description: String, link: String
         ){
        self.lat = lat
        self.long = long
        self.username = username
        self.description = description
        self.title = title
        self.link = link
    }
    
    
    
    
}
