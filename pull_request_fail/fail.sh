#!/bin/bash

# Suggested by Github actions to be strict
set -e
set -o pipefail

################################################################################
# Global Variables (we can't use GITHUB_ prefix)
################################################################################

API_VERSION=v3
BASE=https://api.github.com
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
HEADER="Accept: application/vnd.github.${API_VERSION}+json;"
HEADER="${HEADER}; application/vnd.github.antiope-preview+json"

# URLs
REPO_URL="${BASE}/repos/${GITHUB_REPOSITORY}"
RUNS_URL=${REPO_URL}/commits/${GITHUB_SHA}/check-runs # Runs, harhar

################################################################################
# Helper Functions
################################################################################

response_fail() {

    echo "Error with token or response.";
    exit 1;

}

get_url() {

    RESPONSE=$(curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" "${1:-}")
    echo ${RESPONSE}
}

check_credentials() {

    if [[ -z "${GITHUB_TOKEN}" ]]; then
        echo "You must include the GITHUB_TOKEN as an environment variable."
        exit 1
    fi

}

check_events_json() {

    if [[ ! -f "${GITHUB_EVENT_PATH}" ]]; then
        echo "Cannot find Github events file at ${GITHUB_EVENT_PATH}";
        exit 1;
    fi
    echo "Found ${GITHUB_EVENT_PATH}";

}

clean_up() {

    # Get all the comments for the pull request.
    BODY=$(get_url "${COMMENTS_URL}");
    COMMENTS=$(echo "$BODY" | jq --raw-output '.[] | {id: .id, body: .body} | @base64')

    for C in ${COMMENTS}; do
        COMMENT="$(echo "$C" | base64 --decode)"
        COMMENT_ID=$(echo "$COMMENT" | jq --raw-output '.id')
        COMMENT_BODY=$(echo "$COMMENT" | jq --raw-output '.body')

        # All Confuscious posts starts with this tag
	if [[ "$COMMENT_BODY" == *"GitHub Confucious Action Say"* ]]; then
            echo "Deleting old comment ID: $COMMENT_ID"
            curl -sSL -H "${AUTH_HEADER}" -H "${HEADER}" -X DELETE "${REPO_URL}/issues/comments/${COMMENT_ID}"
        fi
    done
}

post_message() {

    WISDOM_FILE=$(mktemp /tmp/wisdom.XXXXXXXXX)
    WISDOM=$(/entrypoint.sh --no-color --message > ${WISDOM_FILE});

    # Feeling lazy, do it with Python
    export AUTH_HEADER HEADER COMMENTS_URL API_VERSION GITHUB_TOKEN WISDOM_FILE
    python3 /post_message.py

}

check_runs() {

    RESPONSE=$(get_url "${RUNS_URL}")

    RUNS=$(echo "${RESPONSE}" | jq --raw-output '.check_runs | .[] | {name: .name, status: .status, conclusion: .conclusion} | @base64')

    # We have to keep looping if in progress
    INPROGRESS=0

    # We need to cycle through actions, and:
    # 1. Skip those that are this action
    # 2. Find if there is a confucious action in progress
    for R in ${RUNS}; do
        RUN="$(echo "${R}" | base64 --decode)"

        echo "Checking run ${RUN}";

        # Case 1: Is it in progress?
	STATE=$(echo "${RUN}" | jq --raw-output '.status')
        echo "Current state is ${STATE}";

        if [[ "${STATE}" == "in_progress" ]]; then
            echo "Pull request checks are still in progress.";
            INPROGRESS=1
            continue
        fi

        # Case 2: Skip this action
        NAME=$(echo "${RUN}" | jq --raw-output '.name')
	if [[ "${GITHUB_ACTION}" == "${NAME}" ]]; then
            echo "Found self! Skipping ${NAME}";
            continue
	fi

        # Case 3: Did we FAIL
	RESULT=$(echo "${RUN}" | jq --raw-output '.conclusion')
        echo "Current result is ${RESULT}";

        if [[ "${STATE}" == "completed" ]] && [[ "$RESULT" == "failure" ]]; then
            echo "Run: $NAME failure! Whomp whomp. Confuscious says..."
            clean_up;
	    post_message;
            exit 0
        fi

        # If we got in progress checks then sleep and loop again.
        if [[ "${INPROGRESS}" -eq 1 ]]; then
            echo "A watched pot never boils! Sleeping..."
            sleep 3

            # Continue calling self until we exit.
            check_runs;
        fi

    done
}


main () {

    # path to file that contains the POST response of the event
    # Example: https://github.com/actions/bin/tree/master/debug
    # Value: /github/workflow/event.json
    check_events_json;

    # Get the name of the action that was triggered
    ACTION=$(jq --raw-output .action "${GITHUB_EVENT_PATH}");
    NUMBER=$(jq --raw-output .number "${GITHUB_EVENT_PATH}");
    COMMENTS_URL="${REPO_URL}/issues/${NUMBER}/comments"

    # Only interested in newly opened 
    # https://developer.github.com/v3/activity/events/types/#pullrequestevent
    if [[ "${ACTION}" == "opened" ]] || [[ "${ACTION}" == "synchronize" ]] ; then
        check_credentials
        check_runs  # other Github actions
                    # note that if you need CircleCI to be included here,
                    # you need to install CircleCI Checks (see main README.md)
        # If we make it here, we didn't hit a fail result, or in progress
        # Delete the confuscious comment if it exists to refresh the pull request
        clean_up;

    fi
}

echo "==========================================================================
START: Running Confucious Fail Action!";
main;
echo "==========================================================================
END: Running Confucious Fail Action";
