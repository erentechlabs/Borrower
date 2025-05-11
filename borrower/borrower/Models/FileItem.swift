import SwiftUI
import AppKit // Required for NSImage and NSWorkspace

// MARK: - Model representing a dropped file item
// This struct defines the data model for a file or folder that has been
// dropped into the application. It conforms to Identifiable for use in lists
// and Equatable to allow for comparisons between items (e.g., to avoid duplicates).
struct FileItem: Identifiable, Equatable {
    // MARK: - Properties
    
    // let id = UUID()
    // A unique identifier for each file item. This is automatically generated
    // when a FileItem instance is created and is used by SwiftUI to uniquely
    // identify items in lists or grids.
    let id = UUID()

    // let url: URL
    // The file system URL of the dropped item. This stores the path to the
    // actual file or folder on the user's system.
    let url: URL

    // var icon: NSImage
    // A computed property that returns the system icon for the file or folder
    // represented by the `url`. It uses `NSWorkspace` to fetch the appropriate icon.
    var icon: NSImage {
        // NSWorkspace.shared is a singleton object that provides information
        // about the file system and can perform operations like opening files.
        // The icon(forFile:) method retrieves the standard icon for a given file path.
        NSWorkspace.shared.icon(forFile: url.path)
    }

    // var isDirectory: Bool
    // A computed property that determines if the item at the `url` is a directory.
    // It also includes a special check to treat '.app' bundles as files rather than directories
    // for typical user interaction purposes (e.g., double-clicking an app should launch it,
    // not navigate into its bundle contents).
    var isDirectory: Bool {
        var isDir: ObjCBool = false // A boolean value passed by reference to fileExists(atPath:isDirectory:).
        // FileManager.default is used to interact with the file system.
        // fileExists(atPath:isDirectory:) checks if an item exists at the given path
        // and, if it does, sets the `isDir` variable to true if the item is a directory.
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            // Special handling for .app bundles: Treat them as files.
            // url.pathExtension gets the extension of the file (e.g., "txt", "app").
            if url.pathExtension.lowercased() == "app" {
                return false // Explicitly return false for .app bundles.
            }
            // For other items, return the value determined by fileExists.
            // isDir.boolValue converts the ObjCBool to a Swift Bool.
            return isDir.boolValue
        }
        // If the file does not exist or an error occurs, assume it's not a directory.
        return false
    }
    
    // MARK: - Equatable Conformance
    // static func == (lhs: FileItem, rhs: FileItem) -> Bool
    // Implements the Equatable protocol, allowing two FileItem instances to be
    // compared for equality. Two FileItems are considered equal if their `url`
    // properties are the same. This is useful for checking for duplicates.
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
