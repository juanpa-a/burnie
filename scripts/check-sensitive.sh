#!/bin/bash
# Fails when a change would put sensitive data into this public repo (SPEC.md 16.6, G-12, root AGENTS.md).
#
# Usage:
#   scripts/check-sensitive.sh         scans the lines the staged diff adds (git diff --cached)
#   scripts/check-sensitive.sh --all   scans every file git tracks or would track (make check, so CI scans the tree)
#
# Prints one line per finding, "SENSITIVE <rule>: <file>:<line>" (just "<file>" for a key file), and never the value
# it matched. Skips binary files. Exits 1 on any finding, 2 on a usage or git error, 0 otherwise.
#
# Rules, and what each allows (allowed names and addresses ignore case):
#   home-path         /Users/<name> or /home/<name>, with <name> starting with a letter, digit or underscore; also
#                     JSON-escaped (\/Users\/<name>, as JSONEncoder writes paths) and the way Claude Code names a
#                     project folder (-Users-<name>-…). Allows the placeholder names of invented test data and docs:
#                     dev, tester, user, name, example, Shared, Library. Tests use /home itself as a fake home folder,
#                     so /home/Library/… and /home/.claude/… are paths inside it.
#   email             an address, except GitHub noreply ones (…@users.noreply.github.com, noreply@github.com), the
#                     commit attribution noreply@anthropic.com, and reserved domains that can't be real mailboxes
#                     (example.com, example.org, example.net and their subdomains; the .example, .test, .invalid and
#                     .localhost TLDs). An image's scale suffix (background@2x.png) isn't an address.
#   token             sk-ant- and 20 or more token characters; Bearer (or bearer) and 30 or more; a JWT (three
#                     dot-separated base64url segments, the first starting with eyJ) outside the fixtures listed in
#                     is_jwt_fixture, which hold invented ones.
#   private-key       a PEM private key header (-----BEGIN … PRIVATE KEY-----).
#   key-file          a .p8 or .p12 file, whatever it holds.
#   certificate-hash  a 40-hex string on a line that mentions codesign, code_sign or identity.

set -u
export LC_ALL=C

# What the rules look for, as extended regexes. Each is written so it never matches this file's own text,
# which --all scans like any other.
readonly home_path='\\?/(Users|home)\\?/[A-Za-z0-9_][A-Za-z0-9._-]*|-Users-[A-Za-z0-9_][A-Za-z0-9_]*'
readonly email_address='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
readonly anthropic_token='sk-ant-[A-Za-z0-9_-]{20,}'
readonly bearer_token='[Bb]earer [A-Za-z0-9._~+/=-]{30,}'
readonly jwt='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
readonly private_key_header='-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----'
readonly hex40='(^|[^0-9A-Fa-f])[0-9A-Fa-f]{40}([^0-9A-Fa-f]|$)'

# The temporary folder of this run, removed on exit.
work=

main() {
	local scan
	if [ $# -eq 0 ]; then
		scan=scan_staged_diff
	elif [ $# -eq 1 ] && [ "$1" = --all ]; then
		scan=scan_all_files
	else
		fail "usage: scripts/check-sensitive.sh [--all]"
	fi

	local root
	root=$(git rev-parse --show-toplevel) || fail "not inside a git repository"
	cd "$root" || fail "can't enter the repository's root"
	work=$(mktemp -d "${TMPDIR:-/tmp}/check-sensitive.XXXXXX") || fail "can't create a temporary folder"
	trap 'rm -rf "$work"' EXIT

	local status=0
	"$scan" > "$work/findings"
	if [ -s "$work/findings" ]; then
		cat "$work/findings"
		echo "Replace each value with an invented one, or keep it out of the repo (G-12, SPEC.md 16.6)."
		status=1
	fi
	echo "Reading git diff --cached by eye before every commit stays mandatory (root AGENTS.md)."
	return $status
}

fail() {
	echo "check-sensitive: $1" >&2
	exit 2
}

# --all: every file git tracks or would track. A deleted file has nothing left to read, but its name still counts.
# A symlink is committed as the path it points to, so that path is what gets scanned, never the file behind it.
scan_all_files() {
	local path
	git ls-files -z --cached --others --exclude-standard > "$work/files" || fail "can't list the repository's files"
	: > "$work/regular"
	while IFS= read -r -d '' path; do
		check_key_file "$path"
		if [ -L "$path" ]; then
			readlink "$path" > "$work/link"
			scan_file "$work/link" "$path"
		else
			printf '%s\0' "$path" >> "$work/regular"
		fi
	done < "$work/files"
	write_candidate_files > "$work/candidates"
	while IFS= read -r -d '' path; do
		scan_file "$path" "$path"
	done < "$work/candidates"
}

# Writes the files that match any pattern, so the rules read only those: one grep over the tree instead of one per
# rule and file. /dev/null keeps grep off stdin when there's nothing to scan; -s skips the deleted files.
write_candidate_files() {
	xargs -0 grep -lsIE --null -e "$home_path" -e "$email_address" -e "$anthropic_token" -e "$bearer_token" \
		-e "$jwt" -e "$private_key_header" -e "$hex40" -- /dev/null < "$work/regular"
}

# Default: the lines the staged diff adds. -M never reports copies, so only a rename (R) comes with a second path.
scan_staged_diff() {
	local status renamed_from path
	git diff --cached --name-status -z -M --diff-filter=AMRT > "$work/staged" || fail "can't read the staged diff"
	while IFS= read -r -d '' status; do
		renamed_from=
		case $status in
			R*) IFS= read -r -d '' renamed_from ;;
		esac
		IFS= read -r -d '' path
		check_key_file "$path"
		write_staged_additions "$path" "$renamed_from" > "$work/added"
		scan_file "$work/added" "$path"
	done < "$work/staged"
}

# Writes the lines the staged diff of $1 (renamed from $2, when given) adds, each at its line number in the staged
# file and blank lines in between, so grep -n on the result reports the staged file's line numbers.
write_staged_additions() {
	git --literal-pathspecs diff --cached -M -U0 --inter-hunk-context=0 --no-color --no-ext-diff --no-textconv -- "$1" ${2:+"$2"} \
		> "$work/diff" || fail "can't read the staged diff of $1"
	awk '
		# A hunk header (@@ -12,3 +15,4 @@) gives the staged line number of its first added line.
		/^@@ / { match($0, /\+[0-9]+/); line = substr($0, RSTART + 1, RLENGTH - 1); in_hunk = 1; next }
		# Before the first hunk, a line starting with + is the header (+++ b/<path>), not an added line.
		in_hunk && /^\+/ {
			while (written < line - 1) { print ""; written++ }
			print substr($0, 2); written++; line++
		}
	' "$work/diff"
}

# Prints the findings in file $1 as file $2: they differ in staged mode, where $1 holds only the added lines.
scan_file() {
	home_path_lines "$1" | print_findings home-path "$2"
	email_lines "$1" | print_findings email "$2"
	token_lines "$1" "$2" | print_findings token "$2"
	private_key_lines "$1" | print_findings private-key "$2"
	certificate_hash_lines "$1" | print_findings certificate-hash "$2"
}

# Turns the line numbers on stdin into one finding of rule $1 in file $2 per line.
print_findings() {
	local line
	sort -nu | while read -r line; do
		printf 'SENSITIVE %s: %s:%s\n' "$1" "$2" "$line"
	done
}

# Each rule below prints the numbers of the lines of file $1 where it fires, in any order and maybe repeated.

home_path_lines() {
	lines_matching_except "$1" "$home_path" '(\\?/(Users|home)\\?/|-Users-)(dev|tester|user|name|example|Shared|Library)'
}

email_lines() {
	local noreply='[^@]+@users\.noreply\.github\.com|noreply@github\.com|noreply@anthropic\.com'
	local reserved='[^@]+@([^@]+\.)?example\.(com|org|net)|[^@]+@[^@]+\.(example|test|invalid|localhost)'
	local image_scale='[^@]+@[0-9]+x\.(png|jpe?g|gif|tiff?|pdf|heic|svg|webp)'
	lines_matching_except "$1" "$email_address" "$noreply|$reserved|$image_scale"
}

# $2 is the file's path in the repo, for the JWT fixture allowlist.
token_lines() {
	lines_matching "$1" "$anthropic_token"
	lines_matching "$1" "$bearer_token"
	if ! is_jwt_fixture "$2"; then
		lines_matching "$1" "$jwt"
	fi
}

# The fixtures that hold invented JWTs on purpose.
is_jwt_fixture() {
	case $1 in
		BurnieKit/Tests/BurnieCoreTests/Fixtures/cursor-jwt.txt) return 0 ;;
	esac
	return 1
}

private_key_lines() {
	lines_matching "$1" "$private_key_header"
}

certificate_hash_lines() {
	grep -nIiE -e 'code_?sign|identity' -- "$1" | grep -E -e "$hex40" | cut -d: -f1
}

# Goes by the name alone, so it prints the finding itself: there's no line to point at.
check_key_file() {
	case $1 in
		*.[pP]8 | *.[pP]12) printf 'SENSITIVE key-file: %s\n' "$1" ;;
	esac
}

# Prints the numbers of the lines of file $1 that match the extended regex $2.
lines_matching() {
	grep -nIE -e "$2" -- "$1" | cut -d: -f1
}

# Like lines_matching, but leaves out each match that the extended regex $3 matches whole, ignoring case.
lines_matching_except() {
	grep -noIE -e "$2" -- "$1" | grep -viE -e "^[0-9]+:($3)\$" | cut -d: -f1
}

main "$@"
