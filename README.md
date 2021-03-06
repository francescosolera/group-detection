group-detection
===============

###structured learning for groups detection in crowd

*Crowds are difficult to analyze, but the events worth to be understood are likely to be limited to the result of a cooperation between members of the same group.
In this work, we propose a novel algorithm for detecting social groups in crowds by means of a Correlation Clustering procedure on people trajectories. The affinity between crowd members is learned through an online formulation of the Structural SVM framework and a set of specifically designed features characterizing both their physical and social identity, inspired by Proxemic theory, Granger causality, DTW and Heat-maps. To adhere to sociological observations, we introduce a loss function (G-MITRE) able to deal with the complexity of evaluating group detection performances. We show our algorithm achieves state-of-the-art results both in presence of complete trajectories and with tracklets provided by available detector/tracker systems.*

<br /><p align="center">
  <img src="http://imagelab.ing.unimore.it/imagelab/immagini/example_group_detection.jpg" />
</p>
<br />

###code and datasets

If you download this code you're half way ready to run it yourself! You'll first need to fetch some data as well.

In order to ease your first launch settings, we suggest you to download our datasets from [ImageLab](http://imagelab.ing.unimore.it/group-detection/) @ University of Modena. On these datasets we've already pretrained our model, so you'll just need to extract the zip file and put the content inside the 'mydata' folder. Suppose you've downloaded the datasets 'student003', starting from your main directory you should be able to see the following structure:
- mydata > student003 > %06d.jpg (all the images)
- mydata > student003 > trajectories.txt (your input file)
- mydata > student003 > clusters.txt (your GT file, where groups are stored)
- mydata > student003 > video_par.mat (some video settings)
- mydata > student003.txt (pretrained parameters)
- mydata > student003.mat (this is where the features, previously extracted, are saved)

If the file 'student003.mat' is missing, the system will just recompute the features and save it for the next time, so it's presence is not mandatory. For the datasets you download from our website, the algorithm has already a pretrained version. To exploit the pretrained version you have to set some parameter in Sec. 2 of the main code. Since each video has it's own parameters, you will also find a file named 'student003.txt' where you can copy/paste its content directly into the main code (from line 29 to 41, *i.e.* inside the "you can edit here!" part).

If you want to make new experiments on our datasets, you will probably have to recompute the features. Only then you'll be able to change the features employed, the length of the time window the training set size and so on. Of course, if you change the features, you might want to retrain your model as well!

Otherwise you can make up your dataset. For the code to run appropriately, you can just mimic the folder structure of one of our datasets. You will need the images, the input and the GT files as well as for the parameter mat file.

#####concluding remarks
You may need to adjust matlab parallel jobs settings in order to run the code - but it will be just a matter of efficiency. Talking about efficiency: sorry the code is not optimized yet! If you find any bugs or need help in running the code, please contact one of the authors. Thank you!


###citation and contacts
If you use this code, please cite the following article:

```
Solera, F.; Calderara, S.; Cucchiara, R., "Socially Constrained Structural Learning for Groups Detection in Crowd"
IEEE Transactions on Pattern Analysis and Machine Intelligence, Aug. 2015
DOI: http://dx.doi.org/10.1109/TPAMI.2015.2470658
```

- Francesco Solera    francesco.solera@unimore.it
- Simone Calderara    simone.calderara@unimore.it
- Rita Cucchiara        rita.cucchiara@unimore.it
