function psi = featureMap(x, y)
psi = zeros(1, size(x.myfeatures, 2));

% loop through each cluster
for i = 1 : size(y, 2)
    
    % consider all possible couples
    mycouples = combnk(sort(y{i}), 2);
    
    % now for each cluster compute a sum of the within similarity
    if size(mycouples, 1) > 0
        for j = 1 : size(mycouples, 1)
            psi = psi + x.myfeatures(x.couples(:, 1) == mycouples(j, 1) & x.couples(:, 2) == mycouples(j, 2), :);
        end
    end
end

% this is an approximated normalization
psi = psi / (size(x.members, 2)^2);
end