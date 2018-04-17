#!/bin/sh
set -em

is_in_cmd()
{
    echo "$CI_TEST_CMD" | grep "$1" > /dev/null
    return $?
}

if [ -n "$CI_TEST_CMD" ]; then
    printf "\e[47;1;35m [RUN TEST_CMD]: %s \e[0m\n" "$CI_TEST_SCRIPT"

    if result=$(eval "$CI_TEST_CMD" 2>&1); then
        printf '\e[42;1;97m [SUCCESS] Message:\e[0m\n \e[0;32m %b \n\e[42;1;97m[END]\e[0m\n' "$result"
        # If 'exit' in cmd do exit;
        is_in_cmd "exit" && exit 0;
    else
        status=$?
        # Because 'grep' do not print any message if 'pattern not found'
        is_in_cmd "grep" && [ $status -eq 1 ] && result="grep: Pattern Not Found"
        printf "\e[41;1;37m [FAILED] CODE: %d\n MESSAGE: %s \e[0m\n" $status "$result" && exit $((status));
    fi
fi

exit 0;