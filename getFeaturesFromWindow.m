function [members, F, couples, myfeatures, detectedGroups] = getFeaturesFromWindow(myF, index_start, index_end, video_par, model_par)
% select the working window
myF = myF(index_start : index_end, :);
F = myF;

% extract the pedestrians which can be seen inside this window
members = unique(myF(:, 2));

% it is also very useful to verify that each pedestrians will remain in the
% scene for at least a minimum number of frames, let's say 4  - so that we
% will be able to actually work on some data. shorter sequences will thus
% be ignored!
for i = 1 : size(members)
    if sum(myF(:, 2) == members(i)) < 4
        % delete the trajectory of the user from this scene
        myF(myF(:, 2) == members(i), :) = [];
    end
end

% update members
members = unique(myF(:, 2));

%% PERSONAL FEATURES
% (i.e. time, position and velocity)

% path is my global variable which contains structured information about
% the trajectory of each pedestrian
path = struct;
path(1).mts = [];

% now i check my video/simulation frame by frame
for f = myF(1, 1) : myF(end, 1)
    % since the number of rows in myF associated with each frame is not
    % fixed, we have to extract subwindows regarding the current frame
    frame_idxs = myF(:, 1) == f;
    
    % I just need the information about this particular frame
    pedestrians = myF(frame_idxs, 2);
    locations = myF(frame_idxs, [3 5]);
    
    % now, for each pedestrian, I can update its multivariate timeseries
    for i = 1 : size(pedestrians)
        % initialize the mts if this is the first frame which he appears in
        if (size(path, 2) < pedestrians(i))
            path(pedestrians(i)).mts = [];
        end
        
        if model_par.include_derivatives
            % check if we can calculate the velocities
            if (size(path(pedestrians(i)).mts, 1) > 0)
                velocities = locations(i, :) - path(pedestrians(i)).mts(end, 2:3);
            else
                velocities = [NaN, NaN];
            end
            
            % update the vector
            path(pedestrians(i)).mts = [path(pedestrians(i)).mts; f, locations(i, :), velocities];
        else
            % just update the vector
            path(pedestrians(i)).mts = [path(pedestrians(i)).mts; f, locations(i, :)];
        end
    end
end

% just remove the first line since we don't have first order
% information about it (i.e. derivatives)
for i = 1 : size(members)
    path(members(i)).mts = path(members(i)).mts(2:end, :);
end

%% PAIR-WISE FEATURES
% (i.e. md-dwt, proxemics, granger causality, heat map)

% establish every possible couple
c = combnk(1:size(members, 1), 2);
couples = zeros(size(c, 1), 2);

% initialize the feature matrix describing the couples in the scene
myfeature_1 = zeros(size(c, 1), 1);
myfeature_2 = zeros(size(c, 1), 1);
myfeature_3 = zeros(size(c, 1), 1);
myfeature_4 = zeros(size(c, 1), 1);

% initialize the cell array that will eventually contain the groups
% detected by the HM optimization
allHeatMaps = cell(size(c, 1), 1);
detectedGroups = [];

% compute features for each couple!
for i = 1 : size(c, 1)
    % select the two pedestrians that will be considered
    a = c(i, 1);        b = c(i, 2);
    couples(i, :) = [members(a), members(b)];
    
    %% 1) compute PROXEMICS
    % extract the multi dimensional data (velocities too if included)
    t = path(members(a)).mts(:, 2:end)';
    r = path(members(b)).mts(:, 2:end)';
    
    if model_par.features(1) == 1
        % get temporal information - we need them because the proxemics is
        % gonna be computed (as opposed to the dtw) only when both pedestrians
        % will be considered available in the scene
        time_t = path(members(a)).mts(:, 1)';
        time_r = path(members(b)).mts(:, 1)';
        
        % call the most basic proxemics function ever written
        myfeature_1(i) = prox(time_t, time_r, t, r);
    end
    
    %% 2) compute MD-DWT
    if model_par.features(2) == 1
        % call the dtwk function by Felty (2005)
        [dist, k] = dtwk(t, r);
        
        % since the distance higly depends on the number of points that are
        % compared, it has to be normalized!
        myfeature_2(i) = dist / k;
    end
    
    %% 3) compute GRANGER CAUSALITY
    if model_par.features(3) == 1
        % granger causality can be a bit tricky if you want to use it without
        % violating its original meaning. the first assumption we want to make
        % is that we are interested in evaluating if there is causality at all,
        % so we'll just keep the biggest one of the two!
        
        % model order: past information that will be used to predict future
        % trends
        granger_order = 4;
        
        % run the functions both ways
        warning('off','MATLAB:rankDeficientMatrix');
        F1 = granger(path(members(a)).mts, path(members(b)).mts, granger_order);
        F2 = granger(path(members(b)).mts, path(members(a)).mts, granger_order);
        warning('on','MATLAB:rankDeficientMatrix');
        
        % just keep the most informative causality
        myfeature_3(i) = max(F1, F2);
    end
    
    %% 4) compute HEAT MAPS
    if model_par.features(4) == 1 || model_par.useHMGroupDetection
        [allHeatMaps{i}, myfeature_4(i)] = heatMap(path(members(a)).mts(:, 1:3), path(members(b)).mts(:, 1:3), video_par);
        if model_par.features(4) ~= 1
            myfeature_4(i) = 0;
        end
    end
    
end

myfeatures = [myfeature_1, myfeature_2, myfeature_3, myfeature_4];
myfeatures = myfeatures(:, model_par.features == 1);

%% HEAT MAPS COARSE GROUP DETECTION
% initialize the detectedGroups to all the couples, that is equivalent not
% to run the HM detection
detectedGroups{1} = couples;

% if specified, run this heuristic to remove the improbable groups from the
% scene
if model_par.useHMGroupDetection
    detectedGroups = detectGroups(couples, allHeatMaps);
end

end
