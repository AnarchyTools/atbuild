#!/bin/bash
if [[ $ENVIRONMENT_VARIABLE != "VALUE_WITH_EQUALS_SIGN=WORKS" ]]; then
    echo "Environment variable trouble" $ENVIRONMENT_VARIABLE
    exit 1
fi