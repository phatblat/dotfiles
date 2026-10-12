# dnuke - Remove unused docker images not just dangling ones
export def dnuke [...args] {
    ^docker system prune --all --force ...$args
}
