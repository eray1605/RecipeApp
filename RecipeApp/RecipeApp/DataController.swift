//
//  DataController.swift
//  RecipeApp
//
//  Created by Eray Bolel on 23.09.23.
//

import Foundation
import CoreData

class DataController : ObservableObject {
    
    var container: NSPersistentContainer
    
    init(name: String){
    container = NSPersistentContainer(name: name)
        container.loadPersistentStores{ _, error in
            if let error = error{
                print("CoreData ERROR:\(error.localizedDescription)")
            }
            
            
        }
        
    }
    
}
