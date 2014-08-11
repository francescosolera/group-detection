%% 0) THIS IS THE MAIN FILE
% IF THIS IS YOUR FIRST TIME HERE, BEFORE YOU CAN RUN THIS CODE, YOU WILL
% NEED TO FETCH SOME DATA - CONSIDER DOWNLOADING SOME PRE TRAINED MODEL
% FROM OUR WEBSITE @ UNIMORE: imagelab.unimore.it
%
% I ALSO SUGGEST YOU TO READ THE README FILE ON GITHUB TO SET UP YOUR FIRST
% EXPERIMENT, IT'S REALLY EASY!
% CHECK IT OUT HERE: https://github.com/francescosolera/group-detection

%% 1) INITIALIZE - NO NEED TO EDIT
clc; clear; close all;

% parallelization
ncore = 12;
if matlabpool('size') ~= ncore
    if matlabpool('size') > 0
        matlabpool close
    end
    matlabpool('open', 'local', ncore);
    fprintf('\n');
end

% units of measurements
s = 1;  Hz = 1/s;   m = 1;

%% 2) PREPARE FOR TRAINING/TESTING
% THIS IS WHERE YOU WANT TO EDIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% specify data
dataDirectory = 'mydata/<dataset_name_here>';
feature_extraction = false;

% parameters
model_par.display                = true;
model_par.window_size            = 10 * s;
model_par.trainingSetSize        = 20;
model_par.testingSetSize         = 20 - model_par.trainingSetSize;
model_par.features               = [1, 1, 1, 1]; % (PROX, MDWT, GRNG, HMAP)

% train model or use pretrained?
model.trainMe = false;

% STOP EDITING HERE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (unless you know what you're doing...)

model_par.numberOfFeatures       = sum(model_par.features);
model_par.include_derivatives    = false;
model_par.useHMGroupDetection    = false;

model.preTrained.w = loadPreTrained(model.trainMe, model_par.features, dataDirectory);

% load data
[myF, clusters, video_par] = loadData('load from file', dataDirectory);

defScenario = [ ...
    'data: '         dataDirectory ...
    ', #tr: '        num2str(model_par.trainingSetSize) ...
    ', #te: '        num2str(model_par.testingSetSize) ...
    ', heuristic: '  num2str(model_par.useHMGroupDetection)];

%% 3) FEATURE EXTRACTION
tic
index_start = 1;    index_end = 1;
if feature_extraction || ~exist([dataDirectory '.mat'], 'file')
    
    X = struct;                         % X contains the input data
    Y = struct;                         % Y contains the ground truth info
        
    fprintf('Extracting features:\n0%%');
    
    for i = 1 : model_par.trainingSetSize + model_par.testingSetSize
        
        % this parameter is needed to select the part of the simulation/video
        % which regards the testing set -> used for calling showClustering!
        if i == model_par.trainingSetSize + 1
            test_starting_index = index_start;
        end
        
        % since the windows size is defined in seconds, we have to understand
        % where a window ends in function of the index of the row in myF
        while index_end + 1 <= size(myF, 1) && myF(index_end + 1, 1) <= myF(index_start, 1) + model_par.window_size * video_par.frame_rate
            index_end = index_end + 1;
        end
        
        % now for this window we have to compute the features and get a coarse
        % detection of the possible groups if needed
        [X(i).members, X(i).F, X(i).couples, X(i).myfeatures, X(i).detectedGroups] = ...
            getFeaturesFromWindow(myF, index_start, index_end, video_par, model_par);
        
        % and we have to retrieve the clusters so we can use them in the
        % training
        [Y(i).mycluster] = getClustersFromWindow(X(i).members, dataDirectory);
        
        % update the sliding indexes
        index_start = index_end + 1;
        index_end = index_start;
        
        % print some output
        clc;
        fprintf('Extracting features:\n%d%% ', round(i / (model_par.trainingSetSize + model_par.testingSetSize) * 100));
    end
    
    save([dataDirectory '.mat'], 'X', 'Y');
    
else
    load([dataDirectory '.mat']);
end

% this parameter is needed to select the part of the simulation/video which
% regards the testing set -> used for calling showClustering!
test_ending_index = max(1, index_start - 1); % -1 added on the 12th of may, 2014

% FEATURES NORMALIZATION
mymax = zeros(1, model_par.numberOfFeatures);
% I believe we cannot consider testing set examples in the normalization
% process since in a typical setting we won't have it.
for i = 1 : model_par.trainingSetSize
    thismax = max(abs(X(i).myfeatures), [], 1);
    if size(thismax, 1) > 0
        mymax(thismax > mymax) = thismax(thismax > mymax);
    end
end

% check whether we have a normalization policy, otherwise we need
% to build a normalization tailored only for this test set...
if any(mymax) == 0
    mymax = zeros(1, model_par.numberOfFeatures);
    for k = 1 : model_par.testingSetSize
        thismax = max(abs(X(k).myfeatures), [], 1);
        if size(thismax, 1) > 0
            mymax(thismax > mymax) = thismax(thismax > mymax);
        end
    end
end

% but I will have to apply it to all my examples
for i = 1 : model_par.trainingSetSize + model_par.testingSetSize
    % make them similarity measures between 0 and 1
    if size(X(i).myfeatures, 1) > 0
        X(i).myfeatures = 1 - (X(i).myfeatures ./ repmat(mymax, size(X(i).myfeatures, 1), 1));
    end
    
    % create complementary features to better identify the similarity
    % threshold (very nice solution to a big limitation of correlational clustering)
    for j = 1 : model_par.numberOfFeatures
        X(i).myfeatures(:, model_par.numberOfFeatures + j) = X(i).myfeatures(:, j) - 1;
    end
end
fprintf('\n');
toc
fprintf('\n%s\n', defScenario);

%% 4) TRAINING
% we have decided to keep all the examples for the tests
test_starting_index = 1;
X_test = X;
Y_test = Y;
X = X(1 : model_par.trainingSetSize);
Y = Y(1 : model_par.trainingSetSize);

if model.trainMe
    % run the training algorithm
    tic; [sol, wf] = trainFW(X, Y); toc
else
    sol.w = model.preTrained.w;
end

%% 5) TESTING
% needed in order to test over all the dataset and not only the "testing set"
model_par.testingSetSize = model_par.testingSetSize + model_par.trainingSetSize;

% then evaluate the algorithm on the dataset
fprintf('\nTesting the classifier on the testing set:\n');
tic
[myY_test, absolute_error_test, p_test, r_test, perf] = test_struct_svm (X_test, Y_test, sol.w);

% print the error
output_test = round([absolute_error_test, p_test, r_test] ./ model_par.testingSetSize .* 100 .* 100) ./ 100;
fprintf('Testing error: %g%% (Precision: %g%%, Recall: %g%%)\n', output_test(1), output_test(2), output_test(3));
toc

% show the testing set clusters prediction!
if model_par.display
    showClustering(myF(test_starting_index : end, :), Y_test, myY_test, 1, model_par.testingSetSize, model_par, video_par);
end