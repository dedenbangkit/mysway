;;; notes.el --- Super+b notes popup (loaded into the Emacs daemon by sway/scripts/notes)

(defvar mysway-notes-dir "~/Orgs/")
(defvar mysway-notes-frame "orgnotes")
(defvar mysway-notes-sync (expand-file-name "~/.config/sway/scripts/notes"))

(defun mysway-notes--start (file)
  (find-file file)
  (widen)
  (when (fboundp 'evil-insert-state) (evil-insert-state)))

(defun mysway-notes-open ()
  "Today's heading in journal.org (newest day on top), with a fresh \"- HH:MM \" line."
  (mysway-notes--start (expand-file-name "journal.org" mysway-notes-dir))
  (let ((day (format-time-string "* %Y-%m-%d %A")))
    (goto-char (point-min))
    (unless (re-search-forward (concat "^" (regexp-quote day) "$") nil t)
      (goto-char (point-min))
      (while (and (not (eobp)) (looking-at "#\\+\\|[ \t]*$")) (forward-line 1))
      (insert day "\n\n")
      (forward-line -2))
    (org-back-to-heading t)
    (org-overview)
    (if (fboundp 'org-fold-show-subtree) (org-fold-show-subtree) (org-show-subtree))
    (org-end-of-subtree t)
    (insert "\n- " (format-time-string "%H:%M") " ")))

(defun mysway-notes-open-file (file)
  "Open (or start) FILE in the notes popup."
  (let ((new (not (file-exists-p file))))
    (mysway-notes--start file)
    (when new
      (insert "#+title: " (file-name-base file) "\n\n"))))

(defun mysway-notes--tidy ()
  "Drop entry lines left empty and day headings with nothing under them."
  (let ((buf (get-file-buffer (expand-file-name "journal.org" mysway-notes-dir))))
    (when buf
      (with-current-buffer buf
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "^- [0-9][0-9]:[0-9][0-9][ \t]*$" nil t)
            (delete-region (line-beginning-position) (min (1+ (point)) (point-max))))
          (goto-char (point-min))
          (while (re-search-forward "^\\* [0-9]\\{4\\}-[0-9][0-9]-[0-9][0-9] [A-Za-z]+$" nil t)
            (let ((beg (line-beginning-position))
                  (end (save-excursion
                         (if (re-search-forward "^\\* " nil t) (match-beginning 0) (point-max)))))
              (when (string-blank-p (buffer-substring (line-end-position) end))
                (delete-region beg end)))))))))

(defun mysway-notes--on-delete (frame)
  "Popup closing (Super+b, Super+Shift+q, C-x 5 0…): tidy, save, commit + push."
  (when (equal (frame-parameter frame 'name) mysway-notes-frame)
    (mysway-notes--tidy)
    (save-some-buffers
     t (lambda () (and buffer-file-name
                       (file-in-directory-p buffer-file-name mysway-notes-dir))))
    (start-process "notes-sync" nil mysway-notes-sync "sync")))

(add-hook 'delete-frame-functions #'mysway-notes--on-delete)

(defun mysway-notes-close ()
  (dolist (f (frame-list))
    (when (equal (frame-parameter f 'name) mysway-notes-frame)
      (delete-frame f t))))
