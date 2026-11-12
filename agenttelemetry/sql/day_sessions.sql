-- Sessions of each day, as traces.sql numbers them
SELECT round(round(%%SF%% * sessions_on(d))::BIGINT * (1 + extra_support(d)))::BIGINT FROM range(%%DAYS%%) t(d) ORDER BY d;
