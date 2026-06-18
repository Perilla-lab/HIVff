package require psfgen
package require autoionize
package require solvate

resetpsf
psfcontext reset
psfcontext mixedcase

set ffdir [pwd]
set basename [file tail $ffdir]

# -------------------------------
# ligand mapping: dir -> {resname, filename}
# -------------------------------
array set ligmap {
    Bevirimat      {BVM BVM}
    BI-1           {BI1 BI-1}
    BI-2           {BI2 BI-2}
    Bictegravir    {BIC BIC}
    BI-D           {BID BI-D}
    Dolutegravir   {DTG DTG}
    EKC110         {EKC EKC110}
    GS-9822        {GS98 GS-9822}
    GS-CA1         {GS GS-CA1}
    IP6            {IHP IP6}
    Lenacapavir    {QNG LEN}
    LEN10          {LEN LEN10}
    PF-46396       {PF96 PF96_S}
    PF74           {PF74 PF74}
    Pirmitegravir  {STP PIR}
}


if {[info exists ligmap($basename)]} {
    set resname   [lindex $ligmap($basename) 0]
    set basename  [lindex $ligmap($basename) 1]
} else {
    set resname $basename
    set basename $basename
}

set segid $resname
if {[string length $segid] > 7} {
    set segid [string range $segid 0 3]
}


set ip [mol new $basename.pdb]
set sel [atomselect $ip "all"]
$sel set segid $segid
$sel set resname $resname
$sel writepdb $basename.pdb

topology $ffdir/top_all36_cgenff.rtf ; # Load CGenFF
topology $ffdir/top_all36_prot.rtf ; # Load CHARMM36

set boxsize 20
set target_concentration 0.15

if {$basename eq "LEN10"} {
    topology $ffdir/../MD_test_scripts/SBCG2/sod_cla_modified.top ; # Load cluster SOD CLA
    set boxsize 50
    set target_concentration 0.03 ;# these are salt clusters not individual salt atoms
}

topology $ffdir/$basename.str


segment $segid {
	first none
	last none
	auto none
	pdb ${basename}.pdb

}
coordpdb ${basename}.pdb $segid

if {$basename ne "LEN10"} {
    regenerate angles dihedrals
}

writepsf ${basename}.psf

solvate ${basename}.psf ${basename}.pdb -t $boxsize -o ${basename}_solvent -s W



if {$basename eq "LEN10"} {
    autoionize -psf ${basename}_solvent.psf -pdb  ${basename}_solvent.pdb -cation SOD -anion CLA -sc $target_concentration -o ${basename}_ions_solvent_sc150mM -seg I1
} else {
    autoionize -psf ${basename}_solvent.psf -pdb  ${basename}_solvent.pdb -cation SOD -anion CLA -sc $target_concentration -o ${basename}.preped -seg I1
}

# #Load the complex
set ip [mol load psf ${basename}.preped.psf pdb ${basename}.preped.pdb]
set all [atomselect $ip "all"] ; # Select system and measure box dimensions
lassign [measure minmax $all] min max
set dims [vecsub $max $min]
puts "Box dimensions:"
#Output box dimentions to file for easy cat in the config
set fp [open "boxdims.txt" w]
foreach dim $dims lab {bx by bz} {puts "set $lab $dim"; puts $fp "set $lab $dim"}
foreach dim [measure center $all] lab {cx cy cz} {puts "set $lab $dim"; puts $fp "set $lab $dim"}
close $fp

if {$basename eq "LEN10"} {
    resetpsf
    psfcontext reset
    readpsf ${basename}_ions_solvent_sc150mM.psf
    coordpdb ${basename}_ions_solvent_sc150mM.pdb
    mol load psf ${basename}_ions_solvent_sc150mM.psf pdb ${basename}_ions_solvent_sc150mM.pdb
    set bad [atomselect top "water"]
    foreach segid [$bad get segid] resid [$bad get resid] {
        delatom $segid $resid
    }
    set CG [atomselect top all]
    writepdb LEN10.preped.pdb
    writepsf LEN10.preped.psf
} ;# NO solvent with SBCG2

#Gemerate restraints
set all [atomselect $ip all]
set sel1 [atomselect $ip "resname ${resname}"]
$all  set beta 0
$sel1 set beta 1
$all writepdb AA_run_restraints_1.pdb

file delete ${basename}_ions.pdb ${basename}_ions_solvent.pdb cionize.in 
file delete ${basename}_ions_solvent.psf ${basename}_solvent.psf
file delete ${basename}_solvent.pdb ${basename}_solvent.log
if {$basename eq "LEN10"} {
    file delete $${basename}_ions_solvent_sc150mM.psf ${basename}_ions_solvent_sc150mM.pdb
}

exit

