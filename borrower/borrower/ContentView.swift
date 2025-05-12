import SwiftUI
import UniformTypeIdentifiers // Required for using UTType, supporting drag-and-drop operations.
import AppKit // Required for accessing NSImage (for file icons) and NSWorkspace (for opening files).

// Assume FileItem struct exists and is Identifiable (e.g., by UUID or URL)
// Example: struct FileItem: Identifiable { let id: UUID; let url: URL; /* ... */ }

// MARK: - Main Content View
struct ContentView: View {
    // MARK: State Variables
    @State private var navigationPath: [URL] = []
    @State private var rootItems: [FileItem] = []
    @State private var currentDisplayItems: [FileItem] = []
    @State private var isTargeted: Bool = false // For drop target visual feedback
    @State private var showDropArea: Bool = true // To toggle the drop area visibility

    /// An ID that changes when the app becomes active. Used to force `FileIconView` instances to reconstruct,
    /// ensuring their drag gestures are reset and allowing an item to be dragged multiple times.
    @State private var appActivationID: UUID = UUID()

    /// Stores the ID of the item currently being dragged *out* of the application.
    /// Used to remove the item from the list after the drag operation finishes (approximated by app reactivation).
    @State private var draggingItemID: FileItem.ID? = nil // <-- Track item being dragged out

    // MARK: Grid Configuration
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100), spacing: 20)
    ]

    // MARK: Computed Properties
    var currentPathForDisplay: String {
        if let currentFolderURL = navigationPath.last {
            return currentFolderURL.lastPathComponent
        }
        return "Dropped Files"
    }

    // MARK: Body
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Drop Area Toggle
            HStack {
                Spacer()
                Button(action: { withAnimation { showDropArea.toggle() } }) {
                    Label("Drop Area", systemImage: showDropArea ? "chevron.up" : "chevron.down")
                        .labelStyle(IconOnlyLabelStyle()).padding(6)
                        .background(Color.secondary.opacity(0.1)).cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle()).padding(.trailing, 12).padding(.top, 8)
            }

            // MARK: Drop Target Area
            if showDropArea {
                DropTargetOverlay(rootItems: $rootItems, isTargeted: $isTargeted)
                    .frame(height: 150)
                    .background(isTargeted ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.1))
                    .cornerRadius(12).padding().transition(.move(edge: .top).combined(with: .opacity))
                Divider().transition(.opacity)
            }

            // MARK: Navigation Header
            HStack {
                 if !navigationPath.isEmpty {
                     Button(action: navigateBack) { Label("Back", systemImage: "chevron.backward") }
                         .padding(.leading)
                 }
                 Text(currentPathForDisplay).font(.headline).lineLimit(1).truncationMode(.middle)
                     .padding(.leading, navigationPath.isEmpty ? 16 : 8)
                 Spacer()
             }
             .padding(.horizontal).padding(.vertical, 8).frame(height: 40)


            // MARK: Main Content Grid
            if currentDisplayItems.isEmpty {
                 // Empty View Message
                Spacer()
                Text(navigationPath.isEmpty ? "Drag and drop files into the area above." : "This folder is empty.")
                    .foregroundColor(.secondary).padding()
                Spacer()
            } else {
                // Grid of File Items
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(currentDisplayItems) { item in
                            FileIconView(
                                item: item,
                                onDoubleTap: { handleItemDoubleTap(item) },
                                onDelete: { deleteItem(item) } // Existing delete button action
                            )
                            // Use appActivationID in the ID to force resets, enabling multiple drags
                            .id("\(item.id)-\(appActivationID)")
                            // Handle dragging items *out* of the application
                            .onDrag {
                                // Record the ID of the item when its drag starts
                                self.draggingItemID = item.id // <-- Record ID on drag start
                                // Provide the file URL to the drag-and-drop system
                                return NSItemProvider(object: item.url as NSURL)
                            }
                            // Optional: Visual feedback for the item being dragged
                            // .opacity(item.id == draggingItemID ? 0.5 : 1.0)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 300, idealHeight: 600)
        // MARK: Lifecycle and State Change Handlers
        .onAppear(perform: updateCurrentDisplayItems)
        .onChange(of: navigationPath) { // For macOS 12+ / iOS 15+
            updateCurrentDisplayItems()
        }
        .onChange(of: rootItems) { // For macOS 12+ / iOS 15+
            if navigationPath.isEmpty { // Only update display if viewing root
                updateCurrentDisplayItems()
            }
        }
        // Handle app reactivation to potentially remove dragged item and reset drag states
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // This notification fires when the app regains focus.
            
            // Check if an item was marked as being dragged out just before reactivation
            if let itemIDToDelete = self.draggingItemID {
                 print("App became active after potentially dragging item ID: \(itemIDToDelete). Removing item from list.")
                 // Remove the item from the data source(s)
                 deleteItemWithID(itemIDToDelete) // <-- REMOVE item from list
                 // Clear the flag so it doesn't delete again on next activation
                 self.draggingItemID = nil
            }
            
            // Always refresh the activation ID on reactivation. This resets the .id()
            // for all FileIconViews, ensuring their drag gestures are ready for the next use.
            self.appActivationID = UUID()
        }
    }

    // MARK: - Action Handlers

    /// Handles double-tap on a file item (navigate into folder or open file).
    func handleItemDoubleTap(_ item: FileItem) {
        if item.isDirectory {
            navigationPath.append(item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    /// Navigates back up one level in the folder hierarchy.
    func navigateBack() {
         if !navigationPath.isEmpty {
             _ = navigationPath.popLast()
         }
    }

    /// Deletes an item triggered by the 'X' button click.
    func deleteItem(_ item: FileItem) {
        print("Deleting item \(item.id) via explicit delete action.")
        deleteItemWithID(item.id)
    }

    /// Central function to remove an item from the relevant data lists based on its ID.
    /// Called by both the 'X' button action and the post-drag removal logic.
    /// - Parameter id: The ID of the `FileItem` to remove.
    func deleteItemWithID(_ id: FileItem.ID) {
        var itemRemoved = false
        
        // Remove from the currently displayed list first
        if let index = currentDisplayItems.firstIndex(where: { $0.id == id }) {
            currentDisplayItems.remove(at: index)
            print("Removed item \(id) from currentDisplayItems.")
            itemRemoved = true
        }

        // If we are currently viewing the root level, also remove from the master rootItems list
        if navigationPath.isEmpty {
            if let index = rootItems.firstIndex(where: { $0.id == id }) {
                rootItems.remove(at: index)
                print("Removed item \(id) from rootItems.")
                itemRemoved = true
            }
        }
        
        if !itemRemoved {
            print("Item \(id) was not found for deletion (perhaps already removed).")
        }
        
        // Note: If navigating within a folder (not root), this only removes the item
        // from the `currentDisplayItems` view. It does *not* delete the file from
        // the actual folder on disk. If the user navigates away and back, the item
        // might reappear unless the underlying folder content has actually changed.
        // If `rootItems` represents *only* items dropped initially, then removing
        // items dragged out from subfolders might require different logic if you
        // want that removal to persist across navigation.
        // For simplicity, this implementation removes from the visible list, and
        // from the root list *if* the user is currently viewing the root.
    }


    // MARK: - Data Loading

    /// Updates the `currentDisplayItems` list based on the current navigation state.
    private func updateCurrentDisplayItems() {
        print("Updating current display items...")
        var newItems: [FileItem] = []
        if let currentFolderURL = navigationPath.last {
            // Load items from the current folder URL
             do {
                 let contentURLs = try FileManager.default.contentsOfDirectory(
                     at: currentFolderURL,
                     includingPropertiesForKeys: [.isDirectoryKey, .nameKey, .isPackageKey],
                     options: [.skipsHiddenFiles]
                 )
                 newItems = contentURLs.map { FileItem(url: $0) } // Assuming FileItem init is available
                 print("Loaded \(newItems.count) items from folder: \(currentFolderURL.lastPathComponent)")
             } catch {
                 print("Error loading contents of \(currentFolderURL.path): \(error.localizedDescription)")
                 // Optionally clear items or show an error state
                 newItems = []
             }
        } else {
            // At root: display the items stored in rootItems
            newItems = rootItems
            print("Displaying \(newItems.count) root items.")
        }

        // Sort the items (folders first, then alphabetically)
        currentDisplayItems = newItems.sorted {
             if $0.isDirectory && !$1.isDirectory { return true }
             if !$0.isDirectory && $1.isDirectory { return false }
             return $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending
        }
    }
}
