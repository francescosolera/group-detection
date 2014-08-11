function [legal] = isClusterLegal (cluster_1, cluster_2, detectedGroups)
% 1) check if there is only one group detected, if this is the case, then
% any two clusters are allowed to be merged.
if size(detectedGroups, 2) == 1
    legal = true;
    return;
end

% otherwise keep checking
legal = false;

% 2) check if every possible combination of elements form an existing couple
couples = cat(1, detectedGroups{:});
myCouples = combnk(unique(cat(1, cluster_1(:), cluster_2(:))), 2);

if ~sum(ismember(myCouples, couples, 'rows')) == size(myCouples, 1)
    return;
end

% 3) check if the groups are two singletons: if this is the case, since the
% couple exists, it will be legal
if size(cluster_1, 2) == 1 && size(cluster_2, 2) == 1
    legal = true;
    return;
end

% 4) otherwise at least one cluster will have more than one element in it.
% we want to be sure to choose that kind of cluster since it will surely
% give us the position of a couple inside a cluster that we want to fix as
% the correct one.
if size(cluster_1, 2) > 1
    for i = 1 : size(detectedGroups, 2)
        if ismember([cluster_1(1), cluster_1(2)], detectedGroups{i}, 'rows')
            index = i;
            break;
        end
    end
else
    for i = 1 : size(detectedGroups, 2)
        if ismember([cluster_2(1), cluster_2(2)], detectedGroups{i}, 'rows')
            index = i;
            break;
        end
    end
end

% 5) now that we have the index, we just have to check if every couple is
% in that detected group!
if sum(ismember(myCouples, detectedGroups{index}, 'rows')) == size(myCouples, 1)
    legal = true;
end

return