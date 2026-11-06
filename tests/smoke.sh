#!/bin/sh
# Compile a document with Mermaid, PlantUML and minted, with mermaid.sty and ltmermaid.sty,
# in place (latexmk) and into a fresh output directory (as rtex and LaTeX Workshop do).
set -eu

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "SMOKE FAILED: $*" >&2; exit 1; }

for pkg in mermaid ltmermaid; do
    dir="$work/$pkg"
    mkdir -p "$dir"
    cd "$dir"
    printf '%s\n' \
        '\documentclass{article}' "\\usepackage{$pkg}" '\usepackage{plantuml}' '\usepackage{minted}' \
        '\begin{document}' \
        '\begin{mermaid}' 'graph LR' '  A --> B' '\end{mermaid}' \
        '\begin{plantuml}' '@startuml' 'Alice -> Bob: Hello' '@enduml' '\end{plantuml}' \
        '\begin{minted}{cpp}' 'int main() { return 0; }' '\end{minted}' \
        '\end{document}' > t.tex

    latexmk -lualatex -interaction=nonstopmode t.tex > latexmk.log 2>&1 \
        || { tail -40 latexmk.log; fail "$pkg: latexmk"; }
    ! grep -a -q '^! ' t.log || fail "$pkg: LaTeX errors in place"
    test -s t.pdf && test -s mermaid/t-mermaid-1.pdf || fail "$pkg: missing PDF in place"
    echo "SMOKE $pkg in place OK"

    rm -rf mermaid _minted* plantuml-* t.aux t.log t.pdf t.fls t.fdb_latexmk
    mkdir out
    shell_escape=t lualatex -interaction=nonstopmode --output-directory=out t.tex > /dev/null 2>&1 || true
    ! grep -a -q '^! ' out/t.log || fail "$pkg: LaTeX errors with an output directory"
    test -s out/t.pdf && test -s out/mermaid/t-mermaid-1.pdf || fail "$pkg: missing PDF with an output directory"
    test ! -e mermaid || fail "$pkg: wrote mermaid/ outside the output directory"
    echo "SMOKE $pkg output directory OK"
done

echo "SMOKE versions: mmdc $(mmdc --version), $(rtex --version)"
