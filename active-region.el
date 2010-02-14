;;; active-region.el
;;; last updated : 2010-02-14
;;
;;; Usage:
;;
;; ;;; active-region.el
;; (when (and (require 'active-region nil t)
;;            (featurep 'anything))
;;   (defun active-region-anything (&optional arg)
;;     (interactive "*P")
;;     (cond ((consp arg) ;; C-u C-i
;;            (anything '(((name       . "Formatting")
;;                         (candidates . (indent-region
;;                                        align
;;                                        fill-region))
;;                         (action     . call-interactively))
;;                        ((name       . "Converting")
;;                         (candidates . (upcase-region
;;                                        downcase-region
;;                                        capitalize-region
;;                                        base64-decode-region
;;                                        base64-encode-region
;;                                        tabify
;;                                        untabify))
;;                         (action     . call-interactively))
;;                        ((name       . "Converting (japanese)")
;;                         (candidates . (japanese-hankaku-region
;;                                        japanese-hiragana-region
;;                                        japanese-katakana-region
;;                                        japanese-zenkaku-region))
;;                         (action     . call-interactively))
;;                        ((name       . "Editing")
;;                         (candidates . (string-rectangle
;;                                        delete-rectangle
;;                                        iedit-mode
;;                                        ))
;;                         (action     . call-interactively))
;;                        )))
;;           ((active-region-multiple-line-p)
;;            (call-interactively 'indent-region)
;;            (message "indent region."))
;;           ))
;;   (define-key active-region-mode-map (kbd "C-i") 'active-region-anything)
;;   )

(eval-when-compile
  (require 'cl))

(defgroup active-region nil
  "Active Region."
  :group 'editing)

(defvar active-region-isearch-use-region t)

(defvar active-region-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-i")   'indent-region)
    (define-key map (kbd "C-w")   'kill-region)
    (define-key map (kbd "M-w")   'kill-ring-save)
    (define-key map (kbd "C-h")   'delete-region)
    (define-key map (kbd "C-d")   'delete-region)
    (define-key map (kbd "M-\\")  'active-region-concat-lines)
    (define-key map (kbd "M-SPC") 'active-region-concat-lines-with-space)
    (define-key map (kbd "<")     'skeleton-pair-insert-maybe)
    (define-key map (kbd "[")     'skeleton-pair-insert-maybe)
    (define-key map (kbd "(")     'skeleton-pair-insert-maybe)
    (define-key map (kbd "{")     'skeleton-pair-insert-maybe)
    (define-key map (kbd "\"")    'skeleton-pair-insert-maybe)
    (define-key map (kbd "'")     'skeleton-pair-insert-maybe)
    (define-key map (kbd "`")     'skeleton-pair-insert-maybe)
    map)
  "Keymap for active region mode.")

(define-minor-mode active-region-mode
  "Active Region minor mode."
  :init-value nil
  :lighter " Region"
  :keymap active-region-mode-map
  :group 'active-region
  (cond (active-region-mode
         (setq skeleton-pair t)
         )
        ((not active-region-mode)
         (setq skeleton-pair nil)
         )))

;; hook
(defun active-region-on ()
  (active-region-mode 1))
(defun active-region-off ()
  (active-region-mode -1))
(add-hook 'activate-mark-hook 'active-region-on)
(add-hook 'deactivate-mark-hook 'active-region-off)

;; advice
(defadvice isearch-mode (around isearch-mode-default-string (forward &optional regexp op-fun recursive-edit word-p) activate)
  (if (and (region-active-p) active-region-isearch-use-region)
      (progn
        (isearch-update-ring (buffer-substring-no-properties (mark) (point)))
        (deactivate-mark)
        ad-do-it
        (if (not forward)
            (isearch-repeat-backward)
          (goto-char (mark))
          (isearch-repeat-forward)))
    ad-do-it))

;;; Formatting Commands
(defun active-region-concat-lines-with-space (start end)
  (interactive "*r")
  (goto-char end)
  (fixup-whitespace)
  (move-beginning-of-line 1)
  (while (< start (point))
    (delete-backward-char 1)
    (fixup-whitespace)
    (move-beginning-of-line 1))
  (goto-char start))

(defun active-region-concat-lines (start end)
  (interactive "*r")
  (when (= (point) (region-end))
    (exchange-point-and-mark))
  (while (< (point) (region-end))
    (delete-horizontal-space)
    (move-end-of-line 1)
    (delete-horizontal-space)
    (delete-char 1)))


;;; utility functions
(defun active-region-single-line-p ()
  (when active-region-mode
    (let ((start (point))
          (end (mark)))
      (when (> start end)
        (psetf start end
               end start))
      (= 1 (count-lines start end))
      )))

(defun active-region-multiple-line-p ()
  (when active-region-mode
    (let ((start (point))
          (end (mark)))
      (when (> start end)
        (psetf start end
               end start))
      (/= 1 (count-lines start end))
      )))

(provide 'active-region)
