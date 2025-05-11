import SwiftUI

// MARK: - Custom View for Drop Target Overlay
// This struct defines a custom view that acts as a drop target for files.
// It displays a message and changes its appearance when a file is being dragged over it.
struct DropTargetOverlay: View {
    // MARK: - State Variables
    // @Binding var rootItems: [FileItem]
    // A binding to an array of FileItem objects. This array will be updated
    // when new files are dropped onto the view.
    @Binding var rootItems: [FileItem]

    // @Binding var isTargeted: Bool
    // A binding to a Boolean value that indicates whether the drop target is currently
    // being targeted by a drag operation (i.e., a file is being dragged over it).
    @Binding var isTargeted: Bool

    // MARK: - Body
    // The body property defines the view's content and layout.
    var body: some View {
        ZStack {
            // A clear rectangle that fills the entire space of the ZStack.
            // This ensures that the drop target area is active even if there's no visible content.
            Rectangle()
                .fill(Color.clear) // Makes the rectangle transparent.

            // Text view to display the "Drop Files Here" message.
            Text("Drop Files Here")
                .font(.title2) // Sets the font size to title2.
                // Sets the text color based on whether the view is targeted.
                // If targeted, the color is primary; otherwise, it's secondary.
                .foregroundColor(isTargeted ? .primary : .secondary)
        }
        // MARK: - Drop Handling
        // The .onDrop modifier handles the drag-and-drop operation.
        // It specifies the types of content that can be dropped (in this case, .fileURL).
        // The isTargeted binding is updated automatically by this modifier.
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers, _ in
            // Loop through each item provider from the drop operation.
            for provider in providers {
                // Check if the provider can load an object of type URL.
                if provider.canLoadObject(ofClass: URL.self) {
                    // Asynchronously load the URL object from the provider.
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        // Check if there was an error loading the URL.
                        if let error = error {
                            print("Error loading file URL from provider: \(error.localizedDescription)")
                            return // Exit if there's an error.
                        }
                        // Check if the URL was successfully loaded.
                        if let fileUrl = url {
                            // Dispatch the update to the main thread, as UI updates must occur on the main thread.
                            DispatchQueue.main.async {
                                // Create a new FileItem from the dropped file's URL.
                                let newItem = FileItem(url: fileUrl)
                                // Check if the item already exists in the rootItems array to avoid duplicates.
                                if !self.rootItems.contains(where: { $0.url == newItem.url }) {
                                    // If the item is not a duplicate, append it to the rootItems array.
                                    self.rootItems.append(newItem)
                                    print("Dropped file: \(fileUrl.path)") // Log the path of the dropped file.
                                }
                            }
                        }
                    }
                } else {
                    // If the provider cannot load a URL, print a message.
                    print("Provider cannot load a URL.")
                }
            }
            // Return true if at least one provider was handled, indicating a successful drop.
            // Return false if no providers were handled (e.g., if the dropped item was not a file URL).
            return !providers.isEmpty
        }
    }
}

