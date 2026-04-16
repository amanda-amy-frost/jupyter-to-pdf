Write-Host "=== Jupyter PDF Conversion Action ===" -ForegroundColor Blue
Write-Host "Input directories: $env:INPUT_DIRS"
Write-Host "Output directory: $env:OUTPUT_DIR"
Write-Host "Dry run: $env:DRY_RUN"
Write-Host "Execute notebooks: $env:EXECUTE"
Write-Host "=====================================" -ForegroundColor Blue

# Normalize booleans
$DryRun = $env:DRY_RUN.ToLower() -eq "true"
$ExecBook = $env:EXECUTE.ToLower() -eq "true"

# Default output directory
if (-not $env:OUTPUT_DIR) {
    $OutputDir = "pdf"
} else {
    $OutputDir = $env:OUTPUT_DIR
}

# Determine notebook list
$Notebooks = @()

if ([string]::IsNullOrWhiteSpace($env:INPUT_DIRS)) {
    Write-Host "Searching entire repository for notebooks..."
    $Notebooks = Get-ChildItem -Recurse -Filter *.ipynb |
        Select-Object -ExpandProperty FullName
} else {
    Write-Host "Searching in specified directories..."
    $Directories = $env:INPUT_DIRS -split ","
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

    # Validate JSON before conversion
    # Do this in particular so the CI test can succeed
    try {
        Get-Content $Book -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Write-Warning "Skipping invalid notebook (JSON parse failed): $Book"
        continue # Go immediately to next book
    }

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
