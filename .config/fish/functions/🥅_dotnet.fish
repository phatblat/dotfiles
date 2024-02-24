function 🥅_dotnet \
    --description 'Installs .NET tools and workpacks.'

    echo "🥅 dotnet"
    echo

    # Tools
    dotnet tool install --global dotnet-format
    # dotnet tool install --global dotnet-validate?
    dotnet tool install --global Redth.Net.Maui.Check

    # Workloads
    dotnet workload list
end
