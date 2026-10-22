#!/bin/bash
set -e

echo "Cleaning up build artifacts..."

# Remove directories
rm -rf iso_root .zig-cache .zig-out

# Remove files
rm -f tinosze.iso

echo "Cleanup complete."