function h = subplot_rc(m, n, r, c)

h1 = subplot(m, n, (r-1)*n + c);

if (nargout > 0)
    h = h1;
end