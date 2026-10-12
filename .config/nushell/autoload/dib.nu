# dib - Build an image from a Dockerfile
export def dib [...args] {
    ^docker image build ...$args
}
