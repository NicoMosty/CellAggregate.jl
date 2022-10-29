clear
pandoc metadata.yml doc.md \
    --citeproc \
    --bibliography=export.bib \
    -o doc.pdf
