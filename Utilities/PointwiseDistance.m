% Calculate distance between each pair of 2 groups of points.
%
% X = n x d (n points, d dimensions)
% Y = m x d (m points, d dimensions)
%
% D = n x m (n points x m points)
%   * each row is the distance between the corresponding X point and all Y points.
%

function D = PointwiseDistance(X, Y)

D = zeros(size(X,1), size(Y,1));
for i = 1:size(D,1)
    D(i,:) = sqrt(sum((X(i,:) - Y).^2,2))';
end