#!/bin/sh
set -e

if [ -n "$CI_TEST_CMD" ]; then
    printf "\e[0;33m Gonna run TEST_CMD: %s \e[0m\n" "$CI_TEST_CMD"
    $CI_TEST_CMD || exit $?
fi

if [ -n "$CI_TEST_SCRIPT" ] && [ -x "$CI_TEST_SCRIPT" ]; then
    printf "\e[0;33m Gonna run TEST_SCRIPT: %s \e[0m\n" "$CI_TEST_SCRIPT"
    $CI_TEST_SCRIPT || exit $?
fi

exit 0;