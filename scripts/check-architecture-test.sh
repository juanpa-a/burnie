#!/bin/bash
#
# check-architecture-test.sh: the architecture check's own test (SPEC.md section 16.2).
#
# Usage: scripts/check-architecture-test.sh
#
# Runs check-architecture.sh over each sample root in check-architecture-samples/ and holds every sample to the first
# line it starts with:
#   // expect: G-6 C-4    these rules fail on the file, and no others
#   // expect: none       nothing fails on the file
# It also checks that every failure line has the documented format, that a root with failures exits 1, and that every
# rule the check documents (the "# <rule>: ..." comments over its functions) has a sample that fails with it.
# Prints one line per mismatch and exits 1, or one summary line and exits 0. Plain bash 3.2.

set -euo pipefail
export LC_ALL=C

HERE=$(cd "$(dirname "$0")" && pwd)
readonly HERE
readonly CHECK="$HERE/check-architecture.sh"
readonly SAMPLES="$HERE/check-architecture-samples"
readonly FAILURE_LINE='^SPEC [A-Z]-[0-9]+: [^:]+:[0-9]+: .+$'
readonly EXPECT_LINE='^// expect: ([A-Z]-[0-9]+( [A-Z]-[0-9]+)*|none)$'

mismatches=0
sample_count=0
declared_rules=''

mismatch() {
	printf 'check-architecture-test: %s\n' "$1"
	mismatches=$((mismatches + 1))
}

# True when the newline-separated LIST holds ITEM.
contains() {
	case $'\n'"$1"$'\n' in
		*$'\n'"$2"$'\n'*) return 0 ;;
		*) return 1 ;;
	esac
}

# The Swift samples under ROOT, relative to it, one per line.
sample_files() {
	(cd "$1" && find . -type f -name '*.swift') | sed 's|^\./||' | sort
}

# The rules FILE declares on its first line, one per line; nothing for "none".
expected_rules() {
	awk 'NR == 1 && sub(/^\/\/ expect: /, "") { for (i = 1; i <= NF; i++) if ($i != "none") print $i } { exit }' "$1" | sort -u
}

# The rules OUTPUT reports for FILE, one per line.
reported_rules() {
	printf '%s\n' "$2" | awk -v file="$1" 'substr($3, 1, length(file) + 1) == file ":" { sub(/:$/, "", $2); print $2 }' | sort -u
}

# The rules check-architecture.sh checks, one per line.
checked_rules() {
	sed -n 's/^# \([A-Z]-[0-9]*\): .*/\1/p' "$CHECK" | sort -u
}

# Every non-empty line of OUTPUT reads "SPEC <rule>: <file>:<line>: <fix>".
check_format() {
	local name=$1 output=$2 line
	while IFS= read -r line; do
		if [ -n "$line" ] && ! printf '%s\n' "$line" | grep -qE "$FAILURE_LINE"; then
			mismatch "$name: malformed failure line: $line"
		fi
	done <<<"$output"
}

# The rules OUTPUT reports for FILE are exactly the ones its first line declares.
check_sample() {
	local name=$1 root=$2 file=$3 output=$4 expected reported rule
	sample_count=$((sample_count + 1))
	if ! head -n 1 "$root/$file" | grep -qE "$EXPECT_LINE"; then
		mismatch "$name/$file: the first line must be \"// expect: <rule IDs>\" or \"// expect: none\""
		return 0
	fi
	expected=$(expected_rules "$root/$file")
	reported=$(reported_rules "$file" "$output")
	declared_rules="$declared_rules"$'\n'"$expected"
	for rule in $expected; do
		contains "$reported" "$rule" || mismatch "$name/$file: expected $rule, which didn't fire"
	done
	for rule in $reported; do
		contains "$expected" "$rule" || mismatch "$name/$file: $rule fired, but the sample doesn't expect it"
	done
}

# Runs the check over ROOT, a folder laid out like the repo, and holds each of its samples to its declaration.
check_root() {
	local root=$1 name output status file
	name=${root##*/}
	status=0
	output=$("$CHECK" "$root" 2>/dev/null) || status=$?
	[ "$status" -eq 1 ] || mismatch "$name: check-architecture.sh exited $status; a root with failures must exit 1"
	check_format "$name" "$output"
	for file in $(sample_files "$root"); do
		check_sample "$name" "$root" "$file" "$output"
	done
}

# Every rule the check documents has a sample that fails with it.
check_rule_coverage() {
	local rule
	for rule in $(checked_rules); do
		contains "$declared_rules" "$rule" || mismatch "no sample fails with $rule; add one to check-architecture-samples/"
	done
}

main() {
	local root roots=0
	for root in "$SAMPLES"/*/; do
		check_root "${root%/}"
		roots=$((roots + 1))
	done
	check_rule_coverage
	if [ "$mismatches" -gt 0 ]; then
		printf 'check-architecture-test: FAILED, mismatches: %d\n' "$mismatches" >&2
		exit 1
	fi
	printf 'check-architecture-test: OK, %d samples in %d roots fail exactly as declared\n' "$sample_count" "$roots"
}

main
