import SwiftUI
import AppKit // Required for NSImage and NSWorkspace

// MARK: - Model representing a file or folder item
// This struct defines the data model for a file or folder.
// It conforms to Identifiable for use in SwiftUI lists/grids,
// and Equatable to allow for comparisons (e.g., to avoid duplicates based on URL).
struct FileItem: Identifiable, Equatable {
    // MARK: - Properties

    // let id: UUID
    // A unique identifier for each FileItem instance.
    // This is automatically generated when a FileItem instance is created and is used
    // by SwiftUI to uniquely identify items in lists or grids, especially for animations and updates.
    let id: UUID

    // let url: URL
    // The file system URL of the item. This stores the path to the
    // actual file or folder on the user's system.
    let url: URL

    // let icon: NSImage
    // The system icon for the file or folder.
    // This is fetched once during initialization.
    let icon: NSImage

    // let isDirectory: Bool
    // A Boolean value indicating whether the item at the `url` is a directory.
    // This is determined once during initialization.
    // It includes special handling for '.app' bundles, treating them as files.
    let isDirectory: Bool

    // MARK: - Initializer
    // Initializes a new FileItem with a given URL.
    // It determines if the item is a directory and fetches its icon.
    init(url: URL) {
        self.id = UUID() // Generate a unique ID for this instance
        self.url = url

        // Determine if it's a directory and handle .app bundles
        var isDirObjC: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirObjC) {
            if url.pathExtension.lowercased() == "app" {
                self.isDirectory = false // Treat .app bundles as files
            } else {
                self.isDirectory = isDirObjC.boolValue
            }
        } else {
            // If the file doesn't exist or there's an error, default to not being a directory.
            // This could happen if the file is deleted between the drop and this initialization.
            self.isDirectory = false
            print("Warning: FileItem init - file does not exist or cannot be accessed at path: \(url.path)")
        }

        // Fetch the system icon for the file/folder.
        // NSWorkspace.shared is a singleton for file system interactions.
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }
    
    // MARK: - Equatable Conformance
    // static func == (lhs: FileItem, rhs: FileItem) -> Bool
    // Implements the Equatable protocol. Two FileItems are considered equal
    // if their `url` properties are the same. This is useful for checking
    // if an item with the same file path has already been added.
    // Note: This compares content identity (same file on disk),
    // while the `id` property handles instance identity (for SwiftUI).
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
