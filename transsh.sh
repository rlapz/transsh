#!/bin/sh

LANG_TARGET="id"
TEXT_SRC=""

help_msg() {
    cat <<EOF
transsh - POSIX script shell helper for moetranslate2

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
		moetranslate2 -if "auto:${LANG_TARGET}" "$TEXT_SRC"
		return
	fi

	moetranslate2 -f "auto:${LANG_TARGET}" "$TEXT_SRC" | less -R
}

speak() {
	input_text

	S_LANG_TARGET=$(moetranslate2 -d "$TEXT_SRC")
	S_LANG_TARGET=${S_LANG_TARGET%% *}

	[ -z "$S_LANG_TARGET" ] && exit 1

	URL="http://translate.google.com/translate_tts?"`
	    `"ie=UTF-8&tl=$S_LANG_TARGET&q=$TEXT_SRC&client=tw-ob"

	USERAGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5)"`
		  `"AppleWebKit/537.31 (KHTML, like Gecko) "`
		  `"Chrome/26.0.1410.65 Safari/537.31"

	TEMP="/tmp/trans_speak"

	wget -q -U "$USERAGENT" "$URL" -O "$TEMP"

	mpv "$TEMP" 1>/dev/null
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

