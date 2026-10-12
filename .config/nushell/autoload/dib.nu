# dib - Build an image from a Dockerfile
export def --wrapped dib [...args] {
    ^docker image build ...$args
}
