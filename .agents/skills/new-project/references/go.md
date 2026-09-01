# Go Reference

## 1. Pin tools

```bash
mise use --pin go@latest just@latest
```

## 2. `mise.toml`

After the pin step, append the `[deps.go]` and `[settings]` blocks:

```toml
[tools]
go = "<pinned>"
just = "<pinned>"

# `mise deps` runs `go mod download` when go.mod or go.sum changes.
[deps.go]

[settings]
# `[deps.*]` is experimental. Declaring it here means the project works without
# the developer's global mise config enabling it.
experimental = true
```

Then run `mise trust && mise fmt`.

## 3. Native init

Ask the user for the module path; default to `github.com/phatblat/<name>` when
they don't give one.

```bash
go mod init <module-path>
```

Then write `main.go` with a `greeting() string` helper so there is something
to test:

```go
package main

import "fmt"

func greeting() string {
	return "Hello, world!"
}

func main() {
	fmt.Println(greeting())
}
```

## 4. Test

`main_test.go`:

```go
package main

import "testing"

func TestGreeting(t *testing.T) {
	if got := greeting(); got != "Hello, world!" {
		t.Errorf("greeting() = %q, want %q", got, "Hello, world!")
	}
}
```

## 5. `.gitignore`

```gitignore
/<name>
/vendor/
```

Replace `<name>` with the built binary name (the project name, unless the
module's `main` package builds to a different output).

## 6. `justfile`

Same header and `_default` block as the Python template (see
`references/python.md`). 11 non-default recipes, so grouping applies.

- `deps` (configuration): `mise install` then `mise deps`
- `format` (configuration): `go fmt ./...` then `mise fmt` then `just --fmt`
- `clean` (configuration): `go clean ./...`
- `outdated` (configuration): `-mise outdated --local --bump` then
  `-go list -u -m all`
- `upgrade` (configuration): `mise upgrade --local --bump --yes` then
  `go get -u ./...` then `go mod tidy`
- `build` (build): `go build ./...`
- `run` (build): `go run .`
- `format-check` (checks): **must** be a `[script]` recipe — `gofmt -l` exits
  `0` even when files are unformatted, so a plain recipe line can't fail on
  it. Check for non-empty output explicitly:

  ```just
  [group('checks')]
  [script]
  format-check:
      set -euo pipefail
      unformatted=$(gofmt -l .)
      if [ -n "$unformatted" ]; then
          echo "gofmt would reformat:" >&2
          echo "$unformatted" >&2
          exit 1
      fi
      mise fmt --check
      just --fmt --check
  ```

- `lint` (checks): `go vet ./...` — not `golangci-lint`, since `vet` ships
  with the Go toolchain and this scaffold does not pin a linter the project
  would otherwise not have.
- `check` (checks): `check: format-check lint test`
- `test` (tests): `go test ./...`

Full file:

```just
set ignore-comments
set script-interpreter := ['bash', '-eu']
set unstable

[default]
_default:
    @just --list

#
# configuration group recipes
#

# Install pinned tools and download dependencies
[group('configuration')]
deps:
    mise install
    mise deps

# Format source, mise config, and the justfile
[group('configuration')]
format:
    go fmt ./...
    mise fmt
    just --fmt

# Remove build cache
[group('configuration')]
clean:
    go clean ./...

# Report tools and dependencies with newer versions available
[group('configuration')]
outdated:
    -mise outdated --local --bump
    -go list -u -m all

# Upgrade pinned tools and dependencies to their latest versions
[group('configuration')]
upgrade:
    mise upgrade --local --bump --yes
    go get -u ./...
    go mod tidy

#
# build group recipes
#

# Build every package
[group('build')]
build:
    go build ./...

# Run the application
[group('build')]
run:
    go run .

#
# checks group recipes
#

# Verify formatting without writing changes
[group('checks')]
[script]
format-check:
    set -euo pipefail
    unformatted=$(gofmt -l .)
    if [ -n "$unformatted" ]; then
        echo "gofmt would reformat:" >&2
        echo "$unformatted" >&2
        exit 1
    fi
    mise fmt --check
    just --fmt --check

# Lint with go vet
[group('checks')]
lint:
    go vet ./...

# Run every gate: formatting, lint, tests
[group('checks')]
check: format-check lint test

#
# tests group recipes
#

# Run the test suite
[group('tests')]
test:
    go test ./...
```
