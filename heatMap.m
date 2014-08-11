function [map, S] = heatMap(X, Y, video_parameters)

% units of measurements
m = 1; cm = m / 100;

% parameters
C = 1;
k_p = 0.5;
k_t = 0.000001;

cellSide = 30 * cm;

numberOfCellForSide(1) = floor((video_parameters.xMax - video_parameters.xMin) / cellSide);
numberOfCellForSide(2) = floor((video_parameters.yMax - video_parameters.yMin) / cellSide);

% matrices for X
heat_X = zeros(numberOfCellForSide(2), numberOfCellForSide(1));
H_X = heat_X;
gridStart_X = ones(numberOfCellForSide(2), numberOfCellForSide(1)) * Inf/Inf;
gridEnd_X = gridStart_X;

% matrices for Y
heat_Y = zeros(numberOfCellForSide(2), numberOfCellForSide(1));
H_Y = heat_Y;
gridStart_Y = ones(numberOfCellForSide(2), numberOfCellForSide(1)) * Inf/Inf;
gridEnd_Y = gridStart_Y;

% define the length of the analysis
frame_start = min(X(1, 1), Y(1, 1));
frame_end = max(X(end, 1), Y(end, 1));

for i = frame_start : video_parameters.downsampling : frame_end
    % trace the path of the trajectory of X
    [~, loc] = ismember(i, X(:, 1));
    if loc ~= 0
        grid_x = min(max(floor(X(loc, 2) / cellSide), 1), numberOfCellForSide(1));
        grid_y = min(max(floor(X(loc, 3) / cellSide), 1), numberOfCellForSide(2));
        if isnan(gridStart_X(end - grid_y + 1, grid_x))
            gridStart_X(grid_y, grid_x) = i;
            gridEnd_X(grid_y, grid_x) = i;
        else
            gridEnd_X(grid_y, grid_x) = i;
        end
    end
    
    % ... and Y
    [~, loc] = ismember(i, Y(:, 1));
    if loc ~= 0
        grid_x = min(max(floor(Y(loc, 2) / cellSide), 1), numberOfCellForSide(1));
        grid_y = min(max(floor(Y(loc, 3) / cellSide), 1), numberOfCellForSide(2));
        if isnan(gridStart_Y(end - grid_y + 1, grid_x))
            gridStart_Y(grid_y, grid_x) = i;
            gridEnd_Y(grid_y, grid_x) = i;
        else
            gridEnd_Y(grid_y, grid_x) = i;
        end
    end
end

for i = 1 : size(heat_X, 1)
    for j = 1 : size(heat_X, 2)
        % compute the accumulated thermal energy for the trajectory on this
        % particular patch for X
        if ~isnan(gridStart_X(i, j))
            Ebar = C / k_t * (1 - exp(-k_t * (gridEnd_X(i, j) - gridStart_X(i, j) + 1) / video_parameters.downsampling));
            heat_X(i, j) = Ebar * exp(-k_t * (frame_end - gridEnd_X(i, j) + 1) / video_parameters.downsampling);
        end
        % ... and Y
        if ~isnan(gridStart_Y(i, j))
            Ebar = C / k_t * (1 - exp(-k_t * (gridEnd_Y(i, j) - gridStart_Y(i, j) + 1) / video_parameters.downsampling));
            heat_Y(i, j) = Ebar * exp(-k_t * (frame_end - gridEnd_Y(i, j) + 1) / video_parameters.downsampling);
        end
    end
end

% interesting patches
z_X = heat_X~=0;
N_X = sum(sum(z_X));
z_Y = heat_Y~=0;
N_Y = sum(sum(z_Y));

for i = 1 : size(heat_X, 1)
    for j = 1 : size(heat_X, 2)
        % now compute the diffusion for X
        for m = 1 : size(z_X, 1)
            for n = 1 : size(z_X, 2)
                if z_X(m, n) == 1
                    dist = sqrt((i - m)^2 + (j - n)^2);
                    H_X(i, j) = H_X(i, j) + heat_X(m, n) * exp(-k_p * dist);
                end
            end
        end
        
        % ... and Y
        for m = 1 : size(z_Y, 1)
            for n = 1 : size(z_Y, 2)
                if z_Y(m, n) == 1
                    dist = sqrt((i - m)^2 + (j - n)^2);
                    H_Y(i, j) = H_Y(i, j) + heat_Y(m, n) * exp(-k_p * dist);
                end
            end
        end
    end
end

H_X = H_X / N_X;
sum_x = sum(sum(H_X));

H_Y = H_Y / N_Y;
sum_y = sum(sum(H_Y));

H = H_X .* H_Y;
sum_H = sum(sum(H));

map = H;
S = sum_H / min(sum_x, sum_y);

% check for legal output
if isnan(S), S = 0; end

end