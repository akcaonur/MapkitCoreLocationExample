//
//  ViewController.swift
//  MapKit-CoreLocation Example
//
//  Created by batuhankarasu on 18.01.2021.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var btnGit: UIButton!
    @IBOutlet weak var lblAdres: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let bolgeBuyukluk :Double = 16000
    var oncekiKonum :CLLocation?
    var rotalar : [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        konumServisKontrol()
        btnGit.layer.cornerRadius = 10
        
    }
    func konumServisKontrol() {
        if CLLocationManager.locationServicesEnabled(){
            //konum açık
            ayarlaLocationManager()
            izinKontrol()
        }else {
            //konum kapalı
        }
    }

    func ayarlaLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func izinKontrol(){
        switch CLLocationManager.authorizationStatus(){
        
        case .authorizedAlways://her zaman konum izni
            break
        case .authorizedWhenInUse://kullanım sırası
            kullaniciTakip()
            break
        case .denied://red
            break
        case .notDetermined://karar verilmedi
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:// uygulamada kısıtlı
            break
            
        
        }
    }
    func konumOdaklan () {
        if let konum = locationManager.location?.coordinate {
            let bolge = MKCoordinateRegion.init(center: konum, latitudinalMeters: bolgeBuyukluk, longitudinalMeters: bolgeBuyukluk)
            mapView.setRegion(bolge, animated: true)
        }
    }
    func merkezJordinatGetir (mapView : MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    @IBAction func btnGitTikla(_ sender: Any) {
        rotaBelirle()
        
    }
    
    func rotaBelirle(){
        guard let baslangicKoordinat = locationManager.location?.coordinate else {return}
        let istek = istekOlustur(baslangicKoordinat: baslangicKoordinat)
        let rotalar = MKDirections(request: istek)
        mapViewTemizle(yeniRota: rotalar)
        rotalar.calculate {(cevap , hata) in
            guard let cevap = cevap else {return}
            for rota in cevap.routes{
                self.mapView.addOverlay(rota.polyline)
                self.mapView.setVisibleMapRect(rota.polyline.boundingMapRect, animated: true)
            }
        }
        
    }
    
    func istekOlustur(baslangicKoordinat : CLLocationCoordinate2D) -> MKDirections.Request {
        let hedefKoordinat = merkezJordinatGetir(mapView: mapView).coordinate
        let baslangicNoktasi = MKPlacemark(coordinate: baslangicKoordinat)
        let hedefNoktasi = MKPlacemark (coordinate: hedefKoordinat)
        let istek = MKDirections.Request()
        istek.source = MKMapItem(placemark: baslangicNoktasi)
        istek.destination = MKMapItem(placemark: hedefNoktasi)
        istek.transportType = .automobile
        istek.requestsAlternateRoutes = true
        
        return istek
    }
    
    func kullaniciTakip() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        konumOdaklan()
        oncekiKonum = merkezJordinatGetir(mapView: mapView)
    }
    func mapViewTemizle(yeniRota : MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        rotalar.append(yeniRota)
        let _ = rotalar.map {($0.cancel())}
        
    }
}
extension ViewController :CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // konum güncellenirse tetiklenir
        guard let konum = locations.last else {return}
        let merkez = CLLocationCoordinate2D(latitude: konum.coordinate.latitude, longitude: konum.coordinate.longitude)
        let bolge = MKCoordinateRegion.init(center: merkez, latitudinalMeters: bolgeBuyukluk, longitudinalMeters: bolgeBuyukluk)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //konum izni değişmesi
        izinKontrol()
    }
    
    
    
}
extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let merkez = merkezJordinatGetir(mapView: mapView)
        guard let oncekiKonum = self.oncekiKonum else {return}
        if merkez.distance(from: oncekiKonum) < 50 {return}
        self.oncekiKonum = merkez
        
        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(merkez){(yerIsaretleri, Hata) in
            if let _ = Hata {
                print("hata meydana geldi")
                return
            }
            guard let isaret = yerIsaretleri?.first else {return}
            
            let sokakNumarasi = isaret.subThoroughfare ?? "yok"
            let sokakAdi = isaret.thoroughfare ?? "yok"
            let ulkeAdi = isaret.country ?? "yok"
            let ilAdi = isaret.administrativeArea ?? "yok"
            let ilceAdi = isaret.locality ?? "yok"
            DispatchQueue.main.async {
                self.lblAdres.text = "\(ilceAdi)/\(ilAdi)/\(ulkeAdi)"
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer (overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 6
        renderer.lineCap = .square
        return renderer
    }
}

