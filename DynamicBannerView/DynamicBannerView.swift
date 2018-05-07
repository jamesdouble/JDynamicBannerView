//
//  DynamicBannerView.swift
//  DynamicBannerView
//
//  Created by 郭介騵 on 2018/5/3.
//  Copyright © 2018年 james12345. All rights reserved.
//

import UIKit

class DynamicCycleScrollViewCell: UICollectionViewCell {
    
    override func awakeFromNib() {
        self.isUserInteractionEnabled = true
    }
    
    var clickBlock: (() -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        clickBlock?()
    }
    
    func insertRootView(_ target: UIView) {
        target.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(target)
        let xC = NSLayoutConstraint(item: target, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let yC = NSLayoutConstraint(item: target, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        let wC = NSLayoutConstraint(item: target, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        let hC = NSLayoutConstraint(item: target, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0.0)
        self.addConstraints([xC, yC, wC, hC])
    }
}

fileprivate class DynamicCycleScrollViewLayout: UICollectionViewFlowLayout {
    
    fileprivate var edges: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    fileprivate var cellGap: CGFloat = 5
    fileprivate var middleX: CGFloat = 0
    fileprivate var itemWidth: CGFloat = 1
    fileprivate var minimumScale: CGFloat = 0.85
    /**
     1.cell的放大和缩小
     2.停止滚动时：cell居中
     */
    
    /**
     1.一个cell对应一个UICollectionViewLayoutAttributes对象
     2.UICollectionViewLayoutAttributes对象决定了cell的摆设位置（frame）
     */

    override func prepare() {
        super.prepare()
        self.scrollDirection = .horizontal
        self.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cellGap)
        guard let collection = self.collectionView else { return }
        self.itemSize = CGSize(width: itemWidth, height: collection.frame.height)
    }
    
    /**
     *  这个方法的返回值是一个数组(数组里存放在rect范围内所有元素的布局属性)
     *  这个方法的返回值  决定了rect范围内所有元素的排布（frame）
     */

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrs = super.layoutAttributesForElements(in: rect), let collection = self.collectionView else { return nil }
        let mutableAttrs = attrs.map { (attr) -> UICollectionViewLayoutAttributes in
            return attr.copy() as! UICollectionViewLayoutAttributes
        }
        for attr in mutableAttrs {
            //cell的中心点x 和CollectionView最中心点的x值
            let contentCenterX = collection.contentOffset.x + middleX
            var delta = CGFloat(abs(Int32(attr.center.x - contentCenterX))) / (collection.frame.size.width * 2)
            delta = delta > 1 ? 1 : delta
            let yscale: CGFloat = delta > (1 - minimumScale) ? minimumScale : 1-delta
            let transform = CGAffineTransform(scaleX: 1, y: yscale)
            attr.transform = transform
        }
        return mutableAttrs
    }
    
    /*!
     *  多次调用 只要滑出范围就会 调用
     *  当CollectionView的显示范围发生改变的时候，是否重新发生布局
     *  一旦重新刷新 布局，就会重新调用
     *  1.layoutAttributesForElementsInRect：方法
     *  2.preparelayout方法
     */
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    /**
     *  只要手一松开就会调用
     *  这个方法的返回值，就决定了CollectionView停止滚动时的偏移量
     *  proposedContentOffset这个是最终的 偏移量的值 但是实际的情况还是要根据返回值来定
     *  velocity  是滚动速率  有个x和y 如果x有值 说明x上有速度
     *  如果y有值 说明y上又速度 还可以通过x或者y的正负来判断是左还是右（上还是下滑动）  有时候会有用
     */
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return proposedContentOffset}
        let rect = CGRect(x: proposedContentOffset.x, y: 0, width: (collectionView.frame.width), height: (collectionView.frame.height))
        guard let attrs = super.layoutAttributesForElements(in: rect) else { return proposedContentOffset }
         // 计算CollectionView最中心点的x值 这里要求 最终的 要考虑惯性
        let centerX = (self.itemWidth) / 2 + proposedContentOffset.x
        var minDelta:CGFloat = 9999
        for attr in attrs {
            if abs(Int32(minDelta)) > abs(Int32(attr.center.x - centerX)) {
                minDelta = attr.center.x - centerX
            }
        }
        var offset = proposedContentOffset
        offset.x += minDelta
        return offset
    }
    
}

@IBDesignable class DynamicCycleScrollView: UIView {
    
    //
    public var defaultInsects: CGFloat = 5 {
        didSet {
            self.edges = UIEdgeInsets(top: defaultInsects, left: defaultInsects, bottom: defaultInsects, right: defaultInsects)
        }
    }
    
    public var edges: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5) {
        didSet {
            collectionViewLayout.middleX = self.frame.width / 2 - edges.left
            collectionViewLayout.edges = edges
            changeConstraint()
            self.setItemWidth()
        }
    }
    
    public var cellGap: CGFloat = 5 {
        didSet {
            collectionViewLayout.cellGap = cellGap
        }
    }
    
    public var tailWidth: CGFloat = 10.0 {
        didSet {
            self.setItemWidth()
            self.collectionView.reloadData()
        }
    }
    
    private func setItemWidth() {
        if viewDataSource.count == 1 {
            collectionViewLayout.itemWidth = self.frame.width - edges.left - edges.right
        } else {
            collectionViewLayout.itemWidth = self.frame.width - edges.left - tailWidth - self.cellGap
        }
    }
    
    public var autoScrollInterval: TimeInterval = 5.0 {
        didSet {
            if autoScrolling {
                autoScrolling = true    //更新Timer
            }
        }
    }

    public var autoScrolling: Bool = true {
        didSet {
            if autoScrolling {
                if let timer = scrollTimer {
                    timer.invalidate()
                }
                scrollTimer = Timer(timeInterval: autoScrollInterval, target: self, selector: #selector(DynamicCycleScrollView.fireTimer(sender:)), userInfo: nil, repeats: true)
                RunLoop.current.add(scrollTimer!, forMode: .defaultRunLoopMode)
            } else {
                guard let timer = scrollTimer else { return }
                timer.invalidate()
                scrollTimer = nil
            }
        }
    }
    
    public var minimumScale: CGFloat = 0.85 {
        didSet {
            collectionViewLayout.minimumScale = minimumScale
        }
    }
    
    fileprivate var viewDataSource: [UIView] = []
    fileprivate var viewCount: Int {
        get {
            return viewDataSource.count
        }
    }
    
    public func setViews(_ views: [UIView]) {
        viewDataSource = views
        self.collectionView.isScrollEnabled = views.count > 1
        self.collectionView.reloadData()
    }
    
    public var clickBlock: ((Int) -> Void)?
    
    fileprivate var scrollTimer: Timer?
    ///防止下個Cell被釋放
    fileprivate var extraDisplayWidth: CGFloat = 20
    //
    fileprivate var collectionViewLayout = DynamicCycleScrollViewLayout()
    fileprivate var collectionView: UICollectionView!
    fileprivate var scrollViewTopConstraint: NSLayoutConstraint!
    fileprivate var scrollViewBottomConstraint: NSLayoutConstraint!
    fileprivate var scrollViewLeadingConstraint: NSLayoutConstraint!
    fileprivate var scrollViewTrailingConstraint: NSLayoutConstraint!
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    init(frame: CGRect, views: [UIView], insects: CGFloat = 5.0, cellGap: CGFloat = 5.0, tailWidth: CGFloat = 10.0, autoScrolling: Bool = true) {
        super.init(frame: frame)
        self.commonInit()
        self.setViews(views)
        self.defaultInsects = insects
        self.autoScrolling = autoScrolling
        self.tailWidth = views.count == 1 ? 0 : tailWidth
        self.cellGap = views.count == 1 ? 0 : cellGap
        self.collectionView.reloadData()
    }
    
    override func didMoveToSuperview() {
        let itemWidth = collectionViewLayout.itemWidth + 2 * cellGap
        self.collectionView.setContentOffset(CGPoint(x: itemWidth * 500, y: self.collectionView.contentOffset.y), animated: false)
        let trigger = defaultInsects
        self.defaultInsects = trigger
    }
    
    private func commonInit() {
        initScrollView()
        self.clipsToBounds = false
    }
    
    private func initScrollView() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(DynamicCycleScrollViewCell.self, forCellWithReuseIdentifier: "DynamicCycleScrollViewCell")
        self.addSubview(collectionView)
        //
        scrollViewTopConstraint = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: edges.top)
        scrollViewLeadingConstraint = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: edges.left)
        scrollViewTrailingConstraint = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: extraDisplayWidth)
        scrollViewBottomConstraint = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -edges.bottom)
        self.addConstraints([scrollViewTopConstraint, scrollViewLeadingConstraint, scrollViewTrailingConstraint, scrollViewBottomConstraint])
    }
    
    private func changeConstraint() {
        scrollViewTopConstraint.constant = edges.top
        scrollViewLeadingConstraint.constant = edges.left
        scrollViewBottomConstraint.constant = -edges.bottom
        scrollViewTrailingConstraint.constant = extraDisplayWidth
        self.setNeedsUpdateConstraints()
    }
}

extension DynamicCycleScrollView {
    
    @objc func fireTimer(sender: Any) {
        if self.collectionView.isDragging {
            return
        }
        let next = getNextContentOffset()
        self.collectionView.setContentOffset(next, animated: true)
    }
    
    private func getNextContentOffset() -> CGPoint {
        let nowOffset = self.collectionView.contentOffset
        let itemWidth = collectionViewLayout.itemWidth + 2 * cellGap
        let page: CGFloat = CGFloat(Int(nowOffset.x / itemWidth))
        return CGPoint(x: itemWidth * (page + 1), y: nowOffset.y)
    }
    
}

extension DynamicCycleScrollView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (viewCount == 1) ? viewCount : viewCount * 1000
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DynamicCycleScrollViewCell", for: indexPath) as! DynamicCycleScrollViewCell
        let view = viewDataSource[indexPath.row % viewCount]
        for subview in cell.subviews {
            subview.removeFromSuperview()
        }
        cell.insertRootView(view)
        cell.clickBlock = {
            self.clickBlock?(indexPath.row % self.viewCount)
        }
        return cell
    }
    
}
