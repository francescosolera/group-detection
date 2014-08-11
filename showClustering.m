function [allPaths] = showClustering (myF, Y, Y_pred, index_start, setSize, model_par, video_par)
% this function should show the simulation of the trajectories coloring
% clusters toghether. On the left subplot we'll be able to see che ground
% truth clustering while on the right one the predicted clustering!

% fix small bug
try video_par.xyReversed; catch, video_par.xyReversed = 0; end

% this variable add a subplot if we also have a video to display
n_subplots = 4 - 1*(video_par.videoObj == 0);
n_subplots = n_subplots(1);

% resize the figure based on the number of subplots
hFig = figure(1);
set(hFig, 'Position', [300, 300, 500 * n_subplots, 400]);

% note that some color may repeat even amongst clearly different clusters
% due to lackage of "simple" colors.
colors = 'rbgmcy';

% this variable stores all the pedestrian trajectories. it may be returned
% as output parameter
allPaths = cell(1, setSize);
index_end = index_start;

% we first have to reconstruct each person path in each scene
for j = 1 : setSize
    
    % since the windows size is defined in seconds, we have to understand
    % where a window ends in function of the index of the row in myF
    while index_end + 1 <= size(myF, 1) && myF(index_end + 1, 1) <= myF(index_start, 1) + model_par.window_size * video_par.frame_rate
        index_end = index_end + 1;
    end
    
    %index_end
    
    % select the working window
    myF_scene = myF(index_start : index_end, :);
    
    % path is my global variable which contains structured information about
    % the trajectory of each pedestrian
    path = struct;
    path(1).mts = [];
    
    % now i check my video/simulation frame by frame
    for f = myF_scene(1, 1) : myF_scene(end, 1)
        
        % since the number of rows in myF associated with each frame is not
        % fixed, we have to extract subwindows regarding the current frame
        frame_idxs = myF_scene(:, 1) == f;
        
        % I just need the information about this particular frame
        pedestrians = myF_scene(frame_idxs, 2);
        locations = myF_scene(frame_idxs, [3 5]);
        
        % now, for each pedestrian, I can update its multivariate timeseries
        for i = 1 : size(pedestrians)
            % 1 added on 12th may, 2014
            if 1 || ismember(pedestrians(i), [Y(j).mycluster{:}])
                % initialize the mts if this is the first frame which he appears in
                if (size(path, 2) < pedestrians(i))
                    path(pedestrians(i)).mts = [];
                end
                
                % update path vector
                path(pedestrians(i)).mts = [path(pedestrians(i)).mts; f, locations(i, :)];
                
                % find it in the ground truth clusters and in the predicted
                % scenario
                index_found_ground = -1;
                index_found_predicted = -1;
                for p = 1 : size(Y(j).mycluster, 2)
                    if ismember(pedestrians(i), Y(j).mycluster{p})
                        index_found_ground = p;
                    end
                end
                for p = 1 : size(Y_pred(j).mycluster, 2)
                    if ismember(pedestrians(i), Y_pred(j).mycluster{p})
                        index_found_predicted = p;
                    end
                end
                
                subplot(1, n_subplots, n_subplots);
                if index_found_ground ~= -1
                    if video_par.xyReversed
                        plot(path(pedestrians(i)).mts(:, 2), path(pedestrians(i)).mts(:, 3), colors(mod(index_found_ground, 6)+1));
                        h1 = text(path(pedestrians(i)).mts(:, 2), path(pedestrians(i)).mts(:, 3), num2str(pedestrians(i)));
                    else
                        plot(path(pedestrians(i)).mts(:, 3), path(pedestrians(i)).mts(:, 2), colors(mod(index_found_ground, 6)+1));
                        h1 = text(path(pedestrians(i)).mts(:, 3), path(pedestrians(i)).mts(:, 2), num2str(pedestrians(i)));
                    end
                    try delete(h1(1:end-1)); catch; end
                end
                
                if video_par.xyReversed
                    axis([video_par.yMin video_par.yMax video_par.xMin video_par.xMax]);
                else
                    axis([video_par.xMin video_par.xMax video_par.yMin video_par.yMax]);
                end
                
                title('Ground truth')
                if video_par.isYreversed
                    set(gca,'YDir','reverse');
                end
                hold all;
                
                subplot(1, n_subplots, n_subplots - 1);
                if index_found_predicted ~= -1
                    if length(Y_pred(j).mycluster{index_found_predicted}) < 2
                        if video_par.xyReversed
                            plot(path(pedestrians(i)).mts(:, 2), path(pedestrians(i)).mts(:, 3), 'k');
                        else
                            plot(path(pedestrians(i)).mts(:, 3), path(pedestrians(i)).mts(:, 2), 'k');
                        end
                    else
                        if video_par.xyReversed
                            plot(path(pedestrians(i)).mts(:, 2), path(pedestrians(i)).mts(:, 3), colors(mod(index_found_predicted, 6)+1));
                            h2 = text(path(pedestrians(i)).mts(:, 2), path(pedestrians(i)).mts(:, 3), num2str(pedestrians(i)));
                        else
                            plot(path(pedestrians(i)).mts(:, 3), path(pedestrians(i)).mts(:, 2), colors(mod(index_found_predicted, 6)+1));
                            h2 = text(path(pedestrians(i)).mts(:, 3), path(pedestrians(i)).mts(:, 2), num2str(pedestrians(i)));
                        end
                        try delete(h2(1:end-1)); catch; end
                        
                    end
                    
                    if video_par.xyReversed
                        axis([video_par.yMin video_par.yMax video_par.xMin video_par.xMax]);
                    else
                        axis([video_par.xMin video_par.xMax video_par.yMin video_par.yMax]);
                    end
                    title('Predicted clustering')
                    if video_par.isYreversed
                        set(gca,'YDir','reverse');
                    end
                    hold all;
                    
                end
            end
        end
        
        % show the video if it exists
        if video_par.videoObj(1) ~= 0 && mod(f, video_par.downsampling) == mod(myF(1, 1), video_par.downsampling)
            % check if its the new way or the old one!
            myVideo = imread(sprintf(video_par.videoObj, f));
            
            subplot(1, n_subplots, n_subplots - 3);
            imshow(myVideo);
            
            subplot(1, n_subplots, n_subplots - 2);
            imshow(myVideo);
            hold all;
            
            % add clusters to the video!!! as convex hulls
            t = linspace(0,2*pi,10);
            r = 20;
            
            for n = 1 : length(Y_pred(j).mycluster)
                if length(Y_pred(j).mycluster{n}) > 1
                    cluster_points = [];
                    for l = 1 : length(Y_pred(j).mycluster{n})
                        % commented on 12th of may, 2014
                        if ismember(Y_pred(j).mycluster{n}(l), pedestrians)
                            % homography
                            data = [path(Y_pred(j).mycluster{n}(l)).mts(end, 2) path(Y_pred(j).mycluster{n}(l)).mts(end, 3)];
                            data = video_par.H * [data, ones(size(data, 1), 1)]';
                            data = round(data ./ (eps+repmat(data(3, :), 3, 1)));
                            
                            x = r*cos(t) + data(1, :);
                            y = r*sin(t) + data(2, :);
                            
                            cluster_points = [cluster_points; [x', y']];
                        end
                    end
                    if size(cluster_points, 1) > 0
                        k = convhull(cluster_points(:, 1), cluster_points(:, 2));
                        h = fill(cluster_points(k, 1), cluster_points(k, 2), colors(mod(n, 6) + 1));
                        set(h,'EdgeColor',colors(mod(n, 6) + 1));
                        alpha(h, 0.1)
                    end
                end
            end
            
            pause(0.1);
            a = subplot(1, 4, 2);
            hold off;
            
            % maybe elsewhere instead of end???
            % pause(0.001)
            subplot(1, n_subplots, n_subplots - 1);     hold off;
            subplot(1, n_subplots, n_subplots);         hold off;
        end
    end
    
    % keep this path in memory
    allPaths{j} = path;
    
    % update the sliding indexes
    index_start = index_end + 1;
    index_end = index_start;
    
    % pause
end

end