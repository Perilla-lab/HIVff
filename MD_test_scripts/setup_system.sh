#!/bin/bash

ffdir="$(pwd)"
base="$(basename "$ffdir")"
base_url="https://charmm-gui.org/?doc=open_toppar&filename="


files=(
    top_all36_cgenff.rtf
    par_all36_cgenff.prm
    top_all36_prot.rtf
    par_all36m_prot.prm
    par_all36_prot.prm
    par_all36_na.prm
    top_all36_na.rtf
)

# ----------------------------
# download + clean function
# ----------------------------
clean_pre_tags () {
    file="$1"

    # clean up HTML formatted text
    sed -i '1s/<pre>//' "$file"
    sed -i '$s/<\/pre>//' "$file"
}

# ----------------------------
# main loop
# ----------------------------
if [[ "$base" == "C4-PF74" || "$base" == "LEN10" ]]; then
    echo "SBCG2 ligand: using the self-contained ligand stream and shared cluster-ion files."
else
    for f in "${files[@]}"; do
        url="${base_url}${f}"

        echo "Downloading: $f"
        wget -q -O "$ffdir/$f" "$url"

        if [[ -s "$ffdir/$f" ]]; then
            clean_pre_tags "$ffdir/$f"
        else
            echo "Warning: $f not downloaded properly"
        fi
    done
fi

if [[ "$base" == "PF-46396" ]]; then
	ln -s PF96.str PF96_S.str
	ln -s PF96.str PF96_R.str
fi

vmd -dispdev text -e auto_generate_structure.tcl


