function yhat = constraintFind(model, callbacks, parameters, detectedGroups, x, y)
w = model.w;

%% INITIALIZE CLUSTERS FOR GREEDY APPROXIMATION
% get the elements
pedestrians = x.members';

% first create a cluster for each element
Y = cell(1, size(pedestrians, 2));
for i = 1 : size(pedestrians, 2)
    Y{i} = pedestrians(i);
end

% make sure the first iteration verifies the condition
changed = true;

%% MAIN LOOP
while changed
    changed = false;
    
    % get the current number of clusters
    n_clusters = size(Y, 2);
    
    % if there's still more than one
    if n_clusters > 1
        Y_best = cell(1, n_clusters - 1);
        
        % try all possible combinations of joinings
        c = combnk(1:n_clusters, 2);
        
        % let's evaluate H(Y) for the current setting of Y
        delta = callbacks.lossFn(y, Y, callbacks, parameters);
        psi = callbacks.featureFn(x, Y);
        H = delta + dot(w, psi);
        
        % for all the possible joinings, and thus for all the possible
        % resulting clusters, we have to evaluate H(Y).
        % We'll do that using a parallel for: as a matter of
        % fact the iterations can be written as indipendent from previous
        % results. The clusters of each iteration will be saved in
        % obj_Y_temp while result (score) of each iteration will be
        % saved in
        H_temp = zeros(1, size(c, 1));
        
        % slice variable c so that it can be indexed using just the
        % iterating variable
        c_1 = c(:, 1);
        c_2 = c(:, 2);
        
        parfor i = 1 : size(c, 1)
            % before doing anything, check if the two clusters can be
            % merged or our first attemp to separate the elements in the
            % scene doesn't allow this configuration
            if ~isClusterLegal(Y{c_1(i)}, Y{c_2(i)}, detectedGroups)
                continue;
            end
            
            Y_temp = cell(1, n_clusters - 1);
            
            % we are merging this specific two ex-clusters
            Y_temp{1} = [Y{c_1(i)}, Y{c_2(i)}];
            
            % cluster counter
            k = 1;
            
            % keep all the others unchanged
            for j = 1 : n_clusters
                if j ~= c_1(i) && j ~= c_2(i)
                    k = k + 1;
                    Y_temp{k} = Y{j};
                end
            end
            
            % now we can evaluate H(Y_temp) and store it in the vector
            delta = callbacks.lossParFn(y, Y_temp, callbacks, parameters);
            psi = callbacks.featureFn(x, Y_temp);
            H_temp(i) = delta + dot(w, psi);
            
            % we also need to store the clustering associated with this
            % gradient so that in case we need it, we can access it outside
            % the parfor loop
            obj_Y_temp{i} = Y_temp;
        end
        
        % if the newly "best" formated cluster has a gradient which
        % is greater than the old one, i.e. is a more violated
        % constraint, then select it!
        [H_temp, index] = max(H_temp);
        
        if (H_temp > H)
            Y = obj_Y_temp(index);
            Y = Y{1};
            
            % loop until something has changed
            changed = true;
        end
    end
end

yhat = Y;
end