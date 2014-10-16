#!/bin/bash
###########
# Imports a strings file that can be localized 
# from all the xib files in the Victorious code.
# 
###########

STR_INFILE=$1
STR_DIR="./xib-strings"
LANG_DIR=$OUTDIR"/en.lproj"
DEST_DIR="./victorious/victorious/"


echo ""
echo "Importing Localized Strings..."

# Process any strings file passed in as a parameter
if [ "$STR_INFILE" ]; then
    echo ""
    path=${STR_INFILE/*}
    base=${STR_INFILE##*/}
    fext=${base##*.}
    filename=$(basename $STR_INFILE)
    xibname=${base%.*}.xib
    storyboardname=${base%.*}.storyboard
    langdir=$( dirname "${STR_INFILE}" )
    lang=${langdir%.*}.lproj | grep '.lproj'

    if [ $fext = "strings" ]; then
        echo "Importing Strings File for $xibname"
        current_xib=$(find . \( -name "$xibname" -or -name "$storyboardname" \) -print | grep '/en.lproj/')
        dest_xib=${current_xib/en.lproj/'es.lproj'}
        echo "Current XIB: $current_xib"
        echo "Dest XIB: $dest_xib"
        ibtool --strings-file "$STR_INFILE" "$current_xib" --write "$dest_xib"
        echo "Finished!"
    else
        echo "Error: Input file must be a strings file... exiting now"
    fi
    echo ""
    exit 0
else # Sweep through entire project directory and locate the xib and storyboard files
    echo ""
    find . \( -name "*.xib" -or -name "*.storyboard" \) -print | grep '/en.lproj/' | while read -d $'\n' xib_file
    do
        path=${xib_file/*}
        base=${xib_file##*/}
        fext=${xib_file##*.}
        strings_file="../xib-strings/es.lproj/"${base%.*}.strings

        echo "File: $base"
        echo "Strings File: $strings_file"
    
        if [ -e "$strings_file" ]; then
            dest_xib=${xib_file/en.lproj/'es.lproj'}
            ibtool --strings-file "$strings_file" "$xib_file" --write "$dest_xib"
            echo "Current XIB: $xib_file"
            echo "Dest XIB: $dest_xib"
            echo ""
        else
            echo "$strings_file does not exist"
            echo ""
        fi
    done

    echo ""
    echo "Finished!"
    echo ""
fi
