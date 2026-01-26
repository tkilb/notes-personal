#!/bin/bash
set -e

git commit -am 'Update' | exit 0
git pull
git commit -am 'Update' | exit 0
git push
