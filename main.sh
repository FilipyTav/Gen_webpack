#!/bin/bash

target_dir=$(pwd)
readonly target_dir

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly base_dir

usage() { 
    echo "Usage: $0 [--stylesheet=(css,sass,scss)] [--script=(js,ts,jsx,tsx)]" 1>&2; 
    exit 1; 
}

STYLESHEETS="css"
SCRIPT="js"

for i in "$@"; do
    case $i in
        --stylesheet=* )
            value="${i#*=}"
            possibilities=("css" "sass" "scss")

            ! [[ ${possibilities[*]} =~ ${value} ]] && break

            STYLESHEETS="$value"
            shift ;;

        --script=* )
            value="${i#*=}"
            possibilities=("js" "ts" "jsx" "tsx")

            ! [[ ${possibilities[*]} =~ ${value} ]] && break

            SCRIPT="$value"
            shift ;;

        -h )
            usage
            shift ;;

        *)
            break ;;
    esac
done

set_dist () {
    local index="$target_dir/dist/index.html"

    ! [[ -f "$index" ]] && 
        mkdir -p "$target_dir/dist/" && cp "$base_dir/files/index.html" "$target_dir/dist"

    local html_replace=0

    while IFS=" " read -r line; do
        if [[ "$line" == *"name"* ]]; then
            html_replace="$line"
            break
        fi
    done < "$target_dir/package.json"

    html_replace="${html_replace:9:-2}"

    sed -i "s/{{----PLACEHOLDER----}}/$html_replace/g" "$index"
}

set_src () {
    local index="$target_dir/src/$SCRIPT/index.$SCRIPT"

    if ! [[ -f "$index" ]]; then 
        mkdir -p "$target_dir/src/$SCRIPT/" 
        cp "$base_dir/files/index.temp" "$target_dir/src/$SCRIPT/" 
        mv "$target_dir/src/$SCRIPT/index.temp" "$target_dir/src/$SCRIPT/index.$SCRIPT"
    fi

    local style_file

    local files
    files=$(find "$target_dir" -not -path "*$target_dir/dist/*" -type f -iname "*.$STYLESHEETS")
    style_file="${files[0]}"
    echo "$style_file"

    if ! [[ -e "$style_file" ]]; then
        local style_path="$target_dir/src/styles/styles.$STYLESHEETS"

        mkdir -p "$target_dir/src/styles/"

        cp "$base_dir/files/styles.temp" "$target_dir/src/styles/"
        mv "$target_dir/src/styles/styles.temp" "$target_dir/src/styles/styles.$STYLESHEETS"

        touch "$style_path" 

        style_file="$style_path"

        local relative_path
        relative_path=$( realpath --relative-to="$index" "$style_file" )
        relative_path="${relative_path:3}"

        relative_path=$(echo "$relative_path" | sed 's/\//\\\//g' )

        sed -i "s/{{----PLACEHOLDER----}}/$relative_path/g" "$index"
    fi

}

set_webpack () {
    npm install webpack webpack-cli --save-dev
    npm install --save-dev style-loader css-loader

    if ! [[ -e "$target_dir/webpack.config.js" ]]; then
        case "$STYLESHEETS" in
            "css" ) 
                cp "$base_dir/files/webpack.config.js" "$target_dir/"
                shift ;;

            "sass" | "scss" ) 
                npm install sass-loader sass webpack --save-dev

                cp "$base_dir/files/webpack.config.sass" "$target_dir/"
                mv "$target_dir/webpack.config.sass" "$target_dir/webpack.config.js"
                shift ;;

            *)
                shift ;;
        esac

        sed -i "s/{{----SCRIPT----}}/$SCRIPT/g" "$target_dir/webpack.config.js"
    fi
}

! [[ -f "$target_dir/package.json" ]] &&
    npm init -y


# If there is no .gitignore file, copy the one in the files directory
! [[ -f ".gitignore" ]] && cp "$base_dir/files/.gitignore" "$target_dir"

set_webpack

set_dist
set_src

