# dlogs - Fetch the logs of a docker container
export def --wrapped dlogs [...args] {
    ^docker logs --follow ...$args
}
