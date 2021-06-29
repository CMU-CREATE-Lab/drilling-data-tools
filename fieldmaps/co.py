"""
weirdly, CO's data doesn't seem to include well type.
Status codes: http://cogcc.state.co.us/documents/about/COGIS_Help/Status_Codes.pdf
"""

layout = {
	'api_field': 'API_Label',
	'date_field': 'Spud_Date',
	'description_layout': '\n'.join(['Operator %s', 'Well_Title %s']),
	'description_fields': ['Operator',   'Well_Title'],
	'lat_field': 'Latitude',
	'lon_field': 'Longitude',
	'status_field': 'Facil_Stat',
    'status_map': {
        'AC': 'ACTIVE',
        'SI': 'SI',
        'pa': 'PA',
        'AL': 'CANCELLED',
        'PA': 'PA',
        'CM': 'ACTIVE',
        'PR': 'ACTIVE',
        'DG': 'ACTIVE',
        'AB': 'A',
        'IJ': 'ACTIVE',
        'XX': 'PERMITTED',
        'TA': 'TA',
        'DA': 'A',
        'WO': 'ACTIVE',
        'DM': 'ACTIVE'
    },
 	'type_field': 'Facil_Stat',
    'type_map': {
        'AC': 'STORAGE',
        'SI': 'OILANDGAS',
        'pa': 'OILANDGAS',
        'AL': 'UNKNOWN',
        'PA': 'OILANDGAS',
        'CM': 'OILANDGAS',
        'PR': 'OILANDGAS',
        'DG': 'OILANDGAS',
        'AB': 'OILANDGAS',
        'IJ': 'INJECTION',
        'XX': 'OILANDGAS',
        'TA': 'OILANDGAS',
        'DA': 'DRY HOLE',
        'WO': 'OILANDGAS',
        'DM': 'GAS'
    }
 }