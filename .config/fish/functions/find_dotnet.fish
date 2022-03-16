function find_dotnet \
    --description='Locates all copies of the dotnet command'

    find / -type f -name dotnet 2>/dev/null
end
