import netCDF4
import json
import numpy as np
from flask import Flask, jsonify, Response, request
app = Flask(__name__)

def find_nearest(array, value):
    idx = (np.abs(array-float(value))).argmin()
    return idx

def options(self):
    return { 'Allow' : 'GET' }, 200, { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET' }

@app.route('/datasets')
def show_datasets():
    resp = Response("""
    {
      "datasets": [
        {"slug":"air","name":"Surface Temperature"},
        {"slug":"pr_wtr","name":"Precipital Water"},
        {"slug":"pres","name":"Pressure"},
        {"slug":"rhum","name":"Relative Humidity"},
        {"slug":"slp","name":"Sea Level Pressure"}
      ]
    }
    """,
    status=200, mimetype='application/json')
    resp.headers['Link'] = 'http://datago.com'
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp

@app.route('/dataset/<year>/<slug>')
def show_data(year, slug):
    time = request.args.get('time')
    lat = request.args.get('lat')
    lng = request.args.get('lng')
    dltLat = request.args.get('delta_lat')
    dltLng = request.args.get('delta_lng')
    nc = netCDF4.Dataset('../../surface/'+slug+'.sig995.'+year+'.nc')
    if (not time is None) and (len(time) > 0) and (not lat is None) and (len(lat) > 0) and (not lng is None) and (len(lng) > 0):
        if(dltLat is None) or (len(dltLat) == 0):
            dltLat = 3
        else:
            dltLat = int(dltLat)

        if (dltLng is None) or (len(dltLng) == 0):
            dltLng = 4
        else:
            dltLng = int(dltLng)

        lng = float(lng)+180
        lat = float(lat)
        times = nc.variables['time']
        lats = nc.variables['lat']
        lngs = nc.variables['lon']
        timeA = np.searchsorted(times[:],time) - 1
        latA = find_nearest(lats[:],lat)
        lngA = find_nearest(lngs[:],lng)
        var = nc.variables[slug][:]
        data = []

        for i in range(0, (dltLat*2)):
            newI = i-dltLat;
            for n in range(0, (dltLng*2)):
                newN = n-dltLng
                newLat = latA + newI
                newLng = lngA + newN

                if(newLat >= 0) and (newLat < len(lats)) and (newLng >= 0) and (newLng < len(lngs)):
                    data.append({"lat":str(np.asscalar(lats[latA+newI])), "lng":str(np.asscalar(lngs[lngA+newN]-180)), "val":str(np.asscalar(var[timeA][latA+newI][lngA+newN]))})

        heads = nc.variables[slug]
        data = '{"headers":{"actual_range":["'+str(np.asscalar(heads.actual_range[0]))+'","'+str(np.asscalar(heads.actual_range[1]))+'"], "units":"'+heads.units+'", "add_offset":"'+str(np.asscalar(heads.add_offset))+'", "var_desc":"'+heads.var_desc+'", "dataset":"'+heads.dataset+'"}, "results":'+json.dumps(data)+'}'
    elif(not time is None) and (len(time) > 0):
        times = nc.variables['time'][:]
        lats = nc.variables['lat'][:]
        lngs = nc.variables['lon'][:]
        timeA = np.searchsorted(times[:],time) - 1
        slugs = nc.variables[slug][:][timeA]
        data = []
        latI = -1
        for latV in slugs[:]:
            latI+=1
            lngI = -1
            for lngV in latV[:]:
                data.append({"lat":str(np.asscalar(lats[latI])), "lng":str(np.asscalar(lngs[lngI])), "val":str(np.asscalar(lngV))})

        heads = nc.variables[slug]
        data = '{"headers":{"actual_range":["'+str(np.asscalar(heads.actual_range[0]))+'","'+str(np.asscalar(heads.actual_range[1]))+'"], "units":"'+heads.units+'", "add_offset":"'+str(np.asscalar(heads.add_offset))+'", "var_desc":"'+heads.var_desc+'", "dataset":"'+heads.dataset+'"}, "results":'+json.dumps(data)+'}'
    else:
        times = nc.variables['time'][:]
        data = []
        for i in times:
            data.append({"time":str(np.asscalar(i)), "time_as_string":str(netCDF4.num2date(i, nc.variables['time'].units))})
        data = '{"times":'+json.dumps(data)+'}'

    resp = Response(data, status=200, mimetype='application/json')
    resp.headers['Link'] = 'http://datago.com'
    resp.headers['Access-Control-Allow-Origin'] = '*'
    return resp

@app.route("/")
def hello():
    return "Usage:<br/>\
/datasets<br/>\
returns all available datasets<br/>\
<br/>\
/dataset/{year}/{dataset.slug}<br/>\
returns available times for dataset and year<br/>\
<br/>\
/dataset/{year}/{dataset.slug}?time={dataset.time}&lat={latitude}&lng={longitude}&delta_lat{data offset for latitude}&delta_lng={data offset for longitude}<br/>\
returns grid of data for dataset, year, time and location"

if __name__ == "__main__":
    app.debug = True
#    app.run()
#     app.run(host='10.0.0.2', port=5001)
    app.run(host='0.0.0.0', port=5001)