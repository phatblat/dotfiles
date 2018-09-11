function chexe --description='Set executable permissions'
    set -l files *.sh
    chmod +x $files
end
