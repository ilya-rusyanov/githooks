#!/bin/bash

# https://codeinthehole.com/tips/tips-for-using-a-git-pre-commit-hook/

STASH_NAME="pre-commit-$(date +%s)"
git stash save -q --keep-index $STASH_NAME

# check for ADDED lines with tabs
tabchar=$(printf '\t')
for file in "$(git diff --name-status --cached | grep -v ^D | cut -c3-)"; do
    if [[ "${file}" =~ [.](h|hpp|c|cpp|cxx|cc|sh|bash)$ ]]; then
        escaped_fn="$(echo "${file}" | sed 's/\//\\\//g')"

        git diff --line-prefix="${file}:" --cached -- "${file}" | grep -E "^${file}:\+.*${tabchar}.*$" && { echo error; exit 1; }
    fi
done

COMMON_FILES="common-files"
CORE_VERSION="core_version.h"
CORE_COMPONENTS='\(\(ASP\)\|\(Atm\)\|\(cmake_helpers\)\|\(Core\)\|\(Include\)\|\(kmto\)\|\(panels-core\)\|\(PPM\)\|\(RM\)\|\(Surface\)\|\(Surface_transas\)\|\(Surface_v21\)\|\(UniObjects\)\|\(Water\)\|\(Windchangers\)\|\(FireHeat\)\)'

# if common-files repository is changed
if [[ $(basename $(pwd)) == "${COMMON_FILES}" ]]; then
    # if common-files core components are changed
    if git diff --cached --name-status | cut -c3- | grep "${CORE_COMPONENTS}"; then
        # if core_version.h is changed
        if git diff --cached --name-status | grep ${CORE_VERSION}; then
            coreDiff="$(git diff --cached Core/${CORE_VERSION} | grep '^\(+\|-\)#define CF_CORE_VERSION ' | sort)"
            # if CF_CORE_VERSION string syntax ok
            if echo "$coreDiff" | grep -q '^+#define CF_CORE_VERSION "[[:digit:]]\+.[[:digit:]]\+.[[:digit:]]\+"'; then
                # check version numbers increase
                vernumStrBefore="$(echo "$coreDiff" | grep '^-' | sed -r 's/^.+CF_CORE_VERSION "(.+)"$/\1/' | tr . ' ')"
                vernumStrAfter="$(echo "$coreDiff" | grep '^+' | sed -r 's/^.+CF_CORE_VERSION "(.+)"$/\1/' | tr . ' ')"

                read -r -a arrayp <<< "$vernumStrBefore"
                read -r -a arraym <<< "$vernumStrAfter"

                deltaFirst=$((${arraym[0]}-${arrayp[0]}))
                deltaSecond=$((${arraym[1]}-${arrayp[1]}))
                deltaThird=$((${arraym[2]}-${arrayp[2]}))
                if (($deltaFirst>0)) ; then
                    echo
                else
                    if (($deltaFirst==0)) && (($deltaSecond>0)); then
                        echo
                    else
                        if (($deltaFirst==0)) && (($deltaSecond==0)) && (($deltaThird>0)); then
                            echo
                        else
                            echo $deltaFirst $deltaSecond $deltaThird >&2
                            echo "CF_CORE_VERSION does not increase properly" >&2
                            exit 1
                        fi
                    fi
                fi
            else
                echo "CF_CORE_VERSION broken string syntax" >&2
                exit 1
            fi
        else
            echo "core components are changed: please update ${CORE_VERSION}" >&2
            #reject commit
            exit 1
        fi
    fi
fi

STASHES=$(git stash list)

if [[ $STASHES == "$STASH_NAME" ]]; then
  git stash pop -q
fi
