#!/usr/bin/env fish
# Activate virtualenv easier

function activate -d "Activate Python virtualenv"
    if test -f env/bin/activate.fish
        source env/bin/activate.fish
    else if test -f .env/bin/activate.fish
        source .env/bin/activate.fish
    else
        echo "No virtualenv found (env/ or .env/)"
        return 1
    end
end
