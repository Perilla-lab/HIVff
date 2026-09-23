# C4-PF74

Canonical four-bead SBCG2 PF74 deployment input, intentionally laid out like `LEN10`.

| File | Purpose |
| --- | --- |
| `C4-PF74.pdb` | Selected four-bead coordinates from `cg_PF74_4_t65_aaconn` |
| `C4-PF74.str` | Self-contained CHARMM stream: topology and bonded/nonbonded C4-PF74 parameters |
| `LICENSE` | Project license |

To prepare a deployment system, copy the shared files from `../MD_test_scripts` into this directory and run `./setup_system.sh`. The shared scripts map this directory to residue `F74`, use the SBCG2 cluster-ion topology/parameters, build the 50 A-padded 30 mM cluster-salt water box, and then write the water-stripped `C4-PF74.preped.{psf,pdb}` used by `min_heat_eq.namd`.

