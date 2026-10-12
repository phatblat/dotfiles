# dit - Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
export def dit [...args] {
    ^docker image tag ...$args
}
