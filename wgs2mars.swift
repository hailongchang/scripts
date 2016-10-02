//
//  wgs2mars.swift
//  usage: let (lat,long) = wgs2mars.transform(wlat, wlong)
//  wlat, wlong is wgs_latitude, wgs_longitude
//  


class wgs2mars{
    static var a:Double = 6378245.0
    static var ee:Double = 0.00669342162296594323
    
    class func outOfChina(lat:Double,_ lon:Double) -> Bool {
        if (lon < 72.004 || lon > 137.8347){
            return true
        }
        if (lat < 0.8293 || lat > 55.8271) {
            return true
        }
    
        return false;
    }
    class func transform(wgLat:Double,_ wgLon:Double) -> (Double,Double){
        var mgLat:Double = 0.0
        var mgLon:Double = 0.0
        
        if(outOfChina(wgLat,wgLon)){
            mgLat = wgLat
            mgLon = wgLon
        }
        
        var dLat:Double = transformLat(wgLon-105.0, wgLat-35.0)
        var dLon:Double = transformLon(wgLon-105.0, wgLat-35.0)
        
        let radLat:Double = wgLat / 180.0 * Pi
        var magic:Double = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic:Double = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * Pi);
        mgLat = wgLat + dLat
        mgLon = wgLon + dLon
        
        return (mgLat,mgLon)
    }
    
    class func transformLat(x:Double,_ y:Double) ->Double{
        let t = sqrt(abs(x))
        var ret:Double = -100.0 + 2.0 * x  + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * t
        ret += 20.0 * sin(6.0 * x * Pi) + 20.0 * sin(2.0 * x * Pi) * 2.0 / 3.0
        ret += 20.0 * sin(y * Pi) + 40.0 * sin(y / 3.0 * Pi) * 2.0 / 3.0
        ret += 160.0 * sin(y / 12.0 * Pi) + 320 * sin(y * Pi / 30.0) * 2.0 / 3.0
        return ret
    }
    
    class func transformLon(x:Double,_ y:Double) -> Double{
        let t = sqrt(abs(x))
        var ret:Double = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 + t
        ret += 20.0 * sin(6.0 * x * Pi) +  20.0 * sin(2.0 * x * Pi) * 2.0 / 3.0
        ret += 20.0 * sin(x * Pi) + 40.0 * sin(x / 3.0 * Pi) * 2.0 / 3.0
        ret += 150.0 * sin(x / 12.0 * Pi) + 300.0 * sin(x / 30.0 * Pi) * 2.0 / 3.0
        return ret
    }
}