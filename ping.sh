# exit when any command fails
set -e

# load .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

RESPONSE=$(curl -s "https://www.beeminder.com/api/v1/users/$BM_USER/goals.json?auth_token=$BM_TOKEN")
NOW=$(date "+%s")

# Get first goal where .losedate > NOW
GOAL=$(printf "%s" "$RESPONSE" | jq -r ". | map(select(.losedate > $NOW)) | .[0]")
LOSEDATE=$(printf "%s" "$GOAL" | jq -r '.losedate')
DIFF=$(($LOSEDATE - $NOW))
MINUTES=$(($DIFF / 60))
WAIT=$(($DIFF / 2))

echo "Now: $NOW"

# Example scheduled notification:
# {"id":"83pk9nIHhQDa","time":1663351243,"event":"message","topic":"bm_pings_8DEtM6ax3","message":"hello world"}

# Check for scheduled notifications scheduled in the future.
# Command to get notifications:
# curl -s "ntfy.sh/${NTFY_TOPIC}/json?poll=1&sched=1"
# The response is one JASON object per line.

# Get the first notification scheduled in the future.
NOTIFICATION=$(curl -s "ntfy.sh/${NTFY_TOPIC}/json?poll=1&sched=1" | jq -rn "inputs | if .time > $NOW then ., halt else empty end")

# If there is a notification scheduled in the future, exit.
if [ -n "$NOTIFICATION" ]; then
    echo "Notification already scheduled in the future."
    echo $NOTIFICATION
    TIME=$(printf "%s" "$NOTIFICATION" | jq -r '.time')
    echo "Exiting."
    exit 0
fi

echo "Scheduling a notification in $WAIT seconds"

# Schedule a notification:
echo $(curl \
    -H "In: ${WAIT}seconds" \
    -d "Less than minutes ${MINUTES}" ntfy.sh/${NTFY_TOPIC})

echo "Notification scheduled"