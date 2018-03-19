import os, errno, array, csv, math, re
from datetime import datetime
import dateutil.parser
import db_settings
import psycopg2
import pprint

"""
date_field and api_field will take a string or a list of field names, evaluated
in the order listed
category_field and category_map optional, but must either both be specified for neither
    'category_field': '',
    'category_map': '',
    'description_layout': '\n'.join(['Descriptor1: %s',
                             'Descriptor2: %s',
                             'Descriptor3: %s',
                             'Descriptor4: %s',
                             'Descriptor5: %s'
                            ]),
        'description_fields': ['DescCol1', 'DescCol2', 'DescCol3', 'DescCol4', 'DescCol5'],
"""
layout_template = {
    'api_field': '',
    'date_field': '',
    'lat_field': '',
    'lon_field': '',
    'status_field': '',
    'status_map': None,
    'type_field': '',
    'type_map': None,
}

def map_template(map_type, values):
    if map_type == 'type':
        t = 'type_map'
        s = well_types
    elif map_type == 'status':
        t = 'status_map'
        s = well_statuses
    elif map_type == 'category':
        t = 'category_map'
        s = well_categories

    print ('valid options:', s)
    print ("    '%s': {" % t)
    for item in sorted(values):
        if item:
            print ("        '" + item + "': '" + (item.upper() if item.upper() in s else '') + "',")
    print ("    },")
    
state_apis = {'WA': '46', 'DE': '07', 'DC': '08', 'WI': '48', 'WV': '47', 'HI': '51', 'FL': '09', 'WY': '49', 
              'NH': '28', 'NJ': '29', 'NM': '30', 'TX': '42', 'LA': '17', 'AK': '50', 'NC': '32', 'ND': '33', 
              'NE': '26', 'TN': '41', 'NY': '31', 'NorthernGulfofMexico': '60', 'PA': '37', 'RI': '38', 
              'NV': '27', 'VA': '45', 'CO': '05', 'CA': '04', 'PacificCoastOffshore': '56', 'AL': '01', 
              'AlaskaOffshore': '55', 'AR': '03', 'VT': '44', 'IL': '12', 'GA': '10', 'IN': '13', 'IA': '14', 
              'OK': '35', 'AZ': '02', 'ID': '11', 'CT': '06', 'ME': '18', 'MD': '19', 'MA': '20', 'OH': '34', 
              'UT': '43', 'MO': '24', 'MN': '22', 'MI': '21', 'KS': '15', 'MT': '25', 'AtlanticCoastOffshore': '61', 
              'MS': '23', 'SC': '39', 'KY': '16', 'OR': '36', 'SD': '40'}

well_types = {'OIL',
    'GAS',
    'OILANDGAS',
    'INJECTION',
    'STORAGE',
    'DISPOSAL',
    'SERVICE',
    'DRY HOLE',
    'OBSERVATION',
    'TEST',
    'WATER',
    'OTHER',
    'UNKNOWN'}
well_statuses = {'ACTIVE', 'A', 'PA', 'TA', 'SI', 'DRY', 'ORPHAN', 'PERMITTED', 'CANCELLED', 'UNKNOWN'} # PA: plugged and abandoned, TA: temporarily abandoned
well_categories = {'CONVENTIONAL','UNCONVENTIONAL','FRAC','CBM','SERVICE','TEST','STORAGE','WATER','OTHER','UNKNOWN'}

class State(object):
    def __init__(self, state, **kwargs):
        # if prepend_api = True, state api will be prepended to apis in data
        # filename (assumes file in csvs directory)

        self.name = state
        self.data = None
        self.source_url = None
        self.description = None
        self.download_directory = os.path.abspath('downloads/' + self.name).lower()
        self.projection = 4326 # WGS84 by default, but can be overridden

        for key, value in kwargs.items(): # used to pass in custom functions
            setattr(self, key, value)
        
        if 'filename' in kwargs:
            self.filename = 'csvs/' + kwargs['filename']
        else:
            self.filename = 'csvs/' + self.name.lower() + '-' + 'data' + '.csv'

        if 'webdate' in kwargs and kwargs['webdate'] == True:
            self.date_function = lambda x: datetime.fromtimestamp(int(float(x))/1000)

        self.load_data()

    def __repr__(self):
        return self.name

    def load_data(self):
        try:
            with open(self.filename, 'r') as f:
                reader = csv.DictReader(f)
                self.data = [row for row in reader]
            if hasattr(self, 'strip_whitespace'):
                self.strip_ws()
        except IOError as e:
            raise IOError("Error in state.load_csv loading data. Verify that " + filename + ' exists and try again. ' + e)
    
    def strip_ws(self):
        for i, row in enumerate(self.data):
            row = self.data[i]
            for key in self.strip_whitespace:
                row[key] = row[key].strip()
            self.data[i] = row


    def write_to_db(self):
        if not self.source_url:
            print ('Warning: Missing source_url')
        if not self.description:
            print ('Warning: Missing state description')

        conn = psycopg2.connect(database=db_settings.DB, user=db_settings.USER, password=db_settings.PASSWD, host=db_settings.HOST)
        with conn:
            with conn.cursor() as cur:
                query = 'UPDATE states SET (source_url, description, last_updated) = (%(source_url)s, %(description)s, now()) WHERE state=%(state)s;'
                values = {'source_url': self.source_url, 'description': self.description, 'state': self.name}
                try:
                    cur.execute(query, values)
                except psycopg2.Error as e:
                    print (query)
                    print (e.pgerror)
        conn.close()
        print ('Wrote description for', self.name, 'to database')

class Dataset(object):   
    def __init__(self, state, layout = None, quiet = False):
        self.ready = False
        self.state_name = state.name
        self.source_data = state.data
        if layout:
            self.__dict__.update(layout)
            result = []
            keys = [key for key in self.source_data[0].keys()]
            self.ready = True
            if self.type_field and not self.type_map:
                print ('Missing or invalid type_map.') if not quiet else None
                map_template('type', { row[self.type_field] for row in self.source_data })
                self.ready = False

            if self.status_field and not self.status_map:
                print ('Missing or invalid status map.') if not quiet else None
                map_template('status', { row[self.status_field] for row in self.source_data })
                self.ready = False

            if hasattr(self, 'category_field') and not self.category_map:
                print ('Warning: missing or invalid category map') if not quiet else None
                map_template('category', { row[self.category_field] for row in self.source_data })

            for key, value in iter(self.__dict__.items()): # check for blank values
                if value == '':
                    result.append(key)
            for key in layout_template.keys(): # check if all template items present
                if key not in self.__dict__.keys():
                    result.append(key)
                    
            if len(result) > 0 and not quiet:
                print ('Invalid layout. Available source file columns: \n\'' + "', '".join(keys) + "'")
                print ('\nExample rows:', self.source_data[:2])
                print ('Missing values for:', ', '.join(result))

        else:
            print("Missing layout.\n")
            #pp = pprint.PrettyPrinter(indent = 4)
            #pp.pprint(layout_template)
            print(layout_template)
            self.ready = False
            
            keys = [key for key in self.source_data[0].keys()]

            print ('Invalid layout. Available source file columns: \n\'' + "', '".join(keys) + "'")
            print ('\nExample rows:', self.source_data[:2])


        self.projection = state.projection
        self.state = state

        self.layout_ready = False
        self.processed_data = None
        if self.ready:
            self.process_rows()
    
    
    def data_ready(self):
        return True if self.processed_data else False
    
    def process_rows(self):

        apis = dict()
        first = True
        tmp_wells = []
        for row in self.source_data:
            #   XX  |  XXX  |  XXXXX  |  XX
            # State  County     Well     Bore
            api = ''
            if type(self.api_field) is list:
                fields = iter(self.api_field)
                while not api:
                    api = row[next(fields)]
            else:
                api = row[self.api_field]
            
            api = re.sub('[\W_]', '', api).upper()
            
            if hasattr(self.state, 'prepend_api') and self.state.prepend_api:
                api = state_apis[self.state.name] + api
            #if len(str(api)) not in [12, 14]:
            #    api = str(api)[0:13]
            if hasattr(self.state, 'api_function'):
                api = self.state.api_function(api)
            
            if not api:
                continue # some states such as AZ include non-O&G wells w/o API numbers
                
            try:
                lon = float(row[self.lon_field])
                lat = float(row[self.lat_field])
            except ValueError:        
                continue

            date = None
            if type(self.date_field) is list:
                fields = iter(self.date_field)
                while not date:
                    try:
                        date = row[next(fields)]
                    except StopIteration:
                        break
            else:
                date = row[self.date_field] if row[self.date_field] else None
            
            if date:
                try:
                    if hasattr(self.state, 'date_function'):
                        date = self.state.date_function(date)
                    else:
                        date = dateutil.parser.parse(str(date).strip())
                except Exception as E:
                    if first:
                        print(E)
                        print('Error converting date for row:\n')
                        print(row)
                        first = False
                    date = None
            
            if type(date) == datetime:
                date = date.date() # convert to date type
                
            if self.type_field and row[self.type_field] in self.type_map:
                well_type = self.type_map[row[self.type_field]]
            else:
                well_type = 'OTHER'
                
            try:
                well_status = self.status_map[row[self.status_field]] if self.status_field else 'UNKNOWN'
                well_category = self.category_map[row[self.category_field]] if hasattr(self, 'category_field') else None
            except:
                if first:
                    print('Error converting status for row:\n')
                    print(row)
                    first = False
                continue 

            description = None
            if hasattr(self, 'description_fields'):
                description_values = tuple([row[field_name] for field_name in self.description_fields])
                description = self.description_layout % description_values

            well = {'state': self.state_name, 'api': api, 'lon': lon, 'lat': lat, 
                    'date': date, 'type': well_type, 'status': well_status,
                    'category': well_category, 'description': description }
            
            if api not in apis: # new API
                apis[api] = well
                tmp_wells.append(well)
            else: # api already in dict
                if (not apis[api]['date']) or (well['date'] and well['date'] > apis[api]['date']): # if the new record has a newer date
                    apis[api] = well # keep the new value
                    tmp_wells.append(well) # and append
                else:
                    continue # discard this record
        
        self.processed_data = tmp_wells
        print (len(self.processed_data), 'of', str(len(self.source_data)), 'rows loaded')
        print ('first item:', tmp_wells[:1])
        return True
    
    def write_to_db(self):
        if not self.processed_data:
            print ('data not ready')
            return False
        inserts = 0
        conn = psycopg2.connect(database=db_settings.DB, user=db_settings.USER, password=db_settings.PASSWD, host=db_settings.HOST)
        cur = conn.cursor()

        for row in self.processed_data:

            fields = "api, state, status, type, category, date, description, location, capture_time"

            values = ("%(api)s, %(state)s, %(status)s, %(type)s, %(category)s, %(date)s, %(description)s, " + 
                      "Geography(ST_Transform(ST_GeometryFromText('POINT(%(lon)s %(lat)s)', {projection}), 4326)), " + 
                      "now()").format(projection = str(self.projection))

            if row['date'] == '':
                row['date'] = None
            
            query =  ("INSERT INTO wells ({fields}) VALUES ({values}) " + 
                      "ON CONFLICT (api, status, date) DO UPDATE SET ({fields}) = ({values}) " +
                      "WHERE wells.api = %(api)s AND wells.status = %(status)s" +
                      "").format(fields = fields, values = values)
            #print(query)
            try:
                cur.execute(query, row)
                inserts += 1
                # result = cur.statusmessage
            except psycopg2.Error as e:
                print (query)
                print (e.pgerror)
                return False
        conn.commit()
        cur.close()
        conn.close()
        
        print('loaded {0} of {1} records into the database'.format(inserts, len(self.processed_data)))
        return inserts       