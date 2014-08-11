function delta = loss01(y, ybar)
%% INITIALIZE THE PROCEDURE
% retrieve the elements from the clustering
x = sort([y{:}]);
% prepare all possible combination
c = combnk(x, 2);

%% MEASURE DISSIMILARITY
% now count on how many couples y and ybar disagree
delta = 0;

for i = 1 : size(c, 1)
    found_y = 1;
    found_ybar = 1;
    for j = 1 : size(y, 2)
        if sum(ismember(c(i, :), y{j})) == 1
            found_y = -1;
            break;
        end
    end

    for j = 1 : size(ybar, 2)
        if sum(ismember(c(i, :), ybar{j})) == 1
            found_ybar = -1;
            break;
        end
    end

    if found_y * found_ybar < 0
        delta = 1;
        break;
    end
end

end