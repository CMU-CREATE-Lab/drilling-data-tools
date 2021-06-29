"""
Status: A code identifying current well status:

• A = Active (Well has been drilled and completed)
• B = Buried (Older well not abandoned to current standards; location of well is approximate)
• I = Idle (Well is idle, not producing, but capable of being reactivated)
• N = New (Recently permitted well; in the process of being drilled)
• P = Plugged & Abandoned (Well has been plugged and abandoned to current standards)
• U = Unknown (Well status not known; mostly older, pre-1976 wells)
Type: Code identifying well types:
• AI = Air Injector 
• DG = Dry Gas 
• GD = Gas Disposal 
• DH = Dry Hole
• GS = Gas Storage
• LG = Liquid Gas
• OB = Observation
• OG = Oil & Gas 
• PM = Pressure Maintenance 
• SC = Cyclic Steam 
• SF = Steam Flood 
• WD = Water Disposal 
• WF = Water Flood 
• WS = Water Source
# NOT SURE WHAT THE SRID IS
"""
layout = {
    'date_field': ['SpudDate', 'CompDate', 'AbdDate'],
    'api_field': 'API',
    'type_field': 'Type',
    'status_field': 'Status',
    'lat_field': 'Latitude',
    'lon_field': 'Longitude',
    'description_layout': '\n'.join(['LeaseName: %s',
                             'OpName: %s',
                             'URL: %s',
                             'Comments: %s',
                             'FieldName: %s'
                            ]),
    'description_fields': ['LeaseName', 'OpName', 'URL', 'Comments', 'FieldName'],
    'type_map': {
        'OTHER': 'UNKNOWN',
        'OG, SF, WD': 'OILANDGAS',
        'GS, OB, OG': 'STORAGE',
        'OB, SF, WF': 'OBSERVATION',
        'PM, WF': 'SERVICE',
        'OG, WS': 'OILANDGAS',
        'AI, OB': 'INJECTION',
        'OB, SC, SF': 'OBSERVATION',
        'OG, SC, WS': 'OILANDGAS',
        'DG': 'GAS',
        'OG': 'OILANDGAS',
        'OG, WD, WS': 'OILANDGAS',
        'GS, OG, PM': 'STORAGE',
        'DG, OB': 'GAS',
        'OG, WD': 'OILANDGAS',
        'WD': 'DISPOSAL',
        'WS': 'WATER',
        'PM, WD': 'SERVICE',
        'DG, GS': 'GAS',
        'OG, PM, WD': 'OILANDGAS',
        'WD, WS': 'DISPOSAL',
        'MW': 'UNKNOWN',
        'AI, OG, SC': 'OILANDGAS',
        'OB': 'OBSERVATION',
        'AI, WF': 'INJECTION',
        'AI, OG, WF': 'INJECTION',
        'SC': 'OTHER',
        'OB, SF, WD, WF': 'OBSERVATION',
        'GD': 'DISPOSAL',
        'OB, OG, WD': 'OBSERVATION',
        'OB, OG, WS': 'OBSERVATION',
        'OB, OG, WF': 'OBSERVATION',
        'DG, OG': 'GAS',
        'SF': 'OTHER',
        'DG, WS': 'GAS',
        'AI, SC, WD': 'INJECTION',
        'OG, WD, WF': 'OILANDGAS',
        'AI': 'INJECTION',
        'AI, SF, WF': 'INJECTION',
        'OG, SF, WF': 'OILANDGAS',
        'PM': 'SERVICE',
        'SC, WF': 'OTHER',
        'OB, WD': 'OBSERVATION',
        'SC, WD': 'OTHER',
        'OG, SC, SF, WD, WF': 'OILANDGAS',
        'OG, PM, SC': 'OILANDGAS',
        'OB, OG': 'OBSERVATION',
        'OG, SF': 'OILANDGAS',
        'OG, WF': 'OILANDGAS',
        'LG, OG': 'OTHER',
        'AI, OG, SC, WD': 'INJECTION',
        'WF': 'OTHER',
        'OB, OG, SC, WF': 'OBSERVATION',
        'AI, OG, SC, WF': 'INJECTION',
        'LG': 'OTHER',
        'OG, SC, WF': 'OILANDGAS',
        'OB, OG, SF, WF': 'OBSERVATION',
        'OB, OG, SC, SF': 'OBSERVATION',
        'PM, SF': 'OTHER',
        'GS': 'STORAGE',
        'OG, SC, SF': 'OILANDGAS',
        'DG, OG, WF': 'GAS',
        'AI, SC': 'INJECTION',
        'DG, PM': 'GAS',
        'WF, WS': 'OTHER',
        'OG, PM, WF': 'OILANDGAS',
        'OB, WF': 'OBSERVATION',
        'GS, OG, SC': 'OTHER',
        'AI, OG, SF, WF': 'INJECTION',
        'DG, GS, OG': 'GAS',
        'GD, OG, SC': 'OTHER',
        'DG, OB, WD': 'OTHER',
        'WD, WF': 'DISPOSAL',
        'GS, OG': 'STORAGE',
        'DG, WF': 'GAS',
        'SF, WF': 'OTHER',
        'GD, OG, PM, SC': 'OTHER',
        'SC, SF': 'OTHER',
        'OB, SF': 'OBSERVATION',
        'OG, SC': 'OILANDGAS',
        'AI, OG': 'INJECTION',
        'GD, WD': 'DISPOSAL',
        'GS, PM': 'STORAGE',
        'AI, SF': 'INJECTION',
        'OB, OG, SF': 'OBSERVATION',
        'AI, OG, SF': 'INJECTION',
        'OG, SC, WD': 'OILANDGAS',
        'SF, WD': 'OTHER',
        'GS, OG, WD': 'STORAGE',
        'OG, PM': 'OILANDGAS',
        'OB, SF, WD': 'OBSERVATION',
        'AI, OG, WS': 'INJECTION',
        'SF, WD, WF': 'OTHER',
        'OG, SC, SF, WF': 'OILANDGAS',
        'AI, WD': 'INJECTION',
        'OG, PM, SF': 'OILANDGAS',
        'OG, SF, WS': 'OILANDGAS',
        'OG, SC, SF, WD': 'OILANDGAS',
        'OG, WF, WS': 'OILANDGAS',
        'GD, OG, SF': 'OTHER',
        'OB, OG, SC': 'OBSERVATION',
        'DG, WD': 'GAS',
    },
    'status_map': {
        'I': 'SI',
        'P': 'PA',
        'B': 'ORPHAN',
        'N': 'PERMITTED',
        'A': 'ACTIVE',
        'U': 'UNKNOWN',
    },
}