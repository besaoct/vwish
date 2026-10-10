// OWNER: UX-08
//
// Placeholder (D-33) created by UX-01. UX-08 replaces this file:
// one-shot editor events: toasts, haptics, announcements.
// Until then it declares only the public names other files compile against.

/// A one-shot UI effect (toast, haptic, announcement; ux.md §16.3).
sealed class EditorEvent {
  /// Creates an event.
  const EditorEvent();
}
