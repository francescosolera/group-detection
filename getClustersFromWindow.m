function clusters = getClustersFromWindow(pedestrians, dataDirectory)
clusters = {};
fid = fopen([dataDirectory, '/clusters.txt']);

tline = fgetl(fid);
while ischar(tline)
    myCluster = str2num(tline);
    % now we have to check if every element of this group shows up in
    % the current window.
    clusters = [clusters, myCluster(ismember(myCluster, pedestrians))];
    
    tline = fgetl(fid);
end
fclose(fid);
end