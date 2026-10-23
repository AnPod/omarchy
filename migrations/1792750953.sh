echo "Hide Papers from the launcher; Evince stays the document viewer"

# Papers only comes in as a dependency of sushi but carries the same
# "Document Viewer" name as Evince, so the launcher shows the app twice.
# This override shadows the packaged entry in ~/.local/share/applications;
# it drops MimeType so Papers stays installed and runnable without
# competing with Evince for PDFs.
mkdir -p "$HOME/.local/share/applications"
cp "$OMARCHY_PATH/applications/org.gnome.Papers.desktop" "$HOME/.local/share/applications/"
