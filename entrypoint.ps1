Write-Host "=== Jupyter PDF Conversion Action ===" -ForegroundColor Blue
Write-Host "Input directories: $env:INPUT_INPUT_DIRS"
Write-Host "Output directory: $env:INPUT_OUTPUT_DIR"
Write-Host "Dry run: $env:INPUT_DRY_RUN"
Write-Host "Execute notebooks: $env:INPUT_EXECUTE"
Write-Host "Input requirements path: $env:INPUT_REQUIREMENTS"
Write-Host "=====================================" -ForegroundColor Blue

# Normalize booleans
$DryRun = $env:INPUT_DRY_RUN.ToLower() -eq "true"
$ExecBook = $env:INPUT_EXECUTE.ToLower() -eq "true"
$InputDirs = $env:INPUT_INPUT_DIRS

# Default output directory
if (-not $env:INPUT_OUTPUT_DIR) {
    $OutputDir = "pdf"
} else {
    $OutputDir = $env:INPUT_OUTPUT_DIR
}

if ($env:INPUT_REQUIREMENTS -and (Test-Path $env:INPUT_REQUIREMENTS)) {
    Write-Host "Installing Python dependencies from $env:INPUT_REQUIREMENTS"
    pip install -r $env:INPUT_REQUIREMENTS
}

# Determine notebook list
$Notebooks = @()

if ([string]::IsNullOrWhiteSpace($InputDirs)) {
    Write-Host "Searching entire repository for notebooks..."
    $Notebooks = Get-ChildItem -Recurse -Filter *.ipynb |
        Select-Object -ExpandProperty FullName
} else {
    Write-Host "Searching in specified directories..."
    $Directories = $InputDirs -split ","
    foreach ($Dir in $Directories) {
        if (Test-Path $Dir) {
            $FoundBooks = Get-ChildItem -Recurse -Path $Dir -Filter *.ipynb |
                Select-Object -ExpandProperty FullName
            $Notebooks += $FoundBooks
        } else {
            Write-Warning "Directory not found: $Dir"
        }
    }
}

# Make sure to handle the edge case first
if ($Notebooks.Count -eq 0) {
    Write-Warning "No notebooks found. Exiting."
    exit 0
}

Write-Host "Found $($Notebooks.Count) notebook(s):" -ForegroundColor Green
$Notebooks | ForEach-Object { Write-Host "- $_" }

if ($DryRun) {
    "Dry run enabled — no execution or conversion will be performed." |
        Write-Host -ForegroundColor Blue
    exit 0
}

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    Write-Host "Creating output directory: $OutputDir" -ForegroundColor Green
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Convert each notebook
foreach ($Book in $Notebooks) {
    Write-Host "Processing: $Book"

    if ($ExecBook) {
        $ExecFlag = "--execute"
    } else {
        $ExecFlag = ""
    }

    try {
        jupyter nbconvert `
            --to pdf `
            $ExecFlag `
            $Book `
            --output-dir $OutputDir

        Write-Host "Successfully converted: $Book" -ForegroundColor Green
    } catch {
        Write-Error "Failed to convert ${Book}: $_"
    }
}

Write-Host "=== Conversion complete ===" -ForegroundColor Blue
