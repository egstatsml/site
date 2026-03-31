;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "comments_errata"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("fancyhdr" "") ("babel" "english") ("geometry" "letterpaper" "top=0.5cm" "bottom=0.5cm" "left=1cm" "right=1cm" "marginparwidth=1.75cm" "bottom=2cm" "bottom=3cm" "includeheadfoot" "bottom=1cm") ("amsmath" "") ("graphicx" "") ("xcolor" "") ("hyperref" "colorlinks=true" "allcolors=blue") ("titlesec" "") ("tocloft" "") ("sectsty" "")))
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10"
    "babel"
    "geometry"
    "amsmath"
    "graphicx"
    "xcolor"
    "hyperref"
    "titlesec"
    "tocloft"
    "sectsty")
   (TeX-add-symbols
    "titlefont"
    "authorfont"))
 :latex)

