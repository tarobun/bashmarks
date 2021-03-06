# Copyright (c) 2010, Huy Nguyen, http://www.huyng.com
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, this list of conditions 
#       and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#       following disclaimer in the documentation and/or other materials provided with the distribution.
#     * Neither the name of Huy Nguyen nor the names of contributors
#       may be used to endorse or promote products derived from this software without 
#       specific prior written permission.
#       
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR 
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.


# USAGE: 
# s bookmarkname - saves the curr dir as bookmarkname
# g bookmarkname - jumps to the that bookmark
# g b[TAB] - tab completion is available
# p bookmarkname - prints the bookmark
# p b[TAB] - tab completion is available
# d bookmarkname - deletes the bookmark
# d [TAB] - tab completion is available
# l - list all bookmarks

# setup file to store bookmarks
if [ ! -n "$SDIRS" ]; then
    SDIRS=~/.bashmarks
fi
touch $SDIRS

# save current directory to bookmarks
function s {
    _bashmarks_check_help $@ || _bashmarks_check_name "$@" || _bashmarks_purge_line "$1"
    if [ $? -eq 1 ]; then
        echo "export DIR_$1=\"$(echo $PWD | sed -e "s#^$HOME#\$HOME#g" -e "s# #\ #g")\"" >> $SDIRS
    fi
}

# delete bookmark
function d {
    _bashmarks_check_help $@ || _bashmarks_check_name "$@" || _bashmarks_purge_line "$1" || unset "DIR_$1"
}

# jump to bookmark
function g {
    _bashmarks_check_help $@ || cd "$(eval $(echo echo $(echo \$DIR_$1)))"
}

# print bookmark
function p {
    _bashmarks_check_help $@ || echo "$(eval $(echo echo $(echo \$DIR_$1)))"
}

# list bookmarks with dirname
function l {
    _bashmarks_check_help $@ || env | sort | awk '/^DIR_.+/{split(substr($0,5),parts,"="); printf("\033[0;33m%-20s\033[0m %s\n", parts[1], parts[2]);}'
}

# print out help for the forgetful
function _bashmarks_check_help {
    source $SDIRS
    if [ "$1" = "-h" ] || [ "$1" = "-help" ] || [ "$1" = "--help" ] ; then
        echo ''
        echo 's <bookmark_name> - Saves the current directory as "bookmark_name"'
        echo 'g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"'
        echo 'p <bookmark_name> - Prints the directory associated with "bookmark_name"'
        echo 'd <bookmark_name> - Deletes the bookmark'
        echo 'l                 - Lists all available bookmarks'
        return 0
    fi
    return 1
}

# validate bookmark name
function _bashmarks_check_name {
    local error_message=""
    if [ -z $1 ]; then
        error_message="bookmark name required"
    elif [ "$1" != "$(echo $1 | sed 's/[^A-Za-z0-9_]//g')" ]; then
        error_message="bookmark name is not valid"
    fi
    [[ -z $error_message ]] && return 1 || echo $error_message; return 0
}

# safe delete line from sdirs
function _bashmarks_purge_line {
    if [ -s "$SDIRS" ]; then
        # safely create a temp file
        t=$(mktemp -t bashmarks.XXXXXX) || exit 1
        trap "rm -f -- '$t'" EXIT

        # purge line
        sed "/export DIR_$1=/d" "$SDIRS" > "$t"
        mv "$t" "$SDIRS"

        # cleanup temp file
        rm -f -- "$t"
        trap - EXIT
        return 1
    fi
    return 0
}

# list bookmarks without dirname
function _bashmarks_list_without_dirname {
    source $SDIRS
    env | grep --color=never "^DIR_" | cut -c5- | sort | grep --color=never "^.*=" | cut -f1 -d "=" 
}

# completion command
function _bashmarks_comp {
    local curw=${COMP_WORDS[COMP_CWORD]}
    COMPREPLY=($(compgen -W '`_bashmarks_list_without_dirname`' -- $curw))
    return 0
}

# ZSH completion command
function _bashmarks_compzsh {
    reply=($(_bashmarks_list_without_dirname))
}

# bind completion command for g,p,d to bashmarks_comp
if [ $ZSH_VERSION ]; then
    compctl -K _bashmarks_compzsh g
    compctl -K _bashmarks_compzsh p
    compctl -K _bashmarks_compzsh d
else
    shopt -s progcomp
    complete -F _bashmarks_comp g
    complete -F _bashmarks_comp p
    complete -F _bashmarks_comp d
fi
