//
//  Copyright (c) 2019 KxCoding <kky0317@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa
import NSObject_Rx


class CoreLocationProvider : LocationProviderType {
    
    private let locationManager = CLLocationManager()
    
    
    //위치 정보 바인딩 behaviorRelay
    private let location = BehaviorRelay<CLLocation>(value: CLLocation.gangnamStation)
    
    //주소 정보를 바인딩
    private let address = BehaviorRelay<String>(value: "강남역")
    
    //허가 상태 바인딩
    private let authorized = BehaviorRelay<Bool>(value: false)
    
    //리소스 관리 disposeBag
    
    private let disposeBag = DisposeBag()
    
    init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //두번이상 안돼게 하기 위해 5초마다 한번 씩
        locationManager.rx.didUpdateLocation
            .throttle(.seconds(5), scheduler: MainScheduler.instance)
            .map { $0.last ?? CLLocation.gangnamStation }
            .bind(to: location)
            .disposed(by: disposeBag)
        
        
        //reverse geocoding 좌표 -> 주소
        location.flatMap { location in
            return Observable<String>.create {
                observer in
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let place = placemarks?.first {
                        //동과 구를 뽑아낸다
                        if let gu = place.locality, let dong = place.subLocality {
                            observer.onNext("\(gu) \(dong)")
                        } else {
                            observer.onNext(place.name ?? "알수 없음")
                        }
                    } else {
                        observer.onNext("알 수 없음")
                    }
                    
                    observer.onCompleted()
                }
                
                return Disposables.create()
            }
        }
        .bind(to: address)
        .disposed(by: disposeBag)
        
        
        
        locationManager.rx.didChangeAuthorizationStatus
            .map {
                $0 == .authorizedAlways || $0 == .authorizedWhenInUse}
            .bind(to: authorized)
            .disposed(by: disposeBag)
        
    }
    
    
    @discardableResult
    func currentLocation() -> Observable<CLLocation> {
        return location.asObservable()
    }
    
    @discardableResult
    func currentAddress() -> Observable<String> {
        return address.asObservable()
    }
    
    
}
