#!/bin/bash
set -e

git rm --cached mobile-common-lib
git rm ../.gitmodules
rm -rf mobile-common-lib/.git
git add mobile-common-lib
git commit -m "Change mobile-common-lib from submodule to included code"