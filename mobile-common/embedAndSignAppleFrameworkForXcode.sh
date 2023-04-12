#!/bin/bash -l
set -e

main()
{
    if [ "$#" -ne 1 ]; then
        printHelp
        exit 1
    fi

    MODE=$1

    if [ -z "$JAVA_HOME" ]; then
        echo "JAVA_HOME not set. Available java environments (/usr/libexec/java_home -V):"
        /usr/libexec/java_home -V
        echo ""

        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
    fi

    if [ -z "$JAVA_HOME" ]; then
        echo "Could not set JAVA_HOME, cannot compile"
        exit 1
    fi

    echo "Using java: $JAVA_HOME"

    if [[ "$MODE" == "Dev" ]]; then
        echo "Using debug build"
        export KOTLIN_FRAMEWORK_BUILD_TYPE="debug"
    elif [[ "$MODE" == "Staging" ]] || [[ "$MODE" == "Production" ]]; then
        echo "Using release build"
        export KOTLIN_FRAMEWORK_BUILD_TYPE="release"
    else
        printHelp "$MODE"
        exit 1
    fi

    ./gradlew :mobile-common-lib:embedAndSignAppleFrameworkForXcode
}

printHelp()
{
    if [ "$#" -ne 1 ]; then
        echo "No configuration parameter found."
    else
        echo "Incorrect configuration parameter: '$1'."
    fi

    echo "Pass either 'Dev', 'Staging' or 'Production' as an argument."
    echo ""
    echo "For example if running the script from xcode:"
    echo "  ./embedAndSignAppleFrameworkForXcode.sh \"\$CONFIGURATION\""
}

main "$@"
