group-detection
===============

Structured learning for social group detection

Crowds are difficult to analyze, but the events worth to be understood are likely to be limited to the result of a cooperation between members of the same group.
In this work, we propose a novel algorithm for detecting social groups in crowds by means of a Correlation Clustering procedure on people trajectories. The affinity between crowd members is learned through an online formulation of the Structural SVM framework and a set of specifically designed features characterizing both their physical and social identity, inspired by Proxemic theory, Granger causality, DTW and Heat-maps. To adhere to sociological observations, we introduce a loss function (G-MITRE) able to deal with the complexity of evaluating group detection performances. We show our algorithm achieves state-of-the-art results both in presence of complete trajectories and with tracklets provided by available detector/tracker systems.
