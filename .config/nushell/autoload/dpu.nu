# dpu - Builds, (re)creates, starts, and attaches to containers for a service
export def --wrapped dpu [...args] {
    ^docker compose up --detach ...$args
}
