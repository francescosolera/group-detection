function out = loadPreTrained(trainMe, features, dataDirectory)
out = [];

% if train, do not load pretrained
if trainMe, return; end

% otherwise yes!
switch dataDirectory
    case 'mydata/university1'
        if isequal(features, [1 1 1 1]), out = [-0.0571164185399134;0.0152895915965976;-0.00500483032017289;-0.0268482806825264;-0.047857369021353;0.0245486411151579;0.00425421919838742;-0.017589231163966]; end
end



end