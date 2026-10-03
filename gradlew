#!/bin/sh
#
# Stub gradle wrapper script — replaced on first CI run by `./gradlew wrapper`.
# This file allows local development if the user has gradle installed.
#
DIR="$(cd "$(dirname "$0")" && pwd)"
exec gradle -p "$DIR" "$@"
