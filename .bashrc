#
# ~/.bashrc
#

#
# If not running interactively, don't do anything
#
[[ $- != *i* ]] && return

#
# Environment Variables
#
export PROMPT_COMMAND="export PROMPT_COMMAND=echo"
export PS1='\[\e[1m\][\[\e[32m\]\u\[\e[39m\]][\[\e[33m\]\H\[\e[39m\]][\[\e[34m\]\W\[\e[39m\]]\nλ \[\e[0m\]'

#
# Aliases
#
alias ls="ls -a -C --color=auto"
alias ..="cd .."
alias clear="unset PROMPT_COMMAND; clear; PROMPT_COMMAND='export PROMPT_COMMAND=echo'"

