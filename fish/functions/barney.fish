function barney
    # Default to current working directory
    set -l target_dir "."

    # If an argument was passed, use it instead
    if test (count $argv) -gt 0
        set target_dir $argv[1]
    end

    # Check if the directory actually exists before running
    if not test -d $target_dir
        echo "Error: '$target_dir' is not a valid directory."
        return 1
    end

    # Run copyparty with read/write access, show QR code
    uvx copyparty@latest --qr -v $target_dir::rw
end