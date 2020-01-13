function pbjup --description='Upgrade personal jenkins formula and restart service'
    brew update
    brew upgrade pbjenkins
    #brew services list
    echo "♻️ 👷🏻‍♂️ Restarting jenkins using admin privileges"
    #sudo brew services restart pbjenkins
    sudo launchctl kickstart -kp system/pbjenkins
end
