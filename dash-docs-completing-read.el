;;; dash-docs-completing-read.el --- Summary

;; Copyright (Cn) 2022 Kristoffer Balintona

;; Author: Kristoffer Balintona <krisbalintona@gmail.com>
;; URL: https://github.com/dash-docs-el/dash-docs
;; Created June 2022
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience extensions tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.nnnnn

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; A `completing-read' frontend for `dash-docs' documentation. `counsel-dash'
;; was used as a template for these functions.
;;
;;; Code:

;;; Requires

(require 'cl-lib)
(require 'subr-x)
(require 'dash-docs)

;;; Variables
(defvar dash-docs-completing-read--docset-elements nil
  "Stores the previously retrieved docset results.")

(defvar-local dash-docs-completing-read-docsets nil
  "Docsets to use for this buffer.")

;;; Helper functions
(advice-add #'dash-docs-buffer-local-docsets :around
            (lambda (old-fun &rest args)
              "Remove duplicate docsets for this buffer."
              (let ((old (apply old-fun args)))
                (cl-remove-duplicates (append old dash-docs-completing-read-docsets)))))

(defun dash-docs-completing-read--collect (docset)
  "Given a string S, query a given DOCSET, retrieve result, and
remove the prepended docset name from each documented item. Also
update `dash-docs-completing-read--docset-elements'."
  (let* ((docset-results (dash-docs-search (concat docset " "))))
    (setq dash-docs-completing-read--docset-elements docset-results)
    (mapcar #'(lambda (elt) (substring (car elt) (+ 1 (length docset))))
            docset-results)))

(defun dash-docs-completing-read--browse-matching-result (match)
  "Given a MATCH, find matching result and browse it's url."
  (when-let ((result (cdr (cl-find-if (lambda (elt) (string= match (car elt)))
                                      dash-docs-completing-read--docset-elements))))
    (dash-docs-browse-url result)))

(defun dash-docs-completing-read--select-docset-maybe ()
  "If the buffer has a value for `dash-docs-common-docsets', then
select and return one of its elements with `completing-read'.
Otherwise, return error."
  (cond ((not dash-docs-common-docsets) ; Download docset if necessary
         (error "No value set for `dash-docs-common-docsets'!"))
        ((< 1 (length dash-docs-common-docsets)) ; If more than one, prompt for one
         (completing-read "Select docset: " dash-docs-common-docsets))
        (t                              ; When only one, return it
         (car dash-docs-common-docsets))))

;;; Commands
(defun dash-docs-completing-read-lookup (&optional initial-input)
  "Query dash docsets. INITIAL-INPUT will be used as the initial
input if given."
  (interactive)
  (dash-docs-initialize-debugging-buffer)
  (dash-docs-create-buffer-connections)
  (dash-docs-create-common-connections)
  (let* ((docset (dash-docs-completing-read--select-docset-maybe))
         (match (concat docset " "
                        (completing-read "Documentation for: "
                                         (dash-docs-completing-read--collect docset)
                                         nil t initial-input t))))
    (dash-docs-completing-read--browse-matching-result match)))

(defun dash-docs-completing-read-at-point ()
  "Bring up a `dash-docs-completing-read-lookup' search interface
with symbol at point as the initial input."
  (interactive)
  (dash-docs-completing-read-lookup (substring-no-properties (or (thing-at-point 'symbol) ""))))

;;; dash-docs-completing-read.el ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dash-docs-completing-read)
