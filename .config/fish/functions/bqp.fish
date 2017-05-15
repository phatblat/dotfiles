# Query brew info, pretty print resulting JSON
function bqp
    bq $argv | prettyjson
end
