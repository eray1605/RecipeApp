//
//  RecipeAppApp.swift
//  RecipeApp
//
//  Created by Eray Bolel on 23.09.23.
//

import SwiftUI

@main
struct RecipeAppApp: App {
    @StateObject private var dataController = DataController(name: "Recipe")
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, dataController.container.viewContext)        }
    }
}
