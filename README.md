# Jupyter Notebook to PDF GitHub Action

Converts Jupyter Notebooks (`.ipynb` files) into PDFs using [nbconvert](https://nbconvert.readthedocs.io/en/latest/) and a LaTeX backend. The entrypoint is written in PowerShell (but still on Linux), as that's just what I know best.

## Features

- Dry-run mode
- Multiple (optional) input directories
- Configurable output directory
- Optional automatic notebook execution before conversion

## Usage

### Inputs

All inputs are strings and are optional.

- `input_dirs`
  - Comma-separated list of directories to search for `*.ipynb` files (recursive). Empty list means search entire repo.
  - Default: `""`
- `output_dir`
  - Directory where PDFs will be saved.
  - Default `"pdf"`
- `dry_run`
  - If true, list the notebooks but do not execute or convert them.
  - Default: `"false"`
- `execute`:
  - If true, run the notebooks before converting them.
  - Default: `"true"`
-  packages:
  - Space-separated list of Python packages to install with pip.
  - Default: `""`

### Example workflow

```yaml
name: Convert notebook to PDF

permissions:
  contents: write

on:
  push:
    branches: [main]
    paths:
      - "scripts/*.ipynb"
      - ".github/workflows/convert-notebook.yml"
  workflow_dispatch:

jobs:
  convert-and-commit:
    if: github.actor != 'github-actions[bot]'
    runs-on: ubuntu-latest
    env:
        DRY_RUN: "false"

    steps:
      - uses: actions/checkout@v6

      - name: Convert notebooks
        uses: amanda-amy-frost/jupyter-to-pdf-action@v1
        with:
          dry_run: ${{ env.DRY_RUN }}
          input_dirs: "scripts"
          output_dir: "."
          execute: "true"
          requirements: "requirements.txt"

      - name: Commit PDF back to repo
        if: ${{ env.DRY_RUN == 'false' }}
        run: |
          git config user.name "Peter Parker"
          git config user.email "spiderman@parkerpictures.web"
          echo "Searching for PDFs recursively..."
          find "$GITHUB_WORKSPACE" -type f -name "*.pdf" -print0 |
            xargs -0 git add
          git commit -m "Update analysis notebook PDF" ||
            echo "No changes to commit"
          git push
```
