group-detection
===============

Structured learning for social group detection

Crowds are difficult to analyze, but the events worth to be understood are likely to be limited to the result of a cooperation between members of the same group.
In this work, we propose a novel algorithm for detecting social groups in crowds by means of a Correlation Clustering procedure on people trajectories. The affinity between crowd members is learned through an online formulation of the Structural SVM framework and a set of specifically designed features characterizing both their physical and social identity, inspired by Proxemic theory, Granger causality, DTW and Heat-maps. To adhere to sociological observations, we introduce a loss function (G-MITRE) able to deal with the complexity of evaluating group detection performances. We show our algorithm achieves state-of-the-art results both in presence of complete trajectories and with tracklets provided by available detector/tracker systems.

code and datasets
=================

If you download this code you're half way ready to run it yourself! You'll first need to fetch the data as well. In order to ease your first launch settings, we suggest you to download our datasets from the ImageLab site at University of Modena and Reggio Emilia (http://goo.gl/st1q3C). On these datasets we've already pretrained our model, so you'll just need to extract the zip file and put the content inside the 'mydata' folder. Suppose you've downloaded the datasets 'student003', starting from your main directory you should be able to see the following structure:
mydata > student003 > %06d.jpg (all the images)
mydata > student003 > trajectories.txt (your input file)
mydata > student003 > clusters.txt (your GT file, where groups are stored)
mydata > student003 > video_par.mat (some video settings)
mydata > student003.txt (pretrained parameters)
mydata > student003.mat (this is where the features, previously extracted, are stored)

If the file 'student003.mat' is missing, the system will just recompute the features and save it for the next time, so it's presence is not mandatory. For the datasets you download from our website, the algorithm has already a pretrained version. To exploit the pretrained version you have to set some parameter in Sec. 2 of the main code. Since each video has it's own parameters, you will also find a file named student003.txt where you can copy/paste its content directly into the main code (from line 20 to 32, i.e. inside the "you can edit here!" part).

If you want to make new experiments on our datasets, you will probably have to recompute the features. Only then you'll be able to change the features employed, the length of the time window the training set size and so on. Of course, if you change the features, you might want to retrain your model as well!

Otherwise you can make up your dataset. For the code to run appropriately, you can just mimic the folder structure of one of our datasets. You will need the images, the input and the GT files as well as for the parameter mat file.


citation
========
If you use this code, please cite the following article:

Solera, F.; Calderara, S.; Cucchiara, R., "Structured learning for detection of social groups in crowd"
Proc. IEEE Int'l Confe. Advanced Video and Signal Based Surveillance (AVSS), pp.7-12, Aug. 2013
URL: http://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6636608&isnumber=6636596

