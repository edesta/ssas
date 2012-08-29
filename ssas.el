;;; ssas.el --- expose the functionality of the emacs library SES to the web

;; Copyright (C) 2012 Ivaylo Ilionov

;; Created: 2th July 2012
;; Keywords: lisp, http, spreadsheet

;; This file is part of ssas

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Source code:

;;; Code:

(require 'cl)

(defmacro negate (var)
  `(setq ,var (not ,var)))

(defun list-books (httpcon)
  "Open a spreasheet and "
  (elnode-http-start httpcon "200" '("Content-type" . "text/html"))
  (let ((table-content ""))
    (with-current-buffer "books-elnode-copy.ses" ses--cells)
    (elnode-http-return httpcon
			(concat "<html><head><meta charset='utf-8'/><script src='/ses-lib.js' type='text/javascript'></script></head><table><captio>Library Books</caption>"
				(loop with y = 1 for x across (with-current-buffer "books-elnode-copy.ses" ses--cells) concat
				      (progn (negate y)
					     (concat "<tr style='background-color: " (if y "#bbbbbb" "#aaaaaa") "'>"
						     (let (rowcol
							   value
							   formula)
						       (loop for y across x concat
							     (progn (with-current-buffer "books-elnode-copy.ses"
								      (setq rowcol (ses-sym-rowcol (aref y 0)))
								      (setq value (ses-cell-value (car rowcol) (cdr rowcol)))
								      (setq formula (aref y 1)))
								    (format "<td onclick='myfun(this, %d, %d,\" %s\")'>%s</td>" (car rowcol) (cdr rowcol) formula (if (null value) "&nbsp" value)))))
						     "</tr>")))
				"</table></html>"))))

;; (with-current-buffer "books-elnode-copy.ses" (ses-cell-set-formula (string-to-number row) (string-to-number col) newval))
(defun change-books (httpcon)
  "This will be called from javascript. Returns an json object."
  (let ((row (elnode-http-param httpcon "row"))
	(col (elnode-http-param httpcon "col"))
	(newval (elnode-http-param httpcon "newval")))
    (or (not (and row col newval))
	(with-current-buffer
	    "books-elnode-copy.ses"
	  ;; (ses-edit-cell (string-to-number row)
	  ;; 		 (string-to-number col)
	  ;; 		 (read newval))
	  (ses-cell-set-formula (string-to-number row)
				(string-to-number col)
				(read newval))
	  (ses-calculate-cell (string-to-number row)
			      (string-to-number col)
			      nil)))
    ;; (elnode-http-start httpcon 302 '("Location" . "/list-books/"))
    ;;(elnode-http-start httpcon 302 '("Refresh" . "5; url=http://127.0.0.1:8000/list-books/"))
    (elnode-http-start httpcon 200 '("Content-type" . "text/html"))
    (elnode-http-return httpcon "{\"cmd\" : \"refresh\"}")))

;; (elnode-stop 8001)
;; (elnode-start 'books-handler :port 8001 :host "localhost")

(add-to-list 'elnode-hostpath-default-table '("/list-books/" . list-books))
(add-to-list 'elnode-hostpath-default-table '("/change-books/" . change-books))
