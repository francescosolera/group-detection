function H = HValue(model, callbacks, parameters, xi, yi, ybar)
deltapsi = callbacks.featureFn(xi, yi) - callbacks.featureFn(xi, ybar);
H = callbacks.lossFn(yi, ybar, callbacks, parameters) - dot(model.w, deltapsi);
end