#!/usr/bin/env bash

case "$(fcitx5-remote -n 2>/dev/null)" in
	keyboard-us)
		printf '{"text":"\U0001F1FA\U0001F1F8","tooltip":"English - United States","class":"us"}\n'
		;;

	hangul)
		printf '{"text":"\U0001F1F0\U0001F1F7","tooltip":"Korean - Hangul","class":"kr"}\n'
		;;

	"")
		printf '{"text":"?","tooltip":"Fcitx5 is unavalible","class":"unknown"}\n'
		;;

	*)
		printf '{"text":"?","tooltip":"Uknown input method","class":"unknown"}\n'
		;;
	
esac
