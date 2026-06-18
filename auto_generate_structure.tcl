package require psfgen
package require cionize
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
    PF-46396       {PF96 PF-46396}
    PF74           {PF74 PF74}
    PIR            {STP PIR}
}


if {[info exists ligmap($basename)]} {
    set resname   [lindex $ligmap($basename) 0]
    set basename  [lindex $ligmap($basename) 1]
} else {
    set resname $basename
    set basename $basename
}

puts $ffdir
puts $resname
puts $basename

set segid $resname
if {[string length $segid] > 7} {
    set segid [string range $segid 0 3]
}


mol addfile $basename.pdb
set sel [atomselect top "all"]
$sel set segid $segid
$sel set resname $resname
$sel writepdb $basename.pdb


topology $ffdir/top_all36_prot.rtf ; # Load CHARMM36
topology $ffdir/top_all36_cgenff.rtf ; # Load CGenFF
topology $ffdir/$basename.str

segment $segid {
	first none
	last none
	auto none
	pdb ${basename}.pdb

}
coordpdb ${basename}.pdb $segid
regenerate angles dihedrals
writepsf ${basename}.psf

solvate ${basename}.psf ${basename}.pdb -t 10 -o ${basename}_solvent -s W

mol new ${basename}_solvent.psf type psf waitfor all; # Load PSF
mol addfile ${basename}_solvent.pdb type pdb waitfor all ; # Load PDB

set mol top
set sel [atomselect $mol all]

set mm [measure minmax $sel]
set min [lindex $mm 0]
set max [lindex $mm 1]

set Lx [expr [lindex $max 0] - [lindex $min 0]]
set Ly [expr [lindex $max 1] - [lindex $min 1]]
set Lz [expr [lindex $max 2] - [lindex $min 2]]

set volume_A3 [expr $Lx * $Ly * $Lz]
set volume_L  [expr $volume_A3 * 1e-27]

set target_concentration 0.15
set NA 6.022e23

set Npairs [expr round($target_concentration * $volume_L * $NA)]

# --- ionize ---
# ::cionize::cionize -mol $mol -pm -ions "{SOD $Npairs CLA $Npairs}"

# Delete ions not within 10 Angstroms of the model based on indices
# set bad [atomselect top "((resname SOD CLA) not within 10 of resname ${resname})"]
# foreach segid [$bad get segid] resid [$bad get resid] {
#     delatom $segid $resid 
# }

set all [atomselect top all]

$all writepsf ${basename}_ions_solvent.psf ; # Output PSF
$all writepdb ${basename}_ions_solvent.pdb ; # Output PDB

puts "consider the ions added during cionize to reach to the target concentration"
set ID [mol load psf ${basename}_ions_solvent.psf pdb ${basename}_ions_solvent.pdb]
set all_ions [[atomselect $ID "ions"] num]
set cla_ions [[atomselect $ID "segid CLA"] num]
set na_ions [[atomselect $ID "segid SOD"] num]
set salt [expr { min( $cla_ions, $na_ions )}] ; #number of NaCl added to the system
set water_molecules [ [atomselect $ID "water and noh"] num]
set n_salt_at_target [expr { $target_concentration * $water_molecules / 56.0}] ;     #56 is molarity of water
puts $target_concentration
puts $salt
puts $n_salt_at_target
puts $water_molecules

set justified_concentration [expr {$target_concentration / (1 + $salt / $n_salt_at_target )}]

autoionize -psf ${basename}_ions_solvent.psf -pdb  ${basename}_ions_solvent.pdb -cation SOD -anion CLA -sc $justified_concentration -o ${basename}.preped -seg I1

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

#Gemerate restraints
set sel1 [atomselect $ip "resname ${resname}"]
$sel1 set beta 1
set all [atomselect top all]
$all writepdb AA_run_restraints_1.pdb

file delete ${basename}_ions.pdb ${basename}_ions_solvent.pdb cionize.in 
file delete ${basename}_ions_solvent.psf ${basename}_solvent.psf
file delete ${basename}_solvent.pdb ${basename}_solvent.log

exit

