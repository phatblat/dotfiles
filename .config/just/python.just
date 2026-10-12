# python — uv-managed tools and Python type-checking

# Lists installed tools managed by uv
[group('python')]
list-uv:
    mise exec -- uv tool list

# Lists outdated uv tools
[group('python')]
outdated-uv:
    mise exec -- uv tool list --outdated

# Upgrades all uv-managed tools
[group('python')]
upgrade-uv-tools:
    mise exec -- uv tool upgrade --all

# CI: check.yml (lint job)
# Type-checks Python with basedpyright; scope and mode come from pyproject's [tool.basedpyright]
[group('python')]
typecheck-python:
    @echo "Type-checking Python scripts..."
    basedpyright --project {{ justfile_directory() }} --warnings
