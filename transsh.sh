#!/bin/sh

LANG_TARGET="id"
TEXT_SRC=""

help_msg() {
    cat <<EOF
transsh - POSIX script shell helper for moetranslate

Usage: transsh [OPT]
       -c  --clipboard    - Load text from the clipboard
             --intr         \` Interactive input mode
       -i  --input        - Input text manually
             --intr         \` Interactive input mode
       -s  --speak        - Play the audio
       -I  --inputspeak   - Input text manually and play the audio
       -h  --help         - Show help
       
Examples:
  transsh --clipboard --intr
  transsh --clipboard
EOF
}

get_text() {
	TEXT_SRC=$(xsel -p 2>/dev/null)
}

input_text() {
	while [ -z "$TEXT_SRC" ]
	do
		printf "Input text: "
		read -r TEXT_SRC
	done
}

translate() {
	input_text

	if [ -n "$2" ]
	then
		[ "$2" != "--intr" ] && exit 1
		moetranslate -id "auto:$LANG_TARGET" "$TEXT_SRC"
		return
	fi

	moetranslate -d "auto:$LANG_TARGET" "$TEXT_SRC" | less +g -R
}

speak() {
	input_text

	S_LANG_TARGET=$(moetranslate -l "$TEXT_SRC")
	S_LANG_TARGET=${S_LANG_TARGET%% *}
	OUT_FILE="/tmp/trans_speak"

	[ -z "$S_LANG_TARGET" ] && exit 1


	URL="http://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=$S_LANG_TARGET"
	curl -s --get --data-urlencode "q=$TEXT_SRC" "$URL" --output "$OUT_FILE"

	if command -v ffplay
	then
	       ffplay -autoexit -hide_banner -vn -nodisp "$OUT_FILE"
	else
	       mpv "$OUT_FILE"
	fi
}

case "$1" in
"-c" | "--clipboard")
	get_text
	translate "$@"
	;;
"-i" | "--input")
	translate "$@"
	;;
"-s" | "--speak")
	get_text
	speak
	;;
"-I" | "--inputspeak")
	speak
	;;
"" | "-h" | "--help")
	help_msg
	;;
*)
	printf "%s\n" "Invalid argument!"
	help_msg
	exit 1
	;;
esac

exit 0

