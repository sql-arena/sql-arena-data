-- Expected sessions of each day, for planning chunks
SELECT %%SF%% * sessions_on(d) * (1 + extra_support(d)) FROM range(%%DAYS%%) t(d) ORDER BY d;
