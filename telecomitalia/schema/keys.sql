ALTER TABLE telecomitalia.grid_mi ADD PRIMARY KEY (square_id);
ALTER TABLE telecomitalia.grid_tn ADD PRIMARY KEY (square_id);

ALTER TABLE telecomitalia.sms_call_internet_mi ADD FOREIGN KEY (square_id) REFERENCES telecomitalia.grid_mi (square_id);
ALTER TABLE telecomitalia.mi_to_mi ADD FOREIGN KEY (square_id_1) REFERENCES telecomitalia.grid_mi (square_id);
ALTER TABLE telecomitalia.mi_to_mi ADD FOREIGN KEY (square_id_2) REFERENCES telecomitalia.grid_mi (square_id);
ALTER TABLE telecomitalia.mi_to_provinces ADD FOREIGN KEY (square_id) REFERENCES telecomitalia.grid_mi (square_id);
ALTER TABLE telecomitalia.sms_call_internet_tn ADD FOREIGN KEY (square_id) REFERENCES telecomitalia.grid_tn (square_id);
ALTER TABLE telecomitalia.tn_to_tn ADD FOREIGN KEY (square_id_1) REFERENCES telecomitalia.grid_tn (square_id);
ALTER TABLE telecomitalia.tn_to_tn ADD FOREIGN KEY (square_id_2) REFERENCES telecomitalia.grid_tn (square_id);
ALTER TABLE telecomitalia.tn_to_provinces ADD FOREIGN KEY (square_id) REFERENCES telecomitalia.grid_tn (square_id);
