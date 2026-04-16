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

### Example workflow

```yaml
name: Convert notebook to PDF

on:
  push:
    branches: [main]
    paths:
      - "scripts/*.ipynb"
  workflow_dispatch:

jobs:
  convert-and-commit:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v6

      - name: Convert notebooks
        uses: amanda-amy-frost/jupyter-to-pdf-action@v1
        with:
          input_dirs: "scripts"
          output_dir: "."

      - name: Commit PDFs back to repo
        run: |
          git config user.name "Peter parker"
          git config user.email "spiderman@parkerphotography.com"
          git add *.pdf
          git commit -m "Update generated Jupyter notebook PDFs" ||
            echo "No changes to commit"
          git push
```
