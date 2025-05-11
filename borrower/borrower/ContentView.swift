import SwiftUI
import UniformTypeIdentifiers // Required for using UTType, supporting drag-and-drop operations.
import AppKit // Required for accessing NSImage (for file icons) and NSWorkspace (for opening files).

// MARK: - Main Content View
// This struct defines the main user interface for the application.
// It handles navigation through folders, display of files, and drag-and-drop functionality.
struct ContentView: View {
    // MARK: State Variables
    // These properties are managed by SwiftUI and will cause the view to re-render when they change.

    /// An array of URLs representing the current folder navigation stack.
    /// The last URL in the array is the currently displayed folder. An empty array means the root view.
    @State private var navigationPath: [URL] = []

    /// An array of `FileItem` objects that were initially dropped into the application's drop area.
    /// These form the "root" level of items if no folder is being browsed.
    @State private var rootItems: [FileItem] = []

    /// An array of `FileItem` objects currently being displayed in the grid.
    /// This list is derived either from `rootItems` or the contents of the folder specified by `navigationPath.last`.
    @State private var currentDisplayItems: [FileItem] = []

    /// A Boolean value indicating whether a dragged item is currently hovering over the designated drop area.
    /// Used for providing visual feedback during drag operations.
    @State private var isTargeted: Bool = false

    /// A Boolean value that controls the visibility of the drag-and-drop area at the top of the view.
    @State private var showDropArea: Bool = true

    // MARK: Grid Configuration
    /// Defines the layout for the `LazyVGrid` that displays file and folder icons.
    /// It uses an adaptive layout, meaning items will adjust their size to fit the available width,
    /// with a minimum item width of 100 points and a spacing of 20 points between items.
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]

    // MARK: Computed Properties
    /// A string representing the name of the currently displayed path or folder.
    /// Used for the navigation header.
    var currentPathForDisplay: String {
        if let currentFolderURL = navigationPath.last {
            return currentFolderURL.lastPathComponent // Display the name of the current folder
        }
        return "Dropped Files" // Default title when viewing the root items
    }

    // MARK: Body
    /// The description of the view's content and layout.
    var body: some View {
        VStack(spacing: 0) { // Main vertical container for all UI elements.
            
            // Section for the button that toggles the visibility of the drop area.
            HStack {
                Spacer() // Pushes the button to the trailing edge.
                Button(action: {
                    withAnimation { // Animate the appearance/disappearance of the drop area.
                        showDropArea.toggle()
                    }
                }) {
                    Label("Drop Area", systemImage: showDropArea ? "chevron.up" : "chevron.down") // Icon changes based on state.
                        .labelStyle(IconOnlyLabelStyle()) // Display only the icon part of the Label.
                        .padding(6)
                        .background(Color.secondary.opacity(0.1)) // Subtle background for the button.
                        .cornerRadius(8)
                        .contentShape(Rectangle()) // Defines the button's tappable area.
                }
                .buttonStyle(PlainButtonStyle()) // Removes default button styling for a cleaner look.
                .padding(.trailing, 12) // Space from the trailing edge of the window.
                .padding(.top, 8)       // Space from the top of the window.
            }

            // Conditional display of the DropTargetOverlay and a Divider.
            if showDropArea {
                DropTargetOverlay(rootItems: $rootItems, isTargeted: $isTargeted) // Custom view for handling file drops.
                    .frame(height: 150) // Sets a fixed height for the drop area.
                    .background(isTargeted ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.1)) // Visual feedback on drag hover.
                    .cornerRadius(12)
                    .padding() // Padding around the drop area.
                    .transition(.move(edge: .top).combined(with: .opacity)) // Animation for showing/hiding.

                Divider() // A visual separator line.
                    .transition(.opacity) // Animation for the divider.
            }
            
            // Navigation header: "Back" button and current path display.
            HStack {
                if !navigationPath.isEmpty { // Display "Back" button only when inside a folder.
                    Button(action: navigateBack) {
                        Label("Back", systemImage: "chevron.backward")
                    }
                    .padding(.leading) // Padding on the left of the "Back" button.
                }
                Text(currentPathForDisplay) // Display the name of the current folder or root.
                    .font(.headline)
                    .lineLimit(1) // Prevent the text from wrapping to multiple lines.
                    .truncationMode(.middle) // Truncate long names in the middle (e.g., "VeryLong...Name.txt").
                    .padding(.leading, navigationPath.isEmpty ? 16 : 8) // Adjust leading padding based on "Back" button's presence.
                Spacer() // Pushes the title to the leading edge (after the back button if present).
            }
            .padding(.horizontal) // Horizontal padding for the header content.
            .padding(.vertical, 8)   // Vertical padding for the header content.
            .frame(height: 40)      // Fixed height for the navigation header.

            // Main content area: either a message or the grid of items.
            if currentDisplayItems.isEmpty {
                // If there are no items to display, show a relevant message.
                Spacer() // Centers the message vertically.
                Text(navigationPath.isEmpty ? "Drag and drop files into the area above." : "This folder is empty.")
                    .foregroundColor(.secondary) // Use a less prominent color for the message.
                    .padding()
                Spacer() // Centers the message vertically.
            } else {
                // If there are items, display them in a scrollable grid.
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) { // Grid that loads items lazily for performance.
                        ForEach(currentDisplayItems) { item in
                            FileIconView( // Custom view for each file/folder item.
                                item: item,
                                onDoubleTap: { handleItemDoubleTap(item) }, // Action for double-tapping the item.
                                onDelete: { deleteItem(item) }              // Action for deleting the item.
                            )
                            .onDrag { // Enable dragging of items out of the application.
                                NSItemProvider(object: item.url as NSURL)
                            }
                        }
                    }
                    .padding() // Padding around the grid content.
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 300, idealHeight: 600) // Define window size constraints.
        .onAppear(perform: updateCurrentDisplayItems) // Load initial items when the view first appears.
        .onChange(of: navigationPath) { // React to changes in the navigation path (folder changes).
            updateCurrentDisplayItems() // Update the displayed items accordingly.
        }
        .onChange(of: rootItems) { // React to changes in the list of root items (e.g., new files dropped).
            if navigationPath.isEmpty { // Only update if currently viewing the root level.
                updateCurrentDisplayItems()
            }
        }
    }

    // MARK: - Action Handlers

    /// Handles the double-tap action on a `FileItem`.
    /// If the item is a directory, it navigates into it. Otherwise, it opens the file.
    /// - Parameter item: The `FileItem` that was double-tapped.
    func handleItemDoubleTap(_ item: FileItem) {
        if item.isDirectory {
            navigationPath.append(item.url) // Add folder to navigation path to navigate into it.
        } else {
            NSWorkspace.shared.open(item.url) // Open the file with its default application.
        }
    }

    /// Navigates back to the previous folder in the `navigationPath`.
    func navigateBack() {
        if !navigationPath.isEmpty {
            _ = navigationPath.popLast() // Remove the last folder from the path to go up one level.
        }
    }

    /// Deletes a `FileItem` from the current view and, if at the root, from `rootItems`.
    /// This does not delete the item from the file system.
    /// - Parameter item: The `FileItem` to be deleted from the view.
    func deleteItem(_ item: FileItem) {
        currentDisplayItems.removeAll { $0.id == item.id } // Remove from the currently visible list.
        if navigationPath.isEmpty { // If at the root level,
            rootItems.removeAll { $0.id == item.id } // also remove from the master list of root items.
        }
    }

    // MARK: - Data Loading

    /// Updates the `currentDisplayItems` list based on the current `navigationPath`.
    /// If the `navigationPath` is empty, it displays `rootItems`. Otherwise, it loads the contents of the current folder.
    private func updateCurrentDisplayItems() {
        var newItems: [FileItem] = []
        if let currentFolderURL = navigationPath.last { // Check if currently inside a folder.
            do {
                // Attempt to read the contents of the directory.
                let contentURLs = try FileManager.default.contentsOfDirectory(
                    at: currentFolderURL,
                    includingPropertiesForKeys: [.isDirectoryKey, .nameKey, .isPackageKey], // Properties to pre-fetch for efficiency.
                    options: [.skipsHiddenFiles] // Exclude hidden files (e.g., .DS_Store).
                )
                // Convert the URLs to `FileItem` objects.
                for url in contentURLs {
                    newItems.append(FileItem(url: url))
                }
            } catch {
                // Handle errors that occur while reading directory contents (e.g., permissions issues).
                print("Error loading contents of \(currentFolderURL.path): \(error.localizedDescription)")
                 if navigationPath.count > 0 { // Provides context if the error occurs in a subfolder.
                     print("\(currentFolderURL.lastPathComponent) could not be loaded, showing empty content for this folder.")
                 }
            }
        } else {
            // If not in a folder (i.e., at the root), display the initially dropped items.
            newItems = rootItems
        }
        
        // Sort the items: folders first, then all items alphabetically by name.
        currentDisplayItems = newItems.sorted {
            if $0.isDirectory && !$1.isDirectory { return true }  // Folders come before files.
            if !$0.isDirectory && $1.isDirectory { return false } // Files come after folders.
            // Sort alphabetically by name for items of the same type (both files or both folders).
            return $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending
        }
    }
}
