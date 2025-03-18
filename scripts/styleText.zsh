# Color name to code mapping
# Using function-based approach for macOS compatibility
function color_code() {
  case "$1" in
  "black") echo "30" ;;
  "red") echo "31" ;;
  "green") echo "32" ;;
  "yellow") echo "33" ;;
  "blue") echo "34" ;;
  "magenta") echo "35" ;;
  "cyan") echo "36" ;;
  "white") echo "37" ;;
  "gray") echo "90" ;;
  *) echo "" ;;
  esac
}

# Get available colors
function available_colors() {
  echo "black red green yellow blue magenta cyan white gray"
}

# Modifiers
BOLD=1
ITALIC=3
UNDERLINE=4
REVERSE=7
STRIKETHROUGH=9

styleText() {
  local MODIFIERS=""
  while [[ $# -gt 0 ]]; do
    if [[ "$1" != -* ]]; then
      break
    fi
    case "$1" in
    -b | --bold)
      MODIFIERS="${MODIFIERS};$BOLD"
      shift
      ;;
    -i | --italic)
      MODIFIERS="${MODIFIERS};$ITALIC"
      shift
      ;;
    -u | --underline)
      MODIFIERS="${MODIFIERS};$UNDERLINE"
      shift
      ;;
    -s | --strikethrough)
      MODIFIERS="${MODIFIERS};$STRIKETHROUGH"
      shift
      ;;
    -r | --reverse)
      MODIFIERS="${MODIFIERS};$REVERSE"
      shift
      ;;
    -c | --color)
      local COLOR_CODE=$(color_code "$2")
      if [[ -n "$2" && -n "$COLOR_CODE" ]]; then
        MODIFIERS="${MODIFIERS};$COLOR_CODE"
        shift 2
      else
        echo "Invalid color name: $2"
        echo "Available colors: $(available_colors)"
        return 1
      fi
      ;;
    --)
      shift
      break
      ;;
    *)
      echo
      echo
      logError "Unknown option: $0 '$(logCyan -i -- "$1")'"
      local help=""
      help+="Usage: styleText [OPTIONS] TEXT\n"
      help+="Options:\n"
      printf "$help"
      {
        echo "  $(logYellow -- -b), $(logYellow -- --bold)|$(logGray "Bold text")"
        echo "  $(logYellow -- -i), $(logYellow -- --italic)|$(logGray "Italic text")"
        echo "  $(logYellow -- -u), $(logYellow -- --underline)|$(logGray "Underline text")"
        echo "  $(logYellow -- -s), $(logYellow -- --strikethrough)|$(logGray "Strikethrough text")"
        echo "  $(logYellow -- -r), $(logYellow -- --reverse)|$(logGray "Reverse colors")"
        echo "  $(logYellow -- -c), $(logYellow -- --color)|$(logGray "Text color name ($(available_colors))")"
      } | column -t -s '|'
      echo $FORCE_NEW_LINE
      echo $FORCE_NEW_LINE
      exit 1
      ;;
    esac
  done
  local ANSI_ESCAPE=$(printf "\033[${MODIFIERS}m")
  local ANSI_END=$(printf "\033[m")
  printf "$ANSI_ESCAPE%s$ANSI_END" "$@"
}

logWhite() {
  styleText -c white "$@"
}

logCyan() {
  styleText -c cyan "$@"
}

logMagenta() {
  styleText -c magenta "$@"
}

logBlue() {
  styleText -c blue "$@"
}

logYellow() {
  styleText -c yellow "$@"
}

logGreen() {
  styleText -c green "$@"
}

logRed() {
  styleText -c red "$@"
}

logGray() {
  styleText -c gray "$@"
}

logInfo() {
  printf "[ $(logBlue "INFO") ] $@\n"
}

logWarn() {
  printf "[ $(logYellow "WARN") ] $@\n"
}

logError() {
  printf "[ $(logRed "ERROR") ] $@\n"
}

# Function that formats command output with a colored prompt
# Usage examples:
#   logCommand "git status"   => $ git status   # git is green, status is normal
#   logCommand ls -la         => $ ls -la       # ls is green, -la is normal
# The command name is displayed in green, the rest in normal text,
# with a bold green "$" prompt at the beginning
logCommand() {
  local command
  local rest
  if [[ "$1" == *" "* ]]; then
    # If $1 contains spaces, split it and capture the first part
    command="${1%% *}"
    # The rest becomes part of the arguments
    rest="${1#* }"
    shift
    rest="$rest $@"
  else
    # If $1 doesn't have spaces, capture it normally
    command=$1
    shift
    rest="$@"
  fi
  printf "$(logGreen -b "$") $(logGreen -- $command) $rest\n"
}

logCommandOutput() {
  printf "$(logGreen -b "$") $@\n"
  eval "$@" | while read -r line; do
    printf "  $line\n"
  done
}
