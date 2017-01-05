#!/bin/sh -e

echo Preparing commit message
echo
if [ "$TRAVIS_EVENT_TYPE" = "cron" ]
then
echo "Daily build - $(date -u)">>commit_msg
else
git log -3 --oneline>>commit_msg
fi
echo "Commit message was set to:" && cat commit_msg

echo
echo Moving files into the right folders
mkdir build/out
mkdir build/out/js
mkdir build/out/css

find build -type f -name "*.js" -exec mv -t build/out/js {} +
find build -type f -name "*.css" -exec mv -t build/out/css {} +
find libs -type f -name "*.js" -exec cp -t build/out/js {} +
find libs -type f -name "*.css" -exec cp -t build/out/css {} +
echo

echo Minification
echo -- Minifying CSS
./node_modules/.bin/minify  build/out/css
echo
echo -- Minifying JS
./node_modules/.bin/minify  build/out/js
echo

echo Cloning this repository itself into a sub directory
git clone --depth=1 --branch=gh-pages https://$GITHUB_TOKEN@github.com/$GITHUB_REPO.git && cd CssDN

echo
echo Git config
git config user.name $GIT_USER
git config user.email $GIT_EMAIL
git config --global push.default simple

echo
echo Delete old artifacts
rm -rf js
rm -rf css

echo
echo Copy new artifacts
cp -r ../build/out/js js
cp -r ../build/out/css css

echo
echo Check if jquery actually had any changes
if [ "$(echo $(git diff --numstat js/jquery.js))" = "1 1 js/jquery.js" ]
then
echo Only build date / time changed, checking out our last build
git checkout js/jquery.js
git checkout js/jquery.min.js
fi

echo
echo Copy README.md from master branch
cp -f ../README.md README.md

echo
echo Stage changes for git
git add --all .

if [ "$(git diff --staged)" = "" ]
then
echo
echo "Nothing changed since last build"
echo "We're finished here"
exit 0
fi

echo
echo Commit with git
git commit -F ../commit_msg

echo
echo Deploy
git push --quiet
echo
