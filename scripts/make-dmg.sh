#!/bin/bash
# Packs Burnie.app into a DMG that opens to a window asking to drag Burnie,
# on the left, onto the shortcut to Applications, on the right.
#
# Usage: scripts/make-dmg.sh <Burnie.app> <output .dmg>
# Finder lays out the window, so this needs a logged-in session (it asks Finder via AppleScript).

set -euo pipefail

app=$1
dmg=$2
volume=Burnie
scripts=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Draws the background at 1x and 2x and joins them, so Finder picks the sharp one on Retina.
mkdir "$work/background"
swift "$scripts/dmg-background.swift" "$work/background"
tiffutil -cathidpicheck "$work/background/background.png" "$work/background/background@2x.png" \
	-out "$work/background.tiff" 2>/dev/null

mkdir -p "$work/stage/.background"
ditto "$app" "$work/stage/Burnie.app"
ln -s /Applications "$work/stage/Applications"
cp "$work/background.tiff" "$work/stage/.background/background.tiff"

if [ -d "/Volumes/$volume" ]; then
	echo "Eject /Volumes/$volume first: Finder would lay out the wrong window." >&2
	exit 1
fi
hdiutil create -volname "$volume" -srcfolder "$work/stage" -fs HFS+ -format UDRW -quiet "$work/rw.dmg"
hdiutil attach "$work/rw.dmg" -readwrite -noverify -noautoopen -quiet

# Bounds are the window's frame: 660×440 of content plus the title bar.
# .background sits below the window, so it stays out of sight for anyone who shows hidden files.
osascript <<EOF
tell application "Finder"
	tell disk "$volume"
		open
		set current view of container window to icon view
		set toolbar visible of container window to false
		set statusbar visible of container window to false
		set bounds of container window to {200, 120, 860, 588}
		set viewOptions to icon view options of container window
		set arrangement of viewOptions to not arranged
		set icon size of viewOptions to 128
		set text size of viewOptions to 13
		set background picture of viewOptions to file ".background:background.tiff"
		set position of item "Burnie.app" to {170, 290}
		set position of item "Applications" to {490, 290}
		set position of item ".background" to {330, 640}
		update without registering applications
		delay 1
		close
	end tell
end tell
EOF

# The read-write mount left .fseventsd, macOS's log of file events, which would also show with hidden files.
rm -rf "/Volumes/$volume/.fseventsd"
sync
hdiutil detach "/Volumes/$volume" -quiet
rm -f "$dmg"
hdiutil convert "$work/rw.dmg" -format UDZO -imagekey zlib-level=9 -quiet -o "$dmg"
