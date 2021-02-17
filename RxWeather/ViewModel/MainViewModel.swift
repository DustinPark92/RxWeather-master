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

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import NSObject_Rx

typealias SectionModel = AnimatableSectionModel<Int, WeatherData>

class MainViewModel: HasDisposeBag {
    
    //Shift + cmd + A  자동으로 Inititalize 해줌
    init(title: String, sceneCoordinator: SceneCoordinatorType, weatherAPi: WeatherApiType, locationProvider: LocationProviderType) {
        self.title = BehaviorRelay(value: title)
        self.sceneCoordinator = sceneCoordinator
        self.weatherAPi = weatherAPi
        self.locationProvider = locationProvider
        
        
        //locationProvider의 주소를 title에 바인딩 , 새로운 주소가 방출 됨.
        locationProvider.currentAddress()
            .bind(to: self.title)
            .disposed(by: disposeBag)
        
        
    }
    
   static let tempFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.minimumFractionDigits = 0
      formatter.maximumFractionDigits = 1
      
      return formatter
   }()
   
   static let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "Ko_kr")
      return formatter
   }()
    
    
    //주소를 바인딩
    let title : BehaviorRelay<String>
   
    
    //의존성 관련 속성
    let sceneCoordinator : SceneCoordinatorType
    let weatherAPi : WeatherApiType
    let locationProvider : LocationProviderType
    
    
    //tableview와 binding할 oberservable -> 항상 driver로 선언
    
    var weartherData : Driver<[SectionModel]> {
        //rxdatesource를 사용하기 위해서 방출하는 형태를 SectionModel로 함
        
        return locationProvider.currentLocation()
            .flatMap {
                [unowned self] in
                self.weatherAPi.fetch(location: $0)
                    .asDriver(onErrorJustReturn: ( nil , [WeatherDataType]()))
            }.map {
                (summary, forecast) in
                var summaryList = [WeatherData]()
                if let summary = summary as? WeatherData {
                    summaryList.append(summary)
                }
                
                return [
                    SectionModel(model: 0, items: summaryList),
                    SectionModel(model: 1, items: forecast as! [WeatherData])
                ]
            }
            .asDriver(onErrorJustReturn: [])
    }
    
    //tableview에서 사용할 dataSource
    
    let dataSource : RxTableViewSectionedAnimatedDataSource<SectionModel> = {
        let ds = RxTableViewSectionedAnimatedDataSource<SectionModel> { (dataSouce, tableView, indexPath, data) -> UITableViewCell in
            //indexPath로 분기하여 필요한 셀 리턴
            
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: SummaryTableViewCell.identifier, for: indexPath) as! SummaryTableViewCell
                cell.configure(from: data, tempFormatter: MainViewModel.tempFormatter)
                
                return cell
                
            default :
                let cell = tableView.dequeueReusableCell(withIdentifier: ForecastTableViewCell.identifier, for: indexPath) as! ForecastTableViewCell
                cell.configure(from: data, dateFormatter: MainViewModel.dateFormatter, tempFormatter: MainViewModel.tempFormatter)
                return cell
            }
            
        }
        return ds
    }()
   
}
