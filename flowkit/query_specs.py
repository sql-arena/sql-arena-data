"""FlowAPI query specs rendered into the FlowKit query set, modelled on flowmachine's tests/test_query_object_construction.py.

"visited_most_days" is left out: flowmachine at this commit fails to render it (no spatial_unit).
Dates stay inside 2016-01-01 to 2016-01-07 so the queries also have data in a 7 day test run.
"""

DAY = "2016-01-01"
WEEK = ("2016-01-01", "2016-01-08")


def daily_location(date, unit="admin3", method="last", event_types=None):
    return {"query_kind": "daily_location", "date": date, "aggregation_unit": unit, "method": method,
            "event_types": event_types, "subscriber_subset": None}


def modal_location(dates, unit="admin3"):
    return {"query_kind": "modal_location", "locations": [daily_location(d, unit) for d in dates]}


def unique_locations(start, end, unit="admin3"):
    return {"query_kind": "unique_locations", "start_date": start, "end_date": end, "aggregation_unit": unit,
            "event_types": None, "subscriber_subset": None}


def joined(metric, locations=None, method="avg"):
    return {"query_kind": "joined_spatial_aggregate", "method": method,
            "locations": locations or modal_location(DAYS), "metric": metric}


def week(kind, **params):
    return {"query_kind": kind, "start_date": WEEK[0], "end_date": WEEK[1], "event_types": None,
            "subscriber_subset": None, **params}


def topups(kind, **params):
    return {"query_kind": kind, "start_date": WEEK[0], "end_date": WEEK[1], "subscriber_subset": None, **params}


DAYS = [f"2016-01-0{d}" for d in range(1, 8)]

SPECS = {
    "q01": {"query_kind": "spatial_aggregate", "locations": daily_location(DAY)},
    "q02": {"query_kind": "spatial_aggregate", "locations": daily_location("2016-01-03", "admin2", "most-common", ["calls", "sms"])},
    "q03": {"query_kind": "spatial_aggregate", "locations": modal_location(DAYS)},
    "q04": {"query_kind": "location_event_counts", "start_date": WEEK[0], "end_date": WEEK[1], "interval": "day",
            "aggregation_unit": "admin3", "direction": "both", "event_types": None, "subscriber_subset": None},
    "q05": {"query_kind": "location_event_counts", "start_date": DAY, "end_date": "2016-01-02", "interval": "hour",
            "aggregation_unit": "admin1", "direction": "out", "event_types": ["calls"], "subscriber_subset": None},
    "q06": {"query_kind": "unique_subscriber_counts", "start_date": WEEK[0], "end_date": WEEK[1], "aggregation_unit": "admin3",
            "event_types": None, "subscriber_subset": None},
    "q07": {"query_kind": "total_network_objects", "start_date": WEEK[0], "end_date": WEEK[1], "total_by": "day",
            "aggregation_unit": "admin2", "event_types": None, "subscriber_subset": None},
    "q08": {"query_kind": "aggregate_network_objects", "statistic": "avg", "aggregate_by": "day",
            "total_network_objects": {"query_kind": "total_network_objects", "start_date": WEEK[0], "end_date": WEEK[1],
                                      "total_by": "hour", "aggregation_unit": "admin3", "event_types": None,
                                      "subscriber_subset": None}},
    "q09": {"query_kind": "flows", "from_location": daily_location(DAY), "to_location": daily_location("2016-01-07"),
            "join_type": "inner"},
    "q10": {"query_kind": "flows", "from_location": daily_location(DAY),
            "to_location": unique_locations("2016-01-01", "2016-01-04"), "join_type": "left outer"},
    "q11": {"query_kind": "flows", "from_location": modal_location(DAYS[:3], "admin2"),
            "to_location": modal_location(DAYS[4:], "admin2"), "join_type": "full outer"},
    "q12": {"query_kind": "flows",
            "from_location": {"query_kind": "majority_location", "subscriber_location_weights": {
                "query_kind": "location_visits", "locations": [daily_location(d) for d in DAYS[:3]]}},
            "to_location": {"query_kind": "majority_location", "subscriber_location_weights": {
                "query_kind": "location_visits", "locations": [daily_location(d) for d in DAYS[4:]]}}},
    "q13": joined(week("radius_of_gyration")),
    "q14": joined(week("nocturnal_events", night_hours={"start_hour": 20, "end_hour": 4})),
    "q15": joined(week("subscriber_degree", direction="both")),
    "q16": joined(week("event_count", direction="both")),
    "q17": joined(week("unique_location_counts", aggregation_unit="admin3")),
    "q18": joined(week("pareto_interactions", proportion=0.8)),
    "q19": joined(week("handset", characteristic="hnd_type", method="most-common"), method="distr"),
    "q20": joined(topups("topup_amount", statistic="avg")),
    "q21": joined(topups("topup_balance", statistic="avg")),
    "q22": joined(week("displacement", statistic="avg", reference_location=modal_location(DAYS[:3], "lon-lat"))),
    "q23": joined({"query_kind": "total_active_periods", "start_date": WEEK[0], "total_periods": 7, "period_length": 1,
                   "period_unit": "days", "event_types": None, "subscriber_subset": None}),
    "q24": {"query_kind": "histogram_aggregate", "metric": week("radius_of_gyration"), "bins": {"n_bins": 20}},
    "q25": {"query_kind": "histogram_aggregate", "metric": week("event_count", direction="out"), "bins": {"n_bins": 10}},
    "q26": {"query_kind": "unique_visitor_counts",
            "active_at_reference_location_counts": {
                "query_kind": "active_at_reference_location_counts",
                "unique_locations": unique_locations(*WEEK),
                "reference_locations": modal_location(DAYS[:3])},
            "unique_subscriber_counts": {"query_kind": "unique_subscriber_counts", "start_date": WEEK[0],
                                         "end_date": WEEK[1], "aggregation_unit": "admin3", "event_types": None,
                                         "subscriber_subset": None}},
    "q27": {"query_kind": "unmoving_counts", "locations": unique_locations(*WEEK)},
    "q28": {"query_kind": "unmoving_at_reference_location_counts", "locations": unique_locations(*WEEK),
            "reference_locations": modal_location(DAYS[:3])},
    "q29": {"query_kind": "trips_od_matrix", "start_date": WEEK[0], "end_date": WEEK[1], "aggregation_unit": "admin3",
            "event_types": None, "subscriber_subset": None},
    "q30": {"query_kind": "consecutive_trips_od_matrix", "start_date": WEEK[0], "end_date": WEEK[1],
            "aggregation_unit": "admin2", "event_types": None, "subscriber_subset": None},
    "q31": {"query_kind": "location_introversion", "start_date": WEEK[0], "end_date": WEEK[1], "aggregation_unit": "admin3",
            "direction": "both"},
    "q32": {"query_kind": "spatial_aggregate", "locations": {
        "query_kind": "most_frequent_location", "start_date": WEEK[0], "end_date": WEEK[1], "aggregation_unit": "admin3",
        "event_types": None, "subscriber_subset": None}},
}
