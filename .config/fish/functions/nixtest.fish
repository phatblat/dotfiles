function nixtest \
    --description 'Tests a Nix installation'

    nix-instantiate '<nixpkgs>' -A hello
end
