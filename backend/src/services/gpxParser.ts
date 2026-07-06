import xml2js from 'xml2js';

export interface GpxPoint {
  lat: number;
  lon: number;
  ele: number;
}

export interface CourseSegment {
  distance: number; // meters from start
  gradient: number; // percentage
  lat: number;
  lon: number;
  ele: number;
}

// Haversine formula for distance between two points in meters
export function getDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c;
}

export async function parseGpx(gpxString: string): Promise<CourseSegment[]> {
  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(gpxString);
  
  const points: GpxPoint[] = [];
  
  if (result.gpx && result.gpx.trk) {
    for (const trk of result.gpx.trk) {
      if (trk.trkseg) {
        for (const seg of trk.trkseg) {
          if (seg.trkpt) {
            for (const pt of seg.trkpt) {
              points.push({
                lat: parseFloat(pt.$.lat),
                lon: parseFloat(pt.$.lon),
                ele: pt.ele ? parseFloat(pt.ele[0]) : 0
              });
            }
          }
        }
      }
    }
  }

  const segments: CourseSegment[] = [];
  let totalDistance = 0;

  for (let i = 0; i < points.length; i++) {
    if (i === 0) {
      segments.push({
        distance: 0,
        gradient: 0,
        lat: points[i].lat,
        lon: points[i].lon,
        ele: points[i].ele
      });
      continue;
    }

    const p1 = points[i - 1];
    const p2 = points[i];
    
    const dist = getDistance(p1.lat, p1.lon, p2.lat, p2.lon);
    const eleDiff = p2.ele - p1.ele;
    
    const gradient = dist > 0 ? (eleDiff / dist) * 100 : 0;
    
    totalDistance += dist;
    
    segments.push({
      distance: totalDistance,
      gradient,
      lat: p2.lat,
      lon: p2.lon,
      ele: p2.ele
    });
  }

  return segments;
}
