"""
From http://www.ogb.state.al.us/ogb/database.aspx:
Well Status Descriptions
AB - Abandoned, AC - Active, CA - Canceled, CI - Canceled with Injection, CV - Converted, DA - Dry and Abandoned, 
PA - Plugged and Abandoned,PB - Plugged Back, PR - Producing, PW - Permitted Well, RJ - Released Jurisdiction
SI - Shut In, TA - Temporarily Abandoned, TP - Temporarily Plugged and Abandoned,UN - Undesignated


Well Type Descriptions, CM - Coal Bed Methane, GAS - Natural Gas, GC - Gas Condensate, 
GI - Gas Injection, GST - Gas Storage, OIL - Oil, SHG - Shale Gas, 
SWD - Salt Water Disposal, UN - Undesignated, WI - Water Injection, WS - Water Source, 
WW - Water Well
"""

layout = {
    'date_field': 'WEBOGBSDE.DBO.WebWell_Prj.SpudDate',
    'api_field': ['WEBOGBSDE.DBO.BottomHoleLocations.APINumber', 'WEBOGBSDE.DBO.WebWell_Prj.API'],
    'type_field': 'WEBOGBSDE.DBO.WebWell_Prj.WellType',
    'category_field': 'WEBOGBSDE.DBO.WebWell_Prj.WellType',
    'status_field': 'WEBOGBSDE.DBO.WebWell_Prj.WellStatus',
    'lat_field': 'WEBOGBSDE.DBO.WebWell_Prj.Latitude',
    'lon_field': 'WEBOGBSDE.DBO.WebWell_Prj.Longitude',
    'source_well_id': 'WEBOGBSDE.DBO.WebWell_Prj.Permit',
    'description_layout': '\n'.join(['Permit Num: %s',
                             'Well Name: %s',
                             'Operator: %s'
                             ]),
    'description_fields': ['WEBOGBSDE.DBO.WebWell_Prj.Permit', 'WEBOGBSDE.DBO.WebWell_Prj.HistoricWellName', 
                           'WEBOGBSDE.DBO.WebWell_Prj.Operator'],
    'type_map': {        'OIL': 'OIL',        'GST': 'STORAGE',        'CM': 'GAS',        'GAS': 'GAS',
        'SWD': 'DISPOSAL',        'WI': 'INJECTION',        'WW': 'WATER',        'UN': 'OTHER',
        'GC': 'GAS',        'SHG': 'GAS',        'WS': 'WATER',        'GI': 'INJECTION',
    },
    'status_map': {
        'PR': 'ACTIVE',        'PA': 'PA',        'AC': 'ACTIVE',        'AB': 'PA',        'PW': 'PERMITTED',
        'PP': 'UNKNOWN',        'CA': 'CANCELLED',        'CI': 'CANCELLED',        'DA': 'PA',
        'PB': 'PA',        'SI': 'PA',        'UN': 'UNKNOWN',        'CV': 'UNKNOWN',
        'RJ': 'UNKNOWN',        'TA': 'TA', 
    },
    'category_map': {
        'OIL': 'CONVENTIONAL',        'GST': 'STORAGE',        'CM': 'CBM',        'GAS': 'CONVENTIONAL',
        'SWD': 'OTHER',        'WI': 'UNCONVENTIONAL',        'WW': 'OTHER',        'UN': 'OTHER',
        'GC': 'CONVENTIONAL',        'SHG': 'UNCONVENTIONAL',        'WS': 'WATER',        'GI': 'UNCONVENTIONAL',
        'GS': 'CONVENTIONAL'
    }
}
