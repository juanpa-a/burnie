PROJECT := Burnie.xcodeproj
SCHEME := BurnieApp
DERIVED_DATA := build/DerivedData
DEBUG_APP := $(DERIVED_DATA)/Build/Products/Debug/Burnie.app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/Burnie.app
APPS_DIR ?= /Applications

.PHONY: gen build test run perf install release

gen:
	xcodegen generate --quiet

build: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED_DATA) -destination "platform=macOS,arch=$(shell uname -m)" -quiet build

test:
	swift test --package-path BurnieKit

run: build
	open $(DEBUG_APP)

perf:
	BURNIE_PERF=1 swift test --package-path BurnieKit -c release -Xswiftc -enable-testing --filter ClaudeLogScanPerformanceTests

# Builds a release copy signed ad hoc for this Mac (no Apple account needed), replaces the installed one, and opens it.
install: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED_DATA) -destination "platform=macOS,arch=$(shell uname -m)" -quiet \
		CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= OTHER_CODE_SIGN_FLAGS= build
	pkill -x Burnie || true
	rm -rf "$(APPS_DIR)/Burnie.app"
	ditto $(RELEASE_APP) "$(APPS_DIR)/Burnie.app"
	open "$(APPS_DIR)/Burnie.app"

# Signs with a Developer ID, notarizes, and leaves build/Burnie.zip.
# `burnie-notary` is created once with `xcrun notarytool store-credentials`.
release: gen
	@test -n "$(TEAM_ID)" || { echo "Usage: make release TEAM_ID=<Apple Developer team>"; exit 1; }
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-archivePath build/Burnie.xcarchive BURNIE_TEAM_ID=$(TEAM_ID) archive
	xcodebuild -exportArchive -archivePath build/Burnie.xcarchive \
		-exportOptionsPlist ExportOptions.plist -exportPath build/export
	ditto -c -k --keepParent build/export/Burnie.app build/Burnie.zip
	xcrun notarytool submit build/Burnie.zip --keychain-profile burnie-notary --wait
	xcrun stapler staple build/export/Burnie.app
	# Zip again so the archive carries the stapled ticket and opens offline.
	ditto -c -k --keepParent build/export/Burnie.app build/Burnie.zip
