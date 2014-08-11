function [ model, w_final ] = trainFW( X, Y )

model = [];
w_final = [];

% check for training
if size(X, 2) == 0, return; end

patterns = cell(1, size(X, 2));
labels = cell(1, size(X, 2));
for i=1:size(X, 2)
    patterns{i} = struct;
    patterns{i} = X(i);
    labels{i} = Y(i).mycluster;
end

parameters.C = 10;                    % regularization parameter
parameters.maxIter = 300;             % maximum number of iterations

augVars.detectedGroups = {X.detectedGroups};
augVars.F = {X.F};

callbacks.lossStandardFn = @lossGM;
callbacks.constraintFn = @constraintFind;
callbacks.featureFn = @featureMap;

% NOTEQUALFN:
% this function can be used to check whether two cluster are the same. More
% precisely the two clusters contain the same elements iff this function
% returns 0, otherwise they are somehow different.
% p.s. @loss01 will do the job!
callbacks.notEqualFn = @loss01;

% HFN
% this function returns the value of a particular violated constraint given
% as input. Since CONSTRAINTFN returns the constraint but not the value, it
% is useful to have a function that just does that.
callbacks.HFn = @HValue;

% LOSSPAR
% this function provides an interface for the the standard loss function to
% access global variables in parfor loops, where not all the workers
% actually have the same synchronized values of those global variables.
% This doesn't need to be changed...
callbacks.lossParFn = @lossGM;

% LOSS
% this function can be viewed as an interface to manage the combination of
% the normal loss function and the shape based loss. It doesn't need to be
% changed since it accept as a parameter the callback to the standard loss
% function (the one used in the QP)
callbacks.lossFn = @lossGM;

n = size(X, 2);
n_it = parameters.maxIter;

% initialize variables
w = zeros(size(patterns{1}.myfeatures, 2), 1);
w_i = zeros(size(patterns{1}.myfeatures, 2), n);
l = 0;
l_i = zeros(1, n);

lambda = 1 / parameters.C;

w_final = zeros(size(X(1).myfeatures, 2), 1);

for k = 1 : n_it
    % pick a block at random
    i = ceil(rand*n);
    
    % solve the oracle
    model.w = w;
    y_star = constraintFind(model, callbacks, parameters, augVars.detectedGroups{i}, patterns{i}, labels{i});
    
    % find the new best value of the variable
    w_s = 1/lambda/n*(callbacks.featureFn(patterns{i}, labels{i}) - callbacks.featureFn(patterns{i}, y_star))';
    
    % also compute the loss at the new point
    l_s = 1/n*callbacks.lossFn(labels{i}, y_star, callbacks, parameters);
    
    % compute the step size
    step_size = min(max((lambda*(w_i(:, i)-w_s)'*w - l_i(i) + l_s) / lambda / ...
        ((w_i(:, i)-w_s)'*(w_i(:, i)-w_s)), 0), 1);
    
    % evaluate w_i and l_i
    w_i_new = (1 - step_size) * w_i(:, i) + step_size * w_s;
    l_i_new = (1 - step_size) * l_i(i) + step_size * l_s;
    
    % update w and l
    w = w + w_i_new - w_i(:, i);
    l = l + l_i_new - l_i(i);
    
    % update w_i and l_i
    w_i(:, i) = w_i_new;
    l_i(i) = l_i_new;
    
    % slowing update should lead to faster convergence
    w = k/(k+2) * model.w + 2/(k+2) * w;
    
    fprintf('%d: %s\n', k, mat2str(w));
    
    w_final = [w_final, w];
    figure(2);
    clf;
    plot(w_final');
    title(['Convergence at ' num2str(k) '-th iteration']);
end
fprintf('\n');

model.w = w;

end

