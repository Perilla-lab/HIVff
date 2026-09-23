# MD Test Scripts for Ligand System Preparation and Equilibration

This directory contains scripts for preparing solvated, ionized ligand systems and running a basic NAMD minimization, heating, and equilibration workflow.

## Files

| File                          | Purpose                                                                                                                 |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `setup_system.sh`             | Downloads required CHARMM/CGenFF topology and parameter files, then runs the VMD/Tcl system-building script.            |
| `auto_generate_structure.tcl` | Builds the ligand PSF/PDB, solvates the system, adds ions, writes box dimensions, and generates a restraint-marker PDB. |
| `min_heat_eq.namd`            | NAMD configuration for minimization, heating, equilibration, and continued equilibration.                               |
| `toppar_water_ions_namd.str`  | CHARMM water and ion parameter stream file used by NAMD.                                                                |

## Requirements

The workflow requires:

* VMD with the `psfgen`, `solvate`, and `autoionize` plugins
* NAMD CPU binary (namd3_cpu) and optionally NAMD GPU enabled binary (namd3)
* `wget`
* A ligand PDB file
* A ligand CGenFF or SBCG2 `.str` file
* Internet access for atomistic ligand setup; it is not required for the `LEN10` or `C4-PF74` SBCG2 branches

## How this workflow is intended to be used

These scripts are designed to be copied into an individual drug directory and run from inside that directory.

The current working directory name is used to determine which ligand is being prepared. For example, if the scripts are copied into a directory named:

```text
Lenacapavir
```

then the setup script recognizes this as the Lenacapavir system and maps it to:

```text
resname  QNG
basename LEN
```

Therefore, the `Lenacapavir` directory should contain the mapped ligand input files:

```text
LEN.pdb
LEN.str
```

along with the setup and simulation scripts.

A typical setup would look like:

```text
Lenacapavir/
├── LEN.pdb
├── LEN.str
├── auto_generate_structure.tcl
├── setup_system.sh
├── min_heat_eq.namd
└── toppar_water_ions_namd.str
```

The scripts should be run directly from inside the drug directory:

```bash
cd Lenacapavir
chmod +x setup_system.sh
./setup_system.sh
```

The same workflow can be repeated for any other drug directory. For example:

```text
Bevirimat/
├── BVM.pdb
├── BVM.str
├── auto_generate_structure.tcl
├── setup_system.sh
├── min_heat_eq.namd
└── toppar_water_ions_namd.str
```

```bash
cd Bevirimat
chmod +x setup_system.sh
./setup_system.sh
```

Each drug directory is self-contained. The setup output, solvated/ionized files, box dimensions, and NAMD output directory are generated inside that same drug directory.

## Ligand name mapping

The scripts currently define the following ligand mappings:

| Directory name  | Residue name | Input basename |
| --------------- | -----------: | -------------: |
| `Bevirimat`     |        `BVM` |          `BVM` |
| `BI-1`          |        `BI1` |         `BI-1` |
| `BI-2`          |        `BI2` |         `BI-2` |
| `Bictegravir`   |        `BIC` |          `BIC` |
| `BI-D`          |        `BID` |         `BI-D` |
| `Dolutegravir`  |        `DTG` |          `DTG` |
| `EKC110`        |        `EKC` |       `EKC110` |
| `GS-9822`       |       `GS98` |      `GS-9822` |
| `GS-CA1`        |         `GS` |       `GS-CA1` |
| `IP6`           |        `IHP` |          `IP6` |
| `Lenacapavir`   |        `QNG` |          `LEN` |
| `LEN10`         |        `LEN` |        `LEN10` |
| `C4-PF74`       |        `F74` |      `C4-PF74` |
| `PF-46396`      |       `PF96` |       `PF96_S` |
| `PF74`          |       `PF74` |         `PF74` |
| `Pirmitegravir` |        `STP` |          `PIR` |

If the directory name is not listed in the mapping, the scripts use the directory name as both the residue name and basename.

## Step 1: Prepare the system

From inside the ligand directory, run:

```bash
chmod +x setup_system.sh
./setup_system.sh
```

The setup script will:

1. Download CHARMM/CGenFF topology and parameter files for atomistic ligands (the `LEN10` and `C4-PF74` SBCG2 branches skip this download).
2. Clean the downloaded files by removing HTML `<pre>` tags.
3. Run `auto_generate_structure.tcl` in VMD text mode.
4. Generate a solvated and ionized system.

The VMD/Tcl script will:

1. Load the ligand PDB.
2. Set the ligand `segid` and `resname`.
3. Load CHARMM36 and CGenFF topology files.
4. Generate the ligand PSF.
5. Solvate the ligand system.
6. Add NaCl to approximately 0.15 M salt.
7. Write the prepared system files.
8. Measure and save the simulation box dimensions.
9. Generate a restraint-marker PDB.

## Main setup outputs

After setup, the important files are:

```text
<basename>.psf
<basename>.pdb
<basename>.preped.psf
<basename>.preped.pdb
boxdims.txt
AA_run_restraints_1.pdb
```

For example, for Lenacapavir:

```text
LEN.psf
LEN.pdb
LEN.preped.psf
LEN.preped.pdb
boxdims.txt
AA_run_restraints_1.pdb
```

The file `boxdims.txt` is sourced by `min_heat_eq.namd` to define the periodic cell dimensions and origin.

The file `AA_run_restraints_1.pdb` marks the ligand atoms with `beta = 1` and all other atoms with `beta = 0`. This can be used later for restraints, although restraints are currently turned off in `min_heat_eq.namd`.

## Step 2: Run minimization, heating, and equilibration

The NAMD configuration uses the variable `n` to choose the simulation stage:

```tcl
set n 0
```

Only one stage is run each time `min_heat_eq.namd` is submitted.

### Stage 0: Minimization

Set:

```tcl
set n 0
```

Then run:

```bash
namd3_cpu +p8 min_heat_eq.namd > min.log
```

This writes output files with the prefix:

```text
output_<basename>.preped/<basename>.preped_min0
```

### Stage 1: Heating

After minimization completes, edit `min_heat_eq.namd`:

```tcl
set n 1
```

Then run:

```bash
namd3 +p8 min_heat_eq.namd > heat.log
```

This restarts from the minimization output and heats the system from 50 K to 300 K in 50 K increments.

### Stage 2: Equilibration

After heating completes, edit `min_heat_eq.namd`:

```tcl
set n 2
```

Then run:

```bash
namd3 +p8 min_heat_eq.namd > eq.log
```

This restarts from the heating output and runs equilibration with the Langevin piston enabled.

The current equilibration length is:

```tcl
run 250000000 ;# 500 ns with a 2 fs timestep
```

### Continued equilibration

For continued equilibration, set:

```tcl
set n 3
```

or higher. For `n > 2`, the script restarts from the previous equilibration output.

For example, `n = 3` restarts from:

```text
output_<basename>.preped/<basename>.preped_eq2.restart.*
```

and writes:

```text
output_<basename>.preped/<basename>.preped_eq3.*
```

## Notes on the NAMD configuration

The configuration uses:

```tcl
timestep 2.0
rigidBonds all
PME yes
cutoff 12.0
switchdist 10.0
pairlistdist 14.0
langevin on
langevinDamping 2.0
```

For equilibration stages, the script enables pressure control:

```tcl
LangevinPiston 1
LangevinPistonTarget 1.01325
LangevinPistonPeriod 200
LangevinPistonDecay 100
LangevinPistonTemp 298
```

The simulation timestep is 2 fs.

```tcl
timestep 2.0
```

### Restraints are not currently active

The setup script generates:

```text
AA_run_restraints_1.pdb
```

where ligand atoms have `beta = 1`. 

```tcl
constraints off
```

To turn on constraints this will need to be set to on (or 1)

### Restart order matters

The stages must be run in order:

```text
n = 0  minimization
n = 1  heating
n = 2  equilibration
n > 2  continued equilibration
```

If a restart file is missing, check that the previous stage completed successfully.

## Troubleshooting

### Missing `.str` file

If VMD reports that it cannot find the ligand `.str` file, check that the input basename matches the directory mapping.

For example, the `Lenacapavir` directory expects:

```text
LEN.str
```

not:

```text
Lenacapavir.str
```

### Missing `.pdb` file

If VMD reports that it cannot find the ligand PDB, check that the PDB filename also matches the mapped basename.

For example, the `IP6` directory expects:

```text
IP6.pdb
```

### Downloaded topology files look like HTML

The setup script attempts to remove opening and closing `<pre>` tags from CHARMM-GUI downloads. If the topology or parameter files still contain HTML text, delete them and rerun:

```bash
./setup_system.sh
```

### NAMD cannot find restart files

Make sure the previous stage completed and that the `n` value is correct.

For example, heating with `n = 1` expects files from minimization:

```text
<basename>.preped_min0.restart.coor
<basename>.preped_min0.restart.vel
<basename>.preped_min0.restart.xsc
```

## Suggested workflow summary

```bash
# 1. Prepare system
chmod +x setup_system.sh
./setup_system.sh

# 2. Run minimization
# edit min_heat_eq.namd: set n 0
namd3_cpu +p8 min_heat_eq.namd > min.log

# 3. Run heating
# edit min_heat_eq.namd: set n 1
namd3 +p8 min_heat_eq.namd > heat.log

# 4. Run equilibration
# edit min_heat_eq.namd: set n 2
namd3 +p8 min_heat_eq.namd > eq.log
```
