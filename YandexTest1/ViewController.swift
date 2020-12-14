

import UIKit
import YandexMapKit
import CoreLocation
import YandexMapKitDirections
import YandexRuntime

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: YMKMapView!
    let locationManager = CLLocationManager()
    var collection: YMKClusterizedPlacemarkCollection?
    var points: [YMKPoint] = []
    var userLocationLayer: YMKUserLocationLayer!
    var currentLocationPoint:YMKPoint!
    var directonLocationPoint:YMKPoint!
    var drivingSession: YMKDrivingSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        mapView.mapWindow.map.addInputListener(with: self)
        
        let pinImage = UIImage(named: "pin")
        
        let myImageView:UIImageView = UIImageView()
        myImageView.contentMode = UIView.ContentMode.scaleAspectFit
        myImageView.frame.size.width = 50
        myImageView.frame.size.height = 100
        myImageView.center = self.view.center
        myImageView.image = pinImage
        
        view.addSubview(myImageView)
        
        let myButton = UIButton(type: .system)
        myButton.frame = CGRect(x: 20, y: 20, width: 65, height: 65)
        myButton.center = CGPoint(x: 330, y: 590 )
        myButton.setTitle("GO", for: .normal)
        myButton.layer.cornerRadius = 0.5 * myButton.bounds.size.width
        myButton.backgroundColor = .green
        myButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        view.addSubview(myButton)
        
        
        collection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
                collection?.addTapListener(with: self)

                for point in points {
                    let placemark = collection?.addPlacemark(with: point,
                                                                   image: UIImage(named: "SearchResult")!,
                                                                   style: YMKIconStyle.init())
                    placemark?.userData = "user data"
                }

        collection?.clusterPlacemarks(withClusterRadius: 60, minZoom: 15)
        
    }
    
    @objc func buttonAction(_ sender:UIButton!){
        mapView.mapWindow.map.mapObjects.clear()
        let requestPoints : [YMKRequestPoint] = [
            YMKRequestPoint(point: currentLocationPoint, type: .waypoint, pointContext: nil),
            YMKRequestPoint(point: directonLocationPoint, type: .waypoint, pointContext: nil),
        ]
        
        let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
            if let routes = routesResponse {
                self.onRoutesReceived(routes)
            } else {
                self.onRoutesError(error!)
            }
        }
        let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
        drivingSession = drivingRouter.requestRoutes(
            with: requestPoints,
            drivingOptions: YMKDrivingDrivingOptions(),
            routeHandler: responseHandler)
    }
    
    func onRoutesReceived(_ routes: [YMKDrivingRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        for route in routes {
            mapObjects.addPolyline(with: route.geometry)
        }
    }
    
    func onRoutesError(_ error: Error) {
        let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if routingError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if routingError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    

    
    
}

extension ViewController:YMKMapCameraListener{
    
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateSource: YMKCameraUpdateSource, finished: Bool) {
        
        let pinPoint = YMKPoint(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude)
        
        guard let lastLocation = YMKLocationManager.lastKnownLocation()?.position else { return }
        currentLocationPoint = lastLocation
        directonLocationPoint = pinPoint
        return
    }
}

extension ViewController: YMKClusterListener{
    func onClusterAdded(with cluster: YMKCluster) {
        
        cluster.appearance.setIconWith(UIImage(named: "SearchResult")!)
        
    }
    
    
}


// MARK: User current location

extension ViewController: CLLocationManagerDelegate{
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAutorization()
        } else {
            //
        }
    }
    
    func centerViewOnUserLocation() {
        
        if let location = YMKLocationManager.lastKnownLocation()?.position {
            mapView.mapWindow.map.isRotateGesturesEnabled = false
            let map = YMKMapKit.sharedInstance()
            if userLocationLayer == nil{
                userLocationLayer = map.createUserLocationLayer(with: mapView.mapWindow)
                userLocationLayer.isHeadingEnabled = true
                userLocationLayer.setVisibleWithOn(true)
                let userLocation = YMKPoint(latitude: location.latitude, longitude: location.longitude)
                mapView.mapWindow.map.move(with:
                    YMKCameraPosition(target: userLocation, zoom: 14, azimuth: 0, tilt: 0))
                mapView.mapWindow.map.addCameraListener(with: self)
                userLocationLayer.setObjectListenerWith(self)
            }
            
        }
    }
    
    func checkLocationAutorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            centerViewOnUserLocation()
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        @unknown default:
            print(Error.self)
        }
    }
}

//MARK: Yandex User location

extension ViewController:  YMKUserLocationObjectListener {
    
    func onObjectAdded(with view: YMKUserLocationView) {
        view.arrow.setIconWith(UIImage(named:"UserArrow")!)
        
        let pinPlacemark = view.pin.useCompositeIcon()
        
        
        pinPlacemark.setIconWithName(
            "pin",
            image: UIImage(named:"SearchResult")!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 1, y: 1) as NSValue,
                rotationType: YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 1,
                tappableArea: nil))

    }
    
    func onObjectRemoved(with view: YMKUserLocationView) {
        //
    }
    
    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {
        //
    }
}


//MARK: Yandex on map Tapping

extension ViewController: YMKMapInputListener{
    
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
//        print(point.latitude)
//        print(point.longitude)
        points.append(point)
        print(points)
    }
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
        //
    }
    
    
}



extension ViewController: YMKMapObjectTapListener {
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        guard let userPoint = mapObject as? YMKPlacemarkMapObject else {
            return true
        }

        print(userPoint.userData!)
        return false
    }
    
    
    
    
}



