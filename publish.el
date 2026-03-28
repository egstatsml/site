;;; publish.el --- Generate a static site using org-publish  -*- lexical-binding:t -*-

;; Copyright (C) 2025 Brihadeesh S

;; Author: Brihadeesh S <contact@ethangoan.com>
;; Version: 1.0
;; URL: https://git.sr.ht/~ethan/ethangoan.com

;;; Commentary:

;; This is the Emacs Lisp used to generate my static site

;;; Code:

(require 'package)

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(setq package-user-dir (expand-file-name "/home/ethan/.cahce/site-packages"))

;; prevent built-in versions of org from loading
(assq-delete-all 'org package--builtins)
(assq-delete-all 'org package--builtin-versions)

(package-initialize)

(unless package-archive-contents
  (add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
  (add-to-list 'package-archives '("melpa"  . "https://melpa.org/packages/")     t)
  ;; (setq package-archives '(("melpa" . "https://melpa.org/packages/")
  ;;                          ("elpa" . "https://elpa.gnu.org/packages/")))
  (package-refresh-contents))

(dolist (pkg '(org org-contrib htmlize ox-tufte webfeeder))
  (unless (package-installed-p pkg)
    (package-install pkg)))

(require 'org)
;; (require 'org-id)
(require 'ox-publish)
(require 'ox-tufte)

(defvar website-title "Ethan Goan"
  "The title of this site.")

(defvar website-url "ethangoan.com"
  "The URL of this site.")

;; author details
(setq user-full-name "Ethan Goan"
      user-mail-address "contact@ethangoan.com")


;; Customize the HTML output
(setq org-export-with-section-numbers nil
      ;; org-export-with-toc nil

      ;; Date Format
      org-html-metadata-timestamp-format "%a %d.%m.%Y %H:%M"
      ;; org-export-date-timestamp-format "%a %d.%m.%Y"

      ;; Enable HTML5
      org-html-html5-fancy t
      org-html-doctype "html5"

      ;; TODO: tweak headline id format. I dislike the randomly generated ones.
      ;; Look into customizing: :html-format-headline-function and
      ;; org-html-format-headline-function
      ;; org-html-self-link-headlines 'nil

      org-html-htmlize-output-type 'css

      ;; Don't show validation link
      org-html-validation-link nil
      ;; Use our own scripts
      org-html-head-include-scripts nil
      ;; Use our own styles
      org-html-head-include-default-style nil

      org-tufte-html-sections '((preamble "header" "top")
				(content "article" "content")
				(postamble "footer" "postamble"))
      org-html-container-element "section"

      ;; disable that garbage home and up shit
      org-html-home/up-format ""

      ;; LaTeX?
      ;; org-html-mathjax-options '((path "/tex-chtml.js"))
      )

(add-to-list 'org-export-global-macros
	     '("timestamp" . "@@html:<time class=\"datetime\">$1</time>@@"))

(add-to-list 'org-export-global-macros
	     '("read-more" . "@@html:<p class=\"read-more\">$1</p>@@"))

(add-to-list 'org-export-global-macros
	     '("numeral" . "@@html:<span class=\"numeral\">$1</span>@@"))

(add-to-list 'org-export-global-macros
	     '("smallcaps" . "@@html:<span style=\"font-variant:small-caps;\">$1</span>@@"))

(add-to-list 'org-export-global-macros
	     '("allsc" . "@@html:<span style=\"font-variant:all-small-caps;\">$1</span>@@"))

(add-to-list 'org-export-global-macros
	     '("sc-grey" . "@@html:<span style=\"font-variant:small-caps;color:var(--tufte-foreground-secondary);\">$1</span>@@"))

(add-to-list 'org-export-global-macros
	     '("tinycaps" . "@@html:<span style=\"font-variant:small-caps;font-size:0.9rem;\">$1</span>@@"))

;; convert inline code to kbd
(add-to-list 'org-html-text-markup-alist '(code . "<kbd>%s</kbd>"))

;; partials for header, footer, etc
(defun read-template (filename)
  "Read template contents from FILENAME."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(setq header-template (read-template "partials/header.html"))
(setq footer-template (read-template "partials/footer.html"))
(setq head-template (read-template "partials/head.html"))

(defun format-date-entry (file project)
  "Format the date found in FILE of PROJECT."
  (format-time-string "%d %b %Y" (org-publish-find-date file project)))

(defun sitemap-with-date (entry style project)
  "Format for sitemap ENTRY, as a string.
ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (unless (equal entry "index.org")
    (format "[[file:%s][/%s/]] {{{timestamp(Published on %s)}}}"
	    entry
	    (org-publish-find-title entry project)
	    (format-date-entry entry project))))


(defun rw/org-publish-sitemap (title list)
  "Generate sitemap as a string, having TITLE.
LIST is an internal representation for the files to include, as
returned by `org-list-to-lisp'."
  (let ((filtered-list (cl-remove-if (lambda (x)
                                       (and (sequencep x) (null (car x))))
                                     list)))
    (concat "#+TITLE: " title "\n"
	    "#+SUBTITLE: \n"
	    "#+OPTIONS: export:nil\n"
            "#+META_TYPE: page\n"
            "#+DESCRIPTION: Miscellanous thoughts, opinions and rants on a variety of topics\n"
	    "\n#+ATTR_HTML: :class blog-entries\n"
	    ;; TODO use org-list-to-subtree instead
            (org-list-to-org filtered-list))))

(defun ogbe/org-publish-get-preview (file)
  "The comments in FILE have to be on their own lines, prefereably before and after paragraphs."
  (with-temp-buffer
    ;; I admit that this is a very dirty hack. but we want to sanitize the
    ;; previews a little. FIXME: add things to remove from the preview blurb as
    ;; I use them.
    (let ((raw-preview-string (with-temp-buffer
                                (insert-file-contents file)
                                (goto-char (point-min))
                                (let ((beg (+ 1 (re-search-forward "^#\\+BEGIN_PREVIEW$")))
                                      (end (progn (re-search-forward "^#\\+END_PREVIEW$")
                                                  (match-beginning 0))))
                                  (buffer-substring beg end)))))
      (insert raw-preview-string)
      ;; remove any footnotes and margin-notes from the preview blurb
      (goto-char (point-min))
      (replace-regexp "\\[fn:.*?\\]" "")
      ;; (replace-regexp "\\[\\[mn:\\]\\[.\\|$\\|^J\\]"  "")
      ;; (replace-regexp "\\[\\[.*?\\]\\]" "")
      (replace-regexp (rx (seq "[[mn:][" (0+ ascii) (= 1 "]]"))) "")
      (buffer-string))))

(defun ogbe/org-publish-parse-sitemap-list (l)
  "Convert the sitemap list L in to a list of filenames."
  (mapcar #'(lambda (i)
	      (let ((link (with-temp-buffer
			    (let ((org-inhibit-startup nil))
			      (insert (car i))
			      (org-mode)
			      (goto-char (point-min))
			      (org-element-link-parser)))))
                (when link
                  (plist-get (cadr link) :path))))
          (cdr l)))

(defun ogbe/org-publish-sitemap (title list)
  "Generate the landing page for my blog using the TITLE and LIST generated previously."
  (let* ((filenames (ogbe/org-publish-parse-sitemap-list list))
         (project-plist (assoc "blog posts" org-publish-project-alist)))

    ;; now generate the actual Blog landing page
    (with-temp-buffer
      ;; insert a title and save
      ;; only display a full preview for the first 3 posts
      (let* ((nfull 3)
             (title-preview (seq-subseq filenames 0  nfull))
             (title-only (seq-subseq filenames nfull)))
	(insert
	 (mapconcat
          (lambda (file)
            (let* ((abspath (file-name-concat "./blog" file))
                   (relpath (file-relative-name abspath "./blog"))
                   (title (org-publish-find-title file project-plist))
                   (date (format-date-entry file project-plist))
		   (preview (ogbe/org-publish-get-preview abspath)))
              (with-temp-buffer
		;; insert the link to the article as h3
		(insert (concat "** [[file:" relpath "][" title "]]\n"))
		;; insert the date, preview, and read more link
		(insert (concat "{{{timestamp(Published on " date ")}}}\n\n"))
		(insert preview)
		(insert "\n")
		(insert (concat "[[file:" relpath "][{{{read-more(Read More...)}}}]]\n"))
		(buffer-string))))
          title-preview "\n\n"))
	;; For the remaining articles, show them as a list
	(insert "\n\n")
	(insert "#+begin_export html\n<h2>Older posts</h2>\n#+end_export\n\n")
	(insert "\n#+ATTR_HTML: :class blog-entries\n")
	(insert "#+begin_section\n")
	(insert
	 (mapconcat
          (lambda (file)
            (let* ((abspath (file-name-concat "./" file))
                   (relpath (file-relative-name abspath "./"))
                   (title (org-publish-find-title file project-plist))
                   (date (format-date-entry file project-plist)))
              (format "- [[file:%s][/%s/]] {{{timestamp(Published on %s)}}}" relpath title date)))
          title-only "\n"))
	(insert "\n#+end_section\n"))
      (buffer-string))))

(defun rw/format-date-subtitle (file project)
  "Format the date found in FILE of PROJECT."
  (format-time-string "%d %b %Y" (org-publish-find-date file project)))

;; stuff for `html-head-extra'?
;; add meta tags dynamically
;; from https://gitlab.com/to1ne/blog/blob/master/elisp/publish.el#L60-126
(defun rw/org-html-close-tag (tag &rest attrs)
  "Return close-tag for string TAG.
ATTRS specify additional attributes."
  (concat "<" tag " "
          (mapconcat (lambda (attr)
                       (format "%s=\"%s\"" (car attr) (cadr attr)))
                     attrs
                     " ")
	  ">"))

(defun rw/html-head-extra (file project)
  "Return <meta> elements for nice unfurling on Twitter and Slack."
  (let* ((info (cdr project))
         (org-export-options-alist
          `((:title "TITLE" nil nil parse)
            (:date "DATE" nil nil parse)
            (:meta-type "META_TYPE" nil ,(plist-get info :meta-type) nil)
	    (:meta-image "META_IMAGE" nil ,(plist-get info :meta-image) nil)))
         (title (org-publish-find-title file project))
	 (date (org-publish-find-date file project))
	 (author (org-publish-find-property file :author project))
	 (description (org-publish-find-property file :description project))
	 (extension (or (plist-get info :html-extension) org-html-extension))
	 (rel-file (org-publish-file-relative-name file info))
	 (link-home (file-name-as-directory (plist-get info :html-link-home)))
	 (type (org-publish-find-property file :meta-type project))
	 (full-url (concat link-home (file-name-sans-extension rel-file) "." extension))
	 (image (concat "https://ethangoan.com/media/" (org-publish-find-property file :meta-image project))))
    (mapconcat 'identity
	       `(,(rw/org-html-close-tag "link" '(rel canonical) `(href ,full-url))
		 ,(rw/org-html-close-tag "meta" '(property og:title) `(content ,title))
		 ,(and description
		       (rw/org-html-close-tag "meta" '(property og:description) `(content ,description)))
		 ,(rw/org-html-close-tag "meta" '(property og:type) `(content ,type))
		 ,(rw/org-html-close-tag "meta" '(property og:url) `(content ,full-url))
		 ,(and (equal type "article")
		       (rw/org-html-close-tag "meta" '(property article:published_time) `(content ,(format-time-string "%FT%T%z" date))))
		 ,(rw/org-html-close-tag "meta" '(property og:image) `(content ,image))

		 ,(rw/org-html-close-tag "meta" '(property twitter:title) `(content ,title))
		 ,(rw/org-html-close-tag "meta" '(property twitter:url) `(content ,full-url))
		 ,(and description
		       (rw/org-html-close-tag "meta" '(property twitter:description) `(content ,description)))
		 ,(and description
		       (rw/org-html-close-tag "meta" '(property twitter:card) '(content summary)))
		 ,(rw/org-html-close-tag "meta" '(property twitter:image) `(content ,image)))
	       "\n")))

(defun rw/org-html-publish-to-html (plist filename pub-dir)
  "Wrapper function to publish an file to html.

PLIST contains the properties, FILENAME the source file and
  PUB-DIR the output directory."
  (let ((project (cons 'rw plist)))
    (plist-put plist :subtitle
               (rw/format-date-subtitle filename project))
    (plist-put plist :html-head-extra
               (rw/html-head-extra filename project))
    (org-tufte-publish-to-html plist filename pub-dir)))

(defun rw/org-html-publish-to-html-no-sub (plist filename pub-dir)
  "Wrapper function to publish an file to html.

PLIST contains the properties, FILENAME the source file and
  PUB-DIR the output directory."
  (let ((project (cons 'rw plist)))
    (plist-put plist :html-head-extra
               (rw/html-head-extra filename project))
    (org-tufte-publish-to-html plist filename pub-dir)))


;; Table of Contents heading drawer

(defun org-html-toc (depth info &optional scope)
  "Build a table of contents.
DEPTH is an integer specifying the depth of the table.  INFO is
a plist used as a communication channel.  Optional argument SCOPE
is an element defining the scope of the table.  Return the table
of contents as a string, or nil if it is empty."
  (let ((toc-entries
	 (mapcar (lambda (headline)
		   (cons (org-html--format-toc-headline headline info)
			 (org-export-get-relative-level headline info)))
		 (org-export-collect-headlines info depth scope))))
    (when toc-entries
      (let* ((toc-id-counter (plist-get info :org-html--toc-counter))
             (toc (concat (format "<div id=\"text-table-of-contents%s\" role=\"doc-toc\">"
                                  (if toc-id-counter (format "-%d" toc-id-counter) ""))
			  (org-html--toc-text toc-entries)
			  "</div>\n")))
        (plist-put info :org-html--toc-counter (1+ (or toc-id-counter 0)))
	(if scope toc
	  (concat (format "<details id=\"table-of-contents%s\" role=\"doc-toc\">\n"
                          (if toc-id-counter (format "-%d" toc-id-counter) ""))
		  (let ((top-level (plist-get info :html-toplevel-hlevel)))
		    (format "<summary class=\"toc-h3\">%s</summary>\n"
			    (org-html--translate "Table of Contents" info)))
		  toc
		  (format "</details>\n")))))))


;; RSS feed
;; functions adapted from David Wilson
;; see: https://codeberg.org/SystemCrafters/systemcrafters-site/src/commit/299b304855c10df57780b0b77876ae7c4f890f2a/publish.el#L554

(defun dw/rss-extract-title (html-file)
  "Extract the title from an HTML-FILE."
  (with-temp-buffer
    (insert-file-contents html-file)
    (let ((dom (libxml-parse-html-region (point-min) (point-max))))
      (dom-text (car (dom-by-class dom "title"))))))

(defun dw/rss-extract-date (html-file)
  "Extract the post date from an HTML-FILE."
  (with-temp-buffer
    (insert-file-contents html-file)
    (let* ((dom (libxml-parse-html-region (point-min) (point-max)))
           (date-string (dom-text (car (dom-by-class dom "subtitle"))))
           (parsed-date (parse-time-string date-string))
           (day (nth 3 parsed-date))
           (month (nth 4 parsed-date))
           (year (nth 5 parsed-date)))
      ;; NOTE: Hardcoding this at 8am for now
      (encode-time 0 0 8 day month year))))

(setq webfeeder-title-function #'dw/rss-extract-title
      webfeeder-date-function #'dw/rss-extract-date)

;; *TODO* remove header and subtitle from RSS fulltext

;; (defun webfeeder-body-libxml (html-file &optional _url exclude-toc)
;;   "Return the body of HTML-FILE as a string.
;; If EXCLUDE-TOC is non-nil, the table-of-contents is not included in the body.
;; This requires Emacs to be linked against libxml."
;;   (with-temp-buffer
;;     (insert-file-contents html-file)
;;     (let* ((dom (libxml-parse-html-region (point-min) (point-max)))
;;            content)
;;       (let ((toc (or (dom-by-tag dom 'details)
;;                      ;; <nav> is only in HTML5.
;;                      (dom-by-id dom "table-of-contents")))
;;             (dom-remove-node dom (car toc))))
;;       (let ((title (or (dom-by-tag dom 'h1)
;;                        (dom-by-class dom "title")))
;; 	    ((subtitle (or (dom-by-tag dom 'p)
;; 			   (dom-by-class dom "subtitle")))))
;;         (dom-remove-node dom (car title))
;; 	(dom-remove-node dom (car subtitle)))
;;       (setq content (car (dom-by-id dom "content")))
;;       (shr-dom-to-xml content))))


;; Redirects

(defun rw/publish-redirect (plist filename pub-dir)
  "Generate redirect files from the old routes to the new.
PLIST contains the project info, FILENAME is the file to publish
and PUB-DIR the output directory."
  (let* ((regexp (org-make-options-regexp '("redirect_from")))
         (from (with-temp-buffer
                 (insert-file-contents filename)
                 (if (re-search-forward regexp nil t)
		     (org-element-property :value (org-element-at-point))))))
    (when from
      (let* ((to-name (file-name-sans-extension (file-name-nondirectory filename)))
             (to-file (format "/blog/%s.html" to-name))
             (from-dir (concat pub-dir from))
             (from-file (concat from-dir "index.html"))
             (other-dir (concat pub-dir to-name))
             (other-file (concat other-dir "/index.html"))
             (to (concat (file-name-sans-extension (file-name-nondirectory filename))
                         ".html"))
             (layout (plist-get plist :redirect-layout))
             (content (with-temp-buffer
                        (insert-file-contents layout)
                        (while (re-search-forward "redirect_to" nil t)
                          (replace-match to-file t t))
                        (buffer-string))))
        (make-directory from-dir t)
        (make-directory other-dir t)
        (with-temp-file from-file
          (insert content)
          (write-file other-file))))))



;; Define the publishing project

(setq org-publish-project-alist
      (list
       ;; non-page stuff like CSS and images
       (list "static"
	     :recursive t
	     :base-extension "css\\|txt\\|ico\\|png\\|jpg\\|jpeg\\|gif\\|pdf\\|woff\\|woff2\\|js\\|wav\\|xml"
	     ;; :base-extension ".*"
	     :base-directory "./static"
	     :publishing-directory "./html"
	     :publishing-function 'org-publish-attachment)

       (list "blog posts"
	     :recursive t
	     :base-extension "org"
	     :base-directory "./blog"
	     :publishing-directory "./html/blog"
	     :publishing-function 'rw/org-html-publish-to-html
	     :exclude (regexp-opt '("feed.org" "index.org" "404.org"))

	     :with-toc nil                ;; Include a table of contents
	     :section-numbers nil       ;; Don't include section numbers

	     ;; :auto-sitemap t
	     ;; :sitemap-title "Posts archive"
	     ;; :sitemap-filename "index.org"
	     ;; :sitemap-sort-files 'anti-chronologically
	     ;; :sitemap-function 'ogbe/org-p
	     ;; :sitemap-format-entry 'sitemap-with-date

	     ;; heading anchors
	     ;; :html-format-headline-function 'my-org-html-format-headline-function

	     ;; :with-title nil
	     :html-head head-template
	     :html-link-home "https://ethangoan.com/blog/"
	     :meta-type "article"
	     :meta-image "og-image.jpg"

	     :html-preamble header-template
	     :html-postamble footer-template
	     :htmlized-source t)

       (list "blog-redirects"
             :base-directory "./blog"
             :base-extension "org"
             :recursive nil
             :exclude (regexp-opt '("feed.org" "index.org" "404.org"))
             :publishing-function 'rw/publish-redirect
             :publishing-directory "./html/blog"
             :redirect-layout "partials/redirect.html")


       (list "pages"
	     :recursive t
	     :base-directory "./pages"
	     :publishing-function 'rw/org-html-publish-to-html-no-sub
	     :publishing-directory "./html"

	     :with-toc nil

	     ;; :with-title nil
	     :html-head head-template
	     :html-link-home "https://ethangoan.com/"
	     :meta-type "page"
	     :meta-image "og-image.jpg"

	     :html-preamble header-template
	     :html-postamble footer-template)

       (list "assets"
             :recursive t
             :base-extension "css\\|txt\\|ico\\|png\\|jpg\\|jpeg\\|gif\\|pdf\\|woff\\|woff2\\|js\\|wav\\|xml"
             :base-directory "./assets"
             :publishing-directory "./html/assets"
             :publishing-function 'org-publish-attachment)
       
       (list "home"
	     :recursive nil
	     :base-directory "./index"
	     :publishing-function 'org-tufte-publish-to-html
	     :publishing-directory "./html"
	     :exclude "emacs.org"

	     :with-toc nil

	     ;; :with-title: nil
	     :html-head head-template
	     :meta-type "website"
	     :html-head-extra "<link rel=\"canonical\" href=\"https://ethangoan.com/\">
<meta property=\"og:url\" content=\"https://ethangoan.com/\">
<meta property=\"og:title\" content=\"Ethan's blog\">
<meta property=\"og:image\" content=\"https://ethangoan.com/media/og-image.jpg\">"
	     :html-preamble header-template
	     :html-postamble footer-template)

       (list "base"
	     :components '("static" "blog posts" "pages" "assets" "home"))))

(message "building static content")

;; Generate the site output
(org-publish "base" t)

(message "Generated static content")

(message "Generating RSS feed")

;; (webfeeder-build
;;  "blog/feed.xml"
;;  "./html"
;;  "https://ethangoan.com/"
;;  (let ((default-directory (expand-file-name "./html")))
;;    (remove "blog/index.html"
;; 	   (directory-files-recursively "blog"
;; 					".*\\.html$")))
;;  :title website-title
;;  :description "Miscellanous thoughts, opinions and rants on a variety of topics"
;;  :author "Brihadeesh S")

(message "Generated RSS feed")

;; remove sitemap pages
;; (delete-file "./html/blog/index.html")
(delete-file "./html/emacs/config.html")

;; redirects
(org-publish "blog-redirects" t)

(message "Generating redirects")

(message "Generating XML sitemap")

(defun ag-generate-xml-head ()
  "Generate the head part of the XML."
  (concat "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
          "<urlset\n"
          "    xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"\n"
          "    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n"
          "    xsi:schemaLocation=\"http://www.sitemaps.org/schemas/sitemap/0.9\n"
          "          http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd\">\n"
          "\n\n"))

(defun ag-generate-first-sitemap-entry (timestamp)
  "Generate the first entry of the sitemap XML with the given TIMESTAMP."
  (concat "<url>\n"
          "  <loc>https://ethangoan.com/</loc>\n"
          "  <lastmod>" timestamp "</lastmod>\n"
          "  <priority>1.00</priority>\n"
          "</url>\n"))

(defun ag-generate-sitemap-entry (filename timestamp)
  "Generate a sitemap entry for a given FILENAME with the given TIMESTAMP."
  (concat "<url>\n"
          "  <loc>https://ethangoan.com/" filename "</loc>\n"
          "  <lastmod>" timestamp "</lastmod>\n"
          "  <priority>0.80</priority>\n"
          "</url>\n"))

(defun ag-generate-sitemap-dot-xml (directory)
  "Generate an XML file with the names of HTML files in the specified DIRECTORY."
  (message "Generation of sitemap.xml START")
  (let ((files (reverse (directory-files-recursively directory "\\.html$")))
        (xml-file (expand-file-name "sitemap.xml" directory))
        (timestamp (format-time-string "%Y-%m-%dT%H:%M:%S+00:00" nil t)))
    (with-temp-file xml-file
      (insert (ag-generate-xml-head))
      (insert (ag-generate-first-sitemap-entry timestamp))
      (dolist (file files)
        (let ((filename (file-relative-name file "./html")))
          (insert (ag-generate-sitemap-entry filename timestamp))))
      (insert "</urlset>\n\n")) ;; Add the two newlines here
    (message "Generated %s" xml-file)
    (message "Generation of sitemap.xml END")))

;; call out function
(ag-generate-sitemap-dot-xml "./html")

(message "Build complete!")

(provide 'publish)
;;; publish.el ends here
