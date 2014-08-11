function [myDetectedClusters] = detectGroups (couples, allHeatMaps)
%% CREATE GROUP PROBABILITY MAP
% first, we need to create the overall probability of couples: the sum
% of all the products of the heat maps of every element taken 2 at a
% time.
cumulativeHM = allHeatMaps{1};
for i = 2 : size(allHeatMaps, 1)
    cumulativeHM = cumulativeHM + allHeatMaps{i};
end

% we also need to make sure maximal cells next to each other always have a
% different value or we may risk to split two groups that would eventually
% converge to the same local maxima
% cumulativeHM = cumulativeHM + 10^-6*rand(size(cumulativeHM));

% we also need to normalize it
cumulativeHM = cumulativeHM' / max(max(cumulativeHM));

%% INITIALIZE CLUSTERING ALGORITHM
% now we want to set up the couples on the cumulative HM for clustering
convergingPos = zeros(size(allHeatMaps, 1), 2);
for i = 1 : size(allHeatMaps, 1)
    % check if this couple makes sense at all
    if max(max(allHeatMaps{i})) < 10^-4
        convergingPos(i, :) = [-1, -1];
        continue;
    end
    
    % we are going to find the highest point on the HM since we want
    % the couple to start on that point, i.e. where it is more probable
    % that the elements are a couple in the first place
    index = find(allHeatMaps{i} == max(max(allHeatMaps{i})), 1, 'first');
    row = ceil(index / size(allHeatMaps{i}, 1));
    column = index - floor(index / size(allHeatMaps{i}, 1)) * size(allHeatMaps{i}, 1);
    
    % save the starting point
    convergingPos(i, :) = [row, column];
end

% and start moving the points towards the local maxima of the
% distribution defined in cumulativeHM!

%% CLUSTERING BY GRADIENT ASCENT
% first of all, to semplify things, we'll expore a slightly
% different matrix which is basically the same but enlarged by 2
% cell on each edge, thus solving the problem of points at the
% border.
cumulativeHM_augmented = zeros(size(cumulativeHM) + 4);
cumulativeHM_augmented( 3 : end - 2, 3 : end - 2) = cumulativeHM;

changed = ones(size(allHeatMaps, 1), 1);
while sum(changed) > 1
    
%     % PLOT
%     figure(3);
%     hold off;
%     imshow(cumulativeHM'*10);
%     hold on;
%     camzoom(2);
%     plot(convergingPos(:, 1), convergingPos(:, 2), '*r');
%     pause(0.1);
    
    for i = 1 : size(allHeatMaps, 1)
       
        if changed(i) == 1 && ~ismember([-1, -1], convergingPos(i, :), 'rows')
            changed(i) = 0;
        else
            changed(i) = 0;
            continue;
        end
        
        % we now want to extract the 3x3 submatrix indexed by the pixel
        % defined in the position (adjusting the position since we are
        % working with a slightly different matrix)
        myPos_augmented = convergingPos(i, :) + 2;
        myBlock = cumulativeHM_augmented(myPos_augmented(1) - 1 : myPos_augmented(1) + 1, ...
            myPos_augmented(2) - 1 : myPos_augmented(2) + 1);
        
        % compute the derivative
        myBlock = myBlock - myBlock(2, 2);
        
        % find the gradient
        index = find(myBlock == max(max(myBlock)), 1, 'first');
        
        % move in the direction of the gradient
        if index ~= 5
            changed(i) = 1;
            
            % decode direction
            adj_r = mod(index - 1, 3) - 1;
            adj_c = ceil(index / 3) - 2;
            
            % adjust position
            convergingPos(i, :) = convergingPos(i, :) + [adj_r, adj_c];
        else
            % if we think we have reached a good local maxima, just check a
            % bit further, i.e. in a 5 cell window, just to be sure we
            % are not stuck in a ridicolously low local maxima.
            
            myBlock = cumulativeHM_augmented(myPos_augmented(1) - 2 : myPos_augmented(1) + 2, ...
                myPos_augmented(2) - 2 : myPos_augmented(2) + 2);
            
            % compute the derivative
            myBlock = myBlock - myBlock(3, 3);
            
            % find the "gradient"
            index = find(myBlock == max(max(myBlock)), 1, 'first');
            
            % try to move in the direction of the gradient
            if index ~= 13
                changed(i) = 1;
                
                % decode the direction
                adj_r = (mod(index - 1, 5) - 2) / 2;
                adj_c = (ceil(index / 5) - 3) / 2;
                
                % adjust position
                convergingPos(i, :) = convergingPos(i, :) + ceil([adj_r, adj_c]);
            end
        end
    end
end

%% CREATE CLUSTERS
% now we can put in the same cluster all the elements that we find on the same location
detectedGroups = zeros(0, 2);

for i = 1 : size(allHeatMaps, 1)
    % check if we want to cluster our couple at all
    if ismember([-1, -1], convergingPos(i, :), 'rows')
        continue;
    end
    
    if sum(ismember(detectedGroups, convergingPos(i, :), 'rows')) > 0
        % then the cluster already exist, fetch the index
        idx = find(ismember(detectedGroups, convergingPos(i, :), 'rows'));
        
        % add the couple to the just found cluster
        myDetectedClusters{idx} = [myDetectedClusters{idx}; couples(i, :)];
    else
        % otherwise the cluster doesn't exist - add it
        detectedGroups = [detectedGroups; convergingPos(i, :)];
        myDetectedClusters{size(detectedGroups, 1)} = couples(i, :);
    end
end
end