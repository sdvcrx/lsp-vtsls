;;; lsp-vtsls.el --- LSP wrapper for typescript extension of vscode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 sdvcrx
;;
;; Author: sdvcrx <me@sdvcrx.com>
;; Maintainer: sdvcrx <me@sdvcrx.com>
;; Created: April 10, 2024
;; Modified: April 10, 2024
;; Version: 0.0.1
;; Keywords: abbrev lsp-mode typescript javascript vtsls
;; Homepage: https://github.com/sdvcrx/lsp-vtsls
;; Package-Requires: ((emacs "29.2"))
;;
;; This file is not part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;;  Description
;;
;;; Code:
(require 'lsp-mode)
(require 'json)

(defgroup lsp-vtsls nil
  "LSP support for JavaScript and TypeScript."
  :group 'lsp-mode
  :link '(url-link "https://github.com/yioneko/vtsls")
  :package-version '(lsp-mode . "9.0.0"))

(defcustom-lsp lsp-vtsls-server-side-fuzzy-match nil
  "Execute fuzzy match of completion items on server side.
Enable this will help filter out useless completion items from tsserver."
  :type 'boolean
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.experimental.completion.enableServerSideFuzzyMatch")

(defcustom-lsp lsp-vtsls-entries-limit nil
  "Maximum number of completion entries to return.
Recommend to also toggle `enableServerSideFuzzyMatch` to preserve items
with higher accuracy."
  :type 'number
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.experimental.completion.entriesLimit")

(defcustom-lsp lsp-vtsls-auto-use-workspace-tsdk nil
  "Automatically use workspace version of TypeScript lib on startup.
By default, the bundled version is used for intelliSense."
  :type 'boolean
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.autoUseWorkspaceTsdk")

(defcustom-lsp lsp-vtsls-typescript-global-tsdk nil
  "Set global TypeScript lib path"
  :type 'string
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.typescript.globalTsdk")

(defcustom-lsp lsp-vtsls-enable-move-to-file-code-action nil
  "Enable 'Move to file' code action.
This action enables user to move code to existing file,
but requires corresponding handling on the client side."
  :type 'boolean
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.enableMoveToFileCodeAction")

(defcustom-lsp lsp-vtsls-typescript-global-plugins (vector)
  "vtsls typescript-plugins"
  :group 'lsp-vtsls
  :package-version '(lsp-mode . "9.0.0")
  :lsp-path "vtsls.tsserver.globalPlugins"
  :type  '(restricted-sexp :tag "Vector"
                           :match-alternatives
                           (lambda (xs)
                             (and (vectorp xs) (seq-every-p
                                                (-lambda ((&plist :name :location :languages))
                                                  (and name location))
                                                xs)))))

(lsp-dependency 'vtsls-language-server
                '(:system "vtsls")
                '(:npm :package "@vtsls/language-server" :path "vtsls"))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   (lambda ()
                     `(,(lsp-package-path 'vtsls-language-server) "--stdio")))
  :activation-fn (lsp-activate-on "javascript" "javascriptreact" "typescript" "typescriptreact")
  :priority -1
  :multi-root t
  :server-id 'vtsls
  :initialization-options (lambda () (ht-merge
                                 (lsp-configuration-section "vtsls")))
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      (lsp--set-configuration
                       (lsp-configuration-section "vtsls"))
                      (lsp--server-register-capability
                       (lsp-make-registration
                        :id "random-id"
                        :method "workspace/didChangeWatchedFiles"
                        :register-options? (lsp-make-did-change-watched-files-registration-options
                                            :watchers
                                            `[,(lsp-make-file-system-watcher :glob-pattern "**/*.js")
                                              ,(lsp-make-file-system-watcher :glob-pattern "**/*.ts")
                                              ,(lsp-make-file-system-watcher :glob-pattern "**/*.jsx")
                                              ,(lsp-make-file-system-watcher :glob-pattern "**/*.tsx")])))))
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (lsp-package-ensure 'vtsls-language-server
                                            callback error-callback))))

(provide 'lsp-vtsls)
;;; lsp-vtsls.el ends here
