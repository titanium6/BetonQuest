#!/bin/bash
if [ -z "${DEPLOY_KEY}" ]; then
  echo -e "WARNING! You need to pass the DEPLOY_KEY environment variable."
  exit 1
fi

# Prepare keys
eval "$(ssh-agent -s)"
ssh-add <(echo "${DEPLOY_KEY}" | base64 -d) || exit 2
git config --global user.name "GitHub Actions"
git config --global user.email "action@github.com"

# Clone gh-pages branch
git clone --depth=1 --branch=gh-pages "git@github.com:${GITHUB_REPOSITORY}" gh-pages || exit 3

VERSION_DIR=''

# If its to the master branch we build to 'latest'
if [ "${GITHUB_REF}" == "refs/heads/master" ]; then
  VERSION_DIR="dev"
fi
# If its a tagged build, build to the tag version and link stable
if [[ "${GITHUB_REF}" =~ ^refs/tags/v.+ ]]; then
  VERSION_DIR="v${VERSION}"
fi
# IF this is not dev or version tag
if [ "$VERSION_DIR" == '' ]; then
  exit 0
fi

echo "$0: Deploying documentation to gh-pages/versions/${VERSION_DIR}"
rm -r "gh-pages/versions/${VERSION_DIR}"
mkdir -p "gh-pages/versions/${VERSION_DIR}" || exit 4
cp -r build/documentation/* "gh-pages/versions/${VERSION_DIR}" || exit 5

# Build versions.json from english
cat <<EOF > gh-pages/versions.json
[
  {"version": "dev", "title": "dev"}
EOF
for i in $(ls -1 gh-pages/versions/ | grep -v dev | sort -V); do
  echo "  ,{\"version\": \"${i}\", \"title\": \"${i:1}\"}" >> gh-pages/versions.json
  (cd "gh-pages" && echo "${i}" > stable.txt)
done
echo "]" >> gh-pages/versions.json

STABLE=$(cat gh-pages/stable.txt)
echo "Linking gh-pages/stable.txt to gh-pages/versions/${STABLE}"

# Commit
(
  cd gh-pages || exit 6
  git add -f .
  git commit -m "Deploy documentation version '${VERSION}'"
  git push -fq origin gh-pages > /dev/null
)
