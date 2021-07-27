function [y, yhat] = KalmanFilter(X, y, ncv, zflag)

if (nargin < 4 || isempty(zflag))
    zflag = false;
end

if (size(X,2) < size(X,1))
    X = X';
end

tflagy = false;
if (size(y,2) < size(y,1))
    y = y';
    tflagy = true;
end

idx = all(~isnan(y),1) & all(~isnan(X),1);
X = X(:,idx);
y = y(:,idx);

% set up cross-validation:
cvseg = ceil(size(X,2)/ncv);
yhat = zeros(size(y));
for i = 1:ncv
    
    testidx = (i-1)*cvseg+1:min([i*cvseg, size(X, 2)]);
    trainidx = setdiff(1:size(X,2), testidx);
    
    % train parameters:
    Ntrain = length(trainidx);
    ytrain = y(:,trainidx);
    
    if (zflag)
        mux = mean(X(:,trainidx), 2);
        sdx = std(X(:,trainidx), [], 2);
    else
        mux = zeros(size(X,1),1);
        sdx = ones(size(mux));
    end
    Xtrain = (X(:,trainidx) - mux)./sdx;
    
    
    A = ytrain(:,2:end)*ytrain(:,1:end-1)'/(ytrain(:,1:end-1)*ytrain(:,1:end-1)');
    C = Xtrain*ytrain'/(ytrain*ytrain');
    
    W = (1/(Ntrain-1))*(ytrain(:,2:end) - A*ytrain(:,1:end-1))*(ytrain(:,2:end) - A*ytrain(:,1:end-1))';
    Q = (1/Ntrain)*(Xtrain - C*ytrain)*(Xtrain - C*ytrain)';
    
    yhat(:,testidx(1)) = y(:,testidx(1));  
    P = W;
    for j = 2:length(testidx)
        
        yhat(:,testidx(j)) = A*yhat(:,testidx(j-1));
        
        P = A*P*A' + W;
        K = P*C'/(C*P*C' + Q);
        
       yhat(:,testidx(j)) = yhat(:,testidx(j)) + ...
           K*((X(:,testidx(j))-mux)./sdx - C*yhat(:,testidx(j)));
        
        P = (eye(size(P)) - K*C)*P;
    end
end


if (tflagy)
    yhat = yhat';
    y = y';
end