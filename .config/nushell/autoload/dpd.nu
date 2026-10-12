# dpd - Stop containers and remove containers, networks, volumes, and images created by up
export def --wrapped dpd [...args] {
    ^docker compose down ...$args
}
