import SwiftUI
import CoreData
import UIKit

struct ContentView: View {
    @State private var searchText = ""
    @State private var showAddRecipeView = false
    @Environment(\.managedObjectContext) private var moc
    @State private var recipeToDelete: Entity?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Entity.title, ascending: true)]) var recipes: FetchedResults<Entity>
    
    // Funktion zum Löschen eines Rezepts aus CoreData
       func deleteRecipe(_ recipe: Entity) {
           moc.delete(recipe)
           do {
               try moc.save()
           } catch {
               print("Fehler beim Löschen des Rezepts: \(error)")
           }
       }
    
    var body: some View {
        NavigationView {
            VStack {
                
                //List(recipes) {
                //    entity in Text(entity.title ?? "ERROR" )
                    
               // }
                
               
                TextField("Suche nach Rezepten!", text: $searchText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                var filteredRecipes: [Entity] {
                    if searchText.isEmpty {
                        return Array(recipes)
                    } else {
                        return recipes.filter { $0.title?.localizedCaseInsensitiveContains(searchText) ?? true }
                    }
                }
                List {
                    ForEach(filteredRecipes, id: \.self){ recipe in
                        
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            HStack {
                                if let imageData = recipe.image,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(recipe.title ?? "")
                                        .font(.headline)
                                    Text(recipe.desc ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("📖Kochbuch").font(Font.custom("SF Compact Rounded", size: 24))
            }
            .navigationBarItems(trailing: Button(action: {
                showAddRecipeView = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
            })
            .alert(item: $recipeToDelete) { recipe in
                // Zeige das Lösch-Popup mit Bestätigungsdialog
                Alert(
                    title: Text("Rezept löschen"),
                    message: Text("Möchten Sie das Rezept wirklich löschen?"),
                    primaryButton: .destructive(Text("Löschen")) {
                        // Löschaktion hier durchführen
                        deleteRecipe(recipe)
                    },
                    secondaryButton: .cancel()
                )

            }
            .sheet(isPresented: $showAddRecipeView) {
                AddRecipeView(registrationComplete: $showAddRecipeView).environment(\.managedObjectContext, moc)
            }
        }
        
    }
    
    struct EditIngredientsView: View {
        @Binding var ingredients: String
        @Environment(\.presentationMode) var presentationMode

        var body: some View {
            NavigationView {
                VStack {
                    Text("Zutaten bearbeiten")
                        .font(.title)
                        .padding()

                    TextEditor(text: $ingredients)
                        .frame(height: 200)
                        .padding()
                }
                .navigationBarItems(trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Speichern")
                })
                .navigationTitle("Zutaten")
            }
        }
    }
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var isShown: Bool
        @Binding var image: UIImage?

        func makeCoordinator() -> Coordinator {
            return Coordinator(isShown: $isShown, image: $image)
        }

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            @Binding var isCoordinatorShown: Bool
            @Binding var imageInCoordinator: UIImage?

            init(isShown: Binding<Bool>, image: Binding<UIImage?>) {
                _isCoordinatorShown = isShown
                _imageInCoordinator = image
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    imageInCoordinator = uiImage
                }
                isCoordinatorShown = false
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                isCoordinatorShown = false
            }
        }
    }


    struct RecipeDetailView: View {
        var recipe: Entity
        @State private var newIngredients = ""
        @State private var showEditIngredients = false
        @State private var showImagePicker = false
        @State private var selectedImage: UIImage?
        
        var body: some View {
            VStack {
                if let imageData = recipe.image {
                    Image(uiImage: selectedImage ?? UIImage(data: imageData)!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .onTapGesture {
                            // Show image picker when tapped
                            self.showImagePicker.toggle()
                        }
                } else {
                    Button(action: {
                        // Show image picker when tapped
                        self.showImagePicker.toggle()
                    }) {
                        Image(systemName: "camera")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .foregroundColor(.blue) // Customize the color
                    }
                }
                
                Text(recipe.desc ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Zutaten:")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView {
                    Text(recipe.ingredients ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: {
                    showEditIngredients = true
                }) {
                    Text("Zutaten bearbeiten")
                        .font(.headline)
                        .padding(.top)
                }
                .sheet(isPresented: $showEditIngredients) {
                    EditIngredientsView(ingredients: $newIngredients)
                }
            }
            .navigationTitle(recipe.title ?? "")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(isShown: $showImagePicker, image: $selectedImage)
            }
        }
    }


    
    struct FocusedTextEditor: UIViewRepresentable {
        @Binding var text: String
        @Binding var isEditing: Bool

        func makeUIView(context: Context) -> UITextField {
            let textField = UITextField()
            textField.delegate = context.coordinator
            textField.font = UIFont.preferredFont(forTextStyle: .body)
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.smartQuotesType = .yes
            textField.smartDashesType = .yes
            textField.text = text
            return textField
        }

        func updateUIView(_ uiView: UITextField, context: Context) {
            uiView.text = text

            if isEditing && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isEditing && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, UITextFieldDelegate {
            var parent: FocusedTextEditor

            init(_ parent: FocusedTextEditor) {
                self.parent = parent
            }

            func textFieldDidChangeSelection(_ textField: UITextField) {
                parent.text = textField.text ?? ""
            }

            func textFieldDidBeginEditing(_ textField: UITextField) {
                parent.isEditing = true
            }

            func textFieldDidEndEditing(_ textField: UITextField) {
                parent.isEditing = false
            }
        }
    }
    
    struct AddRecipeView: View {
        @Environment(\.managedObjectContext) private var moc
        @Binding var registrationComplete: Bool
        @State private var newTitle = ""
        @State private var newDesc = ""
        @State private var newImage: Data? = nil
        @State private var newIngredients = ""
        @State private var isFocused = false
        
        var body: some View {
            VStack {
                TextField("Name des Rezepts", text: $newTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Beschreibung", text: $newDesc)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                VStack {
                    Text("Hier die Zutaten eingeben") // Beschreibungstext
                        .font(.headline)
                    ScrollView{
                        
                        TextEditor(text: $newIngredients)
                            .frame(minWidth: 200, minHeight: 400, maxHeight: .infinity) // Set a minimum height for the TextEditor
                            .multilineTextAlignment(.leading) // Text horizontal links ausrichten
                            .padding()
                            .background(Color(.secondarySystemBackground))
                        
                        
                        
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    
                    
                    
                    Button(action: {
                        // Save new recipe to Core Data
                        let newRecipe = Entity(context: moc)
                        newRecipe.title = newTitle
                        newRecipe.desc = newDesc
                        newRecipe.image = newImage
                        newRecipe.ingredients = newIngredients
                        
                        do {
                            try moc.save()
                            registrationComplete = true
                        } catch {
                            print("Error saving new recipe: \(error)")
                        }
                    }) {
                        Text("Rezept hinzufügen")
                            .font(.none)
                            .padding()
                            .frame(maxWidth: 300) // Make the button expand to fill the width
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                  
                
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
