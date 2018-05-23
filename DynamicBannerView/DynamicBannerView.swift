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
        self.contentView.addSubview(target)
        let xC = NSLayoutConstraint(item: target, attribute: .centerX, relatedBy: .equal, toItem: self.contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let yC = NSLayoutConstraint(item: target, attribute: .width, relatedBy: .equal, toItem: self.contentView, attribute: .width, multiplier: 1.0, constant: 0.0)
        let wC = NSLayoutConstraint(item: target, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: edges.top)
        let hC = NSLayoutConstraint(item: target, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: -edges.bottom)
        self.contentView.addConstraints([xC, yC, wC, hC])
    }
}

private class DynamicCycleCollectionViewLayout: UICollectionViewLayout {
    
    internal let dynamicCycleScrollView: DynamicCycleScrollView
    
    init(cycleScrollView: DynamicCycleScrollView) {
        dynamicCycleScrollView = cycleScrollView
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    internal var needsReprepare = true
    
    internal var numberOfItems: Int {
        return dynamicCycleScrollView.viewCount
    }
    internal var actualInteritemSpacing: CGFloat {
        return dynamicCycleScrollView.cellGap
    }
    internal var minimumScale: CGFloat {
        return dynamicCycleScrollView.minimumScale
    }
    internal var leadingSpacing: CGFloat {
        return dynamicCycleScrollView.edges.left
    }
    internal var isInfinite: Bool {
        return dynamicCycleScrollView.infinityScrolling
    }
    internal var tailWidth: CGFloat {
        return dynamicCycleScrollView.tailWidth
    }
    internal var edges: UIEdgeInsets {
        return dynamicCycleScrollView.edges
    }
    internal var numberOfSections: Int {
        return dynamicCycleScrollView.numberOfSections
    }
    
    ///需prepare計算得知
    fileprivate var middleX: CGFloat = 0
    internal var contentSize: CGSize = .zero
    fileprivate var actualItemSize: CGSize = .zero
    internal var itemSpacing: CGFloat = 0
    fileprivate var collectionViewSize: CGSize = .zero
    
    override open func prepare() {
        guard let collectionView = self.collectionView else {
            return
        }
        guard self.needsReprepare || self.collectionViewSize != collectionView.frame.size else {
            return
        }
        self.needsReprepare = false
        self.collectionViewSize = collectionView.frame.size
        ///
        let viewCount = self.numberOfItems
        let frame = dynamicCycleScrollView.frame
        self.actualItemSize = {
            let realTailWidth = viewCount < 2 ? 0 : tailWidth
            let realCellGap = viewCount < 2 ? 0 : actualInteritemSpacing
            let width: CGFloat = viewCount < 2 ? (frame.width - edges.left - edges.right) : (frame.width - edges.left - realTailWidth - realCellGap)
            let height: CGFloat = collectionView.frame.height
            let size = CGSize(width: width <= 0 ? 10 : width, height: height <= 0 ? 10 : height)
            return size
        }()
        ///
        self.middleX = self.actualItemSize.width / 2
        ///
        self.itemSpacing = self.actualItemSize.width + self.actualInteritemSpacing
        // Calculate and cache contentSize, rather than calculating each time
        self.contentSize = {
            let numberOfItems = self.numberOfItems * self.numberOfSections
            var contentSizeWidth: CGFloat = self.leadingSpacing*2 // Leading & trailing spacing
            contentSizeWidth += CGFloat(numberOfItems-1)*self.actualInteritemSpacing // Interitem spacing
            contentSizeWidth += CGFloat(numberOfItems)*self.actualItemSize.width // Item sizes
            let contentSize = CGSize(width: contentSizeWidth, height: collectionView.frame.height)
            return contentSize
        }()
        self.adjustCollectionViewBounds()
    }
    
    override open var collectionViewContentSize: CGSize {
        return self.contentSize
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        guard self.itemSpacing > 0, !rect.isEmpty else {
            return layoutAttributes
        }
        let rect = rect.intersection(CGRect(origin: .zero, size: self.contentSize))
        guard !rect.isEmpty else {
            return layoutAttributes
        }
        // Calculate start position and index of certain rects
        let numberOfItemsBefore = max(Int((rect.minX-self.leadingSpacing)/self.itemSpacing),0)
        let startPosition = self.leadingSpacing + CGFloat(numberOfItemsBefore)*self.itemSpacing
        let startIndex = numberOfItemsBefore
        // Create layout attributes
        var itemIndex = startIndex
        
        var origin = startPosition
        let maxPosition = min(rect.maxX,self.contentSize.width-self.actualItemSize.width-self.leadingSpacing)
        while origin-maxPosition <= max(CGFloat(100.0) * .ulpOfOne * fabs(origin+maxPosition), .leastNonzeroMagnitude) {
            let indexPath = IndexPath(item: itemIndex%self.numberOfItems, section: itemIndex/self.numberOfItems)
            let attributes = self.layoutAttributesForItem(at: indexPath)
            self.applyTransform(to: attributes)
            layoutAttributes.append(attributes)
            itemIndex += 1
            origin += self.itemSpacing
        }
        return layoutAttributes
    }
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = self.frame(for: indexPath)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        attributes.center = center
        attributes.size = self.actualItemSize
        return attributes
    }
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return proposedContentOffset}
        let rect = CGRect(x: proposedContentOffset.x, y: 0, width: (collectionView.frame.width), height: (collectionView.frame.height))
        guard let attrs = self.layoutAttributesForElements(in: rect) else { return proposedContentOffset }
        // 计算CollectionView最中心点的x值 这里要求 最终的 要考虑惯性
        let centerX = (self.actualItemSize.width) / 2 + proposedContentOffset.x
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
    
    internal func forceInvalidate() {
        self.needsReprepare = true
        self.invalidateLayout()
    }
    
    internal func contentOffset(for indexPath: IndexPath) -> CGPoint {
        let origin = self.frame(for: indexPath).origin
        let contentOffset = CGPoint(x: origin.x, y: 0)
        return contentOffset
    }
    
    internal func frame(for indexPath: IndexPath) -> CGRect {
        let numberOfItems = self.numberOfItems*indexPath.section + indexPath.item
        let originX: CGFloat = {
            return self.leadingSpacing + CGFloat(numberOfItems) * self.itemSpacing
        }()
        let originY: CGFloat = {
            return (self.collectionView!.frame.height-self.actualItemSize.height)*0.5
        }()
        let origin = CGPoint(x: originX, y: originY)
        let frame = CGRect(origin: origin, size: self.actualItemSize)
        return frame
    }
    
    public func getNowIndexPath() -> IndexPath {
        guard let collectionView = self.collectionView else {
            return IndexPath(item: 0, section: 0)
        }
        let nowOffset = collectionView.contentOffset
        let currentIndex = Int(nowOffset.x / self.itemSpacing) % self.numberOfItems
        if currentIndex + 1 == self.numberOfItems {
            let currentSection = Int(nowOffset.x) / (Int(self.itemSpacing) * self.numberOfItems)
            let nowIndexPath = IndexPath(item: 0, section: currentSection + 1)
            return nowIndexPath
        } else {
            let currentSection = Int(nowOffset.x) / (Int(self.itemSpacing) * self.numberOfItems)
            let nowIndexPath = IndexPath(item: currentIndex + 1, section: currentSection)
            return nowIndexPath
        }
    }
    
    fileprivate func adjustCollectionViewBounds() {
        guard let collectionView = self.collectionView else {
            return
        }
        let currentIndexPath = IndexPath(item: 0, section: self.isInfinite ? self.numberOfSections/2 : 0)
        let contentOffset = self.contentOffset(for: currentIndexPath)
        let newBounds = CGRect(origin: contentOffset, size: collectionView.frame.size)
        collectionView.bounds = newBounds
    }
    
    fileprivate func applyTransform(to attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = self.collectionView else {
            return
        }
        let contentCenterX = collectionView.contentOffset.x + middleX
        var delta = CGFloat(abs(Int32(attributes.center.x - contentCenterX))) / (collectionView.frame.size.width * 2)
        delta = delta > 1 ? 1 : delta
        let yscale: CGFloat = delta > (1 - minimumScale) ? minimumScale : 1-delta
        let transform = CGAffineTransform(scaleX: 1, y: yscale)
        attributes.transform = transform
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
            collectionViewLayout.forceInvalidate()
        }
    }
    
    public var cellGap: CGFloat = 5 {
        didSet {
            collectionViewLayout.forceInvalidate()
        }
    }
    
    public var tailWidth: CGFloat = 10.0 {
        didSet {
            collectionViewLayout.forceInvalidate()
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
    
    ///是否無限輪播
    public var infinityScrolling: Bool = true {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    public var minimumScale: CGFloat = 0.85
    
    fileprivate var viewDataSource: [UIView] = []
    fileprivate var viewCount: Int {
        get {
            return viewDataSource.count
        }
    }
    
    fileprivate var numberOfSections: Int {
        if viewCount == 0 { return 1 }
        return self.infinityScrolling && (self.viewCount > 1) ? 100 : 1
    }
    
    public func setViews(_ views: [UIView]) {
        viewDataSource = views
        self.autoScrolling = views.count > 1
        self.collectionView.isScrollEnabled = views.count > 1
        self.collectionView.reloadData()
        self.layoutIfNeeded()
        self.collectionViewLayout.forceInvalidate()
    }
    
    public var clickBlock: ((Int) -> Void)?
    
    fileprivate var scrollTimer: Timer?
    ///防止下個Cell被釋放
    fileprivate var extraDisplayWidth: CGFloat = 20
    //
    fileprivate var collectionViewLayout: DynamicCycleCollectionViewLayout!
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
        fatalError()
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
    }
    
    private func commonInit() {
        collectionViewLayout = DynamicCycleCollectionViewLayout(cycleScrollView: self)
        initScrollView()
        self.clipsToBounds = false
        collectionViewLayout.actualItemSize = CGSize(width: 10, height: 10)
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
        let next = self.collectionViewLayout.getNowIndexPath()
        self.collectionView.scrollToItem(at: next, at: .left, animated: true)
    }
}

extension DynamicCycleScrollView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DynamicCycleScrollViewCell", for: indexPath) as! DynamicCycleScrollViewCell
        let view = viewDataSource[indexPath.row % viewCount]
        cell.insertRootView(view, edges: self.edges)
        return cell
    }
}

extension DynamicCycleScrollView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.clickBlock?(indexPath.row % self.viewCount)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollTimer?.invalidate()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollTimer = Timer(timeInterval: autoScrollInterval, target: self, selector: #selector(DynamicCycleScrollView.fireTimer(sender:)), userInfo: nil, repeats: true)
        RunLoop.current.add(scrollTimer!, forMode: .defaultRunLoopMode)
    }
}
