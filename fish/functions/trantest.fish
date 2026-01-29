#!/usr/bin/env fish
# Test transfer speed to an argument directory/device

function trantest -d "Test transfer speed to directory/device"
    set -l target $argv[1]

    if test -z "$target"
        echo "Usage: trantest <directory>"
        return 1
    end

    dd if=/dev/zero of="$target/test.img" bs=1G count=1 oflag=dsync
    rm "$target/test.img"
end
