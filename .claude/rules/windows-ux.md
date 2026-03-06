## Windows Desktop UX Rules
- **Window Management**: Include a custom title bar that fits Windows 11 aesthetics.
- **Packaging**: Always include a 256x256 `.ico` file for the Windows taskbar.
- **Performance**: Use `page.window_prevent_close = True` to handle "Save before exit" prompts—a standard expectation for Windows enterprise software.
- **Fonts**: Use 'Segoe UI' as a fallback for Windows and 'San Francisco' for Mac to ensure native readability.