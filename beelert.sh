export $(grep -v '^#' .env | xargs)

run() {
    RESPONSE=$(curl -s "https://www.beeminder.com/api/v1/users/$BM_USER/goals.json?auth_token=$BM_TOKEN")
    GOAL=$(printf "%s" "$RESPONSE" | jq -r '.[0]')
    LOSEDATE=$(printf "%s" "$GOAL" | jq -r '.losedate')
    SLUG=$(printf "%s" "$GOAL" | jq -r '.slug')
    LIMSUM=$(printf "%s" "$GOAL" | jq -r '.limsum')
    PRETTY_DATE=$(date -jf "%s" "$LOSEDATE" "+%D %T")
    NOW=$(date "+%s")
    DIFF=$(($LOSEDATE - $NOW))
    WAIT=$(($DIFF / 2))
    PRETTY_WAIT=$(date -jf "%s" "$WAIT" "+%H:%M:%S")
    MINUTES=$(($DIFF / 60))
    
    echo "$SLUG: $LIMSUM ($PRETTY_DATE)"
    osascript -e "display notification \"$SLUG: $LIMSUM ($PRETTY_DATE)\" with title \"Beeminder\""
    say "Less than minutes $MINUTES"

    echo "Waiting $WAIT seconds ($PRETTY_WAIT)"
    sleep $WAIT

    run
}

run