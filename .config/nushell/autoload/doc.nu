# doc - Quickly launch docker containers in the current dir
export def doc [image_name: string, image_version: string = "latest"] {
    ^docker run --rm --privileged --interactive --tty --volume $"($env.PWD):/src" --workdir "/src" $"($image_name):($image_version)"
}
