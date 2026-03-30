;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "main"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("babel" "english") ("geometry" "letterpaper" "top=1cm" "bottom=1cm" "left=1.5cm" "right=1.5cm" "marginparwidth=1.75cm") ("amsmath" "") ("graphicx" "") ("xcolor" "") ("hyperref" "colorlinks=true" "allcolors=blue") ("titlesec" "")))
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "href")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
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
    "titlesec")
   (TeX-add-symbols
    "titlefont"
    "authorfont"))
 :latex)

