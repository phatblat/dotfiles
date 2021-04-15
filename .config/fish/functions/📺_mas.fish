function 📺_mas \
    --description='Manage Mac App Store apps'

    echo "📺 mas"
    echo

    echo "Updating Mac App Store apps"

    echo using mas (mas version)

    echo
    echo "🏬 Mac App Store account"
    mas account

    echo
    echo "🔎 Checking macOS system updates"
    mas outdated

    echo
    echo "⬆️ Updating macOS system software"
    mas upgrade
end
