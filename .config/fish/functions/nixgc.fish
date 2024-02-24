function nixgc \
    --description 'Runs nix garbage collection and optimisation'

    nix-collect-garbage -d
    nix-store --optimise
end
