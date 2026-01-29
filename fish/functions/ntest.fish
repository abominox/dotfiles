#!/usr/bin/env fish
# Test nginx conf and restart service if successful

function ntest -d "Test nginx config and restart if successful"
    sudo nginx -t; and sudo service nginx restart; and sudo service nginx status
end
