import sys
import logging
from pathlib import Path

from geofence.geofenceHelper import GeofenceHelper

import argparse 

log = logging.getLogger(__name__)

parser = argparse.ArgumentParser(description="A program that checks if a lat/lon coord is contained within a geofence")
parser.add_argument("-i", "--include", default="geofence_inc.txt",
                    help="Geofence include file")
parser.add_argument("-e", "--exclude", default=None,
                    help="Geofence exclude file")
parser.add_argument("-lat", "--latitude", type=float, required=True,
                    help="Latitude of coordinate")
parser.add_argument("-lon", "--longitude", type=float, required=True,
                    help="Longitude of coordinate")
args = parser.parse_args()

if not Path(args.include).is_file():
    raise RuntimeError("Geofence included file configured does not exist " + args.include)

if (args.exclude != None ) and (not Path(args.exclude).is_file()):
    raise RuntimeError("Geofence excluded file configured does not exist " + args.exclude)

geofence_helper = GeofenceHelper(args.include, args.exclude)
if geofence_helper.is_coord_inside_include_geofence([args.latitude, args.longitude]):
    exit(0)
else:
    exit(1)
