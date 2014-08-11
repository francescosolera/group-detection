function F = granger(X, Y, d)

% now we need to align them
% find common elements
int = intersect(X(:, 1), Y(:, 1));

if size(int, 1) == 0
    F = 0;
else
    % find indexes
    int_X = ismember(X(:, 1), int);
    int_Y = ismember(Y(:, 1), int);
    
    % keep only the common frames and get rid of the frame number
    X = X(int_X, 2:end);
    Y = Y(int_Y, 2:end);
    
    % number of features
    n = size(X, 2);
    
    % get the length of the shortest series
    length = min(size(X, 1));
    
    % before doing anything we want to de-mean them
    X = X - repmat(mean(X), length, 1);
    Y = Y - repmat(mean(Y), length, 1);
    
    % do we need to normalize them
    X = X ./ repmat(max(abs(X)), length, 1);
    Y = Y ./ repmat(max(abs(Y)), length, 1);
    
    % let's apply a median filter
    for i = 1 : n
        X(:, i) = medfilt1(X(:, i), 7);
        Y(:, i) = medfilt1(Y(:, i), 7);
    end
    
    % now check that the degree of complexity of the model is fine with the
    % lengths of our observations
    if (d > length - 1)
        d = length - 1;
    end
    
    % we'll compute the weights of the linear regression based on the first
    % d samples, and then repeat this process for m times. As a matter of
    % fact, since we cannot state our process variance is stationary, we'll
    % have to compute some kind of average to be able to obtain a reliable
    % result.
    m = length - d;
    
    % prepare the error matrix: one row for each prediction, the first
    % column is for the autonomous prediction, the second column is for the
    % joint prediction of X- and Y- on X
    
    % we know we can express our multivariate regression as a linear
    % system AX_ = B, where A is the horizontal concatenation of
    % matrices of the coefficients from all the lagged terms, X_ is the
    % vertical concatenation of all training lagged observation and
    % horizontal concatenation of different training for different
    % predictions while B are terms that has to be predicted (by column)
    
    e = struct;
    
    % B has n rows (one for each variable that has to be predicted) and m
    % columns (one for each prediction that has to be made)
    B = zeros(n, m);
    for i = 1 : m
        B(:, i) = X(i+d, :)';
    end
    
    % let us first consider the autonomous prediction
    X_ = zeros(n*d, m);
    for i = 1 : m
        temp = X(i:i+d-1, :)';
        X_(:, i) = temp(:);
    end
    
    % solve the system
    A = mrdivide(B, X_);
    
    % for each prediction, compute the error
    for i = 1 : m
        e(i).x = B(:, i) - A*X_(:, i);
    end
    
    % now consider the joint prediction X- and Y- on X
    % so B doesn't change, but at X must be added the values of Y-
    X_ = zeros(n*d*2, m);
    for i = 1 : m
        temp = [X(i:i+d-1, :); Y(i:i+d-1, :)]';
        X_(:, i) = temp(:);
    end
    
    % solve the system
    A = mrdivide(B, X_);
    
    % for each prediction, compute the error
    for i = 1 : m
        e(i).xy = B(:, i) - A*X_(:, i);
    end
    
    % we know that an estimate for the residuals covariance matrix is then
    % obtained as the unbiased sample covariance of the residual errors
    S_x = zeros(n, n);
    S_xy = zeros(n, n);
    for i = 1 : m
        S_x     = S_x   +   e(i).x  * e(i).x'  / (m-1);
        S_xy    = S_xy  +   e(i).xy * e(i).xy' / (m-1);
    end
    
    % compute the absolute G-causality of Y on X
    F = abs(log(det(S_x)/det(S_xy)));
    
    % just check if it's ok
    if isnan(F)
        F = 0;
    else if isinf(F)
            F = 100;
        end
    end
end
end