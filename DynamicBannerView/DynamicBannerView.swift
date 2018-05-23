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
    
    func insertRootView(_ target: UIView, edges: UIEdgeInsets) {
        target.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(target)
        let xC = NSLayoutConstraint(item: target, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let yC = NSLayoutConstraint(item: target, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        let wC = NSLayoutConstraint(item: target, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: edges.top)
        let hC = NSLayoutConstraint(item: target, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -edges.bottom)
        self.addConstraints([xC, yC, wC, hC])
    }
}

private class DynamicCycleScrollViewLayout: UICollectionViewFlowLayout {
    
    fileprivate var cellGap: CGFloat = 5 {
        didSet {
            self.minimumInteritemSpacing = cellGap
            self.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cellGap)
        }
    }
    fileprivate var middleX: CGFloat = 0
    fileprivate var minimumScale: CGFloat = 0.85
    var itemWidth: CGFloat = 1
    
    override func prepare() {
        itemWidth = (self.itemSize.width + cellGap)
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
            //
            let indexPath = attr.indexPath
            attr.frame.origin.x = itemWidth * CGFloat(indexPath.item)
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
        guard let attrs = self.layoutAttributesForElements(in: rect) else { return proposedContentOffset }
        // 计算CollectionView最中心点的x值 这里要求 最终的 要考虑惯性
        let centerX = (self.itemSize.width) / 2 + proposedContentOffset.x
        var minDelta: CGFloat = 9999
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
    
    ///統一上下左右間距
    public var defaultInsects: CGFloat = 5 {
        didSet {
            self.edges = UIEdgeInsets(top: defaultInsects, left: defaultInsects, bottom: defaultInsects, right: defaultInsects)
        }
    }
    
    public var edges: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5) {
        didSet {
            changeConstraint()
            self.setItemSize()
        }
    }
    
    public var cellGap: CGFloat = 5 {
        didSet {
            self.setItemSize()
            collectionViewLayout.cellGap = cellGap
        }
    }
    
    public var tailWidth: CGFloat = 10.0 {
        didSet {
            self.setItemSize()
        }
    }
    
    private func setItemSize() {
        let realTailWidth = viewCount < 2 ? 0 : tailWidth
        let realCellGap = viewCount < 2 ? 0 : cellGap
        let width: CGFloat = viewCount < 2 ? (self.frame.width - edges.left - edges.right) : (self.frame.width - edges.left - realTailWidth - realCellGap)
        let height: CGFloat = self.collectionView.frame.height
        let size = CGSize(width: width <= 0 ? 0.1 : width, height: height <= 0 ? 0.1 : height)
        collectionViewLayout.itemSize = size
        collectionViewLayout.middleX = size.width / 2
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
    
    ///是否無限輪播
    public var infinityScrolling: Bool = true {
        didSet {
            self.collectionView.reloadData()
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
        self.autoScrolling = views.count > 1
        self.setItemSize()
        self.collectionView.isScrollEnabled = views.count > 1
        self.collectionView.reloadData()
        self.layoutIfNeeded()
    }
    
    public var clickBlock: ((Int) -> Void)?
    
    fileprivate var scrollTimer: Timer?
    ///防止下個Cell被釋放
    fileprivate var extraDisplayWidth: CGFloat = 20
    //
    fileprivate var collectionViewLayout = DynamicCycleScrollViewLayout()
    fileprivate var collectionView: UICollectionView!
    fileprivate var scrollViewLeadingConstraint: NSLayoutConstraint!
    fileprivate var scrollViewTrailingConstraint: NSLayoutConstraint!
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    deinit {
        scrollTimer?.invalidate()
        scrollTimer = nil
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
        self.autoScrolling = views.count > 1 ? autoScrolling : false
        self.collectionView.reloadData()
        self.layoutIfNeeded()
    }
    
    override func didMoveToSuperview() {
        let trigger = edges
        self.edges = trigger
        let auto = self.autoScrolling
        self.autoScrolling = auto
        self.scrollToMiddle()
    }
    
    private func commonInit() {
        initScrollView()
        self.clipsToBounds = false
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: 0.1, height: 0.1)
        collectionView.decelerationRate = 0.05
    }
    
    private func initScrollView() {
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(DynamicCycleScrollViewCell.self, forCellWithReuseIdentifier: "DynamicCycleScrollViewCell")
        self.addSubview(collectionView)
        //
        let scrollViewTopConstraint = NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0)
        scrollViewLeadingConstraint = NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: edges.left)
        scrollViewTrailingConstraint = NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: extraDisplayWidth)
        let scrollViewBottomConstraint = NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0)
        self.addConstraints([scrollViewTopConstraint, scrollViewLeadingConstraint, scrollViewTrailingConstraint, scrollViewBottomConstraint])
    }
    
    private func changeConstraint() {
        scrollViewLeadingConstraint.constant = edges.left
        scrollViewTrailingConstraint.constant = extraDisplayWidth
        self.setNeedsUpdateConstraints()
    }
}

extension DynamicCycleScrollView {
    
    @objc func fireTimer(sender: Any) {
        if self.collectionView.isDragging {
            return
        }
        let next = getNextIndex()
        self.collectionView.scrollToItem(at: IndexPath(item: next, section: 0), at: .left, animated: true)
    }
    
    private func getNextIndex() -> Int {
        let nowOffset = self.collectionView.contentOffset
        let itemWidth = collectionViewLayout.itemSize.width + cellGap
        let nowIndex = Int(nowOffset.x / itemWidth)
        guard itemWidth > 0 else { return nowIndex }
        return (nowIndex + 1)
    }
    
    fileprivate func scrollToMiddle() {
        if viewDataSource.count < 2 || !self.infinityScrolling { return }
        self.collectionView.scrollToItem(at: IndexPath(item: 5000, section: 0), at: .left, animated: false)
    }
    
}

extension DynamicCycleScrollView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (viewCount == 1 || !self.infinityScrolling) ? viewCount : viewCount * 10000
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DynamicCycleScrollViewCell", for: indexPath) as! DynamicCycleScrollViewCell
        let view = viewDataSource[indexPath.row % viewCount]
        for subview in cell.subviews {
            subview.removeFromSuperview()
        }
        cell.insertRootView(view, edges: self.edges)
        return cell
    }
}

extension DynamicCycleScrollView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.clickBlock?(indexPath.row % self.viewCount)
    }
}
