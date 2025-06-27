function chat \
    --description='chat' \
    --argument-names message

    if test -z $argname
        set message hello
    end

    curl --progress-bar \
        http://localhost:1234/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{
        "model": "qwen/qwen3-235b-a22b",
        "messages": [
        { "role": "system", "content": "Always answer in rhymes. Today is Thursday" },
        { "role": "user", "content": "$message" }
        ],
        "temperature": 0.7,
        "max_tokens": -1,
        "stream": false
    }' |
    jq -r .choices[0].message.content |
    sed '/<think>/,/<\/think>/d'

end
