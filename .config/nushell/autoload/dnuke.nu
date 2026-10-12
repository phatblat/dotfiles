# dnuke - Remove unused docker images not just dangling ones
export def --wrapped dnuke [...args] {
    ^docker system prune --all --force ...$args
}
