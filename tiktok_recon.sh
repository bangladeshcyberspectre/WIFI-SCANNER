
 #!/bin/bash
# ══════════════════════════════════════════════════════════════════
#   TikTok Recon Tool  v1.0
#   Created by : অচেনা গেমার
#   Purpose    : Public TikTok profile information fetcher
# ══════════════════════════════════════════════════════════════════

set -u

# ─── Colors ───────────────────────────────────────────────────────
E=$'\033'
RED="${E}[1;31m"; GRN="${E}[1;32m"; YEL="${E}[1;33m"
BLU="${E}[1;34m"; MAG="${E}[1;35m"; CYN="${E}[1;36m"
WHT="${E}[1;37m"; DIM="${E}[2m";  NC="${E}[0m"

BW=56   # box width

# ─── Helpers ──────────────────────────────────────────────────────
hline() { printf '═%.0s' $(seq 1 $BW); }

center() {
  local t="$1" l p q
  l=${#t}
  p=$(( (BW - l) / 2 ))
  q=$(( BW - l - p ))
  printf '%*s%s%*s' "$p" '' "$t" "$q" ''
}

jget() { printf '%s' "$1" | jq -r "$2 // empty" 2>/dev/null; }

# ─── Dependency check ─────────────────────────────────────────────
check_deps() {
  local miss=0
  for d in curl jq; do
    command -v "$d" >/dev/null 2>&1 || { echo -e "${RED}   [!] '$d' ইনস্টল করা নেই।${NC}"; miss=1; }
  done
  if [ "$miss" -eq 1 ]; then
    echo -e "${YEL}       Termux : pkg install curl jq${NC}"
    echo -e "${YEL}       Ubuntu : sudo apt install curl jq${NC}"
    echo -e "${YEL}       macOS  : brew install curl jq${NC}"
    exit 1
  fi
}

# ─── Banner ───────────────────────────────────────────────────────
banner() {
  clear
  echo
  echo -e "${CYN}   ╔$(hline)╗${NC}"
  echo -e "${CYN}   ║${NC}$(center '')${CYN}║${NC}"
  echo -e "${CYN}   ║${NC}$(center '▸  T I K T O K   R E C O N  ◂')${CYN}║${NC}"
  echo -e "${CYN}   ║${NC}$(center '')${CYN}║${NC}"
  echo -e "${CYN}   ║${NC}${YEL}$(center 'T O O L   v 1 . 0')${NC}${CYN}║${NC}"
  echo -e "${CYN}   ║${NC}$(center '')${CYN}║${NC}"
  echo -e "${CYN}   ╚$(hline)╝${NC}"
  echo -e "${GRN}             ✦  Created by : অচেনা গেমার  ✦${NC}"
  echo
}

# ─── Menu ─────────────────────────────────────────────────────────
menu() {
  echo -e "${CYN}   ┌──────────────────────────────────────────────────────${NC}"
  echo -e "${CYN}   │${NC} ${WHT}মেইন মেনু${NC} ${DIM}/ MAIN MENU${NC}"
  echo -e "${CYN}   ├──────────────────────────────────────────────────────${NC}"
  echo -e "${CYN}   │${NC}  ${GRN}[1]${NC}  🔍  ইউজারনেম দিয়ে প্রোফাইল সার্চ করুন"
  echo -e "${CYN}   │${NC}  ${GRN}[2]${NC}  ℹ️   টুল সম্পর্কে জানুন"
  echo -e "${CYN}   │${NC}  ${GRN}[3]${NC}  🚪  প্রস্থান করুন"
  echo -e "${CYN}   └──────────────────────────────────────────────────────${NC}"
  echo
  echo -ne "${YEL}   ➤ অপশন বেছে নিন [1-3] : ${NC}"
}

# ─── Loading spinner ──────────────────────────────────────────────
fetch_with_spinner() {
  local url="$1" out="$2" pid i=0
  local frames='|/-\'
  curl -s -L \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36" \
    "$url" -o "$out" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r   ${CYN}%s${NC}  ডেটা আনা হচ্ছে ...  " "${frames:$i:1}"
    i=$(( (i + 1) % 4 ))
    sleep 0.12
  done
  wait "$pid" 2>/dev/null
  printf "\r   ${GRN}✔${NC}  ডেটা আনা সম্পন্ন!                \n"
}

# ─── Extract JSON block ───────────────────────────────────────────
extract_json() {
  local html="$1"
  if grep -qP '' /dev/null 2>/dev/null; then
    printf '%s' "$html" | grep -oP '(?<=<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">).*?(?=</script>)' | head -n1
  else
    printf '%s' "$html" | sed -n 's|.*<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">\(.*\)</script>.*|\1|p' | head -n1
  fi
}

# ─── Main lookup ──────────────────────────────────────────────────
do_lookup() {
  echo
  echo -e "${YEL}   ┌──────────────────────────────────────────────────────${NC}"
  echo -e "${YEL}   │${NC} ${WHT}ইউজারনেম লিখুন${NC} ${DIM}(যেমন: @khaby.lame)${NC}"
  echo -e "${YEL}   └──────────────────────────────────────────────────────${NC}"
  echo -ne "${GRN}   ➤ ${NC}"
  read -r INPUT

  INPUT="${INPUT// /}"
  if [ -z "$INPUT" ]; then
    echo -e "${RED}   [!] আপনি কিছু লেখেননি।${NC}"; sleep 1; return
  fi
  USERNAME="${INPUT#@}"

  local TMP="/tmp/tt_recon_$$.html"
  echo
  fetch_with_spinner "https://www.tiktok.com/@${USERNAME}" "$TMP"

  local HTML JSON BASE U S
  HTML=$(cat "$TMP"); rm -f "$TMP"

  JSON=$(extract_json "$HTML")

  if [ -z "$JSON" ]; then
    echo
    echo -e "${RED}   ╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}   ║${NC}${WHT}   ✖  ডেটা পাওয়া যায়নি!${NC}"
    echo -e "${RED}   ║${NC}   • অ্যাকাউন্টটি প্রাইভেট / ব্যান / ডিলিট হতে পারে"
    echo -e "${RED}   ║${NC}   • অথবা ইউজারনেম ভুল লিখেছেন"
    echo -e "${RED}   ╚════════════════════════════════════════════════════════╝${NC}"
    return
  fi

  BASE='.__DEFAULT_SCOPE__."webapp.user-detail".userInfo'
  U=$(printf '%s' "$JSON" | jq -c "${BASE}.user"  2>/dev/null)
  S=$(printf '%s' "$JSON" | jq -c "${BASE}.stats" 2>/dev/null)
  [ "$U" = "null" ] && U=""
  [ "$S" = "null" ] && S=""

  # Fallback: যেকোনো uniqueId object খুঁজে বের করো
  if [ -z "$U" ]; then
    U=$(printf '%s' "$JSON" | jq -c '.. | objects | select(has("uniqueId"))' 2>/dev/null | head -n1)
  fi

  if [ -z "$U" ]; then
    echo -e "${RED}   [!] ইউজার ইনফরমেশন খুঁজে পাওয়া যায়নি।${NC}"
    return
  fi

  stat() {
    local v; v=$(jget "$S" ".$1")
    [ -z "$v" ] && v=$(jget "$U" ".stats.$1")
    [ -z "$v" ] && v="0"
    printf '%s' "$v"
  }

  local uname name uid secuid bio ver priv region created
  uname=$(jget "$U" '.uniqueId');  [ -z "$uname" ] && uname="$USERNAME"
  name=$(jget "$U" '.nickname');   [ -z "$name" ]  && name="N/A"
  uid=$(jget "$U" '.id');          [ -z "$uid" ]   && uid="N/A"
  secuid=$(jget "$U" '.secUid');   [ -z "$secuid" ]&& secuid="N/A"
  bio=$(jget "$U" '.signature');   [ -z "$bio" ]   && bio="—"
  ver=$(jget "$U" '.verified');    [ -z "$ver" ]   && ver="false"
  priv=$(jget "$U" '.privateAccount'); [ -z "$priv" ] && priv="false"
  region=$(jget "$U" '.region');   [ -z "$region" ]&& region="N/A"
  created=$(jget "$U" '.createTime')

  # ─── Result box ─────────────────────────────────────────────────
  echo
  echo -e "${CYN}   ╔$(hline)╗${NC}"
  echo -e "${CYN}   ║${NC}${WHT}$(center 'P R O F I L E   I N F O')${NC}${CYN}║${NC}"
  echo -e "${CYN}   ╚$(hline)╝${NC}"

  row() { printf "${CYN}   ║${NC} ${YEL}%-15s${NC}${WHT}:${NC} %s\n" "$1" "$2"; }

  row "Username"      "@${uname}"
  row "Display Name"  "${name}"
  row "User ID"       "${uid}"
  row "SecUid"        "${secuid:0:32}..."
  row "Bio"           "${bio}"
  row "Region"        "${region}"
  row "Verified"      "$( [ "$ver" = "true" ] && echo -e "${GRN}✔ Yes${NC}" || echo -e "${RED}✖ No${NC}" )"
  row "Private Acc"   "$( [ "$priv" = "true" ] && echo -e "${YEL}🔒 Yes${NC}" || echo -e "${GRN}🔓 No${NC}" )"
  echo -e "${CYN}   ╟──────────────────────────────────────────────────────${NC}"
  row "Followers"     "$(stat followerCount)"
  row "Following"     "$(stat followingCount)"
  row "Total Likes"   "$(stat heartCount)"
  row "Videos"        "$(stat videoCount)"
  echo -e "${CYN}   ╟──────────────────────────────────────────────────────${NC}"

  if [ -n "$created" ]; then
    local human
    human=$(date -d @"$created" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
         || date -r "$created" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
         || echo "$created")
    row "Created"     "${human}"
  fi

  row "Profile URL"  "https://www.tiktok.com/@${uname}"
  echo -e "${CYN}   ╚──────────────────────────────────────────────────────${NC}"
  echo
}

# ─── About ────────────────────────────────────────────────────────
about() {
  clear; banner
  echo -e "${WHT}   📌 টুল সম্পর্কে${NC}"
  echo -e "${CYN}   ────────────────────────────────────────────────────────${NC}"
  echo -e "   এই টুলটি TikTok-এর ${GRN}পাবলিকলি দৃশ্যমান${NC} প্রোফাইল ডেটা"
  echo -e "   সংগ্রহ করে — যেমন ইউজারনেম, নাম, বায়ো, ফলোয়ার কাউন্ট ইত্যাদি।"
  echo
  echo -e "${RED}   ⚠  যা পাওয়া সম্ভব নয়:${NC}"
  echo -e "     ${RED}✖${NC} ফোন নাম্বার        — TikTok কখনোই পাবলিক করেনা"
  echo -e "     ${RED}✖${NC} কে খুলেছে (আসল পরিচয়) — এটা TikTok-এর প্রাইভেট ডেটা"
  echo -e "     ${RED}✖${NC} কার সাথে কথা হয়েছে (DM) — এন্ড-টু-এন্ড এনক্রিপ্টেড"
  echo
  echo -e "${YEL}   এই ধরনের ডেটা কোনো স্ক্রিপ্ট দিয়ে বের করা সম্ভব নয়।${NC}"
  echo -e "${YEL}   যারা এসব দাবি করে টুল বিক্রি করে — তারা স্ক্যামার।${NC}"
  echo
  echo -ne "${GRN}   ➤ Enter চাপুন ফিরে যেতে...${NC}"; read -r _
}

# ─── Main loop ────────────────────────────────────────────────────
check_deps
while true; do
  banner
  menu
  read -r CHOICE
  case "$CHOICE" in
    1) do_lookup; echo -ne "${GRN}   ➤ Enter চাপুন...${NC}"; read -r _ ;;
    2) about ;;
    3) clear; echo -e "${MAG}   ✦ ধন্যবাদ! অচেনা গেমার ✦${NC}"; echo; exit 0 ;;
    *) echo -e "${RED}   [!] ভুল অপশন। আবার চেষ্টা করুন।${NC}"; sleep 1 ;;
  esac
done