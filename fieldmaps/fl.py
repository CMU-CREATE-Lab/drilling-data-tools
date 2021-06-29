"""
I could do some extra processing on the "text" columns to separate out
oil and gas wells from others, but not going to at this time.
"""

layout = {
    'date_field': ['SPUD_DATE', 'COMPLETION_DATE', 'PLUGDATE'],
    'api_field': 'API_NO',
    'status_field': 'CURRENT_STATUS',
    'status_map': {
        'Injector': 'ACTIVE',
        'Plugged & Abandoned': 'PA',
        'Producer': 'ACTIVE',
        'Never Drilled': 'CANCELLED',
        'Temporarily Abandoned': 'TA',
        'Saltwater Disposal': 'ACTIVE',
        'Junked': 'A',
        'Dry Hole': 'A',
    },
    'type_field': 'CURRENT_STATUS',
    'type_map': {
        'Injector': 'INJECTION',
        'Plugged & Abandoned': 'OILANDGAS',
        'Producer': 'OILANDGAS',
        'Never Drilled': 'OTHER',
        'Temporarily Abandoned': 'OILANDGAS',
        'Saltwater Disposal': 'DISPOSAL',
        'Junked': 'DRY HOLE',
        'Dry Hole': 'DRY HOLE',
    },
    'lat_field': 'y',
    'lon_field': 'x',
}