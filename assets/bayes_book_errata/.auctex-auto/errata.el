;; -*- lexical-binding: t; -*-

(TeX-add-style-hook
 "errata"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("babel" "english") ("geometry" "letterpaper" "includehead" "nomarginpar" "textwidth=15cm" "headheight=1mm" "") ("fancyhdr" "") ("amsmath" "") ("amssymb" "") ("graphicx" "") ("xcolor" "") ("hyperref" "colorlinks=true" "allcolors=blue") ("titlesec" "")))
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
    "fancyhdr"
    "amsmath"
    "amssymb"
    "graphicx"
    "xcolor"
    "hyperref"
    "titlesec")
   (TeX-add-symbols
    "titlefont"
    "authorfont"))
 :latex)

