Anatomy_Labelled_dataExplorerGUI includes 2 main additional features compared to Anatomy_dataExplorerGUI. 

1) Population PSTH. The new GUI includes a button that toggles either Single Unit (original viewer) or Population Mode. Switching to population mode, shows a PSTH of the z-scored, average spike rate ACROSS units.
Unit selection occurs via the table filtering tool - all units selected by the current filter settings are plotted.

3) Directional Labels. The GUI accesses classification_v2.mat table, which also needs to be placed in the root folder. The table includes the outcome of a Friedman test, as well as 3 Wilcoxon-Signed Rank tests.
Statistical tests compare the spike rate in the baseline (i.e., -2 - 0s, **B**), early part of the onset response (i.e., 0 - 0.4s, **E**) and late part of the response (i.e., 0.4-0.8s, **L**).
Direction labels describe the firing activity of units within these windows, based on the outcomes of these statistical tests. 
In v2 only the spiking activity in SLOW trials was considered.

5) Small quality of life improvements, including the option to plot different event codes in PSTHs side-by-side, toggle visualization options on and off and choice between SEM and STD in the PSTHs.
