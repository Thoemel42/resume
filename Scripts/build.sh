#!/usr/bin/env sh

# Build PDF files for each Markdown file in the content directory
# and place them in the output directory.

################################################################################
## Include functions
################################################################################
. Scripts/functions.sh


################################################################################
## Variables
################################################################################

# Get current date in format DD.MM.YYYY
document_date=$(date +%d.%m.%Y)

# Get current year in format YYYY
document_date_year=$(date +%Y)

# Get latest git tag
document_git_tag=$(git describe --tags --abbrev=0)

# Load dot env file with variables
export $(grep -v '^#' .env | xargs)


################################################################################
## Environment specific replacements commands
################################################################################

if [ $CI ]; then
	sedcmd="sed -i"
else
	sedcmd="sed -i ''"
fi


################################################################################
## Requirement
################################################################################

# Check if Docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo "🚨\tDocker is not installed. Please install Docker!"
  exit 1
fi
# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "🚨\tDocker is not running. Please start Docker!"
  exit 1
fi

# Check if sed is installed
if ! [ -x "$(command -v sed)" ]; then
  echo "🚨\tSed is not installed. Please install Sed!"
  exit 1
fi

# Pull docker image ghcr.io/vergissberlin/pandoc-eisvogel-de from GitHub Container Registry if it doesn't exist
if ! docker image inspect ghcr.io/vergissberlin/pandoc-eisvogel-de > /dev/null 2>&1; then
    echo "👉\tPull docker image ghcr.io/vergissberlin/pandoc-eisvogel-de from GitHub Container Registry"
    docker pull ghcr.io/vergissberlin/pandoc-eisvogel-de
fi


################################################################################
## Prepare
################################################################################

# Create temporary directory
mkdir -p Temp

# Copy all Markdown files from the content directory to the temporary directory
# cp -R Content/* Temp

# Create the output directory if it doesn't exist and delete all files in it
mkdir -p Results
rm -rf Results/*


################################################################################
## Modifier
################################################################################

# Replace some characters in the Markdown files which are not supported by Pandoc
# and place the modified files in the temporary directory
echo "✅\tFilter and replace characters in Markdown files"
for file in Temp/*.md; do
    sh Scripts/filter.sh ${file}
    sh Scripts/replace.sh ${file}
done

# Delete files in temporary directory which are not Markdown files
find Temp -type f ! -name '*.md' -delete

################################################################################
## Generate Documents
################################################################################

## Generate separate PDF files for each Markdown file in the content directory
echo "\n✅\tGenerate PDF for each file"

# Generate PDF files
for file in Content/*.md; do
  # Check if $file is a file
  if [ -f "$file" ]; then
    # Get the filename without the extension
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    # Strip leading numbers and following dash from filename
    filename=$(echo $filename | sed 's/^[0-9]-*//')
    # Generate title from filename with first letter uppercase
    title="cv"
    echo "👉\tBuild PDF for \"${title}\""
    docker run -v $PWD:/data ghcr.io/vergissberlin/pandoc-eisvogel-de ${file} \
      -o Results/${FILENAME}-${filename}.pdf \
      --defaults Template/Config/defaults-pdf-single.yml \
      --metadata-file Template/Config/metadata-pdf.yml \
      -V title="${title}" \
      -V author="$AUTHOR" \
      -V footer-center="v$document_git_tag" \
      -V date="$document_date";
  fi
done

# Generate a single PDF file from all Markdown files in the content directory
echo "\n✅\tGenerate documents for combined documents"
echo "👉\tGenerate PDF for all files"
cat Temp/*.md | docker run -i -v $PWD:/data ghcr.io/vergissberlin/pandoc-eisvogel-de \
  -o Results/resume-${FILENAME}.pdf \
  --defaults Template/Config/defaults-pdf.yml \
  --metadata-file Template/Config/metadata-pdf.yml \
  -V author="$AUTHOR" \
  -V description="Resume by ${AUTHOR}" \
  -V rights="© ${document_date_year} ${NAME}, CC BY-NC" \
  -V date="$document_date";

# Generate a singe epub file from all Markdown files in the content directory
echo "👉\tGenerate EPUB for all files"
cat Temp/*.md | docker run -i -v $PWD:/data ghcr.io/vergissberlin/pandoc-eisvogel-de \
  -o Results/resume-${FILENAME}.epub \
  --defaults Template/Config/defaults-epub.yml \
  --metadata-file Template/Config/metadata-epub.yml \
  -V author="Author: ${AUTHOR}" \
  -V description="Resume by ${AUTHOR}" \
  -V rights="© ${document_date_year} ${NAME}, CC BY-NC" \
  -V ibooks.version="$document_git_tag" \
  -V date="$document_date";


################################################################################
## Clean up
################################################################################

# Remove the temporary directory
# rm -rf Temp