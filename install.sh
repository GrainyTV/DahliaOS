#!/usr/bin/env bash

GITHUB="https://github.com"

function get_font_family ()
{
    local google_font_repository="https://github.com/google/fonts/raw/refs/heads/main/ofl"
    local font_family="$1"
    local -a font_ids=("${@:2}")
    local font_dir="$HOME/.local/share/fonts/${font_family^}"

    mkdir -p "$font_dir"

    for id in "${font_ids[@]}"
    do
        local font=$(grep -Po "^[a-zA-Z-]+" <<< "$id")
        curl -Ls "$google_font_repository/$font_family/$id.ttf" -o "$font_dir/$font.ttf"
    done
}

function latest_git_release ()
{
    git ls-remote --tags "$GITHUB/$1" | cut -d/ -f3- | tail -n1
}

# [FONTS]
lora_fonts=("Lora%5Bwght%5D.ttf" "Lora-Italic%5Bwght%5D.ttf")
get_font_family "lora" "${lora_fonts[@]}"

inter_fonts=("Inter%5Bopsz%2Cwght%5D" "Inter-Italic%5Bopsz%2Cwght%5D")
get_font_family "inter" "${inter_fonts[@]}"

fira_fonts=("FiraMono-Bold" "FiraMono-Medium" "FiraMono-Regular")
get_font_family "firamono" "${fira_fonts[@]}"

echo "Fonts installed!"

# [ICON-THEME]
icon_theme_owner="vinceliuice"
icon_theme_name="Tela-circle-icon-theme"
icon_theme_id="$icon_theme_owner/$icon_theme_name"
icon_theme_tag=$(latest_git_release "$icon_theme_id")

curl -Ls "$GITHUB/$icon_theme_id/archive/refs/tags/$icon_theme_tag.tar.gz" -o "$icon_theme_name"
tar -xf "$icon_theme_name"
cd "$icon_theme_name-$icon_theme_tag"
bash "install.sh" "-c" "orange"
cd ..

# small hack for file-manager icon
ln -s "system-file-manager.svg" "$HOME/.local/share/icons/Tela-circle-orange/scalable/apps/pcmanfm-qt.svg"
gtk-update-icon-cache "$HOME/.local/share/icons/Tela-circle-orange"

# [GTK-THEME]
gtk_theme_owner="vinceliuice"
gtk_theme_name="Orchis-theme"
gtk_theme_id="$gtk_theme_owner/$gtk_theme_name"
gtk_theme_tag=$(latest_git_release "$gtk_theme_id")

curl -Ls "$GITHUB/$gtk_theme_id/archive/refs/tags/$gtk_theme_tag.tar.gz" -o "$gtk_theme_name"
tar -xf "$gtk_theme_name"
cd "$gtk_theme_name-$gtk_theme_tag"
bash "install.sh" "-d" "$HOME/.local/share/themes" "-t" "orange" "-s" "standard" "--tweaks" "primary" "--round" "8px"
cd ..
