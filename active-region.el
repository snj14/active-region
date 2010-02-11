;;; active-region.el

;;; Usage:
;;
;; ;;; active-region.el
;; (require 'active-region)
;; (when (require 'active-region nil t)
;;   (when (featurep 'anything)
;;     (defun active-region-anything ()
;;       (interactive)
;;       (anything '(((name       . "Formatt")
;;                    (candidates . (indent-region align fill-region))
;;                    (action     . call-interactively))
;;                   ((name       . "Converting")
;;                    (candidates . (upcase-region downcase-region capitalize-region base64-decode-region base64-encode-region))
;;                    (action     . call-interactively))
;;                   ((name       . "Converting (japanese)")
;;                    (candidates . (japanese-hankaku-region japanese-hiragana-region japanese-katakana-region japanese-zenkaku-region))
;;                    (action     . call-interactively))
;;                   )))
;;     (define-key active-region-mode-map (kbd "C-i") 'active-region-anything))
;;   (define-key active-region-mode-map (kbd "\"") (active-region-surround-string "\"" "\""))
;;   (define-key active-region-mode-map (kbd "'")  (active-region-surround-string "'" "'"))
;;   (define-key active-region-mode-map (kbd "{")  (active-region-surround-string "{" "}"))
;;   (define-key active-region-mode-map (kbd "(")  (active-region-surround-string "(" ")"))
;;   (define-key active-region-mode-map (kbd "[")  (active-region-surround-string "[" "]")))

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
    map)
  "Keymap for mark active mode.")

(define-minor-mode active-region-mode
  "Active Region minor mode."
  :init-value nil
  :lighter " Region"
  :keymap active-region-mode-map
  :group 'active-region)

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

;; commands
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

(defun active-region-surround-string (beginning-string end-string)
  (lexical-let ((beginning-string beginning-string)
                (end-string end-string))
  (lambda () "active-region-surround-string"
    (interactive)
    (let ((point-min (min (point) (mark)))
          (point-max (max (point) (mark))))
      (save-excursion
        (goto-char point-max)
        (insert end-string)
        (goto-char point-min)
        (insert beginning-string))))))

(provide 'active-region)
