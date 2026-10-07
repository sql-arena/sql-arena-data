-- rowid breaks ties, so a rerun sorts identically and resumed parts line up
CREATE OR REPLACE TEMP TABLE _sorted AS
SELECT * FROM %%SOURCE%% ORDER BY %%ORDER_BY%%, rowid;
