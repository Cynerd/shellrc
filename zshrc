[[ -o interactive ]] || return # skip on initialization if not interactive

for sh in /etc/zsh/zshrc.d/*; do
	[ -r "$sh" ] && . "$sh"
done
