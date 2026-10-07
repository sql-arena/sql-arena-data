CREATE TABLE publicbi."Euro2016_1" (
    "Number of Records" INT NOT NULL,
    id INT NOT NULL,
    lang VARCHAR NOT NULL,
    latitude VARCHAR NULL,
    longitude VARCHAR NULL,
    polarity VARCHAR NULL,
    polarity_confidence DECIMAL(16,15) NULL,
    subjectivity VARCHAR NULL,
    subjectivity_confidence DECIMAL(16,15) NULL,
    tweet VARCHAR NOT NULL,
    tweeted_at TIMESTAMP NULL
);
