**JDynamicBannerView** 是一個仿京東首頁做的一個廣告橫幅Banner控件

**JDynamicBannerView** is a banner view component inspired by 京東


![Alt text](https://img.shields.io/badge/SwiftVersion-4.0+-red.svg?link=http://left&link=http://right)
![Alt text](https://img.shields.io/badge/IOSVersion-8.0+-green.svg)
![Alt text](https://img.shields.io/badge/BuildVersion-1.0.0-green.svg)
![Alt text](https://img.shields.io/badge/Author-JamesDouble-blue.svg?link=http://https://jamesdouble.github.io/index.html&link=http://https://jamesdouble.github.io/index.html)


![Alt text](https://raw.githubusercontent.com/jamesdouble/JDSwiftHeatMap/master/Readme_img/jdheatmapDemo.png?token=AJBUU1UA_L_wx5f_E3iRsaUGAh_xg3pCks5Zb1yIwA%3D%3D)

# Installation
* Cocoapods

```
	pod 'JDynamicBannerView'
```


# Usage

### Init

```swift
let banner = DynamicCycleScrollView(frame: CGRect(origin: CGPoint(x: 20, y: 100), size: CGSize(width: 340, height: 100)))
banner.setView(viewCount: 2) { (index) -> UIView in
            let text = "test\(index+1)"
            let img = UIImage(named: text)
            let imgView = UIImageView(image: img)
            return imgView
}      

```

### ClickBlock

```swift
banner.clickBlock = { (idx) in
            print(idx)
        }   

```

### Parameter



