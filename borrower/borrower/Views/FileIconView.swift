import SwiftUI

// MARK: - Single File Icon View with Delete Button
// This view represents each card in a grid, displaying a file or folder icon,
// its name, and a delete button. It also handles double-tap gestures.
struct FileIconView: View {
    // MARK: - Layout Constants
    // Consistent dimensions for each card to ensure a uniform grid appearance.
    private let cardWidth: CGFloat = 96    // Fixed width for the card.
    private let cardHeight: CGFloat = 120  // Fixed height, ensuring space for icon and 2 lines of text.
    private let iconImageSize: CGFloat = 50 // Size of the file/folder icon.
    private let textBlockMinHeight: CGFloat = 36 // Minimum height for the text block, designed to fit approximately 2 lines of caption text.

    // MARK: - Properties
    let item: FileItem           // The data item (file/folder) to display. Assumes FileItem has 'icon' (NSImage) and 'url' (URL) properties.
    let onDoubleTap: () -> Void  // Closure to execute on a double-tap gesture on the card.
    let onDelete: () -> Void     // Closure to execute when the delete button is pressed.

    // MARK: - Body
    // The body property defines the view's content and layout.
    var body: some View {
        // Root ZStack: Defines the card's fixed frame and aligns the delete button to the top-trailing corner.
        ZStack(alignment: .topTrailing) {
            
            // VStack for the card's main content (icon and text).
            // This VStack arranges the icon and the text vertically.
            VStack(spacing: 5) { // Controls the vertical spacing between the icon and the text.
                Spacer(minLength: 0) // Flexible space to help center content vertically within this VStack.

                // Displays the file or folder icon.
                Image(nsImage: item.icon) // Assumes 'item.icon' provides an NSImage.
                    .resizable() // Allows the image to be resized.
                    .aspectRatio(contentMode: .fit) // Maintains the aspect ratio while fitting within the frame.
                    .frame(width: iconImageSize, height: iconImageSize) // Apply fixed size to the icon.

                // Displays the file name.
                Text(item.url.lastPathComponent) // Extracts the last part of the URL as the name.
                    .font(.caption) // Uses a standard caption font for file names.
                    .lineLimit(2)   // Allows the file name to wrap to a maximum of two lines.
                    .multilineTextAlignment(.center) // Centers the text if it wraps to multiple lines.
                    // Ensures the text area width is constrained and has a minimum height for layout consistency.
                    // Max width considers 8pt horizontal padding on each side of the cardWidth.
                    .frame(maxWidth: cardWidth - 16, minHeight: textBlockMinHeight)

                Spacer(minLength: 0) // Flexible space, balances the top spacer to keep content centered.
            }
            .padding(8) // Internal padding for the content (icon and text) within the visual card area.
            // The VStack (content + padding) defines the visual appearance of the card.
            // It's explicitly framed to the cardWidth and cardHeight to ensure its background fills the fixed size.
            .frame(width: cardWidth, height: cardHeight)
            .background(Material.regular) // Uses a Material background for a modern, slightly translucent look.
            .cornerRadius(10) // Applies rounded corners to the card.
            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1) // Adds a subtle shadow for depth.

            // Delete Button ("X")
            // Positioned in the top-right corner due to the ZStack's alignment.
            Button(action: onDelete) { // Executes the onDelete closure when tapped.
                Image(systemName: "xmark.circle.fill") // Uses a standard SF Symbol for delete/close actions.
                    .font(.system(size: 24)) // Explicitly sets the size for the delete icon symbol.
                    .foregroundColor(.secondary.opacity(0.7)) // Sets a slightly subdued color for the icon.
                    // The ".circle.fill" part of the SF Symbol provides its own circular background.
                    // To ensure a good tap target and visual separation, a minimal effective background is added.
                    // This background is nearly transparent but ensures the tap area is consistent.
                    .background(Circle().fill(Material.ultraThin.opacity(0.001)))
            }
            .buttonStyle(PlainButtonStyle()) // Removes any default button styling that might interfere with the custom look.
            // Offsets the button to position it slightly inside the top-right corner of the card.
            // From .topTrailing alignment: negative x moves left (inward), positive y moves down (inward).
            .offset(x: -6, y: 6)
        }
        // CRUCIAL FIX: The entire FileIconView (this ZStack) has a fixed size.
        // This frame modifier applies to the ZStack, ensuring the entire card adheres to the defined dimensions.
        .frame(width: cardWidth, height: cardHeight)
        .contentShape(Rectangle()) // Defines the tappable area for the gesture below, covering the entire fixed frame.
        .onTapGesture(count: 2) { // Handles the double-tap action on the card.
            onDoubleTap() // Calls the provided onDoubleTap closure.
        }
    }
}

