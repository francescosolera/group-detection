function [myY, error, p_abs, r_abs, perf] = test_struct_svm (X, Y, w)
% this variable will contain our computed clustering
myY = struct;

% this variable is going to accumulate the absolute error computed during
% the test
error = 0;
p_abs = 0;
r_abs = 0;
perf = zeros(1, size(X, 2));

% loop through all the different scenarios
for i = 1 : size(X, 2)
    fprintf('.');
    
    % start with each element in its own cluster
    cluster = cell(1, size(X(i).members, 1));
    for j = 1 : size(X(i).members, 1)
        cluster{j} = X(i).members(j);
    end
    
    % get the number of clusters
    n_clusters = size(cluster, 2);
    
    % if there is more than one cluster try to merge two of them!
    changed = true;
    while changed && n_clusters > 1
        changed = false;
        % let's evaluate our current score
        psi = zeros(1, size(X(i).myfeatures, 2));
        for k = 1 : size(cluster, 2)
            mycouples = combnk(sort(cluster{k}), 2);
            if size(mycouples, 1) > 0
                for j = 1 : size(mycouples, 1)
                    psi = psi + X(i).myfeatures(X(i).couples(:, 1) == mycouples(j, 1) & X(i).couples(:, 2) == mycouples(j, 2), :);
                end
            end
        end
        
        obj_score = dot(w, psi);
        
        % we now have to try all possible joinings...
        c = combnk(1:n_clusters, 2);
        
        % ... and evaluate them all using a parallel for: as a matter of
        % fact the iterations can be written as indipendent from previous
        % results. The clusters of each iteration will be saved in
        % obj_cluster_temp while result (score) of each iteration will be
        % saved in
        obj_score_temp = zeros(1, size(c, 1));
        
        parfor j = 1 : size(c, 1)
            % before doing anything, check if the two clusters can be
            % merged or our first attemp to separate the elements in the
            % scene doesn't allow this configuration
            if ~isClusterLegal(cluster{c(j, 1)}, cluster{c(j, 2)}, X(i).detectedGroups)
                 continue;
             end
            
            cluster_temp = cell(1, n_clusters - 1);
            
            % create a new cluster setting...
            cluster_temp{1} = [cluster{c(j, 1)}, cluster{c(j, 2)}];
            k = 1;
            for l = 1 : n_clusters
                if l ~= c(j, 1) && l ~= c(j, 2)
                    k = k + 1;
                    cluster_temp{k} = cluster{l};
                end
            end
            
            % ... and evaluate it
            psi = zeros(1, size(X(i).myfeatures, 2));
            for k = 1 : size(cluster_temp, 2)
                mycouples = combnk(sort(cluster_temp{k}), 2);
                if size(mycouples, 1) > 0
                    for p = 1 : size(mycouples, 1)
                        psi = psi + X(i).myfeatures(X(i).couples(:, 1) == mycouples(p, 1) & X(i).couples(:, 2) == mycouples(p, 2), :);
                    end
                end
            end
            
            % save the results of this iteration so that we can access them
            % outside the parfor loop
            obj_score_temp(j) = dot(w, psi);
            obj_cluster_temp{j} = cluster_temp;
        end
        
        % find the max score and its index, so that we can go and get the
        % associated clustering
        [obj_score_temp, index] = max(obj_score_temp);
        
        % if the highest score clustering increases the current setting,
        % then allow the clusters to be merged, otherwise we'll stop this
        % iteration.
        if obj_score_temp > obj_score
            cluster = obj_cluster_temp(index);
            cluster = cluster{1};
            changed = true;
        end
        
        % update the number of clusters
        n_clusters = size(cluster, 2);
    end
    
    % add cluster scenario to the solution
    myY(i).mycluster = cluster;
    
    % accumulate error on the test set
    [delta, p, r] = lossGM(cluster, Y(i).mycluster);
    p_abs = p_abs + p;
    r_abs = r_abs + r; 
    error = error + delta;
    perf(i) = 2*p*r/(p+r);
end

fprintf('\n');

end