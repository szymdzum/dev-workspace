# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
VCS_INFO_formats () {
	setopt localoptions noksharrays NO_shwordsplit
	local msg tmp
	local -i i
	local -A hook_com
	hook_com=(action "$1" action_orig "$1" branch "$2" branch_orig "$2" base "$3" base_orig "$3" staged "$4" staged_orig "$4" unstaged "$5" unstaged_orig "$5" revision "$6" revision_orig "$6" misc "$7" misc_orig "$7" vcs "${vcs}" vcs_orig "${vcs}") 
	hook_com[base-name]="${${hook_com[base]}:t}" 
	hook_com[base-name_orig]="${hook_com[base-name]}" 
	hook_com[subdir]="$(VCS_INFO_reposub ${hook_com[base]})" 
	hook_com[subdir_orig]="${hook_com[subdir]}" 
	: vcs_info-patch-9b9840f2-91e5-4471-af84-9e9a0dc68c1b
	for tmp in base base-name branch misc revision subdir
	do
		hook_com[$tmp]="${hook_com[$tmp]//\%/%%}" 
	done
	VCS_INFO_hook 'post-backend'
	if [[ -n ${hook_com[action]} ]]
	then
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" actionformats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b|%a]%u%c-' 
	else
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" formats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b]%u%c-' 
	fi
	if [[ -n ${hook_com[staged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" stagedstr tmp
		[[ -z ${tmp} ]] && hook_com[staged]='S'  || hook_com[staged]=${tmp} 
	fi
	if [[ -n ${hook_com[unstaged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" unstagedstr tmp
		[[ -z ${tmp} ]] && hook_com[unstaged]='U'  || hook_com[unstaged]=${tmp} 
	fi
	if [[ ${quiltmode} != 'standalone' ]] && VCS_INFO_hook "pre-addon-quilt"
	then
		local REPLY
		VCS_INFO_quilt addon
		hook_com[quilt]="${REPLY}" 
		unset REPLY
	elif [[ ${quiltmode} == 'standalone' ]]
	then
		hook_com[quilt]=${hook_com[misc]} 
	fi
	(( ${#msgs} > maxexports )) && msgs[$(( maxexports + 1 )),-1]=() 
	for i in {1..${#msgs}}
	do
		if VCS_INFO_hook "set-message" $(( $i - 1 )) "${msgs[$i]}"
		then
			zformat -f msg ${msgs[$i]} a:${hook_com[action]} b:${hook_com[branch]} c:${hook_com[staged]} i:${hook_com[revision]} m:${hook_com[misc]} r:${hook_com[base-name]} s:${hook_com[vcs]} u:${hook_com[unstaged]} Q:${hook_com[quilt]} R:${hook_com[base]} S:${hook_com[subdir]}
			msgs[$i]=${msg} 
		else
			msgs[$i]=${hook_com[message]} 
		fi
	done
	hook_com=() 
	backend_misc=() 
	return 0
}
add-zle-hook-widget () {
	# undefined
	builtin autoload -XU
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
ai-tree () {
	tree -L 2 "$AI_HOME" -I 'cache|logs|backups'
}
alias_value () {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
azure_prompt_info () {
	return 1
}
backup () {
	cp -i "$1"{,.backup.$(date +%Y%m%d_%H%M%S)}
	echo "✓ Created backup: $1.backup.$(date +%Y%m%d_%H%M%S)"
}
bashcompinit () {
	# undefined
	builtin autoload -XUz
}
bracketed-paste-magic () {
	# undefined
	builtin autoload -XUz
}
brews () {
	local formulae="$(brew leaves | xargs brew deps --installed --for-each)" 
	local casks="$(brew list --cask 2>/dev/null)" 
	local blue="$(tput setaf 4)" 
	local bold="$(tput bold)" 
	local off="$(tput sgr0)" 
	echo "${blue}==>${off} ${bold}Formulae${off}"
	echo "${formulae}" | sed "s/^\(.*\):\(.*\)$/\1${blue}\2${off}/"
	echo "\n${blue}==>${off} ${bold}Casks${off}\n${casks}"
}
btrestart () {
	sudo kextunload -b com.apple.iokit.BroadcomBluetoothHostControllerUSBTransport
	sudo kextload -b com.apple.iokit.BroadcomBluetoothHostControllerUSBTransport
}
bzr_prompt_info () {
	local bzr_branch
	bzr_branch=$(bzr nick 2>/dev/null)  || return
	if [[ -n "$bzr_branch" ]]
	then
		local bzr_dirty="" 
		if [[ -n $(bzr status 2>/dev/null) ]]
		then
			bzr_dirty=" %{$fg[red]%}*%{$reset_color%}" 
		fi
		printf "%s%s%s%s" "$ZSH_THEME_SCM_PROMPT_PREFIX" "bzr::${bzr_branch##*:}" "$bzr_dirty" "$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
cdf () {
	cd "$(pfd)"
}
cdx () {
	cd "$(pxd)"
}
chpwd_dirhistory () {
	push_past $PWD
	if [[ -z "${DIRHISTORY_CD+x}" ]]
	then
		dirhistory_future=() 
	fi
}
chruby_prompt_info () {
	return 1
}
claude-cmd () {
	local name=$1 
	shift
	echo "---" > "$AI_HOME/.claude/commands/${name}.md"
	echo "description: $*" >> "$AI_HOME/.claude/commands/${name}.md"
	echo "---" >> "$AI_HOME/.claude/commands/${name}.md"
	echo "" >> "$AI_HOME/.claude/commands/${name}.md"
	echo "$*" >> "$AI_HOME/.claude/commands/${name}.md"
	echo "✓ Created command: /$(echo $name | tr '[:upper:]' '[:lower:]')"
}
claude-focus () {
	echo -e "\n## Current Focus ($(date +%Y-%m-%d))\n$*" >> "$AI_HOME/.claude/CLAUDE.md"
	echo "✓ Updated current focus"
}
clipcopy () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
clippaste () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
colors () {
	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 italic 23 no-italic 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	for k in grey gray
	do
		color[$k]=${color[black]} 
		color[fg-$k]=${color[$k]} 
		color[bg-$k]=${color[bg-black]} 
	done
	colour=(${(kv)color}) 
	local lc=$'\e[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
}
compaudit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compdef () {
	local opt autol type func delete eval new i ret=0 cmd svc 
	local -a match mbegin mend
	emulate -L zsh
	setopt extendedglob
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	while getopts "anpPkKde" opt
	do
		case "$opt" in
			(a) autol=yes  ;;
			(n) new=yes  ;;
			([pPkK]) if [[ -n "$type" ]]
				then
					print -u2 "$0: type already set to $type"
					return 1
				fi
				if [[ "$opt" = p ]]
				then
					type=pattern 
				elif [[ "$opt" = P ]]
				then
					type=postpattern 
				elif [[ "$opt" = K ]]
				then
					type=widgetkey 
				else
					type=key 
				fi ;;
			(d) delete=yes  ;;
			(e) eval=yes  ;;
		esac
	done
	shift OPTIND-1
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	if [[ -z "$delete" ]]
	then
		if [[ -z "$eval" ]] && [[ "$1" = *\=* ]]
		then
			while (( $# ))
			do
				if [[ "$1" = *\=* ]]
				then
					cmd="${1%%\=*}" 
					svc="${1#*\=}" 
					func="$_comps[${_services[(r)$svc]:-$svc}]" 
					[[ -n ${_services[$svc]} ]] && svc=${_services[$svc]} 
					[[ -z "$func" ]] && func="${${_patcomps[(K)$svc][1]}:-${_postpatcomps[(K)$svc][1]}}" 
					if [[ -n "$func" ]]
					then
						_comps[$cmd]="$func" 
						_services[$cmd]="$svc" 
					else
						print -u2 "$0: unknown command or service: $svc"
						ret=1 
					fi
				else
					print -u2 "$0: invalid argument: $1"
					ret=1 
				fi
				shift
			done
			return ret
		fi
		func="$1" 
		[[ -n "$autol" ]] && autoload -rUz "$func"
		shift
		case "$type" in
			(widgetkey) while [[ -n $1 ]]
				do
					if [[ $# -lt 3 ]]
					then
						print -u2 "$0: compdef -K requires <widget> <comp-widget> <key>"
						return 1
					fi
					[[ $1 = _* ]] || 1="_$1" 
					[[ $2 = .* ]] || 2=".$2" 
					[[ $2 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$1" "$2" "$func"
					if [[ -n $new ]]
					then
						bindkey "$3" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] && bindkey "$3" "$1"
					else
						bindkey "$3" "$1"
					fi
					shift 3
				done ;;
			(key) if [[ $# -lt 2 ]]
				then
					print -u2 "$0: missing keys"
					return 1
				fi
				if [[ $1 = .* ]]
				then
					[[ $1 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" "$1" "$func"
				else
					[[ $1 = menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" ".$1" "$func"
				fi
				shift
				for i
				do
					if [[ -n $new ]]
					then
						bindkey "$i" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] || continue
					fi
					bindkey "$i" "$func"
				done ;;
			(*) while (( $# ))
				do
					if [[ "$1" = -N ]]
					then
						type=normal 
					elif [[ "$1" = -p ]]
					then
						type=pattern 
					elif [[ "$1" = -P ]]
					then
						type=postpattern 
					else
						case "$type" in
							(pattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_patcomps[$match[1]]="=$match[2]=$func" 
								else
									_patcomps[$1]="$func" 
								fi ;;
							(postpattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_postpatcomps[$match[1]]="=$match[2]=$func" 
								else
									_postpatcomps[$1]="$func" 
								fi ;;
							(*) if [[ "$1" = *\=* ]]
								then
									cmd="${1%%\=*}" 
									svc=yes 
								else
									cmd="$1" 
									svc= 
								fi
								if [[ -z "$new" || -z "${_comps[$1]}" ]]
								then
									_comps[$cmd]="$func" 
									[[ -n "$svc" ]] && _services[$cmd]="${1#*\=}" 
								fi ;;
						esac
					fi
					shift
				done ;;
		esac
	else
		case "$type" in
			(pattern) unset "_patcomps[$^@]" ;;
			(postpattern) unset "_postpatcomps[$^@]" ;;
			(key) print -u2 "$0: cannot restore key bindings"
				return 1 ;;
			(*) unset "_comps[$^@]" ;;
		esac
	fi
}
compdump () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compgen () {
	local opts prefix suffix job OPTARG OPTIND ret=1 
	local -a name res results jids
	local -A shortopts
	emulate -L sh
	setopt kshglob noshglob braceexpand nokshautoload
	shortopts=(a alias b builtin c command d directory e export f file g group j job k keyword u user v variable) 
	while getopts "o:A:G:C:F:P:S:W:X:abcdefgjkuv" name
	do
		case $name in
			([abcdefgjkuv]) OPTARG="${shortopts[$name]}"  ;&
			(A) case $OPTARG in
					(alias) results+=("${(k)aliases[@]}")  ;;
					(arrayvar) results+=("${(k@)parameters[(R)array*]}")  ;;
					(binding) results+=("${(k)widgets[@]}")  ;;
					(builtin) results+=("${(k)builtins[@]}" "${(k)dis_builtins[@]}")  ;;
					(command) results+=("${(k)commands[@]}" "${(k)aliases[@]}" "${(k)builtins[@]}" "${(k)functions[@]}" "${(k)reswords[@]}")  ;;
					(directory) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N-/)) 
						setopt nobareglobqual ;;
					(disabled) results+=("${(k)dis_builtins[@]}")  ;;
					(enabled) results+=("${(k)builtins[@]}")  ;;
					(export) results+=("${(k)parameters[(R)*export*]}")  ;;
					(file) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N)) 
						setopt nobareglobqual ;;
					(function) results+=("${(k)functions[@]}")  ;;
					(group) emulate zsh
						_groups -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(hostname) emulate zsh
						_hosts -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(job) results+=("${savejobtexts[@]%% *}")  ;;
					(keyword) results+=("${(k)reswords[@]}")  ;;
					(running) jids=("${(@k)savejobstates[(R)running*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(stopped) jids=("${(@k)savejobstates[(R)suspended*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(setopt | shopt) results+=("${(k)options[@]}")  ;;
					(signal) results+=("SIG${^signals[@]}")  ;;
					(user) results+=("${(k)userdirs[@]}")  ;;
					(variable) results+=("${(k)parameters[@]}")  ;;
					(helptopic)  ;;
				esac ;;
			(F) COMPREPLY=() 
				local -a args
				args=("${words[0]}" "${@[-1]}" "${words[CURRENT-2]}") 
				() {
					typeset -h words
					$OPTARG "${args[@]}"
				}
				results+=("${COMPREPLY[@]}")  ;;
			(G) setopt nullglob
				results+=(${~OPTARG}) 
				unsetopt nullglob ;;
			(W) results+=(${(Q)~=OPTARG})  ;;
			(C) results+=($(eval $OPTARG))  ;;
			(P) prefix="$OPTARG"  ;;
			(S) suffix="$OPTARG"  ;;
			(X) if [[ ${OPTARG[0]} = '!' ]]
				then
					results=("${(M)results[@]:#${OPTARG#?}}") 
				else
					results=("${results[@]:#$OPTARG}") 
				fi ;;
		esac
	done
	print -l -r -- "$prefix${^results[@]}$suffix"
}
compinit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compinstall () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@") 
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}
conda_prompt_info () {
	return 1
}
current_branch () {
	git_current_branch
}
d () {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -n 10
	fi
}
default () {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
detect-clipboard () {
	emulate -L zsh
	if [[ "${OSTYPE}" == darwin* ]] && (( ${+commands[pbcopy]} )) && (( ${+commands[pbpaste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | pbcopy
		}
		clippaste () {
			pbpaste
		}
	elif [[ "${OSTYPE}" == (cygwin|msys)* ]]
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" > /dev/clipboard
		}
		clippaste () {
			cat /dev/clipboard
		}
	elif (( $+commands[clip.exe] )) && (( $+commands[powershell.exe] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | clip.exe
		}
		clippaste () {
			powershell.exe -noprofile -command Get-Clipboard
		}
	elif [ -n "${WAYLAND_DISPLAY:-}" ] && (( ${+commands[wl-copy]} )) && (( ${+commands[wl-paste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | wl-copy &> /dev/null &|
		}
		clippaste () {
			wl-paste --no-newline
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xsel]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xsel --clipboard --input
		}
		clippaste () {
			xsel --clipboard --output
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xclip]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &> /dev/null &|
		}
		clippaste () {
			xclip -out -selection clipboard
		}
	elif (( ${+commands[lemonade]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | lemonade copy
		}
		clippaste () {
			lemonade paste
		}
	elif (( ${+commands[doitclient]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | doitclient wclip
		}
		clippaste () {
			doitclient wclip -r
		}
	elif (( ${+commands[win32yank]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | win32yank -i
		}
		clippaste () {
			win32yank -o
		}
	elif [[ $OSTYPE == linux-android* ]] && (( $+commands[termux-clipboard-set] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | termux-clipboard-set
		}
		clippaste () {
			termux-clipboard-get
		}
	elif [ -n "${TMUX:-}" ] && (( ${+commands[tmux]} ))
	then
		clipcopy () {
			tmux load-buffer "${1:--}"
		}
		clippaste () {
			tmux save-buffer -
		}
	else
		_retry_clipboard_detection_or_fail () {
			local clipcmd="${1}" 
			shift
			if detect-clipboard
			then
				"${clipcmd}" "$@"
			else
				print "${clipcmd}: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
				return 1
			fi
		}
		clipcopy () {
			_retry_clipboard_detection_or_fail clipcopy "$@"
		}
		clippaste () {
			_retry_clipboard_detection_or_fail clippaste "$@"
		}
		return 1
	fi
}
diff () {
	command diff --color "$@"
}
dirhistory_back () {
	local cw="" 
	local d="" 
	pop_past cw
	if [[ "" == "$cw" ]]
	then
		dirhistory_past=($PWD) 
		return
	fi
	pop_past d
	if [[ "" != "$d" ]]
	then
		dirhistory_cd $d
		push_future $cw
	else
		push_past $cw
	fi
}
dirhistory_cd () {
	DIRHISTORY_CD="1" 
	cd $1
	unset DIRHISTORY_CD
}
dirhistory_down () {
	cd "$(find . -mindepth 1 -maxdepth 1 -type d | sort -n | head -n 1)" || return 1
}
dirhistory_forward () {
	local d="" 
	pop_future d
	if [[ "" != "$d" ]]
	then
		dirhistory_cd $d
		push_past $d
	fi
}
dirhistory_up () {
	cd .. || return 1
}
dirhistory_zle_dirhistory_back () {
	zle .kill-buffer
	dirhistory_back
	zle .accept-line
}
dirhistory_zle_dirhistory_down () {
	zle .kill-buffer
	dirhistory_down
	zle .accept-line
}
dirhistory_zle_dirhistory_future () {
	zle .kill-buffer
	dirhistory_forward
	zle .accept-line
}
dirhistory_zle_dirhistory_up () {
	zle .kill-buffer
	dirhistory_up
	zle .accept-line
}
down-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
edit-command-line () {
	# undefined
	builtin autoload -XU
}
env_default () {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}
extract () {
	if [ -f "$1" ]
	then
		case "$1" in
			(*.tar.bz2) tar xjf "$1" ;;
			(*.tar.gz) tar xzf "$1" ;;
			(*.bz2) bunzip2 "$1" ;;
			(*.rar) unrar e "$1" ;;
			(*.gz) gunzip "$1" ;;
			(*.tar) tar xf "$1" ;;
			(*.tbz2) tar xjf "$1" ;;
			(*.tgz) tar xzf "$1" ;;
			(*.zip) unzip "$1" ;;
			(*.Z) uncompress "$1" ;;
			(*.7z) 7z x "$1" ;;
			(*) echo "'$1' cannot be extracted" ;;
		esac
	else
		echo "'$1' is not a valid file"
	fi
}
fbr () {
	local branches branch
	branches=$(git branch -a | grep -v HEAD)  && branch=$(echo "$branches" | fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m)  && git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}
fcd () {
	local dir
	dir=$(fd --type d --hidden --follow --exclude .git 2> /dev/null | fzf +m)  && cd "$dir"
}
fe () {
	local file
	file=$(fd --type f --hidden --follow --exclude .git 2> /dev/null | fzf +m)  && ${EDITOR:-vim} "$file"
}
freespace () {
	if [[ -z "$1" ]]
	then
		echo "Usage: $0 <disk>"
		echo "Example: $0 /dev/disk1s1"
		echo
		echo "Possible disks:"
		df -h | awk 'NR == 1 || /^\/dev\/disk/'
		return 1
	fi
	echo "Cleaning purgeable files from disk: $1 ...."
	diskutil secureErase freespace 0 $1
}
gbda () {
	git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2> /dev/null
}
gbds () {
	local default_branch=$(git_main_branch) 
	(( ! $? )) || default_branch=$(git_develop_branch) 
	git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch
	do
		local merge_base=$(git merge-base $default_branch $branch) 
		if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]
		then
			git branch -D $branch
		fi
	done
}
gccd () {
	setopt localoptions extendedglob
	local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}" 
	command git clone --recurse-submodules "$@" || return
	[[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
gdnolock () {
	git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
gdv () {
	git diff -w "$@" | view -
}
getent () {
	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi
}
ggf () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force origin "${b:=$1}"
}
ggfl () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force-with-lease origin "${b:=$1}"
}
ggl () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git pull origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git pull origin "${b:=$1}"
	fi
}
ggp () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git push origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git push origin "${b:=$1}"
	fi
}
ggpnp () {
	if [[ "$#" == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi
}
ggu () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git pull --rebase origin "${b:=$1}"
}
git_commits_ahead () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count @{upstream}..HEAD 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi
}
git_commits_behind () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count HEAD..@{upstream} 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi
}
git_current_branch () {
	local ref
	ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/}
}
git_current_user_email () {
	__git_prompt_git config user.email 2> /dev/null
}
git_current_user_name () {
	__git_prompt_git config user.name 2> /dev/null
}
git_develop_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local branch
	for branch in dev devel develop development
	do
		if command git show-ref -q --verify refs/heads/$branch
		then
			echo $branch
			return 0
		fi
	done
	echo develop
	return 1
}
git_main_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
	do
		if command git show-ref -q --verify $ref
		then
			echo ${ref:t}
			return 0
		fi
	done
	echo master
	return 1
}
git_previous_branch () {
	local ref
	ref=$(__git_prompt_git rev-parse --quiet --symbolic-full-name @{-1} 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]] || [[ -z $ref ]]
	then
		return
	fi
	echo ${ref#refs/heads/}
}
git_prompt_ahead () {
	if [[ -n "$(__git_prompt_git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi
}
git_prompt_behind () {
	if [[ -n "$(__git_prompt_git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi
}
git_prompt_info () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}"
	fi
}
git_prompt_long_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_remote () {
	if [[ -n "$(__git_prompt_git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi
}
git_prompt_short_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_status () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}"
	fi
}
git_remote_status () {
	local remote ahead behind git_remote_status git_remote_status_detailed
	remote=${$(__git_prompt_git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} 
	if [[ -n ${remote} ]]
	then
		ahead=$(__git_prompt_git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l) 
		behind=$(__git_prompt_git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l) 
		if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}" 
		elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		fi
		if [[ -n $ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_PREFIX${remote:gs/%/%%}$git_remote_status_detailed$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_SUFFIX" 
		fi
		echo $git_remote_status
	fi
}
git_repo_name () {
	local repo_path
	if repo_path="$(__git_prompt_git rev-parse --show-toplevel 2>/dev/null)"  && [[ -n "$repo_path" ]]
	then
		echo ${repo_path:t}
	fi
}
grename () {
	if [[ -z "$1" || -z "$2" ]]
	then
		echo "Usage: $0 old_branch new_branch"
		return 1
	fi
	git branch -m "$1" "$2"
	if git push origin :"$1"
	then
		git push --set-upstream origin "$2"
	fi
}
gunwipall () {
	local _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H) 
	if [[ "$_commit" != "$(git rev-parse HEAD)" ]]
	then
		git reset $_commit || return 1
	fi
}
handle_completion_insecurities () {
	local -aU insecure_dirs
	insecure_dirs=(${(f@):-"$(compaudit 2>/dev/null)"}) 
	[[ -z "${insecure_dirs}" ]] && return
	print "[oh-my-zsh] Insecure completion-dependent directories detected:"
	ls -ld "${(@)insecure_dirs}"
	cat <<EOD

[oh-my-zsh] For safety, we will not load completions from these directories until
[oh-my-zsh] you fix their permissions and ownership and restart zsh.
[oh-my-zsh] See the above list for directories with group or other writability.

[oh-my-zsh] To fix your permissions you can do so by disabling
[oh-my-zsh] the write permission of "group" and "others" and making sure that the
[oh-my-zsh] owner of these directories is either root or your current user.
[oh-my-zsh] The following command may help:
[oh-my-zsh]     compaudit | xargs chmod g-w,o-w

[oh-my-zsh] If the above didn't help or you want to skip the verification of
[oh-my-zsh] insecure directories you can set the variable ZSH_DISABLE_COMPFIX to
[oh-my-zsh] "true" before oh-my-zsh is sourced in your zshrc file.

EOD
}
hg_prompt_info () {
	return 1
}
history-substring-search-down () {
	_history-substring-search-begin
	_history-substring-search-down-history || _history-substring-search-down-buffer || _history-substring-search-down-search
	_history-substring-search-end
}
history-substring-search-up () {
	_history-substring-search-begin
	_history-substring-search-up-history || _history-substring-search-up-buffer || _history-substring-search-up-search
	_history-substring-search-end
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
is_plugin () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/plugins/$name/$name.plugin.zsh || builtin test -f $base_dir/plugins/$name/_$name
}
is_theme () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/$name.zsh-theme
}
itunes () {
	local APP_NAME=Music sw_vers=$(sw_vers -productVersion 2>/dev/null) 
	autoload is-at-least
	if [[ -z "$sw_vers" ]] || is-at-least 10.15 $sw_vers
	then
		if [[ $0 = itunes ]]
		then
			echo The itunes function name is deprecated. Use \'music\' instead. >&2
			return 1
		fi
	else
		APP_NAME=iTunes 
	fi
	local opt=$1 playlist=$2 
	(( $# > 0 )) && shift
	case "$opt" in
		(launch | play | pause | stop | rewind | resume | quit)  ;;
		(mute) opt="set mute to true"  ;;
		(unmute) opt="set mute to false"  ;;
		(next | previous) opt="$opt track"  ;;
		(vol) local new_volume volume=$(osascript -e "tell application \"$APP_NAME\" to get sound volume") 
			if [[ $# -eq 0 ]]
			then
				echo "Current volume is ${volume}."
				return 0
			fi
			case $1 in
				(up) new_volume=$((volume + 10 < 100 ? volume + 10 : 100))  ;;
				(down) new_volume=$((volume - 10 > 0 ? volume - 10 : 0))  ;;
				(<0-100>) new_volume=$1  ;;
				(*) echo "'$1' is not valid. Expected <0-100>, up or down."
					return 1 ;;
			esac
			opt="set sound volume to ${new_volume}"  ;;
		(playlist) if [[ -n "$playlist" ]]
			then
				osascript 2> /dev/null <<EOF
          tell application "$APP_NAME"
            set new_playlist to "$playlist" as string
            play playlist new_playlist
          end tell
EOF
				if [[ $? -eq 0 ]]
				then
					opt="play" 
				else
					opt="stop" 
				fi
			else
				opt="set allPlaylists to (get name of every playlist)" 
			fi ;;
		(playing | status) local currenttrack currentartist state=$(osascript -e "tell application \"$APP_NAME\" to player state as string") 
			if [[ "$state" = "playing" ]]
			then
				currenttrack=$(osascript -e "tell application \"$APP_NAME\" to name of current track as string") 
				currentartist=$(osascript -e "tell application \"$APP_NAME\" to artist of current track as string") 
				echo -E "Listening to ${fg[yellow]}${currenttrack}${reset_color} by ${fg[yellow]}${currentartist}${reset_color}"
			else
				echo "$APP_NAME is $state"
			fi
			return 0 ;;
		(shuf | shuff | shuffle) local state=$1 
			if [[ -n "$state" && "$state" != (on|off|toggle) ]]
			then
				print "Usage: $0 shuffle [on|off|toggle]. Invalid option."
				return 1
			fi
			case "$state" in
				(on | off) osascript > /dev/null 2>&1 <<EOF
            tell application "System Events" to perform action "AXPress" of (menu item "${state}" of menu "Shuffle" of menu item "Shuffle" of menu "Controls" of menu bar item "Controls" of menu bar 1 of application process "iTunes" )
EOF
					return 0 ;;
				(toggle | *) osascript > /dev/null 2>&1 <<EOF
            tell application "System Events" to perform action "AXPress" of (button 2 of process "iTunes"'s window "iTunes"'s scroll area 1)
EOF
					return 0 ;;
			esac ;;
		("" | -h | --help) echo "Usage: $0 <option>"
			echo "option:"
			echo "\t-h|--help\tShow this message and exit"
			echo "\tlaunch|play|pause|stop|rewind|resume|quit"
			echo "\tmute|unmute\tMute or unmute $APP_NAME"
			echo "\tnext|previous\tPlay next or previous track"
			echo "\tshuf|shuffle [on|off|toggle]\tSet shuffled playback. Default: toggle. Note: toggle doesn't support the MiniPlayer."
			echo "\tvol [0-100|up|down]\tGet or set the volume. 0 to 100 sets the volume. 'up' / 'down' increases / decreases by 10 points. No argument displays current volume."
			echo "\tplaying|status\tShow what song is currently playing in Music."
			echo "\tplaylist [playlist name]\t Play specific playlist"
			return 0 ;;
		(*) print "Unknown option: $opt"
			return 1 ;;
	esac
	osascript -e "tell application \"$APP_NAME\" to $opt"
}
jenv_prompt_info () {
	return 1
}
man-preview () {
	[[ $# -eq 0 ]] && echo "Usage: $0 command1 [command2 ...]" >&2 && return 1
	local page
	for page in "${(@f)"$(command man -w $@)"}"
	do
		command mandoc -Tpdf $page | open -f -a Preview
	done
}
mcp-add-fs () {
	claude mcp add filesystem --scope project -- npx -y @modelcontextprotocol/server-filesystem .
	echo "✓ Added filesystem server to current project"
}
mcp-add-git () {
	claude mcp add git --scope project -- npx -y @modelcontextprotocol/server-git .
	echo "✓ Added git server to current project"
}
mcp-add-github () {
	read -p "GitHub token: " token
	claude mcp add github --scope project --env "GITHUB_PERSONAL_ACCESS_TOKEN=$token" -- npx -y @modelcontextprotocol/server-github
	echo "✓ Added GitHub server to current project"
}
mkcd () {
	mkdir -pv -p "$1" && cd "$1"
}
music () {
	local APP_NAME=Music sw_vers=$(sw_vers -productVersion 2>/dev/null) 
	autoload is-at-least
	if [[ -z "$sw_vers" ]] || is-at-least 10.15 $sw_vers
	then
		if [[ $0 = itunes ]]
		then
			echo The itunes function name is deprecated. Use \'music\' instead. >&2
			return 1
		fi
	else
		APP_NAME=iTunes 
	fi
	local opt=$1 playlist=$2 
	(( $# > 0 )) && shift
	case "$opt" in
		(launch | play | pause | stop | rewind | resume | quit)  ;;
		(mute) opt="set mute to true"  ;;
		(unmute) opt="set mute to false"  ;;
		(next | previous) opt="$opt track"  ;;
		(vol) local new_volume volume=$(osascript -e "tell application \"$APP_NAME\" to get sound volume") 
			if [[ $# -eq 0 ]]
			then
				echo "Current volume is ${volume}."
				return 0
			fi
			case $1 in
				(up) new_volume=$((volume + 10 < 100 ? volume + 10 : 100))  ;;
				(down) new_volume=$((volume - 10 > 0 ? volume - 10 : 0))  ;;
				(<0-100>) new_volume=$1  ;;
				(*) echo "'$1' is not valid. Expected <0-100>, up or down."
					return 1 ;;
			esac
			opt="set sound volume to ${new_volume}"  ;;
		(playlist) if [[ -n "$playlist" ]]
			then
				osascript 2> /dev/null <<EOF
          tell application "$APP_NAME"
            set new_playlist to "$playlist" as string
            play playlist new_playlist
          end tell
EOF
				if [[ $? -eq 0 ]]
				then
					opt="play" 
				else
					opt="stop" 
				fi
			else
				opt="set allPlaylists to (get name of every playlist)" 
			fi ;;
		(playing | status) local currenttrack currentartist state=$(osascript -e "tell application \"$APP_NAME\" to player state as string") 
			if [[ "$state" = "playing" ]]
			then
				currenttrack=$(osascript -e "tell application \"$APP_NAME\" to name of current track as string") 
				currentartist=$(osascript -e "tell application \"$APP_NAME\" to artist of current track as string") 
				echo -E "Listening to ${fg[yellow]}${currenttrack}${reset_color} by ${fg[yellow]}${currentartist}${reset_color}"
			else
				echo "$APP_NAME is $state"
			fi
			return 0 ;;
		(shuf | shuff | shuffle) local state=$1 
			if [[ -n "$state" && "$state" != (on|off|toggle) ]]
			then
				print "Usage: $0 shuffle [on|off|toggle]. Invalid option."
				return 1
			fi
			case "$state" in
				(on | off) osascript > /dev/null 2>&1 <<EOF
            tell application "System Events" to perform action "AXPress" of (menu item "${state}" of menu "Shuffle" of menu item "Shuffle" of menu "Controls" of menu bar item "Controls" of menu bar 1 of application process "iTunes" )
EOF
					return 0 ;;
				(toggle | *) osascript > /dev/null 2>&1 <<EOF
            tell application "System Events" to perform action "AXPress" of (button 2 of process "iTunes"'s window "iTunes"'s scroll area 1)
EOF
					return 0 ;;
			esac ;;
		("" | -h | --help) echo "Usage: $0 <option>"
			echo "option:"
			echo "\t-h|--help\tShow this message and exit"
			echo "\tlaunch|play|pause|stop|rewind|resume|quit"
			echo "\tmute|unmute\tMute or unmute $APP_NAME"
			echo "\tnext|previous\tPlay next or previous track"
			echo "\tshuf|shuffle [on|off|toggle]\tSet shuffled playback. Default: toggle. Note: toggle doesn't support the MiniPlayer."
			echo "\tvol [0-100|up|down]\tGet or set the volume. 0 to 100 sets the volume. 'up' / 'down' increases / decreases by 10 points. No argument displays current volume."
			echo "\tplaying|status\tShow what song is currently playing in Music."
			echo "\tplaylist [playlist name]\t Play specific playlist"
			return 0 ;;
		(*) print "Unknown option: $opt"
			return 1 ;;
	esac
	osascript -e "tell application \"$APP_NAME\" to $opt"
}
npm_toggle_install_uninstall () {
	local line
	for line in "$BUFFER" "${history[$((HISTCMD-1))]}" "${history[$((HISTCMD-2))]}"
	do
		case "$line" in
			("npm uninstall"*) BUFFER="${line/npm uninstall/npm install}" 
				(( CURSOR = CURSOR + 2 )) ;;
			("npm install"*) BUFFER="${line/npm install/npm uninstall}" 
				(( CURSOR = CURSOR + 2 )) ;;
			("npm un "*) BUFFER="${line/npm un/npm install}" 
				(( CURSOR = CURSOR + 5 )) ;;
			("npm i "*) BUFFER="${line/npm i/npm uninstall}" 
				(( CURSOR = CURSOR + 8 )) ;;
			(*) continue ;;
		esac
		return 0
	done
	BUFFER="npm install" 
	CURSOR=${#BUFFER} 
}
nvm () {
	unset -f nvm
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	nvm "$@"
}
nvm_add_iojs_prefix () {
	nvm_echo "$(nvm_iojs_prefix)-$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${1-}")")"
}
nvm_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err 'An alias is required.'
		return 1
	fi
	ALIAS="$(nvm_normalize_lts "${ALIAS}")" 
	if [ -z "${ALIAS}" ]
	then
		return 2
	fi
	local NVM_ALIAS_PATH
	NVM_ALIAS_PATH="$(nvm_alias_path)/${ALIAS}" 
	if [ ! -f "${NVM_ALIAS_PATH}" ]
	then
		nvm_err 'Alias does not exist.'
		return 2
	fi
	command cat "${NVM_ALIAS_PATH}"
}
nvm_alias_path () {
	nvm_echo "$(nvm_version_dir old)/alias"
}
nvm_auto () {
	local NVM_MODE
	NVM_MODE="${1-}" 
	local VERSION
	local NVM_CURRENT
	if [ "_${NVM_MODE}" = '_install' ]
	then
		VERSION="$(nvm_alias default 2>/dev/null || nvm_echo)" 
		if [ -n "${VERSION}" ]
		then
			nvm install "${VERSION}" > /dev/null
		elif nvm_rc_version > /dev/null 2>&1
		then
			nvm install > /dev/null
		fi
	elif [ "_$NVM_MODE" = '_use' ]
	then
		NVM_CURRENT="$(nvm_ls_current)" 
		if [ "_${NVM_CURRENT}" = '_none' ] || [ "_${NVM_CURRENT}" = '_system' ]
		then
			VERSION="$(nvm_resolve_local_alias default 2>/dev/null || nvm_echo)" 
			if [ -n "${VERSION}" ]
			then
				nvm use --silent "${VERSION}" > /dev/null
			elif nvm_rc_version > /dev/null 2>&1
			then
				nvm use --silent > /dev/null
			fi
		else
			nvm use --silent "${NVM_CURRENT}" > /dev/null
		fi
	elif [ "_${NVM_MODE}" != '_none' ]
	then
		nvm_err 'Invalid auto mode supplied.'
		return 1
	fi
}
nvm_binary_available () {
	nvm_version_greater_than_or_equal_to "$(nvm_strip_iojs_prefix "${1-}")" v0.8.6
}
nvm_cache_dir () {
	nvm_echo "${NVM_DIR}/.cache"
}
nvm_cd () {
	\cd "$@"
}
nvm_change_path () {
	if [ -z "${1-}" ]
	then
		nvm_echo "${3-}${2-}"
	elif ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/[^/]*${2-}" && ! nvm_echo "${1-}" | nvm_grep -q "${NVM_DIR}/versions/[^/]*/[^/]*${2-}"
	then
		nvm_echo "${3-}${2-}:${1-}"
	elif nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/[^/]*${2-}" || nvm_echo "${1-}" | nvm_grep -Eq "(^|:)(/usr(/local)?)?${2-}:.*${NVM_DIR}/versions/[^/]*/[^/]*${2-}"
	then
		nvm_echo "${3-}${2-}:${1-}"
	else
		nvm_echo "${1-}" | command sed -e "s#${NVM_DIR}/[^/]*${2-}[^:]*#${3-}${2-}#" -e "s#${NVM_DIR}/versions/[^/]*/[^/]*${2-}[^:]*#${3-}${2-}#"
	fi
}
nvm_check_file_permissions () {
	nvm_is_zsh && setopt local_options nonomatch
	for FILE in "$1"/* "$1"/.[!.]* "$1"/..?*
	do
		if [ -d "$FILE" ]
		then
			if [ -n "${NVM_DEBUG-}" ]
			then
				nvm_err "${FILE}"
			fi
			if ! nvm_check_file_permissions "${FILE}"
			then
				return 2
			fi
		elif [ -e "$FILE" ] && [ ! -w "$FILE" ] && [ ! -O "$FILE" ]
		then
			nvm_err "file is not writable or self-owned: $(nvm_sanitize_path "$FILE")"
			return 1
		fi
	done
	return 0
}
nvm_clang_version () {
	clang --version | command awk '{ if ($2 == "version") print $3; else if ($3 == "version") print $4 }' | command sed 's/-.*$//g'
}
nvm_command_info () {
	local COMMAND
	local INFO
	COMMAND="${1}" 
	if type "${COMMAND}" | nvm_grep -q hashed
	then
		INFO="$(type "${COMMAND}" | command sed -E 's/\(|\)//g' | command awk '{print $4}')" 
	elif type "${COMMAND}" | nvm_grep -q aliased
	then
		INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4="" ;print }' | command sed -e 's/^\ *//g' -Ee "s/\`|'//g"))" 
	elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is an alias for"
	then
		INFO="$(which "${COMMAND}") ($(type "${COMMAND}" | command awk '{ $1=$2=$3=$4=$5="" ;print }' | command sed 's/^\ *//g'))" 
	elif type "${COMMAND}" | nvm_grep -q "^${COMMAND} is \\/"
	then
		INFO="$(type "${COMMAND}" | command awk '{print $3}')" 
	else
		INFO="$(type "${COMMAND}")" 
	fi
	nvm_echo "${INFO}"
}
nvm_compare_checksum () {
	local FILE
	FILE="${1-}" 
	if [ -z "${FILE}" ]
	then
		nvm_err 'Provided file to checksum is empty.'
		return 4
	elif ! [ -f "${FILE}" ]
	then
		nvm_err 'Provided file to checksum does not exist.'
		return 3
	fi
	local COMPUTED_SUM
	COMPUTED_SUM="$(nvm_compute_checksum "${FILE}")" 
	local CHECKSUM
	CHECKSUM="${2-}" 
	if [ -z "${CHECKSUM}" ]
	then
		nvm_err 'Provided checksum to compare to is empty.'
		return 2
	fi
	if [ -z "${COMPUTED_SUM}" ]
	then
		nvm_err "Computed checksum of '${FILE}' is empty."
		nvm_err 'WARNING: Continuing *without checksum verification*'
		return
	elif [ "${COMPUTED_SUM}" != "${CHECKSUM}" ]
	then
		nvm_err "Checksums do not match: '${COMPUTED_SUM}' found, '${CHECKSUM}' expected."
		return 1
	fi
	nvm_err 'Checksums matched!'
}
nvm_compute_checksum () {
	local FILE
	FILE="${1-}" 
	if [ -z "${FILE}" ]
	then
		nvm_err 'Provided file to checksum is empty.'
		return 2
	elif ! [ -f "${FILE}" ]
	then
		nvm_err 'Provided file to checksum does not exist.'
		return 1
	fi
	if nvm_has_non_aliased "sha256sum"
	then
		nvm_err 'Computing checksum with sha256sum'
		command sha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "shasum"
	then
		nvm_err 'Computing checksum with shasum -a 256'
		command shasum -a 256 "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha256"
	then
		nvm_err 'Computing checksum with sha256 -q'
		command sha256 -q "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "gsha256sum"
	then
		nvm_err 'Computing checksum with gsha256sum'
		command gsha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "openssl"
	then
		nvm_err 'Computing checksum with openssl dgst -sha256'
		command openssl dgst -sha256 "${FILE}" | command awk '{print $NF}'
	elif nvm_has_non_aliased "bssl"
	then
		nvm_err 'Computing checksum with bssl sha256sum'
		command bssl sha256sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha1sum"
	then
		nvm_err 'Computing checksum with sha1sum'
		command sha1sum "${FILE}" | command awk '{print $1}'
	elif nvm_has_non_aliased "sha1"
	then
		nvm_err 'Computing checksum with sha1 -q'
		command sha1 -q "${FILE}"
	fi
}
nvm_curl_libz_support () {
	curl -V 2> /dev/null | nvm_grep "^Features:" | nvm_grep -q "libz"
}
nvm_curl_use_compression () {
	nvm_curl_libz_support && nvm_version_greater_than_or_equal_to "$(nvm_curl_version)" 7.21.0
}
nvm_curl_version () {
	curl -V | command awk '{ if ($1 == "curl") print $2 }' | command sed 's/-.*$//g'
}
nvm_die_on_prefix () {
	local NVM_DELETE_PREFIX
	NVM_DELETE_PREFIX="${1-}" 
	case "${NVM_DELETE_PREFIX}" in
		(0 | 1)  ;;
		(*) nvm_err 'First argument "delete the prefix" must be zero or one'
			return 1 ;;
	esac
	local NVM_COMMAND
	NVM_COMMAND="${2-}" 
	local NVM_VERSION_DIR
	NVM_VERSION_DIR="${3-}" 
	if [ -z "${NVM_COMMAND}" ] || [ -z "${NVM_VERSION_DIR}" ]
	then
		nvm_err 'Second argument "nvm command", and third argument "nvm version dir", must both be nonempty'
		return 2
	fi
	if [ -n "${PREFIX-}" ] && [ "$(nvm_version_path "$(node -v)")" != "${PREFIX}" ]
	then
		nvm deactivate > /dev/null 2>&1
		nvm_err "nvm is not compatible with the \"PREFIX\" environment variable: currently set to \"${PREFIX}\""
		nvm_err 'Run `unset PREFIX` to unset it.'
		return 3
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_NPM_CONFIG_x_PREFIX_ENV
	NVM_NPM_CONFIG_x_PREFIX_ENV="$(command awk 'BEGIN { for (name in ENVIRON) if (toupper(name) == "NPM_CONFIG_PREFIX") { print name; break } }')" 
	if [ -n "${NVM_NPM_CONFIG_x_PREFIX_ENV-}" ]
	then
		local NVM_CONFIG_VALUE
		eval "NVM_CONFIG_VALUE=\"\$${NVM_NPM_CONFIG_x_PREFIX_ENV}\""
		if [ -n "${NVM_CONFIG_VALUE-}" ] && [ "_${NVM_OS}" = "_win" ]
		then
			NVM_CONFIG_VALUE="$(cd "$NVM_CONFIG_VALUE" 2>/dev/null && pwd)" 
		fi
		if [ -n "${NVM_CONFIG_VALUE-}" ] && ! nvm_tree_contains_path "${NVM_DIR}" "${NVM_CONFIG_VALUE}"
		then
			nvm deactivate > /dev/null 2>&1
			nvm_err "nvm is not compatible with the \"${NVM_NPM_CONFIG_x_PREFIX_ENV}\" environment variable: currently set to \"${NVM_CONFIG_VALUE}\""
			nvm_err "Run \`unset ${NVM_NPM_CONFIG_x_PREFIX_ENV}\` to unset it."
			return 4
		fi
	fi
	local NVM_NPM_BUILTIN_NPMRC
	NVM_NPM_BUILTIN_NPMRC="${NVM_VERSION_DIR}/lib/node_modules/npm/npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_BUILTIN_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
			npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_BUILTIN_NPMRC}"
		else
			nvm_err "Your builtin npmrc file ($(nvm_sanitize_path "${NVM_NPM_BUILTIN_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_GLOBAL_NPMRC
	NVM_NPM_GLOBAL_NPMRC="${NVM_VERSION_DIR}/etc/npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_GLOBAL_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --global --loglevel=warn delete prefix
			npm config --global --loglevel=warn delete globalconfig
		else
			nvm_err "Your global npmrc file ($(nvm_sanitize_path "${NVM_NPM_GLOBAL_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_USER_NPMRC
	NVM_NPM_USER_NPMRC="${HOME}/.npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_USER_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix --userconfig="${NVM_NPM_USER_NPMRC}"
			npm config --loglevel=warn delete globalconfig --userconfig="${NVM_NPM_USER_NPMRC}"
		else
			nvm_err "Your user’s .npmrc file ($(nvm_sanitize_path "${NVM_NPM_USER_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
	local NVM_NPM_PROJECT_NPMRC
	NVM_NPM_PROJECT_NPMRC="$(nvm_find_project_dir)/.npmrc" 
	if nvm_npmrc_bad_news_bears "${NVM_NPM_PROJECT_NPMRC}"
	then
		if [ "_${NVM_DELETE_PREFIX}" = "_1" ]
		then
			npm config --loglevel=warn delete prefix
			npm config --loglevel=warn delete globalconfig
		else
			nvm_err "Your project npmrc file ($(nvm_sanitize_path "${NVM_NPM_PROJECT_NPMRC}"))"
			nvm_err 'has a `globalconfig` and/or a `prefix` setting, which are incompatible with nvm.'
			nvm_err "Run \`${NVM_COMMAND}\` to unset it."
			return 10
		fi
	fi
}
nvm_download () {
	local CURL_COMPRESSED_FLAG
	if nvm_has "curl"
	then
		if nvm_curl_use_compression
		then
			CURL_COMPRESSED_FLAG="--compressed" 
		fi
		curl --fail ${CURL_COMPRESSED_FLAG:-} -q "$@"
	elif nvm_has "wget"
	then
		ARGS=$(nvm_echo "$@" | command sed -e 's/--progress-bar /--progress=bar /' \
                            -e 's/--compressed //' \
                            -e 's/--fail //' \
                            -e 's/-L //' \
                            -e 's/-I /--server-response /' \
                            -e 's/-s /-q /' \
                            -e 's/-sS /-nv /' \
                            -e 's/-o /-O /' \
                            -e 's/-C - /-c /') 
		eval wget $ARGS
	fi
}
nvm_download_artifact () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 1 ;;
	esac
	local KIND
	case "${2-}" in
		(binary | source) KIND="${2}"  ;;
		(*) nvm_err 'supported kinds: binary, source'
			return 1 ;;
	esac
	local TYPE
	TYPE="${3-}" 
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")" 
	if [ -z "${MIRROR}" ]
	then
		return 2
	fi
	local VERSION
	VERSION="${4}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	if [ "${KIND}" = 'binary' ] && ! nvm_binary_available "${VERSION}"
	then
		nvm_err "No precompiled binary available for ${VERSION}."
		return
	fi
	local SLUG
	SLUG="$(nvm_get_download_slug "${FLAVOR}" "${KIND}" "${VERSION}")" 
	local COMPRESSION
	COMPRESSION="$(nvm_get_artifact_compression "${VERSION}")" 
	local CHECKSUM
	CHECKSUM="$(nvm_get_checksum "${FLAVOR}" "${TYPE}" "${VERSION}" "${SLUG}" "${COMPRESSION}")" 
	local tmpdir
	if [ "${KIND}" = 'binary' ]
	then
		tmpdir="$(nvm_cache_dir)/bin/${SLUG}" 
	else
		tmpdir="$(nvm_cache_dir)/src/${SLUG}" 
	fi
	command mkdir -p "${tmpdir}/files" || (
		nvm_err "creating directory ${tmpdir}/files failed"
		return 3
	)
	local TARBALL
	TARBALL="${tmpdir}/${SLUG}.${COMPRESSION}" 
	local TARBALL_URL
	if nvm_version_greater_than_or_equal_to "${VERSION}" 0.1.14
	then
		TARBALL_URL="${MIRROR}/${VERSION}/${SLUG}.${COMPRESSION}" 
	else
		TARBALL_URL="${MIRROR}/${SLUG}.${COMPRESSION}" 
	fi
	if [ -r "${TARBALL}" ]
	then
		nvm_err "Local cache found: $(nvm_sanitize_path "${TARBALL}")"
		if nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" > /dev/null 2>&1
		then
			nvm_err "Checksums match! Using existing downloaded archive $(nvm_sanitize_path "${TARBALL}")"
			nvm_echo "${TARBALL}"
			return 0
		fi
		nvm_compare_checksum "${TARBALL}" "${CHECKSUM}"
		nvm_err "Checksum check failed!"
		nvm_err "Removing the broken local cache..."
		command rm -rf "${TARBALL}"
	fi
	nvm_err "Downloading ${TARBALL_URL}..."
	nvm_download -L -C - "${PROGRESS_BAR}" "${TARBALL_URL}" -o "${TARBALL}" || (
		command rm -rf "${TARBALL}" "${tmpdir}"
		nvm_err "Binary download from ${TARBALL_URL} failed, trying source."
		return 4
	)
	if nvm_grep '404 Not Found' "${TARBALL}" > /dev/null
	then
		command rm -rf "${TARBALL}" "${tmpdir}"
		nvm_err "HTTP 404 at URL ${TARBALL_URL}"
		return 5
	fi
	nvm_compare_checksum "${TARBALL}" "${CHECKSUM}" || (
		command rm -rf "${tmpdir}/files"
		return 6
	)
	nvm_echo "${TARBALL}"
}
nvm_echo () {
	command printf %s\\n "$*" 2> /dev/null
}
nvm_echo_with_colors () {
	command printf %b\\n "$*" 2> /dev/null
}
nvm_ensure_default_set () {
	local VERSION
	VERSION="$1" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'nvm_ensure_default_set: a version is required'
		return 1
	elif nvm_alias default > /dev/null 2>&1
	then
		return 0
	fi
	local OUTPUT
	OUTPUT="$(nvm alias default "${VERSION}")" 
	local EXIT_CODE
	EXIT_CODE="$?" 
	nvm_echo "Creating default alias: ${OUTPUT}"
	return $EXIT_CODE
}
nvm_ensure_version_installed () {
	local PROVIDED_VERSION
	PROVIDED_VERSION="${1-}" 
	if [ "${PROVIDED_VERSION}" = 'system' ]
	then
		if nvm_has_system_iojs || nvm_has_system_node
		then
			return 0
		fi
		nvm_err "N/A: no system version of node/io.js is installed."
		return 1
	fi
	local LOCAL_VERSION
	local EXIT_CODE
	LOCAL_VERSION="$(nvm_version "${PROVIDED_VERSION}")" 
	EXIT_CODE="$?" 
	local NVM_VERSION_DIR
	if [ "${EXIT_CODE}" != "0" ] || ! nvm_is_version_installed "${LOCAL_VERSION}"
	then
		if VERSION="$(nvm_resolve_alias "${PROVIDED_VERSION}")" 
		then
			nvm_err "N/A: version \"${PROVIDED_VERSION} -> ${VERSION}\" is not yet installed."
		else
			local PREFIXED_VERSION
			PREFIXED_VERSION="$(nvm_ensure_version_prefix "${PROVIDED_VERSION}")" 
			nvm_err "N/A: version \"${PREFIXED_VERSION:-$PROVIDED_VERSION}\" is not yet installed."
		fi
		nvm_err ""
		nvm_err "You need to run \"nvm install ${PROVIDED_VERSION}\" to install it before using it."
		return 1
	fi
}
nvm_ensure_version_prefix () {
	local NVM_VERSION
	NVM_VERSION="$(nvm_strip_iojs_prefix "${1-}" | command sed -e 's/^\([0-9]\)/v\1/g')" 
	if nvm_is_iojs_version "${1-}"
	then
		nvm_add_iojs_prefix "${NVM_VERSION}"
	else
		nvm_echo "${NVM_VERSION}"
	fi
}
nvm_err () {
	nvm_echo "$@" >&2
}
nvm_err_with_colors () {
	nvm_echo_with_colors "$@" >&2
}
nvm_find_nvmrc () {
	local dir
	dir="$(nvm_find_up '.nvmrc')" 
	if [ -e "${dir}/.nvmrc" ]
	then
		nvm_echo "${dir}/.nvmrc"
	fi
}
nvm_find_project_dir () {
	local path_
	path_="${PWD}" 
	while [ "${path_}" != "" ] && [ ! -f "${path_}/package.json" ] && [ ! -d "${path_}/node_modules" ]
	do
		path_=${path_%/*} 
	done
	nvm_echo "${path_}"
}
nvm_find_up () {
	local path_
	path_="${PWD}" 
	while [ "${path_}" != "" ] && [ ! -f "${path_}/${1-}" ]
	do
		path_=${path_%/*} 
	done
	nvm_echo "${path_}"
}
nvm_format_version () {
	local VERSION
	VERSION="$(nvm_ensure_version_prefix "${1-}")" 
	local NUM_GROUPS
	NUM_GROUPS="$(nvm_num_version_groups "${VERSION}")" 
	if [ "${NUM_GROUPS}" -lt 3 ]
	then
		nvm_format_version "${VERSION%.}.0"
	else
		nvm_echo "${VERSION}" | command cut -f1-3 -d.
	fi
}
nvm_get_arch () {
	local HOST_ARCH
	local NVM_OS
	local EXIT_CODE
	NVM_OS="$(nvm_get_os)" 
	if [ "_${NVM_OS}" = "_sunos" ]
	then
		if HOST_ARCH=$(pkg_info -Q MACHINE_ARCH pkg_install) 
		then
			HOST_ARCH=$(nvm_echo "${HOST_ARCH}" | command tail -1) 
		else
			HOST_ARCH=$(isainfo -n) 
		fi
	elif [ "_${NVM_OS}" = "_aix" ]
	then
		HOST_ARCH=ppc64 
	else
		HOST_ARCH="$(command uname -m)" 
	fi
	local NVM_ARCH
	case "${HOST_ARCH}" in
		(x86_64 | amd64) NVM_ARCH="x64"  ;;
		(i*86) NVM_ARCH="x86"  ;;
		(aarch64) NVM_ARCH="arm64"  ;;
		(*) NVM_ARCH="${HOST_ARCH}"  ;;
	esac
	L=$(ls -dl /sbin/init 2>/dev/null) 
	if [ "$(uname)" = "Linux" ] && [ "${NVM_ARCH}" = arm64 ] && [ "$(od -An -t x1 -j 4 -N 1 "${L#*-> }")" = ' 01' ]
	then
		NVM_ARCH=armv7l 
		HOST_ARCH=armv7l 
	fi
	nvm_echo "${NVM_ARCH}"
}
nvm_get_artifact_compression () {
	local VERSION
	VERSION="${1-}" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local COMPRESSION
	COMPRESSION='tar.gz' 
	if [ "_${NVM_OS}" = '_win' ]
	then
		COMPRESSION='zip' 
	elif nvm_supports_xz "${VERSION}"
	then
		COMPRESSION='tar.xz' 
	fi
	nvm_echo "${COMPRESSION}"
}
nvm_get_checksum () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 2 ;;
	esac
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${2-}")" 
	if [ -z "${MIRROR}" ]
	then
		return 1
	fi
	local SHASUMS_URL
	if [ "$(nvm_get_checksum_alg)" = 'sha-256' ]
	then
		SHASUMS_URL="${MIRROR}/${3}/SHASUMS256.txt" 
	else
		SHASUMS_URL="${MIRROR}/${3}/SHASUMS.txt" 
	fi
	nvm_download -L -s "${SHASUMS_URL}" -o - | command awk "{ if (\"${4}.${5}\" == \$2) print \$1}"
}
nvm_get_checksum_alg () {
	local NVM_CHECKSUM_BIN
	NVM_CHECKSUM_BIN="$(nvm_get_checksum_binary 2>/dev/null)" 
	case "${NVM_CHECKSUM_BIN-}" in
		(sha256sum | shasum | sha256 | gsha256sum | openssl | bssl) nvm_echo 'sha-256' ;;
		(sha1sum | sha1) nvm_echo 'sha-1' ;;
		(*) nvm_get_checksum_binary
			return $? ;;
	esac
}
nvm_get_checksum_binary () {
	if nvm_has_non_aliased 'sha256sum'
	then
		nvm_echo 'sha256sum'
	elif nvm_has_non_aliased 'shasum'
	then
		nvm_echo 'shasum'
	elif nvm_has_non_aliased 'sha256'
	then
		nvm_echo 'sha256'
	elif nvm_has_non_aliased 'gsha256sum'
	then
		nvm_echo 'gsha256sum'
	elif nvm_has_non_aliased 'openssl'
	then
		nvm_echo 'openssl'
	elif nvm_has_non_aliased 'bssl'
	then
		nvm_echo 'bssl'
	elif nvm_has_non_aliased 'sha1sum'
	then
		nvm_echo 'sha1sum'
	elif nvm_has_non_aliased 'sha1'
	then
		nvm_echo 'sha1'
	else
		nvm_err 'Unaliased sha256sum, shasum, sha256, gsha256sum, openssl, or bssl not found.'
		nvm_err 'Unaliased sha1sum or sha1 not found.'
		return 1
	fi
}
nvm_get_colors () {
	local COLOR
	local SYS_COLOR
	if [ -n "${NVM_COLORS-}" ]
	then
		case $1 in
			(1) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 1, 1); }')")  ;;
			(2) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 2, 1); }')")  ;;
			(3) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 3, 1); }')")  ;;
			(4) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 4, 1); }')")  ;;
			(5) COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 5, 1); }')")  ;;
			(6) SYS_COLOR=$(nvm_print_color_code "$(echo "$NVM_COLORS" | awk '{ print substr($0, 2, 1); }')") 
				COLOR=$(nvm_echo "$SYS_COLOR" | command tr '0;' '1;')  ;;
			(*) nvm_err "Invalid color index, ${1-}"
				return 1 ;;
		esac
	else
		case $1 in
			(1) COLOR='0;34m'  ;;
			(2) COLOR='0;33m'  ;;
			(3) COLOR='0;32m'  ;;
			(4) COLOR='0;31m'  ;;
			(5) COLOR='0;37m'  ;;
			(6) COLOR='1;33m'  ;;
			(*) nvm_err "Invalid color index, ${1-}"
				return 1 ;;
		esac
	fi
	echo "$COLOR"
}
nvm_get_default_packages () {
	local NVM_DEFAULT_PACKAGE_FILE="${NVM_DIR}/default-packages" 
	if [ -f "${NVM_DEFAULT_PACKAGE_FILE}" ]
	then
		local DEFAULT_PACKAGES
		DEFAULT_PACKAGES='' 
		local line
		WORK=$(mktemp -d)  || exit $?
		trap "command rm -rf '$WORK'" EXIT
		sed -e '$a\' "${NVM_DEFAULT_PACKAGE_FILE}" > "${WORK}/default-packages"
		while IFS=' ' read -r line
		do
			[ -n "${line-}" ] || continue
			[ "$(nvm_echo "${line}" | command cut -c1)" != "#" ] || continue
			case $line in
				(*\ *) nvm_err "Only one package per line is allowed in the ${NVM_DIR}/default-packages file. Please remove any lines with multiple space-separated values."
					return 1 ;;
			esac
			DEFAULT_PACKAGES="${DEFAULT_PACKAGES}${line} " 
		done < "${WORK}/default-packages"
		echo "${DEFAULT_PACKAGES}" | command xargs
	fi
}
nvm_get_download_slug () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 1 ;;
	esac
	local KIND
	case "${2-}" in
		(binary | source) KIND="${2}"  ;;
		(*) nvm_err 'supported kinds: binary, source'
			return 2 ;;
	esac
	local VERSION
	VERSION="${3-}" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_ARCH
	NVM_ARCH="$(nvm_get_arch)" 
	if ! nvm_is_merged_node_version "${VERSION}"
	then
		if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]
		then
			NVM_ARCH="arm-pi" 
		fi
	fi
	if nvm_version_greater '16.0.0' "${VERSION}"
	then
		if [ "_${NVM_OS}" = '_darwin' ] && [ "${NVM_ARCH}" = 'arm64' ]
		then
			NVM_ARCH=x64 
		fi
	fi
	if [ "${KIND}" = 'binary' ]
	then
		nvm_echo "${FLAVOR}-${VERSION}-${NVM_OS}-${NVM_ARCH}"
	elif [ "${KIND}" = 'source' ]
	then
		nvm_echo "${FLAVOR}-${VERSION}"
	fi
}
nvm_get_latest () {
	local NVM_LATEST_URL
	local CURL_COMPRESSED_FLAG
	if nvm_has "curl"
	then
		if nvm_curl_use_compression
		then
			CURL_COMPRESSED_FLAG="--compressed" 
		fi
		NVM_LATEST_URL="$(curl ${CURL_COMPRESSED_FLAG:-} -q -w "%{url_effective}\\n" -L -s -S http://latest.nvm.sh -o /dev/null)" 
	elif nvm_has "wget"
	then
		NVM_LATEST_URL="$(wget -q http://latest.nvm.sh --server-response -O /dev/null 2>&1 | command awk '/^  Location: /{DEST=$2} END{ print DEST }')" 
	else
		nvm_err 'nvm needs curl or wget to proceed.'
		return 1
	fi
	if [ -z "${NVM_LATEST_URL}" ]
	then
		nvm_err "http://latest.nvm.sh did not redirect to the latest release on GitHub"
		return 2
	fi
	nvm_echo "${NVM_LATEST_URL##*/}"
}
nvm_get_make_jobs () {
	if nvm_is_natural_num "${1-}"
	then
		NVM_MAKE_JOBS="$1" 
		nvm_echo "number of \`make\` jobs: ${NVM_MAKE_JOBS}"
		return
	elif [ -n "${1-}" ]
	then
		unset NVM_MAKE_JOBS
		nvm_err "$1 is invalid for number of \`make\` jobs, must be a natural number"
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local NVM_CPU_CORES
	case "_${NVM_OS}" in
		("_linux") NVM_CPU_CORES="$(nvm_grep -c -E '^processor.+: [0-9]+' /proc/cpuinfo)"  ;;
		("_freebsd" | "_darwin" | "_openbsd") NVM_CPU_CORES="$(sysctl -n hw.ncpu)"  ;;
		("_sunos") NVM_CPU_CORES="$(psrinfo | wc -l)"  ;;
		("_aix") NVM_CPU_CORES="$(pmcycles -m | wc -l)"  ;;
	esac
	if ! nvm_is_natural_num "${NVM_CPU_CORES}"
	then
		nvm_err 'Can not determine how many core(s) are available, running in single-threaded mode.'
		nvm_err 'Please report an issue on GitHub to help us make nvm run faster on your computer!'
		NVM_MAKE_JOBS=1 
	else
		nvm_echo "Detected that you have ${NVM_CPU_CORES} CPU core(s)"
		if [ "${NVM_CPU_CORES}" -gt 2 ]
		then
			NVM_MAKE_JOBS=$((NVM_CPU_CORES - 1)) 
			nvm_echo "Running with ${NVM_MAKE_JOBS} threads to speed up the build"
		else
			NVM_MAKE_JOBS=1 
			nvm_echo 'Number of CPU core(s) less than or equal to 2, running in single-threaded mode'
		fi
	fi
}
nvm_get_minor_version () {
	local VERSION
	VERSION="$1" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'a version is required'
		return 1
	fi
	case "${VERSION}" in
		(v | .* | *..* | v*[!.0123456789]* | [!v]*[!.0123456789]* | [!v0123456789]* | v[!0123456789]*) nvm_err 'invalid version number'
			return 2 ;;
	esac
	local PREFIXED_VERSION
	PREFIXED_VERSION="$(nvm_format_version "${VERSION}")" 
	local MINOR
	MINOR="$(nvm_echo "${PREFIXED_VERSION}" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2)" 
	if [ -z "${MINOR}" ]
	then
		nvm_err 'invalid version number! (please report this)'
		return 3
	fi
	nvm_echo "${MINOR}"
}
nvm_get_mirror () {
	case "${1}-${2}" in
		(node-std) nvm_echo "${NVM_NODEJS_ORG_MIRROR:-https://nodejs.org/dist}" ;;
		(iojs-std) nvm_echo "${NVM_IOJS_ORG_MIRROR:-https://iojs.org/dist}" ;;
		(*) nvm_err 'unknown type of node.js or io.js release'
			return 1 ;;
	esac
}
nvm_get_os () {
	local NVM_UNAME
	NVM_UNAME="$(command uname -a)" 
	local NVM_OS
	case "${NVM_UNAME}" in
		(Linux\ *) NVM_OS=linux  ;;
		(Darwin\ *) NVM_OS=darwin  ;;
		(SunOS\ *) NVM_OS=sunos  ;;
		(FreeBSD\ *) NVM_OS=freebsd  ;;
		(OpenBSD\ *) NVM_OS=openbsd  ;;
		(AIX\ *) NVM_OS=aix  ;;
		(CYGWIN* | MSYS* | MINGW*) NVM_OS=win  ;;
	esac
	nvm_echo "${NVM_OS-}"
}
nvm_grep () {
	GREP_OPTIONS='' command grep "$@"
}
nvm_has () {
	type "${1-}" > /dev/null 2>&1
}
nvm_has_colors () {
	local NVM_NUM_COLORS
	if nvm_has tput
	then
		NVM_NUM_COLORS="$(tput -T "${TERM:-vt100}" colors)" 
	fi
	[ "${NVM_NUM_COLORS:--1}" -ge 8 ]
}
nvm_has_non_aliased () {
	nvm_has "${1-}" && ! nvm_is_alias "${1-}"
}
nvm_has_solaris_binary () {
	local VERSION="${1-}" 
	if nvm_is_merged_node_version "${VERSION}"
	then
		return 0
	elif nvm_is_iojs_version "${VERSION}"
	then
		nvm_iojs_version_has_solaris_binary "${VERSION}"
	else
		nvm_node_version_has_solaris_binary "${VERSION}"
	fi
}
nvm_has_system_iojs () {
	[ "$(nvm deactivate >/dev/null 2>&1 && command -v iojs)" != '' ]
}
nvm_has_system_node () {
	[ "$(nvm deactivate >/dev/null 2>&1 && command -v node)" != '' ]
}
nvm_install_binary () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 4 ;;
	esac
	local TYPE
	TYPE="${2-}" 
	local PREFIXED_VERSION
	PREFIXED_VERSION="${3-}" 
	if [ -z "${PREFIXED_VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	local nosource
	nosource="${4-}" 
	local VERSION
	VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")" 
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	if [ -z "${NVM_OS}" ]
	then
		return 2
	fi
	local TARBALL
	local TMPDIR
	local PROGRESS_BAR
	local NODE_OR_IOJS
	if [ "${FLAVOR}" = 'node' ]
	then
		NODE_OR_IOJS="${FLAVOR}" 
	elif [ "${FLAVOR}" = 'iojs' ]
	then
		NODE_OR_IOJS="io.js" 
	fi
	if [ "${NVM_NO_PROGRESS-}" = "1" ]
	then
		PROGRESS_BAR="-sS" 
	else
		PROGRESS_BAR="--progress-bar" 
	fi
	nvm_echo "Downloading and installing ${NODE_OR_IOJS-} ${VERSION}..."
	TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" binary "${TYPE-}" "${VERSION}" | command tail -1)" 
	if [ -f "${TARBALL}" ]
	then
		TMPDIR="$(dirname "${TARBALL}")/files" 
	fi
	if nvm_install_binary_extract "${NVM_OS}" "${PREFIXED_VERSION}" "${VERSION}" "${TARBALL}" "${TMPDIR}"
	then
		if [ -n "${ALIAS-}" ]
		then
			nvm alias "${ALIAS}" "${provided_version}"
		fi
		return 0
	fi
	if [ "${nosource-}" = '1' ]
	then
		nvm_err 'Binary download failed. Download from source aborted.'
		return 0
	fi
	nvm_err 'Binary download failed, trying source.'
	if [ -n "${TMPDIR-}" ]
	then
		command rm -rf "${TMPDIR}"
	fi
	return 1
}
nvm_install_binary_extract () {
	if [ "$#" -ne 5 ]
	then
		nvm_err 'nvm_install_binary_extract needs 5 parameters'
		return 1
	fi
	local NVM_OS
	local PREFIXED_VERSION
	local VERSION
	local TARBALL
	local TMPDIR
	NVM_OS="${1}" 
	PREFIXED_VERSION="${2}" 
	VERSION="${3}" 
	TARBALL="${4}" 
	TMPDIR="${5}" 
	local VERSION_PATH
	[ -n "${TMPDIR-}" ] && command mkdir -p "${TMPDIR}" && VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")"  || return 1
	if [ "${NVM_OS}" = 'win' ]
	then
		VERSION_PATH="${VERSION_PATH}/bin" 
		command unzip -q "${TARBALL}" -d "${TMPDIR}" || return 1
	else
		local tar_compression_flag
		tar_compression_flag='z' 
		if nvm_supports_xz "${VERSION}"
		then
			tar_compression_flag='J' 
		fi
		local tar
		if [ "${NVM_OS}" = 'aix' ]
		then
			tar='gtar' 
		else
			tar='tar' 
		fi
		command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" --strip-components 1 || return 1
	fi
	command mkdir -p "${VERSION_PATH}" || return 1
	if [ "${NVM_OS}" = 'win' ]
	then
		command mv "${TMPDIR}/"*/* "${VERSION_PATH}" || return 1
		command chmod +x "${VERSION_PATH}"/node.exe || return 1
		command chmod +x "${VERSION_PATH}"/npm || return 1
		command chmod +x "${VERSION_PATH}"/npx 2> /dev/null
	else
		command mv "${TMPDIR}/"* "${VERSION_PATH}" || return 1
	fi
	command rm -rf "${TMPDIR}"
	return 0
}
nvm_install_default_packages () {
	nvm_echo "Installing default global packages from ${NVM_DIR}/default-packages..."
	nvm_echo "npm install -g --quiet $1"
	if ! nvm_echo "$1" | command xargs npm install -g --quiet
	then
		nvm_err "Failed installing default packages. Please check if your default-packages file or a package in it has problems!"
		return 1
	fi
}
nvm_install_latest_npm () {
	nvm_echo 'Attempting to upgrade to the latest working version of npm...'
	local NODE_VERSION
	NODE_VERSION="$(nvm_strip_iojs_prefix "$(nvm_ls_current)")" 
	if [ "${NODE_VERSION}" = 'system' ]
	then
		NODE_VERSION="$(node --version)" 
	elif [ "${NODE_VERSION}" = 'none' ]
	then
		nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
		NODE_VERSION='' 
	fi
	if [ -z "${NODE_VERSION}" ]
	then
		nvm_err 'Unable to obtain node version.'
		return 1
	fi
	local NPM_VERSION
	NPM_VERSION="$(npm --version 2>/dev/null)" 
	if [ -z "${NPM_VERSION}" ]
	then
		nvm_err 'Unable to obtain npm version.'
		return 2
	fi
	local NVM_NPM_CMD
	NVM_NPM_CMD='npm' 
	if [ "${NVM_DEBUG-}" = 1 ]
	then
		nvm_echo "Detected node version ${NODE_VERSION}, npm version v${NPM_VERSION}"
		NVM_NPM_CMD='nvm_echo npm' 
	fi
	local NVM_IS_0_6
	NVM_IS_0_6=0 
	if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.6.0 && nvm_version_greater 0.7.0 "${NODE_VERSION}"
	then
		NVM_IS_0_6=1 
	fi
	local NVM_IS_0_9
	NVM_IS_0_9=0 
	if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 0.9.0 && nvm_version_greater 0.10.0 "${NODE_VERSION}"
	then
		NVM_IS_0_9=1 
	fi
	if [ $NVM_IS_0_6 -eq 1 ]
	then
		nvm_echo '* `node` v0.6.x can only upgrade to `npm` v1.3.x'
		$NVM_NPM_CMD install -g npm@1.3
	elif [ $NVM_IS_0_9 -eq 0 ]
	then
		if nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 1.0.0 && nvm_version_greater 2.0.0 "${NPM_VERSION}"
		then
			nvm_echo '* `npm` v1.x needs to first jump to `npm` v1.4.28 to be able to upgrade further'
			$NVM_NPM_CMD install -g npm@1.4.28
		elif nvm_version_greater_than_or_equal_to "${NPM_VERSION}" 2.0.0 && nvm_version_greater 3.0.0 "${NPM_VERSION}"
		then
			nvm_echo '* `npm` v2.x needs to first jump to the latest v2 to be able to upgrade further'
			$NVM_NPM_CMD install -g npm@2
		fi
	fi
	if [ $NVM_IS_0_9 -eq 1 ] || [ $NVM_IS_0_6 -eq 1 ]
	then
		nvm_echo '* node v0.6 and v0.9 are unable to upgrade further'
	elif nvm_version_greater 1.1.0 "${NODE_VERSION}"
	then
		nvm_echo '* `npm` v4.5.x is the last version that works on `node` versions < v1.1.0'
		$NVM_NPM_CMD install -g npm@4.5
	elif nvm_version_greater 4.0.0 "${NODE_VERSION}"
	then
		nvm_echo '* `npm` v5 and higher do not work on `node` versions below v4.0.0'
		$NVM_NPM_CMD install -g npm@4
	elif [ $NVM_IS_0_9 -eq 0 ] && [ $NVM_IS_0_6 -eq 0 ]
	then
		local NVM_IS_4_4_OR_BELOW
		NVM_IS_4_4_OR_BELOW=0 
		if nvm_version_greater 4.5.0 "${NODE_VERSION}"
		then
			NVM_IS_4_4_OR_BELOW=1 
		fi
		local NVM_IS_5_OR_ABOVE
		NVM_IS_5_OR_ABOVE=0 
		if [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 5.0.0
		then
			NVM_IS_5_OR_ABOVE=1 
		fi
		local NVM_IS_6_OR_ABOVE
		NVM_IS_6_OR_ABOVE=0 
		local NVM_IS_6_2_OR_ABOVE
		NVM_IS_6_2_OR_ABOVE=0 
		if [ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.0.0
		then
			NVM_IS_6_OR_ABOVE=1 
			if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 6.2.0
			then
				NVM_IS_6_2_OR_ABOVE=1 
			fi
		fi
		local NVM_IS_9_OR_ABOVE
		NVM_IS_9_OR_ABOVE=0 
		local NVM_IS_9_3_OR_ABOVE
		NVM_IS_9_3_OR_ABOVE=0 
		if [ $NVM_IS_6_2_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.0.0
		then
			NVM_IS_9_OR_ABOVE=1 
			if nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 9.3.0
			then
				NVM_IS_9_3_OR_ABOVE=1 
			fi
		fi
		local NVM_IS_10_OR_ABOVE
		NVM_IS_10_OR_ABOVE=0 
		if [ $NVM_IS_9_3_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 10.0.0
		then
			NVM_IS_10_OR_ABOVE=1 
		fi
		local NVM_IS_12_LTS_OR_ABOVE
		NVM_IS_12_LTS_OR_ABOVE=0 
		if [ $NVM_IS_10_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 12.13.0
		then
			NVM_IS_12_LTS_OR_ABOVE=1 
		fi
		local NVM_IS_13_OR_ABOVE
		NVM_IS_13_OR_ABOVE=0 
		if [ $NVM_IS_12_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 13.0.0
		then
			NVM_IS_13_OR_ABOVE=1 
		fi
		local NVM_IS_14_LTS_OR_ABOVE
		NVM_IS_14_LTS_OR_ABOVE=0 
		if [ $NVM_IS_13_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 14.15.0
		then
			NVM_IS_14_LTS_OR_ABOVE=1 
		fi
		local NVM_IS_15_OR_ABOVE
		NVM_IS_15_OR_ABOVE=0 
		if [ $NVM_IS_14_LTS_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 15.0.0
		then
			NVM_IS_15_OR_ABOVE=1 
		fi
		local NVM_IS_16_OR_ABOVE
		NVM_IS_16_OR_ABOVE=0 
		if [ $NVM_IS_15_OR_ABOVE -eq 1 ] && nvm_version_greater_than_or_equal_to "${NODE_VERSION}" 16.0.0
		then
			NVM_IS_16_OR_ABOVE=1 
		fi
		if [ $NVM_IS_4_4_OR_BELOW -eq 1 ] || {
				[ $NVM_IS_5_OR_ABOVE -eq 1 ] && nvm_version_greater 5.10.0 "${NODE_VERSION}"
			}
		then
			nvm_echo '* `npm` `v5.3.x` is the last version that works on `node` 4.x versions below v4.4, or 5.x versions below v5.10, due to `Buffer.alloc`'
			$NVM_NPM_CMD install -g npm@5.3
		elif [ $NVM_IS_4_4_OR_BELOW -eq 0 ] && nvm_version_greater 4.7.0 "${NODE_VERSION}"
		then
			nvm_echo '* `npm` `v5.4.1` is the last version that works on `node` `v4.5` and `v4.6`'
			$NVM_NPM_CMD install -g npm@5.4.1
		elif [ $NVM_IS_6_OR_ABOVE -eq 0 ]
		then
			nvm_echo '* `npm` `v5.x` is the last version that works on `node` below `v6.0.0`'
			$NVM_NPM_CMD install -g npm@5
		elif {
				[ $NVM_IS_6_OR_ABOVE -eq 1 ] && [ $NVM_IS_6_2_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_9_OR_ABOVE -eq 1 ] && [ $NVM_IS_9_3_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v6.9` is the last version that works on `node` `v6.0.x`, `v6.1.x`, `v9.0.x`, `v9.1.x`, or `v9.2.x`'
			$NVM_NPM_CMD install -g npm@6.9
		elif [ $NVM_IS_10_OR_ABOVE -eq 0 ]
		then
			nvm_echo '* `npm` `v6.x` is the last version that works on `node` below `v10.0.0`'
			$NVM_NPM_CMD install -g npm@6
		elif [ $NVM_IS_12_LTS_OR_ABOVE -eq 0 ] || {
				[ $NVM_IS_13_OR_ABOVE -eq 1 ] && [ $NVM_IS_14_LTS_OR_ABOVE -eq 0 ]
			} || {
				[ $NVM_IS_15_OR_ABOVE -eq 1 ] && [ $NVM_IS_16_OR_ABOVE -eq 0 ]
			}
		then
			nvm_echo '* `npm` `v7.x` is the last version that works on `node` `v13`, `v15`, below `v12.13`, or `v14.0` - `v14.15`'
			$NVM_NPM_CMD install -g npm@7
		else
			nvm_echo '* Installing latest `npm`; if this does not work on your node version, please report a bug!'
			$NVM_NPM_CMD install -g npm
		fi
	fi
	nvm_echo "* npm upgraded to: v$(npm --version 2>/dev/null)"
}
nvm_install_npm_if_needed () {
	local VERSION
	VERSION="$(nvm_ls_current)" 
	if ! nvm_has "npm"
	then
		nvm_echo 'Installing npm...'
		if nvm_version_greater 0.2.0 "${VERSION}"
		then
			nvm_err 'npm requires node v0.2.3 or higher'
		elif nvm_version_greater_than_or_equal_to "${VERSION}" 0.2.0
		then
			if nvm_version_greater 0.2.3 "${VERSION}"
			then
				nvm_err 'npm requires node v0.2.3 or higher'
			else
				nvm_download -L https://npmjs.org/install.sh -o - | clean=yes npm_install=0.2.19 sh
			fi
		else
			nvm_download -L https://npmjs.org/install.sh -o - | clean=yes sh
		fi
	fi
	return $?
}
nvm_install_source () {
	local FLAVOR
	case "${1-}" in
		(node | iojs) FLAVOR="${1}"  ;;
		(*) nvm_err 'supported flavors: node, iojs'
			return 4 ;;
	esac
	local TYPE
	TYPE="${2-}" 
	local PREFIXED_VERSION
	PREFIXED_VERSION="${3-}" 
	if [ -z "${PREFIXED_VERSION}" ]
	then
		nvm_err 'A version number is required.'
		return 3
	fi
	local VERSION
	VERSION="$(nvm_strip_iojs_prefix "${PREFIXED_VERSION}")" 
	local NVM_MAKE_JOBS
	NVM_MAKE_JOBS="${4-}" 
	local ADDITIONAL_PARAMETERS
	ADDITIONAL_PARAMETERS="${5-}" 
	local NVM_ARCH
	NVM_ARCH="$(nvm_get_arch)" 
	if [ "${NVM_ARCH}" = 'armv6l' ] || [ "${NVM_ARCH}" = 'armv7l' ]
	then
		if [ -n "${ADDITIONAL_PARAMETERS}" ]
		then
			ADDITIONAL_PARAMETERS="--without-snapshot ${ADDITIONAL_PARAMETERS}" 
		else
			ADDITIONAL_PARAMETERS='--without-snapshot' 
		fi
	fi
	if [ -n "${ADDITIONAL_PARAMETERS}" ]
	then
		nvm_echo "Additional options while compiling: ${ADDITIONAL_PARAMETERS}"
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	local make
	make='make' 
	local MAKE_CXX
	case "${NVM_OS}" in
		('freebsd' | 'openbsd') make='gmake' 
			MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"  ;;
		('darwin') MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}"  ;;
		('aix') make='gmake'  ;;
	esac
	if nvm_has "clang++" && nvm_has "clang" && nvm_version_greater_than_or_equal_to "$(nvm_clang_version)" 3.5
	then
		if [ -z "${CC-}" ] || [ -z "${CXX-}" ]
		then
			nvm_echo "Clang v3.5+ detected! CC or CXX not specified, will use Clang as C/C++ compiler!"
			MAKE_CXX="CC=${CC:-cc} CXX=${CXX:-c++}" 
		fi
	fi
	local tar_compression_flag
	tar_compression_flag='z' 
	if nvm_supports_xz "${VERSION}"
	then
		tar_compression_flag='J' 
	fi
	local tar
	tar='tar' 
	if [ "${NVM_OS}" = 'aix' ]
	then
		tar='gtar' 
	fi
	local TARBALL
	local TMPDIR
	local VERSION_PATH
	if [ "${NVM_NO_PROGRESS-}" = "1" ]
	then
		PROGRESS_BAR="-sS" 
	else
		PROGRESS_BAR="--progress-bar" 
	fi
	nvm_is_zsh && setopt local_options shwordsplit
	TARBALL="$(PROGRESS_BAR="${PROGRESS_BAR}" nvm_download_artifact "${FLAVOR}" source "${TYPE}" "${VERSION}" | command tail -1)"  && [ -f "${TARBALL}" ] && TMPDIR="$(dirname "${TARBALL}")/files"  && if ! (
			command mkdir -p "${TMPDIR}" && command "${tar}" -x${tar_compression_flag}f "${TARBALL}" -C "${TMPDIR}" --strip-components 1 && VERSION_PATH="$(nvm_version_path "${PREFIXED_VERSION}")"  && nvm_cd "${TMPDIR}" && nvm_echo '$>'./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS'<' && ./configure --prefix="${VERSION_PATH}" $ADDITIONAL_PARAMETERS && $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} && command rm -f "${VERSION_PATH}" 2> /dev/null && $make -j "${NVM_MAKE_JOBS}" ${MAKE_CXX-} install
		)
	then
		nvm_err "nvm: install ${VERSION} failed!"
		command rm -rf "${TMPDIR-}"
		return 1
	fi
}
nvm_iojs_prefix () {
	nvm_echo 'iojs'
}
nvm_iojs_version_has_solaris_binary () {
	local IOJS_VERSION
	IOJS_VERSION="$1" 
	local STRIPPED_IOJS_VERSION
	STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${IOJS_VERSION}")" 
	if [ "_${STRIPPED_IOJS_VERSION}" = "${IOJS_VERSION}" ]
	then
		return 1
	fi
	nvm_version_greater_than_or_equal_to "${STRIPPED_IOJS_VERSION}" v3.3.1
}
nvm_is_alias () {
	\alias "${1-}" > /dev/null 2>&1
}
nvm_is_iojs_version () {
	case "${1-}" in
		(iojs-*) return 0 ;;
	esac
	return 1
}
nvm_is_merged_node_version () {
	nvm_version_greater_than_or_equal_to "$1" v4.0.0
}
nvm_is_natural_num () {
	if [ -z "$1" ]
	then
		return 4
	fi
	case "$1" in
		(0) return 1 ;;
		(-*) return 3 ;;
		(*) [ "$1" -eq "$1" ] 2> /dev/null ;;
	esac
}
nvm_is_valid_version () {
	if nvm_validate_implicit_alias "${1-}" 2> /dev/null
	then
		return 0
	fi
	case "${1-}" in
		("$(nvm_iojs_prefix)" | "$(nvm_node_prefix)") return 0 ;;
		(*) local VERSION
			VERSION="$(nvm_strip_iojs_prefix "${1-}")" 
			nvm_version_greater_than_or_equal_to "${VERSION}" 0 ;;
	esac
}
nvm_is_version_installed () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local NVM_NODE_BINARY
	NVM_NODE_BINARY='node' 
	if [ "_$(nvm_get_os)" = '_win' ]
	then
		NVM_NODE_BINARY='node.exe' 
	fi
	if [ -x "$(nvm_version_path "$1" 2>/dev/null)/bin/${NVM_NODE_BINARY}" ]
	then
		return 0
	fi
	return 1
}
nvm_is_zsh () {
	[ -n "${ZSH_VERSION-}" ]
}
nvm_list_aliases () {
	local ALIAS
	ALIAS="${1-}" 
	local NVM_CURRENT
	NVM_CURRENT="$(nvm_ls_current)" 
	local NVM_ALIAS_DIR
	NVM_ALIAS_DIR="$(nvm_alias_path)" 
	command mkdir -p "${NVM_ALIAS_DIR}/lts"
	if [ "${ALIAS}" != "${ALIAS#lts/}" ]
	then
		nvm_alias "${ALIAS}"
		return $?
	fi
	nvm_is_zsh && unsetopt local_options nomatch
	(
		local ALIAS_PATH
		for ALIAS_PATH in "${NVM_ALIAS_DIR}/${ALIAS}"*
		do
			NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}" &
		done
		wait
	) | sort
	(
		local ALIAS_NAME
		for ALIAS_NAME in "$(nvm_node_prefix)" "stable" "unstable"
		do
			{
				if [ ! -f "${NVM_ALIAS_DIR}/${ALIAS_NAME}" ] && {
						[ -z "${ALIAS}" ] || [ "${ALIAS_NAME}" = "${ALIAS}" ]
					}
				then
					NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_default_alias "${ALIAS_NAME}"
				fi
			} &
		done
		wait
		ALIAS_NAME="$(nvm_iojs_prefix)" 
		if [ ! -f "${NVM_ALIAS_DIR}/${ALIAS_NAME}" ] && {
				[ -z "${ALIAS}" ] || [ "${ALIAS_NAME}" = "${ALIAS}" ]
			}
		then
			NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_CURRENT="${NVM_CURRENT}" nvm_print_default_alias "${ALIAS_NAME}"
		fi
	) | sort
	(
		local LTS_ALIAS
		for ALIAS_PATH in "${NVM_ALIAS_DIR}/lts/${ALIAS}"*
		do
			{
				LTS_ALIAS="$(NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS=true nvm_print_alias_path "${NVM_ALIAS_DIR}" "${ALIAS_PATH}")" 
				if [ -n "${LTS_ALIAS}" ]
				then
					nvm_echo "${LTS_ALIAS}"
				fi
			} &
		done
		wait
	) | sort
	return
}
nvm_ls () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSIONS
	VERSIONS='' 
	if [ "${PATTERN}" = 'current' ]
	then
		nvm_ls_current
		return
	fi
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local NVM_VERSION_DIR_IOJS
	NVM_VERSION_DIR_IOJS="$(nvm_version_dir "${NVM_IOJS_PREFIX}")" 
	local NVM_VERSION_DIR_NEW
	NVM_VERSION_DIR_NEW="$(nvm_version_dir new)" 
	local NVM_VERSION_DIR_OLD
	NVM_VERSION_DIR_OLD="$(nvm_version_dir old)" 
	case "${PATTERN}" in
		("${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}") PATTERN="${PATTERN}-"  ;;
		(*) if nvm_resolve_local_alias "${PATTERN}"
			then
				return
			fi
			PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")"  ;;
	esac
	if [ "${PATTERN}" = 'N/A' ]
	then
		return
	fi
	local NVM_PATTERN_STARTS_WITH_V
	case $PATTERN in
		(v*) NVM_PATTERN_STARTS_WITH_V=true  ;;
		(*) NVM_PATTERN_STARTS_WITH_V=false  ;;
	esac
	if [ $NVM_PATTERN_STARTS_WITH_V = true ] && [ "_$(nvm_num_version_groups "${PATTERN}")" = "_3" ]
	then
		if nvm_is_version_installed "${PATTERN}"
		then
			VERSIONS="${PATTERN}" 
		elif nvm_is_version_installed "$(nvm_add_iojs_prefix "${PATTERN}")"
		then
			VERSIONS="$(nvm_add_iojs_prefix "${PATTERN}")" 
		fi
	else
		case "${PATTERN}" in
			("${NVM_IOJS_PREFIX}-" | "${NVM_NODE_PREFIX}-" | "system")  ;;
			(*) local NUM_VERSION_GROUPS
				NUM_VERSION_GROUPS="$(nvm_num_version_groups "${PATTERN}")" 
				if [ "${NUM_VERSION_GROUPS}" = "2" ] || [ "${NUM_VERSION_GROUPS}" = "1" ]
				then
					PATTERN="${PATTERN%.}." 
				fi ;;
		esac
		nvm_is_zsh && setopt local_options shwordsplit
		nvm_is_zsh && unsetopt local_options markdirs
		local NVM_DIRS_TO_SEARCH1
		NVM_DIRS_TO_SEARCH1='' 
		local NVM_DIRS_TO_SEARCH2
		NVM_DIRS_TO_SEARCH2='' 
		local NVM_DIRS_TO_SEARCH3
		NVM_DIRS_TO_SEARCH3='' 
		local NVM_ADD_SYSTEM
		NVM_ADD_SYSTEM=false 
		if nvm_is_iojs_version "${PATTERN}"
		then
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_IOJS}" 
			PATTERN="$(nvm_strip_iojs_prefix "${PATTERN}")" 
			if nvm_has_system_iojs
			then
				NVM_ADD_SYSTEM=true 
			fi
		elif [ "${PATTERN}" = "${NVM_NODE_PREFIX}-" ]
		then
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}" 
			NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}" 
			PATTERN='' 
			if nvm_has_system_node
			then
				NVM_ADD_SYSTEM=true 
			fi
		else
			NVM_DIRS_TO_SEARCH1="${NVM_VERSION_DIR_OLD}" 
			NVM_DIRS_TO_SEARCH2="${NVM_VERSION_DIR_NEW}" 
			NVM_DIRS_TO_SEARCH3="${NVM_VERSION_DIR_IOJS}" 
			if nvm_has_system_iojs || nvm_has_system_node
			then
				NVM_ADD_SYSTEM=true 
			fi
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH1}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH1}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH1='' 
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH2}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH2}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH2="${NVM_DIRS_TO_SEARCH1}" 
		fi
		if ! [ -d "${NVM_DIRS_TO_SEARCH3}" ] || ! (
				command ls -1qA "${NVM_DIRS_TO_SEARCH3}" | nvm_grep -q .
			)
		then
			NVM_DIRS_TO_SEARCH3="${NVM_DIRS_TO_SEARCH2}" 
		fi
		local SEARCH_PATTERN
		if [ -z "${PATTERN}" ]
		then
			PATTERN='v' 
			SEARCH_PATTERN='.*' 
		else
			SEARCH_PATTERN="$(nvm_echo "${PATTERN}" | command sed 's#\.#\\\.#g;')" 
		fi
		if [ -n "${NVM_DIRS_TO_SEARCH1}${NVM_DIRS_TO_SEARCH2}${NVM_DIRS_TO_SEARCH3}" ]
		then
			VERSIONS="$(command find "${NVM_DIRS_TO_SEARCH1}"/* "${NVM_DIRS_TO_SEARCH2}"/* "${NVM_DIRS_TO_SEARCH3}"/* -name . -o -type d -prune -o -path "${PATTERN}*" \
        | command sed -e "
            s#${NVM_VERSION_DIR_IOJS}/#versions/${NVM_IOJS_PREFIX}/#;
            s#^${NVM_DIR}/##;
            \\#^[^v]# d;
            \\#^versions\$# d;
            s#^versions/##;
            s#^v#${NVM_NODE_PREFIX}/v#;
            \\#${SEARCH_PATTERN}# !d;
          " \
          -e 's#^\([^/]\{1,\}\)/\(.*\)$#\2.\1#;' \
        | command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n \
        | command sed -e 's#\(.*\)\.\([^\.]\{1,\}\)$#\2-\1#;' \
                      -e "s#^${NVM_NODE_PREFIX}-##;" \
      )" 
		fi
	fi
	if [ "${NVM_ADD_SYSTEM-}" = true ]
	then
		if [ -z "${PATTERN}" ] || [ "${PATTERN}" = 'v' ]
		then
			VERSIONS="${VERSIONS}$(command printf '\n%s' 'system')" 
		elif [ "${PATTERN}" = 'system' ]
		then
			VERSIONS="$(command printf '%s' 'system')" 
		fi
	fi
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}"
}
nvm_ls_current () {
	local NVM_LS_CURRENT_NODE_PATH
	if ! NVM_LS_CURRENT_NODE_PATH="$(command which node 2>/dev/null)" 
	then
		nvm_echo 'none'
	elif nvm_tree_contains_path "$(nvm_version_dir iojs)" "${NVM_LS_CURRENT_NODE_PATH}"
	then
		nvm_add_iojs_prefix "$(iojs --version 2>/dev/null)"
	elif nvm_tree_contains_path "${NVM_DIR}" "${NVM_LS_CURRENT_NODE_PATH}"
	then
		local VERSION
		VERSION="$(node --version 2>/dev/null)" 
		if [ "${VERSION}" = "v0.6.21-pre" ]
		then
			nvm_echo 'v0.6.21'
		else
			nvm_echo "${VERSION}"
		fi
	else
		nvm_echo 'system'
	fi
}
nvm_ls_remote () {
	local PATTERN
	PATTERN="${1-}" 
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		local IMPLICIT
		IMPLICIT="$(nvm_print_implicit_alias remote "${PATTERN}")" 
		if [ -z "${IMPLICIT-}" ] || [ "${IMPLICIT}" = 'N/A' ]
		then
			nvm_echo "N/A"
			return 3
		fi
		PATTERN="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${IMPLICIT}" | command tail -1 | command awk '{ print $1 }')" 
	elif [ -n "${PATTERN}" ]
	then
		PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")" 
	else
		PATTERN=".*" 
	fi
	NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab node std "${PATTERN}"
}
nvm_ls_remote_index_tab () {
	local LTS
	LTS="${NVM_LTS-}" 
	if [ "$#" -lt 3 ]
	then
		nvm_err 'not enough arguments'
		return 5
	fi
	local FLAVOR
	FLAVOR="${1-}" 
	local TYPE
	TYPE="${2-}" 
	local MIRROR
	MIRROR="$(nvm_get_mirror "${FLAVOR}" "${TYPE}")" 
	if [ -z "${MIRROR}" ]
	then
		return 3
	fi
	local PREFIX
	PREFIX='' 
	case "${FLAVOR}-${TYPE}" in
		(iojs-std) PREFIX="$(nvm_iojs_prefix)-"  ;;
		(node-std) PREFIX=''  ;;
		(iojs-*) nvm_err 'unknown type of io.js release'
			return 4 ;;
		(*) nvm_err 'unknown type of node.js release'
			return 4 ;;
	esac
	local SORT_COMMAND
	SORT_COMMAND='command sort' 
	case "${FLAVOR}" in
		(node) SORT_COMMAND='command sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n'  ;;
	esac
	local PATTERN
	PATTERN="${3-}" 
	if [ "${PATTERN#"${PATTERN%?}"}" = '.' ]
	then
		PATTERN="${PATTERN%.}" 
	fi
	local VERSIONS
	if [ -n "${PATTERN}" ] && [ "${PATTERN}" != '*' ]
	then
		if [ "${FLAVOR}" = 'iojs' ]
		then
			PATTERN="$(nvm_ensure_version_prefix "$(nvm_strip_iojs_prefix "${PATTERN}")")" 
		else
			PATTERN="$(nvm_ensure_version_prefix "${PATTERN}")" 
		fi
	else
		unset PATTERN
	fi
	nvm_is_zsh && setopt local_options shwordsplit
	local VERSION_LIST
	VERSION_LIST="$(nvm_download -L -s "${MIRROR}/index.tab" -o - \
    | command sed "
        1d;
        s/^/${PREFIX}/;
      " \
  )" 
	local LTS_ALIAS
	local LTS_VERSION
	command mkdir -p "$(nvm_alias_path)/lts"
	{
		command awk '{
        if ($10 ~ /^\-?$/) { next }
        if ($10 && !a[tolower($10)]++) {
          if (alias) { print alias, version }
          alias_name = "lts/" tolower($10)
          if (!alias) { print "lts/*", alias_name }
          alias = alias_name
          version = $1
        }
      }
      END {
        if (alias) {
          print alias, version
        }
      }' | while read -r LTS_ALIAS_LINE
		do
			LTS_ALIAS="${LTS_ALIAS_LINE%% *}" 
			LTS_VERSION="${LTS_ALIAS_LINE#* }" 
			nvm_make_alias "${LTS_ALIAS}" "${LTS_VERSION}" > /dev/null 2>&1
		done
	} <<EOF
$VERSION_LIST
EOF
	if [ -n "${LTS-}" ]
	then
		LTS="$(nvm_normalize_lts "lts/${LTS}")" 
		LTS="${LTS#lts/}" 
	fi
	VERSIONS="$({ command awk -v lts="${LTS-}" '{
        if (!$1) { next }
        if (lts && $10 ~ /^\-?$/) { next }
        if (lts && lts != "*" && tolower($10) !~ tolower(lts)) { next }
        if ($10 !~ /^\-?$/) {
          if ($10 && $10 != prev) {
            print $1, $10, "*"
          } else {
            print $1, $10
          }
        } else {
          print $1
        }
        prev=$10;
      }' \
    | nvm_grep -w "${PATTERN:-.*}" \
    | $SORT_COMMAND; } << EOF
$VERSION_LIST
EOF
)" 
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}"
}
nvm_ls_remote_iojs () {
	NVM_LTS="${NVM_LTS-}" nvm_ls_remote_index_tab iojs std "${1-}"
}
nvm_make_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err "an alias name is required"
		return 1
	fi
	local VERSION
	VERSION="${2-}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err "an alias target version is required"
		return 2
	fi
	nvm_echo "${VERSION}" | tee "$(nvm_alias_path)/${ALIAS}" > /dev/null
}
nvm_match_version () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local PROVIDED_VERSION
	PROVIDED_VERSION="$1" 
	case "_${PROVIDED_VERSION}" in
		("_${NVM_IOJS_PREFIX}" | '_io.js') nvm_version "${NVM_IOJS_PREFIX}" ;;
		('_system') nvm_echo 'system' ;;
		(*) nvm_version "${PROVIDED_VERSION}" ;;
	esac
}
nvm_node_prefix () {
	nvm_echo 'node'
}
nvm_node_version_has_solaris_binary () {
	local NODE_VERSION
	NODE_VERSION="$1" 
	local STRIPPED_IOJS_VERSION
	STRIPPED_IOJS_VERSION="$(nvm_strip_iojs_prefix "${NODE_VERSION}")" 
	if [ "_${STRIPPED_IOJS_VERSION}" != "_${NODE_VERSION}" ]
	then
		return 1
	fi
	nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v0.8.6 && ! nvm_version_greater_than_or_equal_to "${NODE_VERSION}" v1.0.0
}
nvm_normalize_lts () {
	local LTS
	LTS="${1-}" 
	if [ "$(expr "${LTS}" : '^lts/-[1-9][0-9]*$')" -gt 0 ]
	then
		local N
		N="$(echo "${LTS}" | cut -d '-' -f 2)" 
		N=$((N+1)) 
		local NVM_ALIAS_DIR
		NVM_ALIAS_DIR="$(nvm_alias_path)" 
		local RESULT
		RESULT="$(command ls "${NVM_ALIAS_DIR}/lts" | command tail -n "${N}" | command head -n 1)" 
		if [ "${RESULT}" != '*' ]
		then
			nvm_echo "lts/${RESULT}"
		else
			nvm_err 'That many LTS releases do not exist yet.'
			return 2
		fi
	else
		nvm_echo "${LTS}"
	fi
}
nvm_normalize_version () {
	command awk 'BEGIN {
    split(ARGV[1], a, /\./);
    printf "%d%06d%06d\n", a[1], a[2], a[3];
    exit;
  }' "${1#v}"
}
nvm_npm_global_modules () {
	local NPMLIST
	local VERSION
	VERSION="$1" 
	NPMLIST=$(nvm use "${VERSION}" >/dev/null && npm list -g --depth=0 2>/dev/null | command sed 1,1d | nvm_grep -v 'UNMET PEER DEPENDENCY') 
	local INSTALLS
	INSTALLS=$(nvm_echo "${NPMLIST}" | command sed -e '/ -> / d' -e '/\(empty\)/ d' -e 's/^.* \(.*@[^ ]*\).*/\1/' -e '/^npm@[^ ]*.*$/ d' | command xargs) 
	local LINKS
	LINKS="$(nvm_echo "${NPMLIST}" | command sed -n 's/.* -> \(.*\)/\1/ p')" 
	nvm_echo "${INSTALLS} //// ${LINKS}"
}
nvm_npmrc_bad_news_bears () {
	local NVM_NPMRC
	NVM_NPMRC="${1-}" 
	if [ -n "${NVM_NPMRC}" ] && [ -f "${NVM_NPMRC}" ] && nvm_grep -Ee '^(prefix|globalconfig) *=' < "${NVM_NPMRC}" > /dev/null
	then
		return 0
	fi
	return 1
}
nvm_num_version_groups () {
	local VERSION
	VERSION="${1-}" 
	VERSION="${VERSION#v}" 
	VERSION="${VERSION%.}" 
	if [ -z "${VERSION}" ]
	then
		nvm_echo "0"
		return
	fi
	local NVM_NUM_DOTS
	NVM_NUM_DOTS=$(nvm_echo "${VERSION}" | command sed -e 's/[^\.]//g') 
	local NVM_NUM_GROUPS
	NVM_NUM_GROUPS=".${NVM_NUM_DOTS}" 
	nvm_echo "${#NVM_NUM_GROUPS}"
}
nvm_print_alias_path () {
	local NVM_ALIAS_DIR
	NVM_ALIAS_DIR="${1-}" 
	if [ -z "${NVM_ALIAS_DIR}" ]
	then
		nvm_err 'An alias dir is required.'
		return 1
	fi
	local ALIAS_PATH
	ALIAS_PATH="${2-}" 
	if [ -z "${ALIAS_PATH}" ]
	then
		nvm_err 'An alias path is required.'
		return 2
	fi
	local ALIAS
	ALIAS="${ALIAS_PATH##"${NVM_ALIAS_DIR}"\/}" 
	local DEST
	DEST="$(nvm_alias "${ALIAS}" 2>/dev/null)"  || :
	if [ -n "${DEST}" ]
	then
		NVM_NO_COLORS="${NVM_NO_COLORS-}" NVM_LTS="${NVM_LTS-}" DEFAULT=false nvm_print_formatted_alias "${ALIAS}" "${DEST}"
	fi
}
nvm_print_color_code () {
	case "${1-}" in
		('r') nvm_echo '0;31m' ;;
		('R') nvm_echo '1;31m' ;;
		('g') nvm_echo '0;32m' ;;
		('G') nvm_echo '1;32m' ;;
		('b') nvm_echo '0;34m' ;;
		('B') nvm_echo '1;34m' ;;
		('c') nvm_echo '0;36m' ;;
		('C') nvm_echo '1;36m' ;;
		('m') nvm_echo '0;35m' ;;
		('M') nvm_echo '1;35m' ;;
		('y') nvm_echo '0;33m' ;;
		('Y') nvm_echo '1;33m' ;;
		('k') nvm_echo '0;30m' ;;
		('K') nvm_echo '1;30m' ;;
		('e') nvm_echo '0;37m' ;;
		('W') nvm_echo '1;37m' ;;
		(*) nvm_err 'Invalid color code'
			return 1 ;;
	esac
}
nvm_print_default_alias () {
	local ALIAS
	ALIAS="${1-}" 
	if [ -z "${ALIAS}" ]
	then
		nvm_err 'A default alias is required.'
		return 1
	fi
	local DEST
	DEST="$(nvm_print_implicit_alias local "${ALIAS}")" 
	if [ -n "${DEST}" ]
	then
		NVM_NO_COLORS="${NVM_NO_COLORS-}" DEFAULT=true nvm_print_formatted_alias "${ALIAS}" "${DEST}"
	fi
}
nvm_print_formatted_alias () {
	local ALIAS
	ALIAS="${1-}" 
	local DEST
	DEST="${2-}" 
	local VERSION
	VERSION="${3-}" 
	if [ -z "${VERSION}" ]
	then
		VERSION="$(nvm_version "${DEST}")"  || :
	fi
	local VERSION_FORMAT
	local ALIAS_FORMAT
	local DEST_FORMAT
	local INSTALLED_COLOR
	local SYSTEM_COLOR
	local CURRENT_COLOR
	local NOT_INSTALLED_COLOR
	local DEFAULT_COLOR
	local LTS_COLOR
	INSTALLED_COLOR=$(nvm_get_colors 1) 
	SYSTEM_COLOR=$(nvm_get_colors 2) 
	CURRENT_COLOR=$(nvm_get_colors 3) 
	NOT_INSTALLED_COLOR=$(nvm_get_colors 4) 
	DEFAULT_COLOR=$(nvm_get_colors 5) 
	LTS_COLOR=$(nvm_get_colors 6) 
	ALIAS_FORMAT='%s' 
	DEST_FORMAT='%s' 
	VERSION_FORMAT='%s' 
	local NEWLINE
	NEWLINE='\n' 
	if [ "_${DEFAULT}" = '_true' ]
	then
		NEWLINE=' (default)\n' 
	fi
	local ARROW
	ARROW='->' 
	if [ -z "${NVM_NO_COLORS}" ] && nvm_has_colors
	then
		ARROW='\033[0;90m->\033[0m' 
		if [ "_${DEFAULT}" = '_true' ]
		then
			NEWLINE=" \033[${DEFAULT_COLOR}(default)\033[0m\n" 
		fi
		if [ "_${VERSION}" = "_${NVM_CURRENT-}" ]
		then
			ALIAS_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${CURRENT_COLOR}%s\033[0m" 
		elif nvm_is_version_installed "${VERSION}"
		then
			ALIAS_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${INSTALLED_COLOR}%s\033[0m" 
		elif [ "${VERSION}" = '∞' ] || [ "${VERSION}" = 'N/A' ]
		then
			ALIAS_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
			DEST_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
			VERSION_FORMAT="\033[${NOT_INSTALLED_COLOR}%s\033[0m" 
		fi
		if [ "_${NVM_LTS-}" = '_true' ]
		then
			ALIAS_FORMAT="\033[${LTS_COLOR}%s\033[0m" 
		fi
		if [ "_${DEST%/*}" = "_lts" ]
		then
			DEST_FORMAT="\033[${LTS_COLOR}%s\033[0m" 
		fi
	elif [ "_${VERSION}" != '_∞' ] && [ "_${VERSION}" != '_N/A' ]
	then
		VERSION_FORMAT='%s *' 
	fi
	if [ "${DEST}" = "${VERSION}" ]
	then
		command printf -- "${ALIAS_FORMAT} ${ARROW} ${VERSION_FORMAT}${NEWLINE}" "${ALIAS}" "${DEST}"
	else
		command printf -- "${ALIAS_FORMAT} ${ARROW} ${DEST_FORMAT} (${ARROW} ${VERSION_FORMAT})${NEWLINE}" "${ALIAS}" "${DEST}" "${VERSION}"
	fi
}
nvm_print_implicit_alias () {
	if [ "_$1" != "_local" ] && [ "_$1" != "_remote" ]
	then
		nvm_err "nvm_print_implicit_alias must be specified with local or remote as the first argument."
		return 1
	fi
	local NVM_IMPLICIT
	NVM_IMPLICIT="$2" 
	if ! nvm_validate_implicit_alias "${NVM_IMPLICIT}"
	then
		return 2
	fi
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local NVM_COMMAND
	local NVM_ADD_PREFIX_COMMAND
	local LAST_TWO
	case "${NVM_IMPLICIT}" in
		("${NVM_IOJS_PREFIX}") NVM_COMMAND="nvm_ls_remote_iojs" 
			NVM_ADD_PREFIX_COMMAND="nvm_add_iojs_prefix" 
			if [ "_$1" = "_local" ]
			then
				NVM_COMMAND="nvm_ls ${NVM_IMPLICIT}" 
			fi
			nvm_is_zsh && setopt local_options shwordsplit
			local NVM_IOJS_VERSION
			local EXIT_CODE
			NVM_IOJS_VERSION="$(${NVM_COMMAND})"  && :
			EXIT_CODE="$?" 
			if [ "_${EXIT_CODE}" = "_0" ]
			then
				NVM_IOJS_VERSION="$(nvm_echo "${NVM_IOJS_VERSION}" | command sed "s/^${NVM_IMPLICIT}-//" | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq | command tail -1)" 
			fi
			if [ "_$NVM_IOJS_VERSION" = "_N/A" ]
			then
				nvm_echo 'N/A'
			else
				${NVM_ADD_PREFIX_COMMAND} "${NVM_IOJS_VERSION}"
			fi
			return $EXIT_CODE ;;
		("${NVM_NODE_PREFIX}") nvm_echo 'stable'
			return ;;
		(*) NVM_COMMAND="nvm_ls_remote" 
			if [ "_$1" = "_local" ]
			then
				NVM_COMMAND="nvm_ls node" 
			fi
			nvm_is_zsh && setopt local_options shwordsplit
			LAST_TWO=$($NVM_COMMAND | nvm_grep -e '^v' | command cut -c2- | command cut -d . -f 1,2 | uniq)  ;;
	esac
	local MINOR
	local STABLE
	local UNSTABLE
	local MOD
	local NORMALIZED_VERSION
	nvm_is_zsh && setopt local_options shwordsplit
	for MINOR in $LAST_TWO
	do
		NORMALIZED_VERSION="$(nvm_normalize_version "$MINOR")" 
		if [ "_0${NORMALIZED_VERSION#?}" != "_$NORMALIZED_VERSION" ]
		then
			STABLE="$MINOR" 
		else
			MOD="$(awk 'BEGIN { print int(ARGV[1] / 1000000) % 2 ; exit(0) }' "${NORMALIZED_VERSION}")" 
			if [ "${MOD}" -eq 0 ]
			then
				STABLE="${MINOR}" 
			elif [ "${MOD}" -eq 1 ]
			then
				UNSTABLE="${MINOR}" 
			fi
		fi
	done
	if [ "_$2" = '_stable' ]
	then
		nvm_echo "${STABLE}"
	elif [ "_$2" = '_unstable' ]
	then
		nvm_echo "${UNSTABLE:-"N/A"}"
	fi
}
nvm_print_npm_version () {
	if nvm_has "npm"
	then
		command printf " (npm v$(npm --version 2>/dev/null))"
	fi
}
nvm_print_versions () {
	local VERSION
	local LTS
	local FORMAT
	local NVM_CURRENT
	local NVM_LATEST_LTS_COLOR
	local NVM_OLD_LTS_COLOR
	local INSTALLED_COLOR
	local SYSTEM_COLOR
	local CURRENT_COLOR
	local NOT_INSTALLED_COLOR
	local DEFAULT_COLOR
	local LTS_COLOR
	INSTALLED_COLOR=$(nvm_get_colors 1) 
	SYSTEM_COLOR=$(nvm_get_colors 2) 
	CURRENT_COLOR=$(nvm_get_colors 3) 
	NOT_INSTALLED_COLOR=$(nvm_get_colors 4) 
	DEFAULT_COLOR=$(nvm_get_colors 5) 
	LTS_COLOR=$(nvm_get_colors 6) 
	NVM_CURRENT=$(nvm_ls_current) 
	NVM_LATEST_LTS_COLOR=$(nvm_echo "${CURRENT_COLOR}" | command tr '0;' '1;') 
	NVM_OLD_LTS_COLOR="${DEFAULT_COLOR}" 
	local NVM_HAS_COLORS
	if [ -z "${NVM_NO_COLORS-}" ] && nvm_has_colors
	then
		NVM_HAS_COLORS=1 
	fi
	local LTS_LENGTH
	local LTS_FORMAT
	nvm_echo "${1-}" | command sed '1!G;h;$!d' | command awk '{ if ($2 && $3 && $3 == "*") { print $1, "(Latest LTS: " $2 ")" } else if ($2) { print $1, "(LTS: " $2 ")" } else { print $1 } }' | command sed '1!G;h;$!d' | while read -r VERSION_LINE
	do
		VERSION="${VERSION_LINE%% *}" 
		LTS="${VERSION_LINE#* }" 
		FORMAT='%15s' 
		if [ "_${VERSION}" = "_${NVM_CURRENT}" ]
		then
			if [ "${NVM_HAS_COLORS-}" = '1' ]
			then
				FORMAT="\033[${CURRENT_COLOR}-> %12s\033[0m" 
			else
				FORMAT='-> %12s *' 
			fi
		elif [ "${VERSION}" = "system" ]
		then
			if [ "${NVM_HAS_COLORS-}" = '1' ]
			then
				FORMAT="\033[${SYSTEM_COLOR}%15s\033[0m" 
			else
				FORMAT='%15s *' 
			fi
		elif nvm_is_version_installed "${VERSION}"
		then
			if [ "${NVM_HAS_COLORS-}" = '1' ]
			then
				FORMAT="\033[${INSTALLED_COLOR}%15s\033[0m" 
			else
				FORMAT='%15s *' 
			fi
		fi
		if [ "${LTS}" != "${VERSION}" ]
		then
			case "${LTS}" in
				(*Latest*) LTS="${LTS##Latest }" 
					LTS_LENGTH="${#LTS}" 
					if [ "${NVM_HAS_COLORS-}" = '1' ]
					then
						LTS_FORMAT="  \\033[${NVM_LATEST_LTS_COLOR}%${LTS_LENGTH}s\\033[0m" 
					else
						LTS_FORMAT="  %${LTS_LENGTH}s" 
					fi ;;
				(*) LTS_LENGTH="${#LTS}" 
					if [ "${NVM_HAS_COLORS-}" = '1' ]
					then
						LTS_FORMAT="  \\033[${NVM_OLD_LTS_COLOR}%${LTS_LENGTH}s\\033[0m" 
					else
						LTS_FORMAT="  %${LTS_LENGTH}s" 
					fi ;;
			esac
			command printf -- "${FORMAT}${LTS_FORMAT}\\n" "${VERSION}" " ${LTS}"
		else
			command printf -- "${FORMAT}\\n" "${VERSION}"
		fi
	done
}
nvm_process_parameters () {
	local NVM_AUTO_MODE
	NVM_AUTO_MODE='use' 
	while [ "$#" -ne 0 ]
	do
		case "$1" in
			(--install) NVM_AUTO_MODE='install'  ;;
			(--no-use) NVM_AUTO_MODE='none'  ;;
		esac
		shift
	done
	nvm_auto "${NVM_AUTO_MODE}"
}
nvm_prompt_info () {
	which nvm &> /dev/null || return
	local nvm_prompt=${$(nvm current)#v} 
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt:gs/%/%%}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
}
nvm_rc_version () {
	export NVM_RC_VERSION='' 
	local NVMRC_PATH
	NVMRC_PATH="$(nvm_find_nvmrc)" 
	if [ ! -e "${NVMRC_PATH}" ]
	then
		if [ "${NVM_SILENT:-0}" -ne 1 ]
		then
			nvm_err "No .nvmrc file found"
		fi
		return 1
	fi
	NVM_RC_VERSION="$(command head -n 1 "${NVMRC_PATH}" | command tr -d '\r')"  || command printf ''
	if [ -z "${NVM_RC_VERSION}" ]
	then
		if [ "${NVM_SILENT:-0}" -ne 1 ]
		then
			nvm_err "Warning: empty .nvmrc file found at \"${NVMRC_PATH}\""
		fi
		return 2
	fi
	if [ "${NVM_SILENT:-0}" -ne 1 ]
	then
		nvm_echo "Found '${NVMRC_PATH}' with version <${NVM_RC_VERSION}>"
	fi
}
nvm_remote_version () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSION
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		case "${PATTERN}" in
			("$(nvm_iojs_prefix)") VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote_iojs | command tail -1)"  && : ;;
			(*) VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${PATTERN}")"  && : ;;
		esac
	else
		VERSION="$(NVM_LTS="${NVM_LTS-}" nvm_remote_versions "${PATTERN}" | command tail -1)" 
	fi
	if [ -n "${NVM_VERSION_ONLY-}" ]
	then
		command awk 'BEGIN {
      n = split(ARGV[1], a);
      print a[1]
    }' "${VERSION}"
	else
		nvm_echo "${VERSION}"
	fi
	if [ "${VERSION}" = 'N/A' ]
	then
		return 3
	fi
}
nvm_remote_versions () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	local PATTERN
	PATTERN="${1-}" 
	local NVM_FLAVOR
	if [ -n "${NVM_LTS-}" ]
	then
		NVM_FLAVOR="${NVM_NODE_PREFIX}" 
	fi
	case "${PATTERN}" in
		("${NVM_IOJS_PREFIX}" | "io.js") NVM_FLAVOR="${NVM_IOJS_PREFIX}" 
			unset PATTERN ;;
		("${NVM_NODE_PREFIX}") NVM_FLAVOR="${NVM_NODE_PREFIX}" 
			unset PATTERN ;;
	esac
	if nvm_validate_implicit_alias "${PATTERN-}" 2> /dev/null
	then
		nvm_err 'Implicit aliases are not supported in nvm_remote_versions.'
		return 1
	fi
	local NVM_LS_REMOTE_EXIT_CODE
	NVM_LS_REMOTE_EXIT_CODE=0 
	local NVM_LS_REMOTE_PRE_MERGED_OUTPUT
	NVM_LS_REMOTE_PRE_MERGED_OUTPUT='' 
	local NVM_LS_REMOTE_POST_MERGED_OUTPUT
	NVM_LS_REMOTE_POST_MERGED_OUTPUT='' 
	if [ -z "${NVM_FLAVOR-}" ] || [ "${NVM_FLAVOR-}" = "${NVM_NODE_PREFIX}" ]
	then
		local NVM_LS_REMOTE_OUTPUT
		NVM_LS_REMOTE_OUTPUT="$(NVM_LTS="${NVM_LTS-}" nvm_ls_remote "${PATTERN-}") "  && :
		NVM_LS_REMOTE_EXIT_CODE=$? 
		NVM_LS_REMOTE_PRE_MERGED_OUTPUT="${NVM_LS_REMOTE_OUTPUT%%v4\.0\.0*}" 
		NVM_LS_REMOTE_POST_MERGED_OUTPUT="${NVM_LS_REMOTE_OUTPUT#"$NVM_LS_REMOTE_PRE_MERGED_OUTPUT"}" 
	fi
	local NVM_LS_REMOTE_IOJS_EXIT_CODE
	NVM_LS_REMOTE_IOJS_EXIT_CODE=0 
	local NVM_LS_REMOTE_IOJS_OUTPUT
	NVM_LS_REMOTE_IOJS_OUTPUT='' 
	if [ -z "${NVM_LTS-}" ] && {
			[ -z "${NVM_FLAVOR-}" ] || [ "${NVM_FLAVOR-}" = "${NVM_IOJS_PREFIX}" ]
		}
	then
		NVM_LS_REMOTE_IOJS_OUTPUT=$(nvm_ls_remote_iojs "${PATTERN-}")  && :
		NVM_LS_REMOTE_IOJS_EXIT_CODE=$? 
	fi
	VERSIONS="$(nvm_echo "${NVM_LS_REMOTE_PRE_MERGED_OUTPUT}
${NVM_LS_REMOTE_IOJS_OUTPUT}
${NVM_LS_REMOTE_POST_MERGED_OUTPUT}" | nvm_grep -v "N/A" | command sed '/^ *$/d')" 
	if [ -z "${VERSIONS}" ]
	then
		nvm_echo 'N/A'
		return 3
	fi
	nvm_echo "${VERSIONS}" | command sed 's/ *$//g'
	return $NVM_LS_REMOTE_EXIT_CODE || $NVM_LS_REMOTE_IOJS_EXIT_CODE
}
nvm_resolve_alias () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local PATTERN
	PATTERN="${1-}" 
	local ALIAS
	ALIAS="${PATTERN}" 
	local ALIAS_TEMP
	local SEEN_ALIASES
	SEEN_ALIASES="${ALIAS}" 
	while true
	do
		ALIAS_TEMP="$(nvm_alias "${ALIAS}" 2>/dev/null || nvm_echo)" 
		if [ -z "${ALIAS_TEMP}" ]
		then
			break
		fi
		if command printf "${SEEN_ALIASES}" | nvm_grep -q -e "^${ALIAS_TEMP}$"
		then
			ALIAS="∞" 
			break
		fi
		SEEN_ALIASES="${SEEN_ALIASES}\\n${ALIAS_TEMP}" 
		ALIAS="${ALIAS_TEMP}" 
	done
	if [ -n "${ALIAS}" ] && [ "_${ALIAS}" != "_${PATTERN}" ]
	then
		local NVM_IOJS_PREFIX
		NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
		local NVM_NODE_PREFIX
		NVM_NODE_PREFIX="$(nvm_node_prefix)" 
		case "${ALIAS}" in
			('∞' | "${NVM_IOJS_PREFIX}" | "${NVM_IOJS_PREFIX}-" | "${NVM_NODE_PREFIX}") nvm_echo "${ALIAS}" ;;
			(*) nvm_ensure_version_prefix "${ALIAS}" ;;
		esac
		return 0
	fi
	if nvm_validate_implicit_alias "${PATTERN}" 2> /dev/null
	then
		local IMPLICIT
		IMPLICIT="$(nvm_print_implicit_alias local "${PATTERN}" 2>/dev/null)" 
		if [ -n "${IMPLICIT}" ]
		then
			nvm_ensure_version_prefix "${IMPLICIT}"
		fi
	fi
	return 2
}
nvm_resolve_local_alias () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local VERSION
	local EXIT_CODE
	VERSION="$(nvm_resolve_alias "${1-}")" 
	EXIT_CODE=$? 
	if [ -z "${VERSION}" ]
	then
		return $EXIT_CODE
	fi
	if [ "_${VERSION}" != '_∞' ]
	then
		nvm_version "${VERSION}"
	else
		nvm_echo "${VERSION}"
	fi
}
nvm_sanitize_path () {
	local SANITIZED_PATH
	SANITIZED_PATH="${1-}" 
	if [ "_${SANITIZED_PATH}" != "_${NVM_DIR}" ]
	then
		SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${NVM_DIR}#\${NVM_DIR}#g")" 
	fi
	if [ "_${SANITIZED_PATH}" != "_${HOME}" ]
	then
		SANITIZED_PATH="$(nvm_echo "${SANITIZED_PATH}" | command sed -e "s#${HOME}#\${HOME}#g")" 
	fi
	nvm_echo "${SANITIZED_PATH}"
}
nvm_set_colors () {
	if [ "${#1}" -eq 5 ] && nvm_echo "$1" | nvm_grep -E "^[rRgGbBcCyYmMkKeW]{1,}$" > /dev/null
	then
		local INSTALLED_COLOR
		local LTS_AND_SYSTEM_COLOR
		local CURRENT_COLOR
		local NOT_INSTALLED_COLOR
		local DEFAULT_COLOR
		INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 1, 1); }')" 
		LTS_AND_SYSTEM_COLOR="$(echo "$1" | awk '{ print substr($0, 2, 1); }')" 
		CURRENT_COLOR="$(echo "$1" | awk '{ print substr($0, 3, 1); }')" 
		NOT_INSTALLED_COLOR="$(echo "$1" | awk '{ print substr($0, 4, 1); }')" 
		DEFAULT_COLOR="$(echo "$1" | awk '{ print substr($0, 5, 1); }')" 
		if ! nvm_has_colors
		then
			nvm_echo "Setting colors to: ${INSTALLED_COLOR} ${LTS_AND_SYSTEM_COLOR} ${CURRENT_COLOR} ${NOT_INSTALLED_COLOR} ${DEFAULT_COLOR}"
			nvm_echo "WARNING: Colors may not display because they are not supported in this shell."
		else
			nvm_echo_with_colors "Setting colors to: \033[$(nvm_print_color_code "${INSTALLED_COLOR}") ${INSTALLED_COLOR}\033[$(nvm_print_color_code "${LTS_AND_SYSTEM_COLOR}") ${LTS_AND_SYSTEM_COLOR}\033[$(nvm_print_color_code "${CURRENT_COLOR}") ${CURRENT_COLOR}\033[$(nvm_print_color_code "${NOT_INSTALLED_COLOR}") ${NOT_INSTALLED_COLOR}\033[$(nvm_print_color_code "${DEFAULT_COLOR}") ${DEFAULT_COLOR}\033[0m"
		fi
		export NVM_COLORS="$1" 
	else
		return 17
	fi
}
nvm_stdout_is_terminal () {
	[ -t 1 ]
}
nvm_strip_iojs_prefix () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	if [ "${1-}" = "${NVM_IOJS_PREFIX}" ]
	then
		nvm_echo
	else
		nvm_echo "${1#"${NVM_IOJS_PREFIX}"-}"
	fi
}
nvm_strip_path () {
	if [ -z "${NVM_DIR-}" ]
	then
		nvm_err '${NVM_DIR} not set!'
		return 1
	fi
	command printf %s "${1-}" | command awk -v NVM_DIR="${NVM_DIR}" -v RS=: '
  index($0, NVM_DIR) == 1 {
    path = substr($0, length(NVM_DIR) + 1)
    if (path ~ "^(/versions/[^/]*)?/[^/]*'"${2-}"'.*$") { next }
  }
  { print }' | command paste -s -d: -
}
nvm_supports_xz () {
	if [ -z "${1-}" ]
	then
		return 1
	fi
	local NVM_OS
	NVM_OS="$(nvm_get_os)" 
	if [ "_${NVM_OS}" = '_darwin' ]
	then
		local MACOS_VERSION
		MACOS_VERSION="$(sw_vers -productVersion)" 
		if nvm_version_greater "10.9.0" "${MACOS_VERSION}"
		then
			return 1
		fi
	elif [ "_${NVM_OS}" = '_freebsd' ]
	then
		if ! [ -e '/usr/lib/liblzma.so' ]
		then
			return 1
		fi
	else
		if ! command which xz > /dev/null 2>&1
		then
			return 1
		fi
	fi
	if nvm_is_merged_node_version "${1}"
	then
		return 0
	fi
	if nvm_version_greater_than_or_equal_to "${1}" "0.12.10" && nvm_version_greater "0.13.0" "${1}"
	then
		return 0
	fi
	if nvm_version_greater_than_or_equal_to "${1}" "0.10.42" && nvm_version_greater "0.11.0" "${1}"
	then
		return 0
	fi
	case "${NVM_OS}" in
		(darwin) nvm_version_greater_than_or_equal_to "${1}" "2.3.2" ;;
		(*) nvm_version_greater_than_or_equal_to "${1}" "1.0.0" ;;
	esac
	return $?
}
nvm_tree_contains_path () {
	local tree
	tree="${1-}" 
	local node_path
	node_path="${2-}" 
	if [ "@${tree}@" = "@@" ] || [ "@${node_path}@" = "@@" ]
	then
		nvm_err "both the tree and the node path are required"
		return 2
	fi
	local previous_pathdir
	previous_pathdir="${node_path}" 
	local pathdir
	pathdir=$(dirname "${previous_pathdir}") 
	while [ "${pathdir}" != '' ] && [ "${pathdir}" != '.' ] && [ "${pathdir}" != '/' ] && [ "${pathdir}" != "${tree}" ] && [ "${pathdir}" != "${previous_pathdir}" ]
	do
		previous_pathdir="${pathdir}" 
		pathdir=$(dirname "${previous_pathdir}") 
	done
	[ "${pathdir}" = "${tree}" ]
}
nvm_use_if_needed () {
	if [ "_${1-}" = "_$(nvm_ls_current)" ]
	then
		return
	fi
	nvm use "$@"
}
nvm_validate_implicit_alias () {
	local NVM_IOJS_PREFIX
	NVM_IOJS_PREFIX="$(nvm_iojs_prefix)" 
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	case "$1" in
		("stable" | "unstable" | "${NVM_IOJS_PREFIX}" | "${NVM_NODE_PREFIX}") return ;;
		(*) nvm_err "Only implicit aliases 'stable', 'unstable', '${NVM_IOJS_PREFIX}', and '${NVM_NODE_PREFIX}' are supported."
			return 1 ;;
	esac
}
nvm_version () {
	local PATTERN
	PATTERN="${1-}" 
	local VERSION
	if [ -z "${PATTERN}" ]
	then
		PATTERN='current' 
	fi
	if [ "${PATTERN}" = "current" ]
	then
		nvm_ls_current
		return $?
	fi
	local NVM_NODE_PREFIX
	NVM_NODE_PREFIX="$(nvm_node_prefix)" 
	case "_${PATTERN}" in
		("_${NVM_NODE_PREFIX}" | "_${NVM_NODE_PREFIX}-") PATTERN="stable"  ;;
	esac
	VERSION="$(nvm_ls "${PATTERN}" | command tail -1)" 
	if [ -z "${VERSION}" ] || [ "_${VERSION}" = "_N/A" ]
	then
		nvm_echo "N/A"
		return 3
	fi
	nvm_echo "${VERSION}"
}
nvm_version_dir () {
	local NVM_WHICH_DIR
	NVM_WHICH_DIR="${1-}" 
	if [ -z "${NVM_WHICH_DIR}" ] || [ "${NVM_WHICH_DIR}" = "new" ]
	then
		nvm_echo "${NVM_DIR}/versions/node"
	elif [ "_${NVM_WHICH_DIR}" = "_iojs" ]
	then
		nvm_echo "${NVM_DIR}/versions/io.js"
	elif [ "_${NVM_WHICH_DIR}" = "_old" ]
	then
		nvm_echo "${NVM_DIR}"
	else
		nvm_err 'unknown version dir'
		return 3
	fi
}
nvm_version_greater () {
	command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (b[i] && b[i] !~ /^[0-9]+$/) { exit(0); }
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(4)
  }' "${1#v}" "${2#v}"
}
nvm_version_greater_than_or_equal_to () {
	command awk 'BEGIN {
    if (ARGV[1] == "" || ARGV[2] == "") exit(1)
    split(ARGV[1], a, /\./);
    split(ARGV[2], b, /\./);
    for (i=1; i<=3; i++) {
      if (a[i] && a[i] !~ /^[0-9]+$/) exit(2);
      if (a[i] < b[i]) exit(3);
      else if (a[i] > b[i]) exit(0);
    }
    exit(0)
  }' "${1#v}" "${2#v}"
}
nvm_version_path () {
	local VERSION
	VERSION="${1-}" 
	if [ -z "${VERSION}" ]
	then
		nvm_err 'version is required'
		return 3
	elif nvm_is_iojs_version "${VERSION}"
	then
		nvm_echo "$(nvm_version_dir iojs)/$(nvm_strip_iojs_prefix "${VERSION}")"
	elif nvm_version_greater 0.12.0 "${VERSION}"
	then
		nvm_echo "$(nvm_version_dir old)/${VERSION}"
	else
		nvm_echo "$(nvm_version_dir new)/${VERSION}"
	fi
}
ofd () {
	if (( ! $# ))
	then
		open_command $PWD
	else
		open_command $@
	fi
}
omz () {
	setopt localoptions noksharrays
	[[ $# -gt 0 ]] || {
		_omz::help
		return 1
	}
	local command="$1" 
	shift
	(( ${+functions[_omz::$command]} )) || {
		_omz::help
		return 1
	}
	_omz::$command "$@"
}
omz_diagnostic_dump () {
	emulate -L zsh
	builtin echo "Generating diagnostic dump; please be patient..."
	local thisfcn=omz_diagnostic_dump 
	local -A opts
	local opt_verbose opt_noverbose opt_outfile
	local timestamp=$(date +%Y%m%d-%H%M%S) 
	local outfile=omz_diagdump_$timestamp.txt 
	builtin zparseopts -A opts -D -- "v+=opt_verbose" "V+=opt_noverbose"
	local verbose n_verbose=${#opt_verbose} n_noverbose=${#opt_noverbose} 
	(( verbose = 1 + n_verbose - n_noverbose ))
	if [[ ${#*} > 0 ]]
	then
		opt_outfile=$1 
	fi
	if [[ ${#*} > 1 ]]
	then
		builtin echo "$thisfcn: error: too many arguments" >&2
		return 1
	fi
	if [[ -n "$opt_outfile" ]]
	then
		outfile="$opt_outfile" 
	fi
	_omz_diag_dump_one_big_text &> "$outfile"
	if [[ $? != 0 ]]
	then
		builtin echo "$thisfcn: error while creating diagnostic dump; see $outfile for details"
	fi
	builtin echo
	builtin echo Diagnostic dump file created at: "$outfile"
	builtin echo
	builtin echo To share this with OMZ developers, post it as a gist on GitHub
	builtin echo at "https://gist.github.com" and share the link to the gist.
	builtin echo
	builtin echo "WARNING: This dump file contains all your zsh and omz configuration files,"
	builtin echo "so don't share it publicly if there's sensitive information in them."
	builtin echo
}
omz_history () {
	local clear list stamp REPLY
	zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp
	if [[ -n "$clear" ]]
	then
		print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
		builtin read -E
		[[ "$REPLY" = [yY] ]] || return 0
		print -nu2 >| "$HISTFILE"
		fc -p "$HISTFILE"
		print -u2 History file deleted.
	elif [[ $# -eq 0 ]]
	then
		builtin fc "${stamp[@]}" -l 1
	else
		builtin fc "${stamp[@]}" -l "$@"
	fi
}
omz_termsupport_cwd () {
	setopt localoptions unset
	local URL_HOST URL_PATH
	URL_HOST="$(omz_urlencode -P $HOST)"  || return 1
	URL_PATH="$(omz_urlencode -P $PWD)"  || return 1
	[[ -z "$KONSOLE_PROFILE_NAME" && -z "$KONSOLE_DBUS_SESSION" ]] || URL_HOST="" 
	printf "\e]7;file://%s%s\e\\" "${URL_HOST}" "${URL_PATH}"
}
omz_termsupport_precmd () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}
omz_termsupport_preexec () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return
	emulate -L zsh
	setopt extended_glob
	local -a cmdargs
	cmdargs=("${(z)2}") 
	if [[ "${cmdargs[1]}" = fg ]]
	then
		local job_id jobspec="${cmdargs[2]#%}" 
		case "$jobspec" in
			(<->) job_id=${jobspec}  ;;
			("" | % | +) job_id=${(k)jobstates[(r)*:+:*]}  ;;
			(-) job_id=${(k)jobstates[(r)*:-:*]}  ;;
			([?]*) job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]}  ;;
			(*) job_id=${(k)jobtexts[(r)${(Q)jobspec}*]}  ;;
		esac
		if [[ -n "${jobtexts[$job_id]}" ]]
		then
			1="${jobtexts[$job_id]}" 
			2="${jobtexts[$job_id]}" 
		fi
	fi
	local CMD="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}" 
	local LINE="${2:gs/%/%%}" 
	title "$CMD" "%100>...>${LINE}%<<"
}
omz_urldecode () {
	emulate -L zsh
	local encoded_url=$1 
	local caller_encoding=$langinfo[CODESET] 
	local LC_ALL=C 
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /} 
	tmp=${tmp:gs/\\/\\\\/} 
	tmp=${tmp:gs/%/\\x/} 
	local decoded="$(printf -- "$tmp")" 
	local -a safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]
	then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi
	echo -E "$decoded"
}
omz_urlencode () {
	emulate -L zsh
	setopt norematchpcre
	local -a opts
	zparseopts -D -E -a opts r m P
	local in_str="$@" 
	local url_str="" 
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]
	then
		spaces_as_plus=1 
	fi
	local str="$in_str" 
	local encoding=$langinfo[CODESET] 
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$encoding]} ]]
	then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi
	local i byte ord LC_ALL=C 
	export LC_ALL
	local reserved=';/?:@&=+$,' 
	local mark='_.!~*''()-' 
	local dont_escape="[A-Za-z0-9" 
	if [[ -z $opts[(r)-r] ]]
	then
		dont_escape+=$reserved 
	fi
	if [[ -z $opts[(r)-m] ]]
	then
		dont_escape+=$mark 
	fi
	dont_escape+="]" 
	local url_str="" 
	for ((i = 1; i <= ${#str}; ++i )) do
		byte="$str[i]" 
		if [[ "$byte" =~ "$dont_escape" ]]
		then
			url_str+="$byte" 
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]
			then
				url_str+="+" 
			elif [[ "$PREFIX" = *com.termux* ]]
			then
				url_str+="$byte" 
			else
				ord=$(( [##16] #byte )) 
				url_str+="%$ord" 
			fi
		fi
	done
	echo -E "$url_str"
}
open_command () {
	local open_cmd
	case "$OSTYPE" in
		(darwin*) open_cmd='open'  ;;
		(cygwin*) open_cmd='cygstart'  ;;
		(linux*) [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open'  || {
				open_cmd='cmd.exe /c start ""' 
				[[ -e "$1" ]] && {
					1="$(wslpath -w "${1:a}")"  || return 1
				}
				[[ "$1" = (http|https)://* ]] && {
					1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')"  || return 1
				}
			} ;;
		(msys*) open_cmd='start ""'  ;;
		(*) echo "Platform $OSTYPE not supported"
			return 1 ;;
	esac
	if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]
	then
		"$BROWSER" "$@"
		return
	fi
	${=open_cmd} "$@" &> /dev/null
}
parse_git_dirty () {
	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain') 
	if [[ "$(__git_prompt_git config --get oh-my-zsh.hide-dirty)" != "1" ]]
	then
		if [[ "${DISABLE_UNTRACKED_FILES_DIRTY:-}" == "true" ]]
		then
			FLAGS+='--untracked-files=no' 
		fi
		case "${GIT_STATUS_IGNORE_SUBMODULES:-}" in
			(git)  ;;
			(*) FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"  ;;
		esac
		STATUS=$(__git_prompt_git status ${FLAGS} 2> /dev/null | tail -n 1) 
	fi
	if [[ -n $STATUS ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
	else
		echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
	fi
}
pfd () {
	osascript 2> /dev/null <<EOF
    tell application "Finder"
      return POSIX path of (insertion location as alias)
    end tell
EOF
}
pfs () {
	osascript 2> /dev/null <<EOF
    set output to ""
    tell application "Finder" to set the_selection to selection
    set item_count to count the_selection
    repeat with item_index from 1 to count the_selection
      if item_index is less than item_count then set the_delimiter to "\n"
      if item_index is item_count then set the_delimiter to ""
      set output to output & ((item item_index of the_selection as alias)'s POSIX path) & the_delimiter
    end repeat
EOF
}
pop_future () {
	setopt localoptions no_ksh_arrays
	if [[ $#dirhistory_future -gt 0 ]]
	then
		typeset -g $1="${dirhistory_future[$#dirhistory_future]}"
		dirhistory_future[$#dirhistory_future]=() 
	fi
}
pop_past () {
	setopt localoptions no_ksh_arrays
	if [[ $#dirhistory_past -gt 0 ]]
	then
		typeset -g $1="${dirhistory_past[$#dirhistory_past]}"
		dirhistory_past[$#dirhistory_past]=() 
	fi
}
push_future () {
	setopt localoptions no_ksh_arrays
	if [[ $#dirhistory_future -ge $DIRHISTORY_SIZE ]]
	then
		shift dirhistory_future
	fi
	if [[ $#dirhistory_future -eq 0 || $dirhistory_futuret[$#dirhistory_future] != "$1" ]]
	then
		dirhistory_future+=($1) 
	fi
}
push_past () {
	setopt localoptions no_ksh_arrays
	if [[ $#dirhistory_past -ge $DIRHISTORY_SIZE ]]
	then
		shift dirhistory_past
	fi
	if [[ $#dirhistory_past -eq 0 || $dirhistory_past[$#dirhistory_past] != "$1" ]]
	then
		dirhistory_past+=($1) 
	fi
}
pushdf () {
	pushd "$(pfd)"
}
pxd () {
	dirname $(osascript 2>/dev/null <<EOF
    if application "Xcode" is running then
      tell application "Xcode"
        return path of active workspace document
      end tell
    end if
EOF
)
}
pyenv () {
	local command=${1:-} 
	[ "$#" -gt 0 ] && shift
	case "$command" in
		(rehash | shell) eval "$(pyenv "sh-$command" "$@")" ;;
		(*) command pyenv "$command" "$@" ;;
	esac
}
pyenv_prompt_info () {
	local version="$(pyenv version-name)" 
	if [[ "$ZSH_THEME_PYENV_NO_SYSTEM" == "true" ]] && [[ "${version}" == "system" ]]
	then
		return
	fi
	echo "${ZSH_THEME_PYENV_PREFIX=}${version:gs/%/%%}${ZSH_THEME_PYENV_SUFFIX=}"
}
quick-look () {
	(( $# > 0 )) && qlmanage -p $* &> /dev/null &
}
rbenv () {
	local command
	command="${1:-}" 
	if [ "$#" -gt 0 ]
	then
		shift
	fi
	case "$command" in
		(rehash | shell) eval "$(rbenv "sh-$command" "$@")" ;;
		(*) command rbenv "$command" "$@" ;;
	esac
}
rbenv_prompt_info () {
	return 1
}
regexp-replace () {
	argv=("$1" "$2" "$3") 
	4=0 
	[[ -o re_match_pcre ]] && 4=1 
	emulate -L zsh
	local MATCH MBEGIN MEND
	local -a match mbegin mend
	if (( $4 ))
	then
		zmodload zsh/pcre || return 2
		pcre_compile -- "$2" && pcre_study || return 2
		4=0 6= 
		local ZPCRE_OP
		while pcre_match -b -n $4 -- "${(P)1}"
		do
			5=${(e)3} 
			argv+=(${(s: :)ZPCRE_OP} "$5") 
			4=$((argv[-2] + (argv[-3] == argv[-2]))) 
		done
		(($# > 6)) || return
		set +o multibyte
		5= 6=1 
		for 2 3 4 in "$@[7,-1]"
		do
			5+=${(P)1[$6,$2]}$4 
			6=$(($3 + 1)) 
		done
		5+=${(P)1[$6,-1]} 
	else
		4=${(P)1} 
		while [[ -n $4 ]]
		do
			if [[ $4 =~ $2 ]]
			then
				5+=${4[1,MBEGIN-1]}${(e)3} 
				if ((MEND < MBEGIN))
				then
					((MEND++))
					5+=${4[1]} 
				fi
				4=${4[MEND+1,-1]} 
				6=1 
			else
				break
			fi
		done
		[[ -n $6 ]] || return
		5+=$4 
	fi
	eval $1=\$5
}
rmdsstore () {
	find "${@:-.}" -type f -name .DS_Store -delete
}
ruby_prompt_info () {
	echo "$(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info)"
}
rvm_prompt_info () {
	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null) 
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt:gs/%/%%}${ZSH_THEME_RUBY_PROMPT_SUFFIX}"
}
search () {
	if command -v rg &> /dev/null
	then
		rg "$@"
	else
		grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -r "$@" .
	fi
}
serve () {
	local port="${1:-8000}" 
	echo "🌐 Serving on http://localhost:$port"
	python3 -m http.server "$port"
}
spectrum_bls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
spectrum_ls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
split_tab () {
	local command="cd \\\"$PWD\\\"; clear" 
	(( $# > 0 )) && command="${command}; $*" 
	local the_app=$(_omz_macos_get_frontmost_app) 
	if [[ "$the_app" == 'iTerm' ]]
	then
		osascript 2> /dev/null <<EOF
      tell application "iTerm" to activate

      tell application "System Events"
        tell process "iTerm"
          tell menu item "Split Horizontally With Current Profile" of menu "Shell" of menu bar item "Shell" of menu bar 1
            click
          end tell
        end tell
        keystroke "${command} \n"
      end tell
EOF
	elif [[ "$the_app" == 'iTerm2' ]]
	then
		osascript <<EOF
      tell application "iTerm2"
        tell current session of first window
          set newSession to (split horizontally with same profile)
          tell newSession
            write text "${command}"
            select
          end tell
        end tell
      end tell
EOF
	elif [[ "$the_app" == 'Hyper' ]]
	then
		osascript > /dev/null <<EOF
    tell application "System Events"
      tell process "Hyper"
        tell menu item "Split Horizontally" of menu "Shell" of menu bar 1
          click
        end tell
      end tell
      delay 1
      keystroke "${command} \n"
    end tell
EOF
	elif [[ "$the_app" == 'Tabby' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Tabby" to keystroke "d" using command down
      end tell
EOF
	elif [[ "$the_app" == 'ghostty' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Ghostty" to keystroke "d" using command down
      end tell
EOF
	else
		echo "$0: unsupported terminal app: $the_app" >&2
		return 1
	fi
}
spotify () {
	USER_CONFIG_DEFAULTS="CLIENT_ID=\"\"\nCLIENT_SECRET=\"\"" 
	USER_CONFIG_FILE="${HOME}/.shpotify.cfg" 
	if ! [[ -f "${USER_CONFIG_FILE}" ]]
	then
		touch "${USER_CONFIG_FILE}"
		echo -e "${USER_CONFIG_DEFAULTS}" > "${USER_CONFIG_FILE}"
	fi
	source "${USER_CONFIG_FILE}"
	VOL_INCREMENT=10 
	showAPIHelp () {
		echo
		echo "Connecting to Spotify's API:"
		echo
		echo "  This command line application needs to connect to Spotify's API in order to"
		echo "  find music by name. It is very likely you want this feature!"
		echo
		echo "  To get this to work, you need to sign up (or in) and create an 'Application' at:"
		echo "  https://developer.spotify.com/dashboard/create"
		echo
		echo "  Once you've created an application, find the 'Client ID' and 'Client Secret'"
		echo "  values, and enter them into your shpotify config file at '${USER_CONFIG_FILE}'"
		echo
		echo "  Be sure to quote your values and don't add any extra spaces!"
		echo "  When done, it should look like this (but with your own values):"
		echo '  CLIENT_ID="abc01de2fghijk345lmnop"'
		echo '  CLIENT_SECRET="qr6stu789vwxyz"'
	}
	showHelp () {
		echo "Usage:"
		echo
		echo "  `basename $0` <command>"
		echo
		echo "Commands:"
		echo
		echo "  play                         # Resumes playback where Spotify last left off."
		echo "  play <song name>             # Finds a song by name and plays it."
		echo "  play album <album name>      # Finds an album by name and plays it."
		echo "  play artist <artist name>    # Finds an artist by name and plays it."
		echo "  play list <playlist name>    # Finds a playlist by name and plays it."
		echo "  play uri <uri>               # Play songs from specific uri."
		echo
		echo "  next                         # Skips to the next song in a playlist."
		echo "  prev                         # Returns to the previous song in a playlist."
		echo "  replay                       # Replays the current track from the beginning."
		echo "  pos <time>                   # Jumps to a time (in secs) in the current song."
		echo "  pause                        # Pauses (or resumes) Spotify playback."
		echo "  stop                         # Stops playback."
		echo "  quit                         # Stops playback and quits Spotify."
		echo
		echo "  vol up                       # Increases the volume by 10%."
		echo "  vol down                     # Decreases the volume by 10%."
		echo "  vol <amount>                 # Sets the volume to an amount between 0 and 100."
		echo "  vol [show]                   # Shows the current Spotify volume."
		echo
		echo "  status                       # Shows the current player status."
		echo "  status artist                # Shows the currently playing artist."
		echo "  status album                 # Shows the currently playing album."
		echo "  status track                 # Shows the currently playing track."
		echo
		echo "  share                        # Displays the current song's Spotify URL and URI."
		echo "  share url                    # Displays the current song's Spotify URL and copies it to the clipboard."
		echo "  share uri                    # Displays the current song's Spotify URI and copies it to the clipboard."
		echo
		echo "  toggle shuffle               # Toggles shuffle playback mode."
		echo "  toggle repeat                # Toggles repeat playback mode."
		showAPIHelp
	}
	cecho () {
		bold=$(tput bold) 
		green=$(tput setaf 2) 
		reset=$(tput sgr0) 
		echo $bold$green"$1"$reset
	}
	showArtist () {
		echo `osascript -e 'tell application "Spotify" to artist of current track as string'`
	}
	showAlbum () {
		echo `osascript -e 'tell application "Spotify" to album of current track as string'`
	}
	showTrack () {
		echo `osascript -e 'tell application "Spotify" to name of current track as string'`
	}
	showStatus () {
		state=`osascript -e 'tell application "Spotify" to player state as string'` 
		cecho "Spotify is currently $state."
		duration=`osascript -e 'tell application "Spotify"
            set durSec to (duration of current track / 1000) as text
            set tM to (round (durSec / 60) rounding down) as text
            if length of ((durSec mod 60 div 1) as text) is greater than 1 then
                set tS to (durSec mod 60 div 1) as text
            else
                set tS to ("0" & (durSec mod 60 div 1)) as text
            end if
            set myTime to tM as text & ":" & tS as text
            end tell
            return myTime'` 
		position=`osascript -e 'tell application "Spotify"
            set pos to player position
            set nM to (round (pos / 60) rounding down) as text
            if length of ((round (pos mod 60) rounding down) as text) is greater than 1 then
                set nS to (round (pos mod 60) rounding down) as text
            else
                set nS to ("0" & (round (pos mod 60) rounding down)) as text
            end if
            set nowAt to nM as text & ":" & nS as text
            end tell
            return nowAt'` 
		echo -e $reset"Artist: $(showArtist)\nAlbum: $(showAlbum)\nTrack: $(showTrack) \nPosition: $position / $duration"
	}
	if [ $# = 0 ]
	then
		showHelp
	else
		if [ ! -d /Applications/Spotify.app ] && [ ! -d $HOME/Applications/Spotify.app ]
		then
			echo "The Spotify application must be installed."
			return 1
		fi
		if [ $(osascript -e 'application "Spotify" is running') = "false" ]
		then
			osascript -e 'tell application "Spotify" to activate' || return 1
			sleep 2
		fi
	fi
	while [ $# -gt 0 ]
	do
		arg=$1 
		case $arg in
			("play") if [ $# != 1 ]
				then
					array=($@) 
					len=${#array[@]} 
					SPOTIFY_SEARCH_API="https://api.spotify.com/v1/search" 
					SPOTIFY_TOKEN_URI="https://accounts.spotify.com/api/token" 
					if [ -z "${CLIENT_ID}" ]
					then
						cecho "Invalid Client ID, please update ${USER_CONFIG_FILE}"
						showAPIHelp
						return 1
					fi
					if [ -z "${CLIENT_SECRET}" ]
					then
						cecho "Invalid Client Secret, please update ${USER_CONFIG_FILE}"
						showAPIHelp
						return 1
					fi
					SHPOTIFY_CREDENTIALS=$(printf "${CLIENT_ID}:${CLIENT_SECRET}" | base64 | tr -d "\n"|tr -d '\r') 
					SPOTIFY_PLAY_URI="" 
					getAccessToken () {
						cecho "Connecting to Spotify's API"
						SPOTIFY_TOKEN_RESPONSE_DATA=$( \
                        curl "${SPOTIFY_TOKEN_URI}" \
                            --silent \
                            -X "POST" \
                            -H "Authorization: Basic ${SHPOTIFY_CREDENTIALS}" \
                            -d "grant_type=client_credentials" \
                    ) 
						if ! [[ "${SPOTIFY_TOKEN_RESPONSE_DATA}" =~ "access_token" ]]
						then
							cecho "Authorization failed, please check ${USER_CONFG_FILE}"
							cecho "${SPOTIFY_TOKEN_RESPONSE_DATA}"
							showAPIHelp
							return 1
						fi
						SPOTIFY_ACCESS_TOKEN=$( \
                        printf "${SPOTIFY_TOKEN_RESPONSE_DATA}" \
                        | command grep -E -o '"access_token":".*",' \
                        | sed 's/"access_token"://g' \
                        | sed 's/"//g' \
                        | sed 's/,.*//g' \
                    ) 
					}
					searchAndPlay () {
						type="$1" 
						Q="$2" 
						getAccessToken
						cecho "Searching ${type}s for: $Q"
						SPOTIFY_PLAY_URI=$( \
                        curl -s -G $SPOTIFY_SEARCH_API \
                            -H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
                            -H "Accept: application/json" \
                            --data-urlencode "q=$Q" \
                            -d "type=$type&limit=1&offset=0" \
                        | command grep -E -o "spotify:$type:[a-zA-Z0-9]+" -m 1
                    ) 
					}
					case $2 in
						("list") _args=${array[@]:2:$len} 
							Q=$_args 
							getAccessToken
							cecho "Searching playlists for: $Q"
							results=$( \
                            curl -s -G $SPOTIFY_SEARCH_API --data-urlencode "q=$Q" -d "type=playlist&limit=10&offset=0" -H "Accept: application/json" -H "Authorization: Bearer ${SPOTIFY_ACCESS_TOKEN}" \
                            | command grep -E -o "spotify:playlist:[a-zA-Z0-9]+" -m 10 \
                        ) 
							count=$( \
                            echo "$results" | command grep -c "spotify:playlist" \
                        ) 
							if [ "$count" -gt 0 ]
							then
								random=$(( $RANDOM % $count)) 
								SPOTIFY_PLAY_URI=$( \
                                echo "$results" | awk -v random="$random" '/spotify:playlist:[a-zA-Z0-9]+/{i++}i==random{print; exit}' \
                            ) 
							fi ;;
						("album" | "artist" | "track") _args=${array[@]:2:$len} 
							searchAndPlay $2 "$_args" ;;
						("uri") SPOTIFY_PLAY_URI=${array[@]:2:$len}  ;;
						(*) _args=${array[@]:1:$len} 
							searchAndPlay track "$_args" ;;
					esac
					if [ "$SPOTIFY_PLAY_URI" != "" ]
					then
						if [ "$2" = "uri" ]
						then
							cecho "Playing Spotify URI: $SPOTIFY_PLAY_URI"
						else
							cecho "Playing ($Q Search) -> Spotify URI: $SPOTIFY_PLAY_URI"
						fi
						osascript -e "tell application \"Spotify\" to play track \"$SPOTIFY_PLAY_URI\""
					else
						cecho "No results when searching for $Q"
					fi
				else
					cecho "Playing Spotify."
					osascript -e 'tell application "Spotify" to play'
				fi
				break ;;
			("pause") state=`osascript -e 'tell application "Spotify" to player state as string'` 
				if [ $state = "playing" ]
				then
					cecho "Pausing Spotify."
				else
					cecho "Playing Spotify."
				fi
				osascript -e 'tell application "Spotify" to playpause'
				break ;;
			("stop") state=`osascript -e 'tell application "Spotify" to player state as string'` 
				if [ $state = "playing" ]
				then
					cecho "Pausing Spotify."
					osascript -e 'tell application "Spotify" to playpause'
				else
					cecho "Spotify is already stopped."
				fi
				break ;;
			("quit") cecho "Quitting Spotify."
				osascript -e 'tell application "Spotify" to quit'
				break ;;
			("next") cecho "Going to next track."
				osascript -e 'tell application "Spotify" to next track'
				showStatus
				break ;;
			("prev") cecho "Going to previous track."
				osascript -e '
            tell application "Spotify"
                set player position to 0
                previous track
            end tell'
				showStatus
				break ;;
			("replay") cecho "Replaying current track."
				osascript -e 'tell application "Spotify" to set player position to 0'
				break ;;
			("vol") vol=`osascript -e 'tell application "Spotify" to sound volume as integer'` 
				if [[ $2 = "" || $2 = "show" ]]
				then
					cecho "Current Spotify volume level is $vol."
					break
				elif [ "$2" = "up" ]
				then
					if [ $vol -le $(( 100-$VOL_INCREMENT )) ]
					then
						newvol=$(( vol+$VOL_INCREMENT )) 
						cecho "Increasing Spotify volume to $newvol."
					else
						newvol=100 
						cecho "Spotify volume level is at max."
					fi
				elif [ "$2" = "down" ]
				then
					if [ $vol -ge $(( $VOL_INCREMENT )) ]
					then
						newvol=$(( vol-$VOL_INCREMENT )) 
						cecho "Reducing Spotify volume to $newvol."
					else
						newvol=0 
						cecho "Spotify volume level is at min."
					fi
				elif [[ $2 =~ ^[0-9]+$ ]] && [[ $2 -ge 0 && $2 -le 100 ]]
				then
					newvol=$2 
					cecho "Setting Spotify volume level to $newvol"
				else
					echo "Improper use of 'vol' command"
					echo "The 'vol' command should be used as follows:"
					echo "  vol up                       # Increases the volume by $VOL_INCREMENT%."
					echo "  vol down                     # Decreases the volume by $VOL_INCREMENT%."
					echo "  vol [amount]                 # Sets the volume to an amount between 0 and 100."
					echo "  vol                          # Shows the current Spotify volume."
					return 1
				fi
				osascript -e "tell application \"Spotify\" to set sound volume to $newvol"
				break ;;
			("toggle") if [ "$2" = "shuffle" ]
				then
					osascript -e 'tell application "Spotify" to set shuffling to not shuffling'
					curr=`osascript -e 'tell application "Spotify" to shuffling'` 
					cecho "Spotify shuffling set to $curr"
				elif [ "$2" = "repeat" ]
				then
					osascript -e 'tell application "Spotify" to set repeating to not repeating'
					curr=`osascript -e 'tell application "Spotify" to repeating'` 
					cecho "Spotify repeating set to $curr"
				fi
				break ;;
			("status") if [ $# != 1 ]
				then
					case $2 in
						("artist") showArtist
							break ;;
						("album") showAlbum
							break ;;
						("track") showTrack
							break ;;
					esac
				else
					showStatus
				fi
				break ;;
			("info") info=`osascript -e 'tell application "Spotify"
                set durSec to (duration of current track / 1000)
                set tM to (round (durSec / 60) rounding down) as text
                if length of ((durSec mod 60 div 1) as text) is greater than 1 then
                    set tS to (durSec mod 60 div 1) as text
                else
                    set tS to ("0" & (durSec mod 60 div 1)) as text
                end if
                set myTime to tM as text & "min " & tS as text & "s"
                set pos to player position
                set nM to (round (pos / 60) rounding down) as text
                if length of ((round (pos mod 60) rounding down) as text) is greater than 1 then
                    set nS to (round (pos mod 60) rounding down) as text
                else
                    set nS to ("0" & (round (pos mod 60) rounding down)) as text
                end if
                set nowAt to nM as text & "min " & nS as text & "s"
                set info to "" & "\nArtist:         " & artist of current track
                set info to info & "\nTrack:          " & name of current track
                set info to info & "\nAlbum Artist:   " & album artist of current track
                set info to info & "\nAlbum:          " & album of current track
                set info to info & "\nSeconds:        " & durSec
                set info to info & "\nSeconds played: " & pos
                set info to info & "\nDuration:       " & mytime
                set info to info & "\nNow at:         " & nowAt
                set info to info & "\nPlayed Count:   " & played count of current track
                set info to info & "\nTrack Number:   " & track number of current track
                set info to info & "\nPopularity:     " & popularity of current track
                set info to info & "\nId:             " & id of current track
                set info to info & "\nSpotify URL:    " & spotify url of current track
                set info to info & "\nArtwork:        " & artwork url of current track
                set info to info & "\nPlayer:         " & player state
                set info to info & "\nVolume:         " & sound volume
                set info to info & "\nShuffle:        " & shuffling
                set info to info & "\nRepeating:      " & repeating
            end tell
            return info'` 
				cecho "$info"
				break ;;
			("share") uri=`osascript -e 'tell application "Spotify" to spotify url of current track'` 
				remove='spotify:track:' 
				url=${uri#$remove} 
				url="https://open.spotify.com/track/$url" 
				if [ "$2" = "" ]
				then
					cecho "Spotify URL: $url"
					cecho "Spotify URI: $uri"
					echo "To copy the URL or URI to your clipboard, use:"
					echo "\`spotify share url\` or"
					echo "\`spotify share uri\` respectively."
				elif [ "$2" = "url" ]
				then
					cecho "Spotify URL: $url"
					echo -n $url | pbcopy
				elif [ "$2" = "uri" ]
				then
					cecho "Spotify URI: $uri"
					echo -n $uri | pbcopy
				fi
				break ;;
			("pos") cecho "Adjusting Spotify play position."
				osascript -e "tell application \"Spotify\" to set player position to $2"
				break ;;
			("help") showHelp
				break ;;
			(*) showHelp
				return 1 ;;
		esac
	done
}
svn_prompt_info () {
	return 1
}
tab () {
	local command="cd \\\"$PWD\\\"; clear" 
	(( $# > 0 )) && command="${command}; $*" 
	local the_app=$(_omz_macos_get_frontmost_app) 
	if [[ "$the_app" == 'Terminal' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Terminal" to keystroke "t" using command down
      end tell
      tell application "Terminal" to do script "${command}" in front window
EOF
	elif [[ "$the_app" == 'iTerm' ]]
	then
		osascript <<EOF
      tell application "iTerm"
        set current_terminal to current terminal
        tell current_terminal
          launch session "Default Session"
          set current_session to current session
          tell current_session
            write text "${command}"
          end tell
        end tell
      end tell
EOF
	elif [[ "$the_app" == 'iTerm2' ]]
	then
		osascript <<EOF
      tell application "iTerm2"
        tell current window
          create tab with default profile
          tell current session to write text "${command}"
        end tell
      end tell
EOF
	elif [[ "$the_app" == 'Hyper' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Hyper" to keystroke "t" using command down
      end tell
      delay 1
      tell application "System Events"
        keystroke "${command}"
        key code 36  #(presses enter)
      end tell
EOF
	elif [[ "$the_app" == 'Tabby' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Tabby" to keystroke "t" using command down
      end tell
EOF
	elif [[ "$the_app" == 'ghostty' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Ghostty" to keystroke "t" using command down
      end tell
EOF
	else
		echo "$0: unsupported terminal app: $the_app" >&2
		return 1
	fi
}
take () {
	if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]
	then
		takeurl "$1"
	elif [[ $1 =~ ^(https?|ftp).*\.(zip)$ ]]
	then
		takezip "$1"
	elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]
	then
		takegit "$1"
	else
		takedir "$@"
	fi
}
takedir () {
	mkdir -p $@ && cd ${@:$#}
}
takegit () {
	git clone "$1"
	cd "$(basename ${1%%.git})"
}
takeurl () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	tar xf "$data"
	thedir="$(tar tf "$data" | head -n 1)" 
	rm "$data"
	cd "$thedir"
}
takezip () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	unzip "$data" -d "./"
	thedir="$(unzip -l "$data" | awk 'NR==4 {print $4}' | sed 's/\/.*//')" 
	rm "$data"
	cd "$thedir"
}
tf_prompt_info () {
	return 1
}
title () {
	setopt localoptions nopromptsubst
	[[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty* | st* | foot* | contour* | wezterm*) print -Pn "\e]2;${2:q}\a"
			print -Pn "\e]1;${1:q}\a" ;;
		(screen* | tmux*) print -Pn "\ek${1:q}\e\\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "\e]2;${2:q}\a"
				print -Pn "\e]1;${1:q}\a"
			else
				if (( ${+terminfo[fsl]} && ${+terminfo[tsl]} ))
				then
					print -Pn "${terminfo[tsl]}$1${terminfo[fsl]}"
				fi
			fi ;;
	esac
}
try_alias_value () {
	alias_value "$1" || echo "$1"
}
uninstall_oh_my_zsh () {
	command env ZSH="$ZSH" sh "$ZSH/tools/uninstall.sh"
}
up-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
upgrade_oh_my_zsh () {
	echo "${fg[yellow]}Note: \`$0\` is deprecated. Use \`omz update\` instead.$reset_color" >&2
	omz update
}
url-quote-magic () {
	# undefined
	builtin autoload -XUz
}
vcs_status () {
	if (( ${+functions[in_svn]} )) && in_svn
	then
		svn_prompt_info
	elif (( ${+functions[in_hg]} )) && in_hg
	then
		hg_prompt_info
	else
		git_prompt_info
	fi
}
vi_mode_prompt_info () {
	return 1
}
virtualenv_prompt_info () {
	return 1
}
vncviewer () {
	open vnc://$@
}
vsplit_tab () {
	local command="cd \\\"$PWD\\\"; clear" 
	(( $# > 0 )) && command="${command}; $*" 
	local the_app=$(_omz_macos_get_frontmost_app) 
	if [[ "$the_app" == 'iTerm' ]]
	then
		osascript <<EOF
      -- tell application "iTerm" to activate
      tell application "System Events"
        tell process "iTerm"
          tell menu item "Split Vertically With Current Profile" of menu "Shell" of menu bar item "Shell" of menu bar 1
            click
          end tell
        end tell
        keystroke "${command} \n"
      end tell
EOF
	elif [[ "$the_app" == 'iTerm2' ]]
	then
		osascript <<EOF
      tell application "iTerm2"
        tell current session of first window
          set newSession to (split vertically with same profile)
          tell newSession
            write text "${command}"
            select
          end tell
        end tell
      end tell
EOF
	elif [[ "$the_app" == 'Hyper' ]]
	then
		osascript > /dev/null <<EOF
    tell application "System Events"
      tell process "Hyper"
        tell menu item "Split Vertically" of menu "Shell" of menu bar 1
          click
        end tell
      end tell
      delay 1
      keystroke "${command} \n"
    end tell
EOF
	elif [[ "$the_app" == 'Tabby' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Tabby" to keystroke "D" using command down
      end tell
EOF
	elif [[ "$the_app" == 'ghostty' ]]
	then
		osascript > /dev/null <<EOF
      tell application "System Events"
        tell process "Ghostty" to keystroke "D" using command down
      end tell
EOF
	else
		echo "$0: unsupported terminal app: $the_app" >&2
		return 1
	fi
}
work_in_progress () {
	command git -c log.showSignature=false log -n 1 2> /dev/null | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -q -- "--wip--" && echo "WIP!!"
}
z () {
	__zoxide_z "$@"
}
zi () {
	__zoxide_zi "$@"
}
zle-line-finish () {
	echoti rmkx
}
zle-line-init () {
	echoti smkx
}
zrecompile () {
	setopt localoptions extendedglob noshwordsplit noksharrays
	local opt check quiet zwc files re file pre ret map tmp mesg pats
	tmp=() 
	while getopts ":tqp" opt
	do
		case $opt in
			(t) check=yes  ;;
			(q) quiet=yes  ;;
			(p) pats=yes  ;;
			(*) if [[ -n $pats ]]
				then
					tmp=($tmp $OPTARG) 
				else
					print -u2 zrecompile: bad option: -$OPTARG
					return 1
				fi ;;
		esac
	done
	shift OPTIND-${#tmp}-1
	if [[ -n $check ]]
	then
		ret=1 
	else
		ret=0 
	fi
	if [[ -n $pats ]]
	then
		local end num
		while (( $# ))
		do
			end=$argv[(i)--] 
			if [[ end -le $# ]]
			then
				files=($argv[1,end-1]) 
				shift end
			else
				files=($argv) 
				argv=() 
			fi
			tmp=() 
			map=() 
			OPTIND=1 
			while getopts :MR opt $files
			do
				case $opt in
					([MR]) map=(-$opt)  ;;
					(*) tmp=($tmp $files[OPTIND])  ;;
				esac
			done
			shift OPTIND-1 files
			(( $#files )) || continue
			files=($files[1] ${files[2,-1]:#*(.zwc|~)}) 
			(( $#files )) || continue
			zwc=${files[1]%.zwc}.zwc 
			shift 1 files
			(( $#files )) || files=(${zwc%.zwc}) 
			if [[ -f $zwc ]]
			then
				num=$(zcompile -t $zwc | wc -l) 
				if [[ num-1 -ne $#files ]]
				then
					re=yes 
				else
					re= 
					for file in $files
					do
						if [[ $file -nt $zwc ]]
						then
							re=yes 
							break
						fi
					done
				fi
			else
				re=yes 
			fi
			if [[ -n $re ]]
			then
				if [[ -n $check ]]
				then
					[[ -z $quiet ]] && print $zwc needs re-compilation
					ret=0 
				else
					[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
					if [[ -z "$quiet" ]] && {
							[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
						} && zcompile $map $tmp $zwc $files
					then
						print succeeded
					elif ! {
							{
								[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
							} && zcompile $map $tmp $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		done
		return ret
	fi
	if (( $# ))
	then
		argv=(${^argv}/*.zwc(ND) ${^argv}.zwc(ND) ${(M)argv:#*.zwc}) 
	else
		argv=(${^fpath}/*.zwc(ND) ${^fpath}.zwc(ND) ${(M)fpath:#*.zwc}) 
	fi
	argv=(${^argv%.zwc}.zwc) 
	for zwc
	do
		files=(${(f)"$(zcompile -t $zwc)"}) 
		if [[ $files[1] = *\(mapped\)* ]]
		then
			map=-M 
			mesg='succeeded (old saved)' 
		else
			map=-R 
			mesg=succeeded 
		fi
		if [[ $zwc = */* ]]
		then
			pre=${zwc%/*}/ 
		else
			pre= 
		fi
		if [[ $files[1] != *$ZSH_VERSION ]]
		then
			re=yes 
		else
			re= 
		fi
		files=(${pre}${^files[2,-1]:#/*} ${(M)files[2,-1]:#/*}) 
		[[ -z $re ]] && for file in $files
		do
			if [[ $file -nt $zwc ]]
			then
				re=yes 
				break
			fi
		done
		if [[ -n $re ]]
		then
			if [[ -n $check ]]
			then
				[[ -z $quiet ]] && print $zwc needs re-compilation
				ret=0 
			else
				[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
				tmp=(${^files}(N)) 
				if [[ $#tmp -ne $#files ]]
				then
					[[ -z $quiet ]] && print 'failed (missing files)'
					ret=1 
				else
					if [[ -z "$quiet" ]] && mv -f $zwc ${zwc}.old && zcompile $map $zwc $files
					then
						print $mesg
					elif ! {
							mv -f $zwc ${zwc}.old && zcompile $map $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		fi
	done
	return ret
}
zsh-z_plugin_unload () {
	emulate -L zsh
	add-zsh-hook -D precmd _zshz_precmd
	add-zsh-hook -d chpwd _zshz_chpwd
	local x
	for x in ${=ZSHZ[FUNCTIONS]}
	do
		(( ${+functions[$x]} )) && unfunction $x
	done
	unset ZSHZ
	fpath=("${(@)fpath:#${0:A:h}}") 
	(( ${+aliases[${ZSHZ_CMD:-${_Z_CMD:-z}}]} )) && unalias ${ZSHZ_CMD:-${_Z_CMD:-z}}
	unfunction $0
}
zsh_stats () {
	fc -l 1 | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}
zshz () {
	setopt LOCAL_OPTIONS NO_KSH_ARRAYS NO_SH_WORD_SPLIT EXTENDED_GLOB UNSET
	(( ZSHZ_DEBUG )) && setopt LOCAL_OPTIONS WARN_CREATE_GLOBAL
	local REPLY
	local -a lines
	local custom_datafile="${ZSHZ_DATA:-$_Z_DATA}" 
	if [[ -n ${custom_datafile} && ${custom_datafile} != */* ]]
	then
		print "ERROR: You configured a custom Zsh-z datafile (${custom_datafile}), but have not specified its directory." >&2
		exit
	fi
	local datafile=${${custom_datafile:-$HOME/.z}:A} 
	if [[ -d $datafile ]]
	then
		print "ERROR: Zsh-z's datafile (${datafile}) is a directory." >&2
		exit
	fi
	[[ -f $datafile ]] || {
		mkdir -p "${datafile:h}" && touch "$datafile"
	}
	[[ -z ${ZSHZ_OWNER:-${_Z_OWNER}} && -f $datafile && ! -O $datafile ]] && return
	lines=(${(f)"$(< $datafile)"}) 
	lines=(${(M)lines:#/*\|[[:digit:]]##[.,]#[[:digit:]]#\|[[:digit:]]##}) 
	_zshz_add_or_remove_path () {
		local action=${1} 
		shift
		if [[ $action == '--add' ]]
		then
			[[ $* == $HOME ]] && return
			local exclude
			for exclude in ${(@)ZSHZ_EXCLUDE_DIRS:-${(@)_Z_EXCLUDE_DIRS}}
			do
				case $* in
					(${exclude} | ${exclude}/*) return ;;
				esac
			done
		fi
		local tempfile="${datafile}.${RANDOM}" 
		if (( ZSHZ[USE_FLOCK] ))
		then
			local lockfd
			zsystem flock -f lockfd "$datafile" 2> /dev/null || return
		fi
		integer tmpfd
		case $action in
			(--add) exec {tmpfd}>| "$tempfile"
				_zshz_update_datafile $tmpfd "$*"
				local ret=$?  ;;
			(--remove) local xdir
				if (( ${ZSHZ_NO_RESOLVE_SYMLINKS:-${_Z_NO_RESOLVE_SYMLINKS}} ))
				then
					[[ -d ${${*:-${PWD}}:a} ]] && xdir=${${*:-${PWD}}:a} 
				else
					[[ -d ${${*:-${PWD}}:A} ]] && xdir=${${*:-${PWD}}:a} 
				fi
				local -a lines_to_keep
				if (( ${+opts[-R]} ))
				then
					if [[ $xdir == '/' ]] && ! read -q "?Delete entire Zsh-z database? "
					then
						print && return 1
					fi
					lines_to_keep=(${lines:#${xdir}\|*}) 
					lines_to_keep=(${lines_to_keep:#${xdir%/}/**}) 
				else
					lines_to_keep=(${lines:#${xdir}\|*}) 
				fi
				if [[ $lines != "$lines_to_keep" ]]
				then
					lines=($lines_to_keep) 
				else
					return 1
				fi
				exec {tmpfd}>| "$tempfile"
				print -u $tmpfd -l -- $lines
				local ret=$?  ;;
		esac
		if (( tmpfd != 0 ))
		then
			exec {tmpfd}>&-
		fi
		if (( ret != 0 ))
		then
			${ZSHZ[RM]} -f "$tempfile"
			return $ret
		fi
		local owner
		owner=${ZSHZ_OWNER:-${_Z_OWNER}} 
		if (( ZSHZ[USE_FLOCK] ))
		then
			if [[ -r '/proc/1/cgroup' && "$(< '/proc/1/cgroup')" == *docker* ]]
			then
				print "$(< "$tempfile")" > "$datafile" 2> /dev/null
				${ZSHZ[RM]} -f "$tempfile"
			else
				${ZSHZ[MV]} "$tempfile" "$datafile" 2> /dev/null || ${ZSHZ[RM]} -f "$tempfile"
			fi
			if [[ -n $owner ]]
			then
				${ZSHZ[CHOWN]} ${owner}:"$(id -ng ${owner})" "$datafile"
			fi
		else
			if [[ -n $owner ]]
			then
				${ZSHZ[CHOWN]} "${owner}":"$(id -ng "${owner}")" "$tempfile"
			fi
			${ZSHZ[MV]} -f "$tempfile" "$datafile" 2> /dev/null || ${ZSHZ[RM]} -f "$tempfile"
		fi
		if [[ $action == '--remove' ]]
		then
			ZSHZ[DIRECTORY_REMOVED]=1 
		fi
	}
	_zshz_update_datafile () {
		integer fd=$1 
		local -A rank time
		local add_path=${(q)2} 
		local -a existing_paths
		local now=$EPOCHSECONDS line dir 
		local path_field rank_field time_field count x
		rank[$add_path]=1 
		time[$add_path]=$now 
		for line in $lines
		do
			if [[ ! -d ${line%%\|*} ]]
			then
				for dir in ${(@)ZSHZ_KEEP_DIRS}
				do
					if [[ ${line%%\|*} == ${dir}/* || ${line%%\|*} == $dir || $dir == '/' ]]
					then
						existing_paths+=($line) 
					fi
				done
			else
				existing_paths+=($line) 
			fi
		done
		lines=($existing_paths) 
		for line in $lines
		do
			path_field=${(q)line%%\|*} 
			rank_field=${${line%\|*}#*\|} 
			time_field=${line##*\|} 
			(( rank_field < 1 )) && continue
			if [[ $path_field == $add_path ]]
			then
				rank[$path_field]=$rank_field 
				(( rank[$path_field]++ ))
				time[$path_field]=$now 
			else
				rank[$path_field]=$rank_field 
				time[$path_field]=$time_field 
			fi
			(( count += rank_field ))
		done
		if (( count > ${ZSHZ_MAX_SCORE:-${_Z_MAX_SCORE:-9000}} ))
		then
			for x in ${(k)rank}
			do
				print -u $fd -- "$x|$(( 0.99 * rank[$x] ))|${time[$x]}" || return 1
			done
		else
			for x in ${(k)rank}
			do
				print -u $fd -- "$x|${rank[$x]}|${time[$x]}" || return 1
			done
		fi
	}
	_zshz_legacy_complete () {
		local line path_field path_field_normalized
		1=${1//[[:space:]]/*} 
		for line in $lines
		do
			path_field=${line%%\|*} 
			path_field_normalized=$path_field 
			if (( ZSHZ_TRAILING_SLASH ))
			then
				path_field_normalized=${path_field%/}/ 
			fi
			if [[ $1 == "${1:l}" && ${path_field_normalized:l} == *${~1}* ]]
			then
				print -- $path_field
			elif [[ $path_field_normalized == *${~1}* ]]
			then
				print -- $path_field
			fi
		done
	}
	_zshz_printv () {
		if (( ZSHZ[PRINTV] ))
		then
			builtin print -v REPLY -f %s $@
		else
			builtin print -z $@
			builtin read -rz REPLY
		fi
	}
	_zshz_find_common_root () {
		local -a common_matches
		local x short
		common_matches=(${(@Pk)1}) 
		for x in ${(@)common_matches}
		do
			if [[ -z $short ]] || (( $#x < $#short )) || [[ $x != ${short}/* ]]
			then
				short=$x 
			fi
		done
		[[ $short == '/' ]] && return
		for x in ${(@)common_matches}
		do
			[[ $x != $short* ]] && return
		done
		_zshz_printv -- $short
	}
	_zshz_output () {
		local match_array=$1 match=$2 format=$3 
		local common k x
		local -a descending_list output
		local -A output_matches
		output_matches=(${(Pkv)match_array}) 
		_zshz_find_common_root $match_array
		common=$REPLY 
		case $format in
			(completion) for k in ${(@k)output_matches}
				do
					_zshz_printv -f "%.2f|%s" ${output_matches[$k]} $k
					descending_list+=(${(f)REPLY}) 
					REPLY='' 
				done
				descending_list=(${${(@On)descending_list}#*\|}) 
				print -l $descending_list ;;
			(list) local path_to_display
				for x in ${(k)output_matches}
				do
					if (( ${output_matches[$x]} ))
					then
						path_to_display=$x 
						(( ZSHZ_TILDE )) && path_to_display=${path_to_display/#${HOME}/\~} 
						_zshz_printv -f "%-10d %s\n" ${output_matches[$x]} $path_to_display
						output+=(${(f)REPLY}) 
						REPLY='' 
					fi
				done
				if [[ -n $common ]]
				then
					(( ZSHZ_TILDE )) && common=${common/#${HOME}/\~} 
					(( $#output > 1 )) && printf "%-10s %s\n" 'common:' $common
				fi
				if (( $+opts[-t] ))
				then
					for x in ${(@On)output}
					do
						print -- $x
					done
				elif (( $+opts[-r] ))
				then
					for x in ${(@on)output}
					do
						print -- $x
					done
				else
					for x in ${(@on)output}
					do
						print $x
					done
				fi ;;
			(*) if (( ! ZSHZ_UNCOMMON )) && [[ -n $common ]]
				then
					_zshz_printv -- $common
				else
					_zshz_printv -- ${(P)match}
				fi ;;
		esac
	}
	_zshz_find_matches () {
		setopt LOCAL_OPTIONS NO_EXTENDED_GLOB
		local fnd=$1 method=$2 format=$3 
		local -a existing_paths
		local line dir path_field rank_field time_field rank dx escaped_path_field
		local -A matches imatches
		local best_match ibest_match hi_rank=-9999999999 ihi_rank=-9999999999 
		for line in $lines
		do
			if [[ ! -d ${line%%\|*} ]]
			then
				for dir in ${(@)ZSHZ_KEEP_DIRS}
				do
					if [[ ${line%%\|*} == ${dir}/* || ${line%%\|*} == $dir || $dir == '/' ]]
					then
						existing_paths+=($line) 
					fi
				done
			else
				existing_paths+=($line) 
			fi
		done
		lines=($existing_paths) 
		for line in $lines
		do
			path_field=${line%%\|*} 
			rank_field=${${line%\|*}#*\|} 
			time_field=${line##*\|} 
			case $method in
				(rank) rank=$rank_field  ;;
				(time) (( rank = time_field - EPOCHSECONDS )) ;;
				(*) (( dx = EPOCHSECONDS - time_field ))
					rank=$(( 10000 * rank_field * (3.75/( (0.0001 * dx + 1) + 0.25)) ))  ;;
			esac
			local q=${fnd//[[:space:]]/\*} 
			local path_field_normalized=$path_field 
			if (( ZSHZ_TRAILING_SLASH ))
			then
				path_field_normalized=${path_field%/}/ 
			fi
			if [[ $ZSHZ_CASE == 'smart' && ${1:l} == $1 && ${path_field_normalized:l} == ${~q:l} ]]
			then
				imatches[$path_field]=$rank 
			elif [[ $ZSHZ_CASE != 'ignore' && $path_field_normalized == ${~q} ]]
			then
				matches[$path_field]=$rank 
			elif [[ $ZSHZ_CASE != 'smart' && ${path_field_normalized:l} == ${~q:l} ]]
			then
				imatches[$path_field]=$rank 
			fi
			escaped_path_field=${path_field//'\'/'\\'} 
			escaped_path_field=${escaped_path_field//'`'/'\`'} 
			escaped_path_field=${escaped_path_field//'('/'\('} 
			escaped_path_field=${escaped_path_field//')'/'\)'} 
			escaped_path_field=${escaped_path_field//'['/'\['} 
			escaped_path_field=${escaped_path_field//']'/'\]'} 
			if (( matches[$escaped_path_field] )) && (( matches[$escaped_path_field] > hi_rank ))
			then
				best_match=$path_field 
				hi_rank=${matches[$escaped_path_field]} 
			elif (( imatches[$escaped_path_field] )) && (( imatches[$escaped_path_field] > ihi_rank ))
			then
				ibest_match=$path_field 
				ihi_rank=${imatches[$escaped_path_field]} 
				ZSHZ[CASE_INSENSITIVE]=1 
			fi
		done
		[[ -z $best_match && -z $ibest_match ]] && return 1
		if [[ -n $best_match ]]
		then
			_zshz_output matches best_match $format
		elif [[ -n $ibest_match ]]
		then
			_zshz_output imatches ibest_match $format
		fi
	}
	local -A opts
	zparseopts -E -D -A opts -- -add -complete c e h -help l r R t x
	if [[ $1 == '--' ]]
	then
		shift
	elif [[ -n ${(M)@:#-*} && -z $compstate ]]
	then
		print "Improper option(s) given."
		_zshz_usage
		return 1
	fi
	local opt output_format method='frecency' fnd prefix req 
	for opt in ${(k)opts}
	do
		case $opt in
			(--add) [[ ! -d $* ]] && return 1
				local dir
				if [[ $OSTYPE == (cygwin|msys) && $PWD == '/' && $* != /* ]]
				then
					set -- "/$*"
				fi
				if (( ${ZSHZ_NO_RESOLVE_SYMLINKS:-${_Z_NO_RESOLVE_SYMLINKS}} ))
				then
					dir=${*:a} 
				else
					dir=${*:A} 
				fi
				_zshz_add_or_remove_path --add "$dir"
				return ;;
			(--complete) if [[ -s $datafile && ${ZSHZ_COMPLETION:-frecent} == 'legacy' ]]
				then
					_zshz_legacy_complete "$1"
					return
				fi
				output_format='completion'  ;;
			(-c) [[ $* == ${PWD}/* || $PWD == '/' ]] || prefix="$PWD "  ;;
			(-h | --help) _zshz_usage
				return ;;
			(-l) output_format='list'  ;;
			(-r) method='rank'  ;;
			(-t) method='time'  ;;
			(-x) if [[ $OSTYPE == (cygwin|msys) && $PWD == '/' && $* != /* ]]
				then
					set -- "/$*"
				fi
				_zshz_add_or_remove_path --remove $*
				return ;;
		esac
	done
	req="$*" 
	fnd="$prefix$*" 
	[[ -n $fnd && $fnd != "$PWD " ]] || {
		[[ $output_format != 'completion' ]] && output_format='list' 
	}
	zshz_cd () {
		setopt LOCAL_OPTIONS NO_WARN_CREATE_GLOBAL
		if [[ -z $ZSHZ_CD ]]
		then
			builtin cd "$*"
		else
			${=ZSHZ_CD} "$*"
		fi
	}
	_zshz_echo () {
		if (( ZSHZ_ECHO ))
		then
			if (( ZSHZ_TILDE ))
			then
				print ${PWD/#${HOME}/\~}
			else
				print $PWD
			fi
		fi
	}
	if [[ ${@: -1} == /* ]] && (( ! $+opts[-e] && ! $+opts[-l] ))
	then
		[[ -d ${@: -1} ]] && zshz_cd ${@: -1} && _zshz_echo && return
	fi
	if [[ ! -z ${(tP)opts[-c]} ]]
	then
		_zshz_find_matches "$fnd*" $method $output_format
	else
		_zshz_find_matches "*$fnd*" $method $output_format
	fi
	local ret2=$? 
	local cd
	cd=$REPLY 
	if (( ZSHZ_UNCOMMON )) && [[ -n $cd ]]
	then
		if [[ -n $cd ]]
		then
			local q=${fnd//[[:space:]]/\*} 
			q=${q%/} 
			if (( ! ZSHZ[CASE_INSENSITIVE] ))
			then
				local q_chars=$(( ${#cd} - ${#${cd//${~q}/}} )) 
				until (( ( ${#cd:h} - ${#${${cd:h}//${~q}/}} ) != q_chars ))
				do
					cd=${cd:h} 
				done
			else
				local q_chars=$(( ${#cd} - ${#${${cd:l}//${~${q:l}}/}} )) 
				until (( ( ${#cd:h} - ${#${${${cd:h}:l}//${~${q:l}}/}} ) != q_chars ))
				do
					cd=${cd:h} 
				done
			fi
			ZSHZ[CASE_INSENSITIVE]=0 
		fi
	fi
	if (( ret2 == 0 )) && [[ -n $cd ]]
	then
		if (( $+opts[-e] ))
		then
			(( ZSHZ_TILDE )) && cd=${cd/#${HOME}/\~} 
			print -- "$cd"
		else
			[[ -d $cd ]] && zshz_cd "$cd" && _zshz_echo
		fi
	else
		if ! (( $+opts[-e] || $+opts[-l] )) && [[ -d $req ]]
		then
			zshz_cd "$req" && _zshz_echo
		else
			return $ret2
		fi
	fi
}
# Shell Options
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt extendedhistory
setopt noflowcontrol
setopt nohashdirs
setopt histexpiredupsfirst
setopt histfindnodups
setopt histignorealldups
setopt histignoredups
setopt histignorespace
setopt histsavenodups
setopt histverify
setopt incappendhistory
setopt interactivecomments
setopt login
setopt longlistjobs
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt pushdsilent
setopt pushdtohome
setopt sharehistory
# Aliases
alias -- -='cd -'
alias -- ..='cd ..'
alias -- ...='cd ../..'
alias -- ....='cd ../../..'
alias -- .....='cd ../../../..'
alias -- ......=../../../../..
alias -- 1='cd -1'
alias -- 2='cd -2'
alias -- 3='cd -3'
alias -- 4='cd -4'
alias -- 5='cd -5'
alias -- 6='cd -6'
alias -- 7='cd -7'
alias -- 8='cd -8'
alias -- 9='cd -9'
alias -- _='sudo '
alias -- activate='source .venv/bin/activate'
alias -- ai='cd /Users/szymondzumak/Developer/.ai'
alias -- ai-status='cd /Users/szymondzumak/Developer/.ai && git status'
alias -- ai-sync='cd /Users/szymondzumak/Developer/.ai && git add . && git commit -m '\''Sync: 2025-08-25'\'' && git push'
alias -- ai-update=/Users/szymondzumak/Developer/.ai/scripts/update-context.sh
alias -- aic='cd /Users/szymondzumak/Developer/.ai/.claude'
alias -- apps='cd /Users/szymondzumak/Developer/Library/apps'
alias -- astropack='cd $REPOS/astrotopack && cursor .'
alias -- ba='brew autoremove'
alias -- bci='brew info --cask'
alias -- bcin='brew install --cask'
alias -- bcl='brew list --cask'
alias -- bcn='brew cleanup'
alias -- bco='brew outdated --cask'
alias -- bcrin='brew reinstall --cask'
alias -- bcubc='brew upgrade --cask && brew cleanup'
alias -- bcubo='brew update && brew outdated --cask'
alias -- bcup='brew upgrade --cask'
alias -- bfu='brew upgrade --formula'
alias -- bi='brew install'
alias -- bl='brew list'
alias -- blog='cd $REPOS/kumak-blog && open -a "Firefox Dev" "http://localhost:4321" & deno task dev'
alias -- bo='brew outdated'
alias -- brewp='brew pin'
alias -- brewsp='brew list --pinned'
alias -- bsl='brew services list'
alias -- bsoff='brew services stop'
alias -- bsoffa='bsoff --all'
alias -- bson='brew services start'
alias -- bsona='bson --all'
alias -- bsr='brew services run'
alias -- bsra='bsr --all'
alias -- bu='brew update'
alias -- bubo='brew update && brew outdated'
alias -- bubu='bubo && bup'
alias -- bubug='bubo && bugbc'
alias -- bugbc='brew upgrade --greedy && brew cleanup'
alias -- bup='brew upgrade'
alias -- buz='brew uninstall --zap'
alias -- c='cursor .'
alias -- cat='bat --style=plain --paging=never'
alias -- cc=claude
alias -- ccc='claude -c'
alias -- ccp='claude -p'
alias -- cde=dirhistory_cd
alias -- cl=claude
alias -- claude-cmds='ls /Users/szymondzumak/Developer/.ai/.claude/commands/'
alias -- claude-ctx='cat /Users/szymondzumak/Developer/.ai/.claude/CLAUDE.md'
alias -- claude-edit=' /Users/szymondzumak/Developer/.ai/.claude/CLAUDE.md'
alias -- cn='cursor -n'
alias -- cp='cp -i'
alias -- dbl='docker build'
alias -- dcin='docker container inspect'
alias -- dcls='docker container ls'
alias -- dclsa='docker container ls -a'
alias -- dev='cd /Users/szymondzumak/Developer'
alias -- devc='cd /Users/szymondzumak/Developer && claude'
alias -- dib='docker image build'
alias -- dii='docker image inspect'
alias -- dils='docker image ls'
alias -- dipru='docker image prune -a'
alias -- dipu='docker image push'
alias -- dirm='docker image rm'
alias -- dit='docker image tag'
alias -- dl='cd ~/Downloads'
alias -- dlo='docker container logs'
alias -- dnc='docker network create'
alias -- dncn='docker network connect'
alias -- dndcn='docker network disconnect'
alias -- dni='docker network inspect'
alias -- dnls='docker network ls'
alias -- dnrm='docker network rm'
alias -- docs='cd /Users/szymondzumak/Developer/Knowledge'
alias -- dpo='docker container port'
alias -- dps='docker ps'
alias -- dpsa='docker ps -a'
alias -- dpu='docker pull'
alias -- dr='docker container run'
alias -- drit='docker container run -it'
alias -- drm='docker container rm'
alias -- drm!='docker container rm -f'
alias -- drs='docker container restart'
alias -- dst='docker container start'
alias -- dsta='docker stop $(docker ps -q)'
alias -- dstp='docker container stop'
alias -- dsts='docker stats'
alias -- dt='cd ~/Desktop'
alias -- dtop='docker top'
alias -- dvi='docker volume inspect'
alias -- dvls='docker volume ls'
alias -- dvprune='docker volume prune'
alias -- dxc='docker container exec'
alias -- dxcit='docker container exec -it'
alias -- egrep='grep -E'
alias -- fgrep='grep -F'
alias -- find=fd
alias -- g=git
alias -- ga='git add'
alias -- gaa='git add --all'
alias -- gam='git am'
alias -- gama='git am --abort'
alias -- gamc='git am --continue'
alias -- gams='git am --skip'
alias -- gamscp='git am --show-current-patch'
alias -- gap='git apply'
alias -- gapa='git add --patch'
alias -- gapt='git apply --3way'
alias -- gau='git add --update'
alias -- gav='git add --verbose'
alias -- gb='git branch'
alias -- gbD='git branch --delete --force'
alias -- gba='git branch --all'
alias -- gbd='git branch --delete'
alias -- gbg='LANG=C git branch -vv | grep ": gone\]"'
alias -- gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias -- gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias -- gbl='git blame -w'
alias -- gbm='git branch --move'
alias -- gbnm='git branch --no-merged'
alias -- gbr='git branch --remote'
alias -- gbs='git bisect'
alias -- gbsb='git bisect bad'
alias -- gbsg='git bisect good'
alias -- gbsn='git bisect new'
alias -- gbso='git bisect old'
alias -- gbsr='git bisect reset'
alias -- gbss='git bisect start'
alias -- gc='git commit'
alias -- gc!='git commit --verbose --amend'
alias -- gcB='git checkout -B'
alias -- gca='git commit --verbose --all'
alias -- gca!='git commit --verbose --all --amend'
alias -- gcam='git commit --all --message'
alias -- gcan!='git commit --verbose --all --no-edit --amend'
alias -- gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias -- gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias -- gcas='git commit --all --signoff'
alias -- gcasm='git commit --all --signoff --message'
alias -- gcb='git checkout -b'
alias -- gcd='git checkout $(git_develop_branch)'
alias -- gcf='git config --list'
alias -- gcfu='git commit --fixup'
alias -- gcl='git clone --recurse-submodules'
alias -- gclean='git clean --interactive -d'
alias -- gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
alias -- gcm='git checkout $(git_main_branch)'
alias -- gcmsg='git commit --message'
alias -- gcn='git commit --verbose --no-edit'
alias -- gcn!='git commit --verbose --no-edit --amend'
alias -- gco='git checkout'
alias -- gcor='git checkout --recurse-submodules'
alias -- gcount='git shortlog --summary --numbered'
alias -- gcp='git cherry-pick'
alias -- gcpa='git cherry-pick --abort'
alias -- gcpc='git cherry-pick --continue'
alias -- gcs='git commit --gpg-sign'
alias -- gcsm='git commit --signoff --message'
alias -- gcss='git commit --gpg-sign --signoff'
alias -- gcssm='git commit --gpg-sign --signoff --message'
alias -- gd='git diff'
alias -- gdca='git diff --cached'
alias -- gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias -- gdcw='git diff --cached --word-diff'
alias -- gds='git diff --staged'
alias -- gdt='git diff-tree --no-commit-id --name-only -r'
alias -- gdup='git diff @{upstream}'
alias -- gdw='git diff --word-diff'
alias -- gf='git fetch'
alias -- gfa='git fetch --all --tags --prune --jobs=10'
alias -- gfg='git ls-files | grep'
alias -- gfo='git fetch origin'
alias -- gg='git gui citool'
alias -- gga='git gui citool --amend'
alias -- ggpull='git pull origin "$(git_current_branch)"'
alias -- ggpur=ggu
alias -- ggpush='git push origin "$(git_current_branch)"'
alias -- ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias -- ghh='git help'
alias -- gignore='git update-index --assume-unchanged'
alias -- gignored='git ls-files -v | grep "^[[:lower:]]"'
alias -- git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias -- gk='\gitk --all --branches &!'
alias -- gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias -- gl='git pull'
alias -- glg='git log --stat'
alias -- glgg='git log --graph'
alias -- glgga='git log --graph --decorate --all'
alias -- glgm='git log --graph --max-count=10'
alias -- glgp='git log --stat --patch'
alias -- glo='git log --oneline --decorate'
alias -- glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias -- glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias -- glog='git log --oneline --graph --decorate'
alias -- gloga='git log --oneline --decorate --graph --all'
alias -- glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias -- glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias -- glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias -- glp=_git_log_prettily
alias -- gluc='git pull upstream $(git_current_branch)'
alias -- glum='git pull upstream $(git_main_branch)'
alias -- gm='git merge'
alias -- gma='git merge --abort'
alias -- gmc='git merge --continue'
alias -- gmff='git merge --ff-only'
alias -- gmom='git merge origin/$(git_main_branch)'
alias -- gms='git merge --squash'
alias -- gmtl='git mergetool --no-prompt'
alias -- gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias -- gmum='git merge upstream/$(git_main_branch)'
alias -- gp='git push'
alias -- gpd='git push --dry-run'
alias -- gpf='git push --force-with-lease --force-if-includes'
alias -- gpf!='git push --force'
alias -- gpoat='git push origin --all && git push origin --tags'
alias -- gpod='git push origin --delete'
alias -- gpr='git pull --rebase'
alias -- gpra='git pull --rebase --autostash'
alias -- gprav='git pull --rebase --autostash -v'
alias -- gpristine='git reset --hard && git clean --force -dfx'
alias -- gprom='git pull --rebase origin $(git_main_branch)'
alias -- gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias -- gprum='git pull --rebase upstream $(git_main_branch)'
alias -- gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias -- gprv='git pull --rebase -v'
alias -- gpsup='git push --set-upstream origin $(git_current_branch)'
alias -- gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
alias -- gpu='git push upstream'
alias -- gpv='git push --verbose'
alias -- gr='git remote'
alias -- gra='git remote add'
alias -- grb='git rebase'
alias -- grba='git rebase --abort'
alias -- grbc='git rebase --continue'
alias -- grbd='git rebase $(git_develop_branch)'
alias -- grbi='git rebase --interactive'
alias -- grbm='git rebase $(git_main_branch)'
alias -- grbo='git rebase --onto'
alias -- grbom='git rebase origin/$(git_main_branch)'
alias -- grbs='git rebase --skip'
alias -- grbum='git rebase upstream/$(git_main_branch)'
alias -- grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias -- grev='git revert'
alias -- greva='git revert --abort'
alias -- grevc='git revert --continue'
alias -- grf='git reflog'
alias -- grh='git reset'
alias -- grhh='git reset --hard'
alias -- grhk='git reset --keep'
alias -- grhs='git reset --soft'
alias -- grm='git rm'
alias -- grmc='git rm --cached'
alias -- grmv='git remote rename'
alias -- groh='git reset origin/$(git_current_branch) --hard'
alias -- grrm='git remote remove'
alias -- grs='git restore'
alias -- grset='git remote set-url'
alias -- grss='git restore --source'
alias -- grst='git restore --staged'
alias -- grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias -- gru='git reset --'
alias -- grup='git remote update'
alias -- grv='git remote --verbose'
alias -- gs='git status'
alias -- gsb='git status --short --branch'
alias -- gsd='git svn dcommit'
alias -- gsh='git show'
alias -- gsi='git submodule init'
alias -- gsps='git show --pretty=short --show-signature'
alias -- gsr='git svn rebase'
alias -- gss='git status --short'
alias -- gst='git status'
alias -- gsta='git stash push'
alias -- gstaa='git stash apply'
alias -- gstall='git stash --all'
alias -- gstc='git stash clear'
alias -- gstd='git stash drop'
alias -- gstl='git stash list'
alias -- gstp='git stash pop'
alias -- gsts='git stash show --patch'
alias -- gstu='gsta --include-untracked'
alias -- gsu='git submodule update'
alias -- gsw='git switch'
alias -- gswc='git switch --create'
alias -- gswd='git switch $(git_develop_branch)'
alias -- gswm='git switch $(git_main_branch)'
alias -- gta='git tag --annotate'
alias -- gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias -- gts='git tag --sign'
alias -- gtv='git tag | sort -V'
alias -- gunignore='git update-index --no-assume-unchanged'
alias -- gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias -- gup=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gup%F{yellow}\' is a deprecated alias, using \'%F{green}gpr%F{yellow}\' instead.%f"\n    gpr'
alias -- gupa=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupa%F{yellow}\' is a deprecated alias, using \'%F{green}gpra%F{yellow}\' instead.%f"\n    gpra'
alias -- gupav=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupav%F{yellow}\' is a deprecated alias, using \'%F{green}gprav%F{yellow}\' instead.%f"\n    gprav'
alias -- gupom=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupom%F{yellow}\' is a deprecated alias, using \'%F{green}gprom%F{yellow}\' instead.%f"\n    gprom'
alias -- gupomi=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupomi%F{yellow}\' is a deprecated alias, using \'%F{green}gpromi%F{yellow}\' instead.%f"\n    gpromi'
alias -- gupv=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupv%F{yellow}\' is a deprecated alias, using \'%F{green}gprv%F{yellow}\' instead.%f"\n    gprv'
alias -- gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias -- gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias -- gwipe='git reset --hard && git clean --force -df'
alias -- gwt='git worktree'
alias -- gwta='git worktree add'
alias -- gwtls='git worktree list'
alias -- gwtmv='git worktree move'
alias -- gwtrm='git worktree remove'
alias -- hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias -- history=omz_history
alias -- l='ls -lah'
alias -- la='ls -lAh'
alias -- less='bat --style=plain'
alias -- libs='cd /Users/szymondzumak/Developer/Library/libs'
alias -- ll='eza -la --icons --git'
alias -- ls='eza --icons'
alias -- lsa='ls -lah'
alias -- lt='eza --tree --level=2 --icons'
alias -- ltt='eza --tree --level=3 --icons'
alias -- mcp-disable=/Users/szymondzumak/Developer/.ai/.claude/scripts/disable-mcp.sh
alias -- mcp-enable=/Users/szymondzumak/Developer/.ai/.claude/scripts/enable-mcp.sh
alias -- mcp-guide='cat /Users/szymondzumak/Developer/.ai/.claude/MCP_GUIDE.md | less'
alias -- mcp-reset='claude mcp reset-project-choices'
alias -- mcp-status='claude mcp list'
alias -- md='mkdir -p'
alias -- mkdir='mkdir -pv'
alias -- mv='mv -i'
alias -- myip='curl -s ifconfig.me'
alias -- npmD='npm i -D '
alias -- npmE='PATH="$(npm bin)":"$PATH"'
alias -- npmF='npm i -f'
alias -- npmI='npm init'
alias -- npmL='npm list'
alias -- npmL0='npm ls --depth=0'
alias -- npmO='npm outdated'
alias -- npmP='npm publish'
alias -- npmR='npm run'
alias -- npmS='npm i -S '
alias -- npmSe='npm search'
alias -- npmU='npm update'
alias -- npmV='npm -v'
alias -- npmg='npm i -g '
alias -- npmi='npm info'
alias -- npmrb='npm run build'
alias -- npmrd='npm run dev'
alias -- npmst='npm start'
alias -- npmt='npm test'
alias -- pad='poetry add'
alias -- path='echo -e ${PATH//:/\\n}'
alias -- pbld='poetry build'
alias -- pch='poetry check'
alias -- pcmd='poetry list'
alias -- pconf='poetry config --list'
alias -- pexp='poetry export --without-hashes > requirements.txt'
alias -- pin='poetry init'
alias -- pinst='poetry install'
alias -- pip=pip3
alias -- plck='poetry lock'
alias -- pnew='poetry new'
alias -- ports='netstat -tulanp'
alias -- ppath='poetry env info --path'
alias -- pplug='poetry self show plugins'
alias -- ppub='poetry publish'
alias -- prm='poetry remove'
alias -- prun='poetry run'
alias -- psad='poetry self add'
alias -- psh='poetry shell'
alias -- pshw='poetry show'
alias -- pslt='poetry show --latest'
alias -- psup='poetry self update'
alias -- psync='poetry install --sync'
alias -- ptree='poetry show --tree'
alias -- pup='poetry update'
alias -- pvinf='poetry env info'
alias -- pvoff='poetry config virtualenvs.create false'
alias -- pvrm='poetry env remove'
alias -- pvu='poetry env use'
alias -- py=python3
alias -- rd=rmdir
alias -- reload='source ~/.zshrc && echo "✓ ZSH configuration reloaded"'
alias -- repos='cd /Users/szymondzumak/Repos'
alias -- rm='rm -i'
alias -- run-help=man
alias -- save-snippet='~/Developer/Knowledge/save-snippet.sh'
alias -- showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias -- v=vim
alias -- venv='python3 -m venv .venv'
alias -- which-command=whence
alias -- z='zshz 2>&1'
alias -- zshrc='cursor ~/.zshrc'
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/Users/szymondzumak/.local/share/claude/versions/1.0.90 --ripgrep'
fi
export PATH=/opt/homebrew/bin\:/opt/homebrew/sbin\:/Users/szymondzumak/.console-ninja/.bin\:/Users/szymondzumak/.pyenv/shims\:/Scripts\:/Users/szymondzumak/.local/bin\:/Users/szymondzumak/.deno/bin\:/Users/szymondzumak/Library/pnpm\:/Users/szymondzumak/.cargo/bin\:/Users/szymondzumak/.pyenv/bin\:/Users/szymondzumak/.rbenv/shims\:/usr/local/bin\:/System/Cryptexes/App/usr/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin\:/usr/local/MacGPG2/bin\:/Users/szymondzumak/.orbstack/bin\:/opt/homebrew/opt/fzf/bin
