layout = {
    'date_field': ['SPUD DATE', 'FIRST COMPLETION DATE', 'FIRST PRODUCTION DATE'],
    'api_field': 'API NUMBER',
    'type_field': 'STANDARD WELL TYPE DESCRIPTION',
    'status_field': 'STANDARD WELL STATUS DESCRIPTION',
    'lat_field': 'WELLHEAD LATITUDE, DECIMAL DEGREES',
    'lon_field': 'WELLHEAD LONGITUDE, DECIMAL DEGREES',
    'description_layout': '\n'.join(['WELL NAME: %s',
                             'WELL NUMBER: %s',
                             'OPERATOR: %s',
                             'COUNTY: %s',
                             'FIELD NAME: %s'
                            ]),
    'description_fields': ['WELL NAME', 'WELL NUMBER', 'OPERATOR', 'COUNTY', 'FIELD NAME'],
    'type_map': {
        'Brine Supply': 'WATER',
        'Dry Hole': 'DRY HOLE',
        'Unassigned': 'UNKNOWN',
        'Coal Bed Methane': 'GAS',
        'Gas': 'GAS',
        'Gas Storage': 'STORAGE',
        'Other': 'OTHER',
        'Oil': 'OIL',
        'Observation Monitor Strat Test': 'TEST',
        'Oil and Gas': 'OILANDGAS',
        'Permit': 'UNKNOWN',
        'Unassigned': 'UNKNOWN',
        'Underground Injection Control:Class 2': 'INJECTION',
        'Underground Injection Control:Class 5': 'INJECTION',
        'Underground Injection Control:Class 2 Enhanced Recovery': 'INJECTION',
        'Underground Injection Control:Class 2 Disposal': 'DISPOSAL',
        'Unknown': 'UNKNOWN',
        'Water Supply': 'WATER',
    },
    'status_map': {
        'Active:Producing': 'ACTIVE',
        'Active': 'ACTIVE',
        'Active:Completed': 'ACTIVE',
        'Active:Dry Hole': 'ACTIVE',
        'Active:Injecting': 'ACTIVE',
        'Abandoned': 'A',
        'Abandoned:Plugged': 'PA',
        'Permit:Active': 'ACTIVE',
        'Permit:Cancelled Expired': 'CANCELLED',
        'Inactive:Temporarily Abandoned': 'TA',
        'Inactive:Shut In': 'SI',
        'Unknown': 'UNKNOWN',
        'Unassigned': 'UNKNOWN',
        'Unknown': 'UNKNOWN',
        'Abandoned:Dry Hole': 'A',
        'Inactive': 'TA',
    }
}
