# dlogs - Fetch the logs of a docker container
export def dlogs [...args] {
    ^docker logs --follow ...$args
}
