function [delta, p, r] = lossGM(y, ybar, ~, ~)
% create an association array for y and ybar:
% the position of the element in y gives him a uinque identifier
elements = [y{:}];

% create the UF data structures
UF_y = zeros(1, 2*length(elements));
UF_ybar = zeros(1, 2*length(elements));

for i = 1 : size(y, 2)
    for j = 1 : length(y{i})
        % find the index of the element and update its input in UF_y
        UF_y(elements == y{i}(j)) = i;
    end
end

for i = 1 : size(ybar, 2)
    for j = 1 : length(ybar{i})
        % find the index of the element and update its input in UF_y
        UF_ybar(elements == ybar{i}(j)) = i;
    end
end

% get the connected components in UF_y and UF_ybar
connected_y = unique(UF_y);
connected_ybar = unique(UF_ybar);

% take 0 away
connected_y(connected_y == 0) = [];
connected_ybar(connected_ybar == 0) = [];

% if we have singletons, we have to add a relationship with "themselfes"
for i = 1 : length(connected_y)
    if sum(UF_y == connected_y(i)) == 1
        UF_y(length(elements) + find(UF_y == connected_y(i))) = connected_y(i);
    end
end

for i = 1 : length(connected_ybar)
    if sum(UF_ybar == connected_ybar(i)) == 1
        UF_ybar(length(elements) + find(UF_ybar == connected_ybar(i))) = connected_ybar(i);
    end
end

% now we can apply the MITRE measure, first from y to ybar...
num = 0;
den = 0;
for i = 1 : length(connected_y)
    S = UF_y == connected_y(i);
    num = num + sum(S) - length(unique(UF_ybar(S)));
    den = den + sum(S) - 1;
end
R_y_ybar = num / den;
if isnan(R_y_ybar)
    R_y_ybar = 1;
end

% ... and then from ybar to y!
num = 0;
den = 0;
for i = 1 : length(connected_ybar)
    S = UF_ybar == connected_ybar(i);
    num = num + sum(S) - length(unique(UF_y(S)));
    den = den + sum(S) - 1;
end
R_ybar_y = num / den;
if isnan(R_ybar_y)
    R_ybar_y = 1;
end

F = 2 * R_y_ybar * R_ybar_y / (R_y_ybar + R_ybar_y);

p = R_ybar_y;
r = R_y_ybar;

if isnan(F)
    F = 0;
end

delta = 1 - F;

end