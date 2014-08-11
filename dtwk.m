function [dist, k] = dtwk(t, r)
    % Dynamic Time Warping Algorithm
    % Dist is unnormalized distance between t and r
    % D is the accumulated distance matrix
    % k is the normalizing factor
    % w is the optimal path
    % t is the vector you are testing against
    % r is the vector you are testing
    % The orinal code by:
    % T. Felty (2005). Dynamic Time Warping [Computer program]. Available
    % at http:// www.mathworks.com/matlabcentral/fileexchange/6516-...
    % dynamic-time-warping (Retrieved 1 March 2012)
    % Modified by Parinya Sanguansat
    
    [~, N] = size(t);
    [rows, M] = size(r);
    
    d = 0;
    for i = 1 : rows
        tt = t(i,:);
        rr = r(i,:);
       
        % I DON'T WANT TO NORMALIZE - 1 CM HAS THE SAME MEANING WHETER WE
        % ARE TALKING ABOUT METERS OR KILOMETERS
        tt = (tt-mean(tt))/(std(tt)+eps);
        rr = (rr-mean(rr))/(std(rr)+eps);
        d = d + (repmat(tt(:),1,M) - repmat(rr(:)',N,1)).^2;
    end
    
    % make the distance euclidean
    d = d.^0.5;
    
    D = zeros(size(d));
    D(1, 1) = d(1, 1);
    
    for n = 2 : N
        D(n, 1) = d(n, 1) + D(n - 1, 1);
    end
    
    for m = 2 : M
        D(1, m) = d(1, m) + D(1, m - 1);
    end
    
    for n = 2 : N
        for m = 2 : M
            D(n, m) = d(n, m) + min([D(n - 1, m), D(n - 1,m - 1), D(n,m - 1)]);
        end
    end
    
    dist = D(N, M);
    
    % reconstruct the path, so that we can gain information about the
    % minimum number of steps needed to minimize the distance, and thus
    % have a normalization coefficient
    n = N;
    m = M;
    k = 1;
    while ((n + m) ~= 2)
        if (n - 1) == 0
            m = m - 1;
        elseif (m - 1) == 0
            n = n - 1;
        else 
            [~, number] = min([D(n - 1, m), D(n, m - 1), D(n - 1, m - 1)]);
            switch number
                case 1
                    n = n - 1;
                case 2
                    m = m - 1;
                case 3
                    n = n - 1;
                    m = m - 1;
            end
        end
        
        k = k + 1;
    end
end