# HIV-1 inhibitor force-field (HIVff) repository

Here you can find CGenFF analogy and QM-derived CHARMM force-field parameters for various drug inhibitors of the HIV-1 virus. Geometry optimized coordinates and ligand restraint files are included for structure refinement tasks.

Pfizer (PF)
Gilead Science (GS)

Type abbreviations:
- Capsid inhibitor (CI)
- Allosteric integrase inhibitor (ALLINI)
- Integrase strand transfer inhibitor (INSTI)
- Maturation inhibitor (MI)

Current parameters:

| Name          | Also Known As     | Type   | Publication                                 |
|---------------|-------------------|--------|---------------------------------------------|
| Lenacapavir   | LEN, GS-6207      | CI     | https://doi.org/10.1021/jacs.5c13735        |
| LEN10         | Lenacapavir (SBCG2) | CI     | In preparation                              |
| C4-PF74       | PF-3450074 (four-bead SBCG2) | CI | In preparation                              |
| GS-CA-1       |                   | CI     | In preparation                              |
| PF74          | PF-3450074        | CI     | https://doi.org/10.1021/acs.jpclett.6b00517 |
| BI-1          |                   | CI     | https://doi.org/10.1021/acs.jpclett.6b00517 |
| BI-2          |                   | CI     | https://doi.org/10.1021/acs.jpclett.6b00517 |
| Primitegravir | PIR, STP0404      | ALLINI | https://doi.org/10.1128/mbio.03560-22       |
| BI-D          |                   | ALLINI | https://doi.org/10.1128/mbio.03560-22       |
| EKC110        |                   | ALLINI | https://doi.org/10.1128/mbio.00465-24       |
| GS-9822       |                   | ALLINI | In preparation                              |
| Dolutegravir  | DTG, S/GSK1349572 | INSTI  | In preparation                              |
| Bictegravir   | BIC, GS-9883      | INSTI  | In preparation                              |
| Bevirimat     | BVM, PA-457       | MI     | https://doi.org/10.1038/s41467-023-36569-y, https://doi.org/10.1021/jacs.5c13735        |
| PF-46396      | PF96              | MI     | In preparation                              |



| Name                     | Also Known As |
|--------------------------|---------------|
| Inositol Hexakisphosphate| IP6           |


The original parameterization work described in the associated
publication extends the CHARMM/CGenFF framework for the modeling of
HIV-1 replication inhibitors.

The force-field topology and parameter files distributed in this
repository were developed within the CHARMM/CGenFF framework. 
These files may contain atom types, topology definitions, and/or
parameter assignments derived from the CHARMM General Force Field
(CGenFF) and related CHARMM force-field distributions.

Users are responsible for complying with any applicable licensing,
distribution, and citation requirements associated with CHARMM and
CGenFF.

Please cite:

Rey JS, Peeples CA, Macke A, Perilla JR. CHARMM-compatible molecular mechanics force fields for multiscale
modeling of HIV-1 replication inhibitors. (Submitted)
