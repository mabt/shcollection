(setq make-backup-files nil) ; stop creating ~ files
(set-default 'truncate-lines t) ; disable wrap text
(electric-indent-mode 0) ; disable auto indent-mode, especialy with a copy/past
(menu-bar-mode -1) ; disable toolbar
(setq x-select-enable-clipboard t) ; enable clipboard in emacs
(fset 'yes-or-no-p 'y-or-n-p) ;gagner du temps sur les confirmations
(savehist-mode 1) ;garder l'historique du minibuffer entre les sessions
;(global-display-line-numbers-mode) ; display number line
;enable mouse scrolling
(blink-cursor-mode -1) ;sert à rien 
(setq require-final-newline 't) ;toujours s'assurer que le fichier finit par une newline
