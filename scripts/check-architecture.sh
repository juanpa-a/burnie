#!/bin/bash
#
# check-architecture.sh: the architecture check of SPEC.md section 16.2.
#
# Usage: scripts/check-architecture.sh [root]
#
# root is a folder laid out like the repo (App/, AppTests/, BurnieKit/) inside a git work tree; it defaults to the repo
# that holds this script. The check reads the Swift files under root's App/, AppTests/ and BurnieKit/ that git tracks or
# would track (git ls-files --cached --others --exclude-standard), so a new file counts before it's staged and ignored
# folders (.build/, generated code) never do. AppTests/, the app's Xcode test target until the refactor, is test code
# like BurnieKit/Tests/.
#
# Output: one line per failure, "SPEC <rule>: <file>:<line>: <fix>", with <file> relative to root. If anything fails,
# a summary goes to stderr and the exit status is 1; otherwise one OK line is printed and the status is 0. A check that
# stops on an error exits 2.
#
# Comment lines (first non-blank characters "//", so "///" too) are skipped by every rule except G-8, because the
# markers G-8 forbids live in comments.
#
# Dormancy (SPEC 14.1): a module exists once it holds a Swift file. A rule scoped to a module has nothing to scan
# until then, and a rule that guards the code around a module wakes when that module appears: G-5 with
# BurnieProviders, C-4 and C-5 with BurnieComponents, G-3 on the app target with BurnieApplication. On today's
# layout BurnieCore stands for Domain in G-3 and D-3, and BurnieSystem (with its tests) for Infra in G-6 and G-11.
#
# Plain bash 3.2, grep and awk, BSD or GNU; nothing else.

set -euo pipefail
export LC_ALL=C # byte-wise matching: [A-Za-z] means the ASCII letters, whatever the user's locale
IFS=$'\n'       # file lists hold one path per line, so an unquoted $(files_in ...) is one argument per file
set -f          # and is never globbed

# --- Where things live: extended regexes over paths relative to the root.

readonly ANY='.'
readonly DOMAIN='^BurnieKit/Sources/BurnieDomain/'
readonly INTERFACE='^BurnieKit/Sources/BurnieInterface/'
readonly PROVIDERS='^BurnieKit/Sources/BurnieProviders/'
readonly APPLICATION='^BurnieKit/Sources/BurnieApplication/'
readonly INFRA='^BurnieKit/Sources/BurnieInfra/'
readonly COMPONENTS='^BurnieKit/Sources/BurnieComponents/'
readonly LEGACY_CORE='^BurnieKit/Sources/BurnieCore/'
readonly LEGACY_SYSTEM='^BurnieKit/Sources/BurnieSystem/'
readonly TESTS='^(BurnieKit/Tests|AppTests)/'
readonly TEST_SUPPORT='^BurnieKit/Tests/BurnieTestSupport/'
readonly PROVIDERS_TESTS='^BurnieKit/Tests/BurnieProvidersTests/'
readonly INFRA_TESTS='^BurnieKit/Tests/Burnie(Infra|System)Tests/'
readonly APP='^App/'
readonly COMPOSITION='^App/Composition/'
readonly PREVIEWS='^App/Previews/'

readonly PERFORMANCE_TEST='^BurnieKit/Tests/.*/ClaudeLogScanPerformanceTests[.]swift$'
readonly ICON_BUTTON='(^|/)IconButton[.]swift$'
readonly DESIGN_TOKENS='(^|/)DesignTokens[.]swift$'
readonly PREVIEW_VALUES='(^|/)PreviewValues[.]swift$'

# Persistence tests of SPEC section 12 that must spell the frozen provider ids ("claude", "cursor"), as the files on
# users' disks do, so G-5 skips them. One path per line, relative to the root.
readonly PROVIDER_ID_ALLOWLIST='BurnieKit/Tests/BurnieDomainTests/PersistenceContractTests.swift'

# --- What may be imported (SPEC 3.2), space separated. Each module's own list is in allowed_imports.

readonly TEST_TARGET_IMPORTS='Testing BurnieTestSupport'
readonly VIEW_IMPORTS='Foundation SwiftUI AppKit BurnieDomain BurnieInterface BurnieComponents BurnieApplication'

# --- What the rules look for: extended regexes over one line.

readonly COMMENT_LINE='^[[:space:]]*//'
# The awk function every rule prints its failures with: "SPEC <rule>: <file>:<line>: <fix>".
readonly REPORT='function report(rule, file, line, fix) { printf "SPEC %s: %s:%d: %s\n", rule, file, line, fix }'

# The extended regex that matches any of its arguments.
any_of() {
	local IFS='|'
	printf '%s' "$*"
}

readonly WORD_START='(^|[^A-Za-z0-9_])'
readonly WORD_END='([^A-Za-z0-9_]|$)'
readonly NONZERO_NUMBER='-?([1-9]|0[0-9._]*[1-9])'
# A string literal that opens right here and holds a letter.
readonly OPENS_LETTERED_STRING='"[^"]*[A-Za-z]'
# A line with a string literal that holds a letter, found by skipping whole literals from the start of the line.
readonly HAS_LETTERED_STRING='^[^"]*("[^"]*"[^"]*)*"[^"]*[A-Za-z][^"]*"'
# A string interpolation or an escaped character, erased before looking inside string literals.
readonly STRING_ESCAPES='\\[(][^)]*[)]|\\.'
# The start of a column-0 declaration: attributes (with arguments) and modifiers, in any order.
readonly DECLARATION_PREFIX='^(@[A-Za-z_][A-Za-z0-9_]*([(]([^()]|[(][^()]*[)])*[)])?[[:space:]]+)*((public|package|internal|fileprivate|private|open|final|indirect|nonisolated)([(][a-z]+[)])?[[:space:]]+)*'
readonly TYPE_DECLARATION="${DECLARATION_PREFIX}(struct|enum|class|actor|protocol)[[:space:]]+"
readonly APP_MODEL_DECLARATION="${DECLARATION_PREFIX}(struct|enum|class|actor|extension)[[:space:]]+(AppModel|AppEnvironment)${WORD_END}"
readonly IMPORT='^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*((public|package|internal|fileprivate|private)[[:space:]]+)?import[[:space:]]+'

readonly SPECIFIC_PROVIDER=$(any_of \
	"${WORD_START}case[[:space:]]+[.](claude|cursor)${WORD_END}" \
	"[=!]=[[:space:]]*[.](claude|cursor)${WORD_END}" \
	'"(claude|cursor)"')
readonly SYSTEM_TIME=$(any_of \
	"${WORD_START}Date[(][)]" \
	"${WORD_START}Date[(]timeIntervalSinceNow" \
	"${WORD_START}(Date|ContinuousClock|SuspendingClock)[.]now${WORD_END}" \
	"[(:,][[:space:]]*[.]now${WORD_END}" \
	"[.]timeIntervalSinceNow${WORD_END}" \
	"${WORD_START}(TimeZone|Locale|Calendar)[.]current${WORD_END}")
readonly TIMELINE_START='TimelineView[(][[:space:]]*[.]periodic[(]from:[[:space:]]*[.]now'
readonly ICON_BUTTON_ANIMATION=$(any_of \
	'Spin[(]startingAt:[[:space:]]*[.]now[)]' \
	'stop[(]at:[[:space:]]*[.]now[)]' \
	'[.]timeIntervalSinceNow')
readonly PRINTING="${WORD_START}(print|NSLog|debugPrint)[(]"
readonly MARKERS="${WORD_START}(TODO|FIXME|XXX)${WORD_END}"
readonly FORCE_UNWRAP='try!|[)]!([^=]|$)'
readonly UNCHECKED_SENDABLE='@unchecked[[:space:]]+Sendable'
readonly STATE_OR_CONCURRENCY=$(any_of \
	"${WORD_START}(class|actor)[[:space:]]" \
	"${WORD_START}(async|Task)${WORD_END}" \
	"${WORD_START}static[[:space:]]+var${WORD_END}")
readonly IO_TYPES="${WORD_START}(FileManager|URLSession|Process|UserDefaults|Bundle|ProcessInfo|NotificationCenter)${WORD_END}"
# What D-6 lets Domain spell, erased before looking for copy: a raw value, a coding key, a Codable error description,
# a format string made only of specifiers and punctuation, a fixed identifier (time zone, locale); then interpolations
# and escapes. Only those literals go, so copy on the same line still fails.
readonly NOT_COPY=$(any_of \
	'(rawValue|debugDescription|identifier):[[:space:]]*"[^"]*"' \
	'case[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*"[^"]*"' \
	'String[(]format:[[:space:]]*"([%][0-9.]*[a-z]+|[^A-Za-z"])*"' \
	"$STRING_ESCAPES")
readonly SHARED_MUTABLE_STATE=$(any_of \
	"${WORD_START}(class|actor)[[:space:]]" \
	"${WORD_START}static[[:space:]]+var${WORD_END}" \
	"${DECLARATION_PREFIX}var[[:space:]]")
readonly OS_LOGGER=$(any_of 'os[.]Logger' "${WORD_START}Logger[(]")
readonly PUBLIC="${WORD_START}public${WORD_END}"
readonly OWN_WAITING=$(any_of "${WORD_START}Task[.]sleep" "${WORD_START}asyncAfter${WORD_END}" "${WORD_START}Timer[.]")
readonly LITERAL_STYLE=$(any_of \
	'Color[(]red:' \
	'Color[(]hex' \
	'#colorLiteral' \
	"[.](frame|padding|opacity)[(]([^)]*[^A-Za-z0-9_.])?${NONZERO_NUMBER}" \
	"${WORD_START}(spacing|cornerRadius|lineWidth):[[:space:]]*${NONZERO_NUMBER}" \
	"[.]font[(][.]system[(]size:[[:space:]]*${NONZERO_NUMBER}")
readonly LITERAL_TEXT=$(any_of \
	"${WORD_START}(Text|Label|Button|Toggle)[(]${OPENS_LETTERED_STRING}" \
	"[.]accessibilityLabel[(]${OPENS_LETTERED_STRING}" \
	"${WORD_START}(title|subtitle|label|accessibilityLabel):[[:space:]]*${OPENS_LETTERED_STRING}")
readonly INFRA_IMPORT="${IMPORT}BurnieInfra${WORD_END}"
readonly PROVIDERS_IMPORT="${IMPORT}BurnieProviders${WORD_END}"

# --- Files.

die() {
	printf 'check-architecture: %s\n' "$1" >&2
	exit 2
}

# The Swift files under App/, AppTests/ and BurnieKit/ that git tracks or would track and that are on disk, one
# per line.
swift_files() {
	git -c core.quotePath=false ls-files --cached --others --exclude-standard -- App AppTests BurnieKit |
		{ grep '\.swift$' || true; } |
		sort -u |
		while IFS= read -r path; do
			if [ -f "$path" ]; then
				printf '%s\n' "$path"
			fi
		done
}

# The scanned files whose path matches the extended regex INCLUDE and not EXCLUDE.
files_in() {
	local include=$1 exclude=${2:-'^$'}
	printf '%s\n' "$SWIFT_FILES" | { grep -E -- "$include" || true; } | { grep -vE -- "$exclude" || true; }
}

# True once a scanned file lives under the module whose path regex is PATH.
module_exists() {
	[ -n "$(files_in "$1")" ]
}

# Drops from standard input the paths listed, one per line, in LIST.
without_listed() {
	if [ -z "$1" ]; then
		cat
	else
		grep -vxF -- "$1" || true
	fi
}

# --- Scanners.

# scan MODE RULE FIX PATTERN ALLOWED FILE...
# Prints "SPEC RULE: <file>:<line>: FIX" for each line of FILE... that matches the extended regex PATTERN once the
# parts that match ALLOWED (empty for none) are erased. MODE says which lines count:
#   code         lines that aren't comments
#   anywhere     every line, comments too (G-8 only)
#   uncommented  code lines whose line above isn't a comment, since that comment is what justifies them (G-9, G-11)
scan() {
	local mode=$1 rule=$2 fix=$3 pattern=$4 allowed=$5
	shift 5
	[ $# -gt 0 ] || return 0
	MODE=$mode RULE=$rule FIX=$fix PATTERN=$pattern ALLOWED=$allowed COMMENT=$COMMENT_LINE awk "$REPORT"'
		BEGIN { mode = ENVIRON["MODE"]; pattern = ENVIRON["PATTERN"]; allowed = ENVIRON["ALLOWED"]; comment = ENVIRON["COMMENT"] }
		FNR == 1 { above_is_comment = 0 }
		{
			is_comment = ($0 ~ comment)
			counts = (mode == "anywhere" || !is_comment) && !(mode == "uncommented" && above_is_comment)
			above_is_comment = is_comment
			line = $0
			if (allowed != "") gsub(allowed, "", line)
			if (counts && line ~ pattern) report(ENVIRON["RULE"], FILENAME, FNR, ENVIRON["FIX"])
		}
	' "$@"
}

# report_imports ALLOWED TESTABLE FILE...
# G-3 over FILE...: every import names a module in the space-separated ALLOWED, and `@testable import` names only
# TESTABLE, the module a test target tests (T-10).
report_imports() {
	local allowed=$1 testable=$2
	shift 2
	[ $# -gt 0 ] || return 0
	IMPORT_LINE=$IMPORT ALLOWED=$allowed TESTABLE=$testable COMMENT=$COMMENT_LINE awk "$REPORT"'
		BEGIN {
			comment = ENVIRON["COMMENT"]
			import_line = ENVIRON["IMPORT_LINE"]
			allowed = " " ENVIRON["ALLOWED"] " "
			listed = ENVIRON["ALLOWED"]
			gsub(/ /, ", ", listed)
		}
		$0 ~ comment { next }
		$0 ~ import_line {
			module = $0
			sub(import_line, "", module)
			sub(/^(typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+/, "", module)
			sub(/[^A-Za-z0-9_].*$/, "", module)
			if (index(allowed, " " module " ") == 0)
				report("G-3", FILENAME, FNR, "import " module " is not allowed here; this file may import only " listed " (SPEC 3.2)")
			else if ($0 ~ /@testable/ && module != ENVIRON["TESTABLE"])
				report("G-3", FILENAME, FNR, "@testable import " module ": a test target @testable-imports only the module it tests (SPEC T-10)")
		}
	' "$@"
}

# What each module of SPEC 3.2 may import, space separated.
allowed_imports() {
	case $1 in
		BurnieDomain) echo 'Foundation' ;;
		BurnieInterface) echo 'Foundation BurnieDomain' ;;
		BurnieProviders) echo 'Foundation BurnieDomain BurnieInterface' ;;
		BurnieApplication) echo 'Foundation Observation BurnieDomain BurnieInterface' ;;
		BurnieInfra) echo 'Foundation os AppKit CoreServices Network ServiceManagement SQLite3 Sparkle BurnieDomain BurnieInterface' ;;
		BurnieComponents) echo 'Foundation SwiftUI BurnieDomain BurnieInterface' ;;
	esac
}

# BurnieTestSupport builds on today's BurnieCore ports while the legacy layout exists (SPEC 18, question 6).
test_support_imports() {
	if module_exists "$LEGACY_CORE"; then
		echo 'Foundation BurnieDomain BurnieInterface BurnieCore'
	else
		echo 'Foundation BurnieDomain BurnieInterface'
	fi
}

# --- Rules, in the order of SPEC 16.2. Each function opens with "# <rule>:", which the check's test reads.

# G-3: every import is in its module's allowed list (SPEC 3.2).
check_g3_imports() {
	local module
	report_imports 'Foundation' '' $(files_in "$LEGACY_CORE")
	for module in BurnieDomain BurnieInterface BurnieProviders BurnieApplication BurnieInfra BurnieComponents; do
		report_imports "$(allowed_imports "$module")" '' $(files_in "^BurnieKit/Sources/$module/")
		report_imports "$TEST_TARGET_IMPORTS $module $(allowed_imports "$module")" "$module" \
			$(files_in "^BurnieKit/Tests/${module}Tests/")
	done
	report_imports "$(test_support_imports)" '' $(files_in "$TEST_SUPPORT")
	if module_exists "$APPLICATION"; then
		report_imports "$VIEW_IMPORTS" '' $(files_in "$APP" "$COMPOSITION|$PREVIEWS")
		report_imports "$VIEW_IMPORTS BurnieProviders" '' $(files_in "$PREVIEWS")
	fi
}

# G-4: one top-level type per file, named like the file; Type+Topic.swift files hold only extensions.
check_g4_one_type_per_file() {
	set -- $(files_in "$ANY")
	[ $# -gt 0 ] || return 0
	DECLARATION=$TYPE_DECLARATION awk "$REPORT"'
		BEGIN { declaration = ENVIRON["DECLARATION"] }
		FNR == 1 {
			expected = FILENAME
			sub(/^.*\//, "", expected)
			sub(/\.swift$/, "", expected)
			holds_extensions = index(expected, "+") > 0
		}
		$0 ~ declaration {
			name = $0
			sub(declaration, "", name)
			sub(/[^A-Za-z0-9_].*$/, "", name)
			if (holds_extensions)
				report("G-4", FILENAME, FNR, "declares " name " in an extension file; Type+Topic.swift holds only extensions, so move " name " to " name ".swift (SPEC 3.3)")
			else if (name != expected)
				report("G-4", FILENAME, FNR, "declares " name " in " expected ".swift; one top-level type per file, named like it: move " name " to " name ".swift or nest it (SPEC 3.3)")
		}
	' "$@"
}

# G-5: no switch on a provider and no comparison with a specific provider id outside BurnieProviders.
check_g5_specific_providers() {
	module_exists "$PROVIDERS" || return 0
	scan code G-5 "names a specific provider; outside BurnieProviders the difference is data in its descriptor or capabilities (SPEC 3.3)" \
		"$SPECIFIC_PROVIDER" '' \
		$(files_in "$ANY" "$PROVIDERS|$PROVIDERS_TESTS" | without_listed "$PROVIDER_ID_ALLOWLIST")
}

# G-6: the system clock, time zone and locale are read only in Infra and the composition root.
check_g6_system_time() {
	local fix="reads the system clock, time zone or locale; take now from the Clock port, today from the events and the locale from SwiftUI's environment (SPEC 3.3)"
	local exempt="$INFRA|$LEGACY_SYSTEM|$INFRA_TESTS|$COMPOSITION"
	scan code G-6 "$fix" "$SYSTEM_TIME" "$TIMELINE_START" $(files_in "$ANY" "$exempt|$ICON_BUTTON")
	scan code G-6 "$fix" "$SYSTEM_TIME" "$TIMELINE_START|$ICON_BUTTON_ANIMATION" $(files_in "$ICON_BUTTON" "$exempt")
}

# G-7: no print, NSLog or debugPrint, except the timings of the performance test.
check_g7_printing() {
	local fix="prints; record diagnostics through the DiagnosticsLog port (SPEC 3.3)"
	if ! module_exists "$INTERFACE"; then
		fix="prints; log counts and timings with os.Logger in BurnieSystem until the DiagnosticsLog port exists (SPEC 3.3)"
	fi
	scan code G-7 "$fix" "$PRINTING" '' $(files_in "$ANY" "$PERFORMANCE_TEST")
}

# G-8: no TODO, FIXME or XXX markers. The one rule that reads comment lines, where these markers live.
check_g8_markers() {
	scan anywhere G-8 "leaves a TODO, FIXME or XXX marker; finish the work or escalate it, never park it in code (SPEC 3.3)" \
		"$MARKERS" '' $(files_in "$ANY")
}

# G-9: no force unwrap after a call and no try! outside tests, unless the line above says why it can't fail.
check_g9_force_unwraps() {
	scan uncommented G-9 "force unwraps or uses try!; handle the failure, or say in a comment on the line above why it can't fail (SPEC 3.3)" \
		"$FORCE_UNWRAP" '' $(files_in "$ANY" "$TESTS")
}

# G-11: @unchecked Sendable only in Infra and test code, and there with a comment on the line above.
check_g11_unchecked_sendable() {
	local allowed="$INFRA|$LEGACY_SYSTEM|$TESTS"
	scan code G-11 "uses @unchecked Sendable outside Infra and test fakes; make the type Sendable or an actor (SPEC 3.3)" \
		"$UNCHECKED_SENDABLE" '' $(files_in "$ANY" "$allowed")
	scan uncommented G-11 "uses @unchecked Sendable without a comment on the line above naming the lock or queue that serializes its state (SPEC 3.3, X-8)" \
		"$UNCHECKED_SENDABLE" '' $(files_in "$allowed")
}

# D-2: Domain is values: no class, actor, async, Task or static var.
check_d2_pure_values() {
	scan code D-2 "brings state or concurrency into Domain; model it as a value and leave effects to Application (SPEC 4.1)" \
		"$STATE_OR_CONCURRENCY" '' $(files_in "$DOMAIN")
}

# D-3: no file system, network, process, defaults, bundle or notification types in the pure modules.
check_d3_no_io() {
	scan code D-3 "does I/O in a pure module; declare a port in BurnieInterface and implement it in Infra (SPEC 4.1, 5.2)" \
		"$IO_TYPES" '' $(files_in "$DOMAIN|$INTERFACE|$PROVIDERS|$APPLICATION")
	scan code D-3 "does I/O in BurnieCore; declare a port in BurnieCore/Ports and implement it in BurnieSystem (SPEC 4.1, 14.1)" \
		"$IO_TYPES" '' $(files_in "$LEGACY_CORE")
}

# D-6: no user-visible strings in Domain.
check_d6_no_copy() {
	scan code D-6 "spells user-visible text in Domain; copy lives in BurnieInterface's Presentation/ (SPEC 4.1)" \
		"$HAS_LETTERED_STRING" "$NOT_COPY" $(files_in "$DOMAIN")
}

# I-2: no shared mutable state in Interface: no class, actor, static var or global var.
check_i2_no_shared_state() {
	scan code I-2 "adds shared mutable state to Interface; use a struct, an enum or a static let (SPEC 5.1)" \
		"$SHARED_MUTABLE_STATE" '' $(files_in "$INTERFACE")
}

# P-1: providers log only through the DiagnosticsLog port.
check_p1_no_logger() {
	scan code P-1 "logs with os.Logger; a provider records through the DiagnosticsLog port it is given (SPEC 6.1)" \
		"$OS_LOGGER" '' $(files_in "$PROVIDERS")
}

# A-1: Application's only public types are AppModel and AppEnvironment, and only they have public members.
check_a1_application_api() {
	set -- $(files_in "$APPLICATION")
	[ $# -gt 0 ] || return 0
	OWNER=$APP_MODEL_DECLARATION PUBLIC_WORD=$PUBLIC COMMENT=$COMMENT_LINE awk "$REPORT"'
		BEGIN { owner = ENVIRON["OWNER"]; public_word = ENVIRON["PUBLIC_WORD"]; comment = ENVIRON["COMMENT"] }
		FNR == 1 { flush(); file = FILENAME; is_owner = 0 }
		$0 ~ comment { next }
		$0 ~ owner { is_owner = 1 }
		$0 ~ public_word {
			count++
			lines[count] = FNR
			# Members are indented, so a public column-0 declaration other than AppModel or AppEnvironment (a type, a
			# typealias, a function, a constant) fails even in their files.
			foreign[count] = ($0 ~ /^[^[:space:]]/ && $0 !~ owner)
		}
		END { flush() }
		function flush(   i) {
			for (i = 1; i <= count; i++)
				if (!is_owner || foreign[i])
					report("A-1", file, lines[i], "makes Application API public; only AppModel and AppEnvironment and their members are public, so make it internal (SPEC 7.1)")
			count = 0
		}
	' "$@"
}

# A-5: waits only through the Sleeper port, in every module below the app.
check_a5_no_waiting() {
	scan code A-5 "waits on its own; wait through the Sleeper port and read time from the Clock port (SPEC 7.1)" \
		"$OWN_WAITING" '' $(files_in "$DOMAIN|$INTERFACE|$PROVIDERS|$APPLICATION")
}

# C-4: colors and measurements come from DesignTokens, in Components and views.
check_c4_design_tokens() {
	module_exists "$COMPONENTS" || return 0
	scan code C-4 "uses a literal color or measurement; take it from DesignTokens, or a provider's color from its descriptor (SPEC 9.1)" \
		"$LITERAL_STYLE" '' $(files_in "$COMPONENTS|$APP" "$COMPOSITION|$DESIGN_TOKENS|$PREVIEW_VALUES")
}

# C-5: no literal user-visible text in Components and views.
check_c5_no_literal_text() {
	module_exists "$COMPONENTS" || return 0
	scan code C-5 "shows literal text; take it as a parameter or from Copy (SPEC 9.1)" \
		"$LITERAL_TEXT" "$STRING_ESCAPES" $(files_in "$COMPONENTS|$APP" "$COMPOSITION|$PREVIEW_VALUES")
}

# V-3: only the composition root imports BurnieInfra; previews may also import BurnieProviders.
check_v3_composition_imports() {
	scan code V-3 "imports BurnieInfra outside the composition root; let App/Composition build the adapters (SPEC 10.1)" \
		"$INFRA_IMPORT" '' $(files_in "$APP" "$COMPOSITION")
	scan code V-3 "imports BurnieProviders outside App/Composition and App/Previews; views get providers through AppModel (SPEC 10.1)" \
		"$PROVIDERS_IMPORT" '' $(files_in "$APP" "$COMPOSITION|$PREVIEWS")
}

run_rules() {
	check_g3_imports
	check_g4_one_type_per_file
	check_g5_specific_providers
	check_g6_system_time
	check_g7_printing
	check_g8_markers
	check_g9_force_unwraps
	check_g11_unchecked_sendable
	check_d2_pure_values
	check_d3_no_io
	check_d6_no_copy
	check_i2_no_shared_state
	check_p1_no_logger
	check_a1_application_api
	check_a5_no_waiting
	check_c4_design_tokens
	check_c5_no_literal_text
	check_v3_composition_imports
}

# --- Summary.

# The line run_rules is followed by, so a run that stopped on an error never reads as a pass.
readonly FINISHED='check-architecture: every rule ran'

# Passes the failures through, then ends with a summary on stderr and status 1, or an OK line for FILE_COUNT files.
# Without the FINISHED line the check broke halfway: status 2.
summarize() {
	awk -v finished_line="$FINISHED" -v file_count="$1" '
		$0 == finished_line { finished = 1; next }
		{ print; failures++ }
		END {
			fflush()
			if (!finished) {
				print "check-architecture: stopped before running every rule; see the error above" > "/dev/stderr"
				exit 2
			}
			if (failures == 0) {
				printf "check-architecture: OK, %d Swift files follow SPEC.md section 16.2\n", file_count
				exit 0
			}
			printf "check-architecture: %d failure%s; each line names its rule in SPEC.md and how to fix it\n", failures, (failures == 1 ? "" : "s") > "/dev/stderr"
			exit 1
		}
	'
}

main() {
	local root=${1:-}
	if [ -z "$root" ]; then
		root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel) || die "can't find the repo root; pass it as the first argument"
	fi
	[ -d "$root" ] || die "no such folder: $root"
	cd "$root"
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$root is not inside a git work tree"

	SWIFT_FILES=$(swift_files)
	readonly SWIFT_FILES
	{
		run_rules
		echo "$FINISHED"
	} | summarize "$(files_in "$ANY" | wc -l)"
}

main "$@"
