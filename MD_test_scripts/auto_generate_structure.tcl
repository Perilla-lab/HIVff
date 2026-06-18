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

puts $ffdir
puts $resname
puts $basename

set segid $resname
if {[string length $segid] > 7} {
    set segid [string range $segid 0 3]
}


set ip [mol new $basename.pdb]
set sel [atomselect $ip "all"]
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

solvate ${basename}.psf ${basename}.pdb -t 20 -o ${basename}_solvent -s W

set target_concentration 0.15

puts "consider the ions added during cionize to reach to the target concentration"
set ID [mol load psf ${basename}_solvent.psf pdb ${basename}_solvent.pdb]
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

autoionize -psf ${basename}_solvent.psf -pdb  ${basename}_solvent.pdb -cation SOD -anion CLA -sc $justified_concentration -o ${basename}.preped -seg I1

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
set all [atomselect $ip all]
set sel1 [atomselect $ip "resname ${resname}"]
$all  set beta 0
$sel1 set beta 1
$all writepdb AA_run_restraints_1.pdb

file delete ${basename}_ions.pdb ${basename}_ions_solvent.pdb cionize.in 
file delete ${basename}_ions_solvent.psf ${basename}_solvent.psf
file delete ${basename}_solvent.pdb ${basename}_solvent.log

exit

