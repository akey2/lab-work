% Performs Naive Bayes classification:
%   - distribution parameters estimated from training sample
%
% Inputs:
% Xtrain  - training sample predictors (size: nxd)
% ytrain  - training sample labels  (size: nx1)
% Xtest   - testing sample predictors (size: mxd)
% (optional) dist - probability distribution ('norm' [default], 'poiss')
%
% Outputs:
% yhat    - estimated testing sample labels (size: mx1)
%
% Written by Zach Irwin for the Chestek Lab, 2013
%   - Last edited: 10/15/2013 by Zach Irwin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [yhat] = NBClassify(Xtrain, ytrain, Xtest, varargin)

    % Handle optional input - specify probability distribution:
    switch (nargin)
        case 3      %default - no input
            
            % Normal distribution
            probfun = @(x, m, v) ((1./sqrt(2*pi*repmat(v,size(x,1)))).*exp(-.5*((x-repmat(m,size(x,1))).^2)./repmat(v,size(x,1))));
            
        case 4      %specified distribution
            
            if (ischar(varargin{1}) && strcmp(varargin{1}, 'norm'))
                % Normal distribution
                probfun = @(x, m, v) ((1./sqrt(2*pi*repmat(v,size(x,1),1))).*exp(-.5*((x-repmat(m,size(x,1),1)).^2)./repmat(v,size(x,1),1))); 
            elseif (ischar(varargin{1}) && strcmp(varargin{1}, 'poiss'))
                %Poisson distribution
                probfun = @(x, m, v) ((repmat(m,size(x,1)).^x).*exp(-repmat(m,size(x,1)))./factorial(x));               
            end
            
        otherwise   %unexpected
            
            error('There is only one optional input.');
    end
    
    % Estimate parameters, calculate log-likelihood for each class:
    labels = unique(ytrain); loglike = zeros(size(Xtest,1),length(labels));
    for i = 1:length(labels)

        % Estimate parameters:
        m = mean(Xtrain(ytrain == labels(i), :), 1);      % predictor means for ith class
        v = var(Xtrain(ytrain == labels(i), :), 0, 1);    % predictor variances for ith class
        
        % Calculate log-likelihood:
        loglike(:,i) = sum(log(probfun(Xtest, m, v+1e-5)), 2);
        
    end
    
    % Choose label which maximizes the log-likelihood:
    [~, maxidx] = max(loglike, [], 2);
    yhat = labels(maxidx);

end
    
    
    
    
    