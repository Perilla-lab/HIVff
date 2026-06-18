#!/bin/bash

ffdir="$(pwd)"
base_url="https://charmm-gui.org/?doc=open_toppar&filename="


files=(
    top_all36_cgenff.rtf
    par_all36_cgenff.prm
    top_all36_prot.rtf
    par_all36m_prot.prm
    par_all36_prot.prm

    par_all36_na.prm
    top_all36_na.rtf
    # toppar_water_ions.str
)

# ----------------------------
# download + clean function
# ----------------------------
clean_pre_tags () {
    file="$1"

    # remove <pre> from FIRST line (if present)
    sed -i '1s/<pre>//' "$file"

    # remove </pre> from LAST line (if present)
    sed -i '$s/<\/pre>//' "$file"
}

# ----------------------------
# main loop
# ----------------------------
for f in "${files[@]}"; do
    url="${base_url}${f}"

    echo "Downloading: $f"

    wget -q -O "$ffdir/$f" "$url"

    # only clean if download succeeded and file is non-empty
    if [[ -s "$ffdir/$f" ]]; then
        clean_pre_tags "$ffdir/$f"
    else
        echo "Warning: $f not downloaded properly"
    fi
done

vmd -dispdev text -e auto_generate_structure.tcl


