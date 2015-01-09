(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(before-save-hook (quote (whitespace-cleanup)))
 '(c-basic-offset 2)
 '(custom-safe-themes (quote ("7ed6913f96c43796aa524e9ae506b0a3a50bfca061eed73b66766d14adfa86d1" default)))
 '(flycheck-clang-include-path (quote ("/home/jah/work/uhd/host/include" "/opt/intel/ipp/6.1.6.063/em64t/include/")))
 '(flycheck-clang-language-standard "c++11")
 '(ido-mode (quote both) nil (ido))
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(initial-buffer-choice t)
 '(initial-scratch-message nil)
 '(package-enable-at-startup nil)
 '(show-paren-mode t)
 '(tool-bar-mode nil)
 '(transient-mark-mode nil)
 '(visible-bell t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


(setq package-list '(ag column-marker company flycheck grandshell-theme
                        markdown-mode rust-mode undo-tree diminish))

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")))

(package-initialize)

(unless (or (file-exists-p package-user-dir) package-archive-contents)
  (package-refresh-contents))

(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))


(add-to-list 'auto-mode-alist '("\\SConstruct\\'" . python-mode))
(add-to-list 'auto-mode-alist '("\\SConscript\\'" . python-mode))


(global-set-key (read-kbd-macro "<C-;>") nil)

(defconst my-key-prefix

  (kbd "C-;")

  "My prefix map keys")

(defvar my-map (lookup-key global-map my-key-prefix))

(unless (keymapp my-map)
  (setq my-map (make-sparse-keymap)))

(define-key global-map my-key-prefix my-map)

(define-key my-map (kbd "r") 'revert-buffer)

(define-key my-map (kbd "g") 'goto-line)


(fset 'yes-or-no-p 'y-or-n-p)

(defun yes-or-no-p (PROMPT)

  (beep)

  (y-or-n-p PROMPT))


(defadvice vc-registered (around my-vc-registered-tramp activate)
  "Don't use vc over TRAMP"
  (if (and (fboundp 'tramp-tramp-file-p)
           (tramp-tramp-file-p (ad-get-arg 0)))
      nil
    ad-do-it))


(defun my-c-mode-common-hook ()

  (c-toggle-hungry-state 1)

  (c-set-offset 'substatement-open 0)

  (column-marker-1 80)

  (auto-fill-mode))

(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)


; fixes for c++11

(require 'font-lock)

(defun --copy-face (new-face face)
  "Define NEW-FACE from existing FACE."
  (copy-face face new-face)
  (eval `(defvar ,new-face nil))
  (set new-face new-face))

(--copy-face 'font-lock-label-face  ; labels, case, public, private, proteced, namespace-tags
         'font-lock-keyword-face)
(--copy-face 'font-lock-doc-markup-face ; comment markups such as Javadoc-tags
         'font-lock-doc-face)
(--copy-face 'font-lock-doc-string-face ; comment markups
         'font-lock-comment-face)

(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

(add-hook
 'c++-mode-hook
 '(lambda()
    ;; We could place some regexes into `c-mode-common-hook', but note that their evaluation order
    ;; matters.
    (font-lock-add-keywords
     nil '(;; complete some fundamental keywords
           ("\\<\\(void\\|unsigned\\|signed\\|char\\|short\\|bool\\|int\\|long\\|float\\|double\\)\\>" . font-lock-keyword-face)
           ;; namespace names and tags - these are rendered as constants by cc-mode
           ("\\<\\(\\w+::\\)" . font-lock-function-name-face)
           ;;  new C++11 keywords
           ("\\<\\(alignof\\|alignas\\|constexpr\\|decltype\\|noexcept\\|nullptr\\|static_assert\\|thread_local\\|override\\|final\\)\\>" . font-lock-keyword-face)
           ("\\<\\(char16_t\\|char32_t\\)\\>" . font-lock-keyword-face)
           ;; PREPROCESSOR_CONSTANT, PREPROCESSORCONSTANT
           ("\\<[A-Z]*_[A-Z_]+\\>" . font-lock-constant-face)
           ("\\<[A-Z]\\{3,\\}\\>"  . font-lock-constant-face)
           ;; hexadecimal numbers
           ("\\<0[xX][0-9A-Fa-f]+\\>" . font-lock-constant-face)
           ;; integer/float/scientific numbers
           ("\\<[\\-+]*[0-9]*\\.?[0-9]+\\([ulUL]+\\|[eE][\\-+]?[0-9]+\\)?\\>" . font-lock-constant-face)
           ;; c++11 string literals
           ;;       L"wide string"
           ;;       L"wide string with UNICODE codepoint: \u2018"
           ;;       u8"UTF-8 string", u"UTF-16 string", U"UTF-32 string"
           ("\\<\\([LuU8]+\\)\".*?\"" 1 font-lock-keyword-face)
           ;;       R"(user-defined literal)"
           ;;       R"( a "quot'd" string )"
           ;;       R"delimiter(The String Data" )delimiter"
           ;;       R"delimiter((a-z))delimiter" is equivalent to "(a-z)"
           ("\\(\\<[uU8]*R\"[^\\s-\\\\()]\\{0,16\\}(\\)" 1 font-lock-keyword-face t) ; start delimiter
           (   "\\<[uU8]*R\"[^\\s-\\\\()]\\{0,16\\}(\\(.*?\\))[^\\s-\\\\()]\\{0,16\\}\"" 1 font-lock-string-face t)  ; actual string
           (   "\\<[uU8]*R\"[^\\s-\\\\()]\\{0,16\\}(.*?\\()[^\\s-\\\\()]\\{0,16\\}\"\\)" 1 font-lock-keyword-face t) ; end delimiter

           ;; user-defined types (rather project-specific)
           ("\\<[A-Za-z_]+[A-Za-z_0-9]*_\\(type\\|ptr\\)\\>" . font-lock-type-face)
           ("\\<\\(xstring\\|xchar\\)\\>" . font-lock-type-face)
           ))
    ) t)

(put 'upcase-region 'disabled nil)

(put 'narrow-to-region 'disabled nil)

(global-auto-revert-mode)

(global-undo-tree-mode)

(load-theme 'grandshell)

(global-flycheck-mode)

(global-company-mode)

(diminish 'undo-tree-mode)
(diminish 'company-mode)

(load "server")
(unless (server-running-p) (server-start))
