function [simil] = prox(time_t, time_r, t, r)
% find common elements
int = intersect(time_t, time_r);

if size(int, 2) == 0
    simil = 0;
else
    % find indexes
    int_t = ismember(time_t, int);
    int_r = ismember(time_r, int);
    
    P_t = t(:, int_t);
    P_r = r(:, int_r);
    
    % find euclidean distance
    ed = sum(exp(-sum((P_t - P_r).^2, 1).^0.5));
    
    % now i can adjust the proxemics adding information about common pts
    simil = ed / max(size(time_t, 2), size(time_r, 2));

end
end