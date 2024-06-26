;;; comp.el --- RPN interpreter -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2024 Duane Edmonds
;;
;; Author: Duane Edmonds
;; Maintainer: Duane Edmonds <duane.edmonds@gmail.com>
;; Created: August 01, 2023
;; Modified: April 21, 2024
;; Version: 0.0.8
;; Keywords: convenience data tools
;; Homepage: https://github.com/dedmonds/comp
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description:  RPN interpreter
;;
;;; Code:

(load-file "~/repos/othello/src/othello.el")


;; create-unary-stack-function :: (number -> number) -> ([string] -> [string])
(defun create-unary-stack-function (f)
  "Create a numerical unary function that can be applied to a stack. Returns a
decorated function that applies the unary function (F) to the element on the top
of the stack and pushes the result back onto the stack."
  (lambda (stack)
    (let ((a (string-to-number (car stack)))
          (rst (cdr stack)))
      (o-thread (funcall f a) ; call function on argument
        'number-to-string
        (lambda (res) (cons res rst)))))) ; push the result back onto the stack


;; create-binary-stack-function ::
;; (number -> number -> number) -> ([string] -> [string])
(defun create-binary-stack-function (f)
  "Create a numerical binary function that can be applied to a stack. Returns a
decorated function that applies the binary function (F) to the elements on the
top of the stack and pushes the result back onto the stack."
  (lambda (stack)
    (let ((b (string-to-number (car stack)))
          (a (string-to-number (cadr stack)))
          (rst (cddr stack)))
      (o-thread (funcall f a b) ; call function on arguments
        'number-to-string
        (lambda (res) (cons res rst)))))) ; push the result back onto the stack


;; gcd :: [int] -> [int] -> [int]
(defun gcd (a b)
  "Calculate the greatest common denominator (GCD) of the two items (A and B)
on the top of the STACK."
  (if (= 0 b)
      a
    (gcd b (mod a b))))


;; apply-swap :: [string] -> [string]
(defun apply-swap (stack)
  "Apply the swap transformation on STACK. Swap the top elements and return
updated stack."
  (let ((b (car stack))
        (a (cadr stack))
        (rst (cddr stack)))
    (cons a (cons b rst))))


;; apply-iota :: [string] -> [string]
(defun apply-iota (stack)
  "Apply the iota transformation on STACK. Add numbers from 1 to the number on
the top of the stack to the stack."
  (let ((a (string-to-number (car stack)))
        (rst (cdr stack)))
    (o-thread (o-range 1 (o-inc a))
      (lambda (lst) ; convert numbers to strings
        (mapcar 'number-to-string lst))
      (lambda (lst) ; add to top of stack
        (append lst rst)))))

;; apply-sum :: [string] -> [string]
(defun apply-sum (stack)
  "Calculate the sum of all items on the STACK."
  (let ((res (o-fold-left
               (lambda (acc a)
                 (+ acc (string-to-number a)))
               0
               stack)))
    (list (number-to-string res)))) ; return new stack


;; apply-prod :: [string] -> [string]
(defun apply-prod (stack)
  "Calculate the product of all items on the STACK."
  (let ((res (o-fold-left
               (lambda (acc a)
                 (* acc (string-to-number a)))
               1
               stack)))
    (list (number-to-string res)))) ; return new stack


;; define primitive commands
(defvar comp-cmds nil)
(add-to-list 'comp-cmds `("abs"  . ,(create-unary-stack-function 'abs)))
(add-to-list 'comp-cmds `("inv"  . ,(create-unary-stack-function (lambda (a) (/ 1.0 a)))))
(add-to-list 'comp-cmds `("sqrt" . ,(create-unary-stack-function 'sqrt)))
(add-to-list 'comp-cmds `("+"    . ,(create-binary-stack-function '+)))
(add-to-list 'comp-cmds `("-"    . ,(create-binary-stack-function '-)))
(add-to-list 'comp-cmds `("*"    . ,(create-binary-stack-function '*)))
(add-to-list 'comp-cmds `("x"    . ,(create-binary-stack-function '*)))
(add-to-list 'comp-cmds `("/"    . ,(create-binary-stack-function (lambda (a b) (/ (* 1.0 a) b)))))
(add-to-list 'comp-cmds `("^"    . ,(create-binary-stack-function 'expt)))
(add-to-list 'comp-cmds `("mod"  . ,(create-binary-stack-function 'mod)))
(add-to-list 'comp-cmds `("%"    . ,(create-binary-stack-function 'mod)))
(add-to-list 'comp-cmds `("gcd"  . ,(create-binary-stack-function 'gcd)))
(add-to-list 'comp-cmds `("dup"  . ,(lambda (stack) ; duplicate item on the top of the stack
                                 (cons (car stack) stack))))
(add-to-list 'comp-cmds `("pi"   . ,(lambda (stack) ; add pi to the top of the stack
                                 (cons (number-to-string float-pi) stack))))
(add-to-list 'comp-cmds `("iota" . ,'apply-iota))
(add-to-list 'comp-cmds `("io"   . ,'apply-iota))
(add-to-list 'comp-cmds `("swap" . ,'apply-swap))
(add-to-list 'comp-cmds `("sum"  . ,'apply-sum))
(add-to-list 'comp-cmds `("prod" . ,'apply-prod))


; process-op :: string -> [string] -> [string]
(defun process-op (stack op)
  "Process operation (OP) on STACK."
  (let ((cmd (assoc op comp-cmds)))
    (if cmd
        (funcall (cdr cmd) stack) ; apply associated stack function to stack
        (cons op stack)))) ; op is not command, add to stack


; evaluate-ops :: string -> [string] -> [string]
(defun evaluate-ops (ops stack)
  "Evaluate OPS operations by consecutively applying operations to STACK."
  (o-fold-left 'process-op stack ops))


; comp-eval :: string -> nil (IMPURE)
(defun comp-eval (exp)
  "Evaluate expression (EXP) and display the resulting stack."
  (let* ((ops (split-string exp))
         (result (evaluate-ops ops '())))
    (kill-new (car result)) ; copy to clipboard
    (message "%s%s" (reverse result) ":"))) ; display as user message


; interactive command (IMPURE)
(defun comp ()
  "Evaluate expression."
  (interactive)
  (let ((exp (read-string "Enter expression: ")))
    (comp-eval exp)))



(provide 'comp)
;; end of comp.el
