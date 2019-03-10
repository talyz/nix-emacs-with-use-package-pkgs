;; run like: "emacs ~/.emacs --no-site-file --batch -l use-package--name-extract.el -f print-packages 2>&1"

(defun upe-list-until (predicate list)
  (cond ((eq list nil)        nil)
        ((funcall predicate
                  (car list)) nil)
        (t                    (cons (car list)
                                    (upe-list-until predicate (cdr list))))))

(defun upe-findcdr (keyword list)
  (cond ((eq list nil)           nil)
        ((eq (car list) keyword) list)
        (t                       (upe-findcdr keyword (cdr list)))))

(defun upe-get-parameter (body keyword)
  (let ((list (upe-findcdr keyword body)))
    (cons (car list) (upe-list-until #'keywordp (cdr list)))))

(defun upe-handle-use-package (use-package-expression)
  (let* ((name (cadr use-package-expression))
         (body (cddr use-package-expression))
         (ensure (upe-get-parameter body :ensure))
         (install-package (cond ((equal ensure '(:ensure t))   (list name))
                                ((equal ensure '(:ensure))     (list name))
                                ((equal ensure '(:ensure nil)) nil)
                                (t                             (cdr ensure))))
         (init-progn    (cdr (upe-get-parameter body :init)))
         (config-progn  (cdr (upe-get-parameter body :config)))
         (preface-progn (cdr (upe-get-parameter body :preface))))
    (append install-package
            (upe-walk init-progn)
            (upe-walk config-progn)
            (upe-walk preface-progn))))

(defun upe-walk (tree)
  (cond ((atom tree)                  nil)
        ((and (eq (car tree) 'when)
              (eq (cadr tree) nil))   nil) ; ignore parts commented out with (when nil ...)
        ((eq (car tree) 'use-package) (upe-handle-use-package tree))
        (t                            (append (upe-walk (car tree))
                                              (upe-walk (cdr tree))))))

(defun read-current-buffer ()
  "Read the current buffer and return its contents as a list of Lisp objects."
  (let (result)
    (while (< (point) (point-max))
      (add-to-list 'result (ignore-errors (read (current-buffer)))))
    result))

(defun print-packages ()
  (dolist (element (upe-walk (read-current-buffer)))
    (message (symbol-name element))))

;; (defun read-file (file-path)
;;   "Read the file at file-path and return its contents as a list of Lisp objects."
;;   (let (result)
;;     (with-temp-buffer
;;       (insert-file-contents file-path)
;;       (while (< (point) (point-max))
;;         (add-to-list 'result (ignore-errors (read (current-buffer))) t))
;;       result)))

;; (defun print-packages (file)
;;   (dolist (element (upe-walk (read-file file)))
;;    (message (symbol-name element))))

