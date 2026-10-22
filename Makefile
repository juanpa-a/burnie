PROJECT := Burnie.xcodeproj
SCHEME := BurnieApp
DERIVED_DATA := build/DerivedData
DEBUG_APP := $(DERIVED_DATA)/Build/Products/Debug/Burnie.app
RELEASE_APP := $(DERIVED_DATA)/Build/Products/Release/Burnie.app
APPS_DIR ?= /Applications
RELEASE_DIR := build/release
RELEASES_URL := https://github.com/juanpa-a/burnie/releases
# Sparkle's command line tools, which SwiftPM downloads with the package.
SPARKLE_BIN := $(DERIVED_DATA)/SourcePackages/artifacts/sparkle/Sparkle/bin

.PHONY: gen build test check verify run perf release-adhoc install dmg release

gen:
	xcodegen generate --quiet

build: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED_DATA) -destination "platform=macOS,arch=$(shell uname -m)" -quiet build

test:
	swift test --package-path BurnieKit

# The architecture rules of SPEC.md section 16.2 (and the check's own test), and sensitive data in every file.
check:
	scripts/check-architecture-test.sh
	scripts/check-architecture.sh
	scripts/check-sensitive.sh --all

# Every gate CI runs on a pull request.
verify: check test build

run: build
	open $(DEBUG_APP)

perf:
	BURNIE_PERF=1 swift test --package-path BurnieKit -c release -Xswiftc -enable-testing --filter ClaudeLogScanPerformanceTests

# Builds a release copy signed ad hoc for this Mac (no Apple account needed).
# Without the hardened runtime, which an ad hoc app can't have and still load Sparkle.framework.
release-adhoc: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED_DATA) -destination "platform=macOS,arch=$(shell uname -m)" -quiet \
		CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= OTHER_CODE_SIGN_FLAGS= ENABLE_HARDENED_RUNTIME=NO build

# Replaces the installed copy with the ad hoc build and opens it.
install: release-adhoc
	pkill -x Burnie || true
	rm -rf "$(APPS_DIR)/Burnie.app"
	ditto $(RELEASE_APP) "$(APPS_DIR)/Burnie.app"
	open "$(APPS_DIR)/Burnie.app"

# Packs the ad hoc build into build/Burnie.dmg, to try the install window without notarizing.
dmg: release-adhoc
	scripts/make-dmg.sh $(RELEASE_APP) build/Burnie.dmg
	open build/Burnie.dmg

# Signs with a Developer ID, notarizes, and leaves build/release/Burnie.dmg and the appcast.xml Sparkle reads.
# Once per Mac: `xcrun notarytool store-credentials burnie-notary`, and Sparkle's `generate_keys` (see README).
release: gen
	@test -n "$(TEAM_ID)" || { echo "Usage: make release TEAM_ID=<Apple Developer team>"; exit 1; }
	rm -rf build/Burnie.xcarchive build/export $(RELEASE_DIR)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED_DATA) -archivePath build/Burnie.xcarchive BURNIE_TEAM_ID=$(TEAM_ID) archive
	xcodebuild -exportArchive -archivePath build/Burnie.xcarchive \
		-exportOptionsPlist ExportOptions.plist -exportPath build/export
	mkdir -p $(RELEASE_DIR)
	scripts/make-dmg.sh build/export/Burnie.app $(RELEASE_DIR)/Burnie.dmg
	codesign --sign "Developer ID Application" --timestamp $(RELEASE_DIR)/Burnie.dmg
	xcrun notarytool submit $(RELEASE_DIR)/Burnie.dmg --keychain-profile burnie-notary --wait
	xcrun stapler staple $(RELEASE_DIR)/Burnie.dmg
	# Signs the DMG and the appcast (Info.plist requires a signed feed) with the EdDSA key in the Keychain, and points
	# the appcast at this version's release.
	version=$$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" build/export/Burnie.app/Contents/Info.plist) && \
		$(SPARKLE_BIN)/generate_appcast --download-url-prefix "$(RELEASES_URL)/download/v$$version/" $(RELEASE_DIR) && \
		echo "Publish with: gh release create v$$version $(RELEASE_DIR)/Burnie.dmg $(RELEASE_DIR)/appcast.xml"
