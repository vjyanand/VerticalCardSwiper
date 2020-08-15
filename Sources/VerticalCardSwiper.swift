// MIT License
//
// Copyright (c) 2017 Joni Van Roost
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit

/**
 The VerticalCardSwiper is a subclass of `UIView` that has a `VerticalCardSwiperView` embedded.
 
 To use this, you need to implement the `VerticalCardSwiperDatasource`.
 
 If you want to handle actions like cards being swiped away, implement the `VerticalCardSwiperDelegate`.
 */
public class VerticalCardSwiper: UIView {

    /// The collectionView where all the magic happens.
    public var verticalCardSwiperView: VerticalCardSwiperView!

    /**
     Returns an array of indexes (as Int) that are currently visible in the `VerticalCardSwiperView`.
     This includes cards that are stacked (behind the focussed card).
     */
    public var indexesForVisibleCards: [Int] {
        var indexes: [Int] = []
        // Add each visible cell except the lowest one and return
        for cellIndexPath in self.verticalCardSwiperView.indexPathsForVisibleItems {
            indexes.append(cellIndexPath.row)
        }
        return indexes.sorted()
    }
    /// The currently focussed card index.
    public var focussedCardIndex: Int? {
        let center = self.convert(self.verticalCardSwiperView.center, to: self.verticalCardSwiperView)
        if let indexPath = self.verticalCardSwiperView.indexPathForItem(at: center) {
            return indexPath.row
        }
        return nil
    }

    public weak var delegate: VerticalCardSwiperDelegate?
    public weak var datasource: VerticalCardSwiperDatasource?
    
    /// The flowlayout used in the collectionView.
    fileprivate lazy var flowLayout: VerticalCardSwiperFlowLayout = {
        let flowLayout = VerticalCardSwiperFlowLayout()
        flowLayout.minimumLineSpacing = 0
        return flowLayout
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.verticalCardSwiperView.delegate = self
    }

    /**
     Inserts new cards at the specified indexes.

     Call this method to insert one or more new cards into the cardSwiper.
     You might do this when your data source object receives data for new items or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to insert the new card. This parameter must not be nil.
     */
    public func insertCards(at indexes: [Int]) {
        performUpdates {
            self.verticalCardSwiperView.insertItems(at: indexes.map { (index) -> IndexPath in
                return convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Deletes cards at the specified indexes.

     Call this method to delete one or more new cards from the cardSwiper.
     You might do this when you remove the items from your data source object or in response to user interactions with the cardSwiper.
     - parameter indexes: An array of integers at which to delete the card. This parameter must not be nil.
     */
    public func deleteCards(at indexes: [Int]) {
        performUpdates {
            self.verticalCardSwiperView.deleteItems(at: indexes.map { (index) -> IndexPath in
                return self.convertIndexToIndexPath(for: index)
            })
        }
    }

    /**
     Moves an item from one location to another in the collection view.

     Use this method to reorganize existing cards. You might do this when you rearrange the items within your data source object or in response to user interactions with the cardSwiper. The cardSwiper updates the layout as needed to account for the move, animating cards into position as needed.

     - parameter atIndex: The index of the card you want to move. This parameter must not be nil.
     - parameter toIndex: The index of the card’s new location. This parameter must not be nil.
     */
    public func moveCard(at atIndex: Int, to toIndex: Int) {
        self.verticalCardSwiperView.moveItem(at: convertIndexToIndexPath(for: atIndex), to: convertIndexToIndexPath(for: toIndex))
    }

    /**
     Returns the visible card object at the specified index.
     - parameter index: The index that specifies the item number of the cell.
     - returns: The card object at the corresponding index or nil if the cell is not visible or index is out of range.
     */
    public func cardForItem(at index: Int) -> CardCell? {
        return self.verticalCardSwiperView.cellForItem(at: convertIndexToIndexPath(for: index)) as? CardCell
    }

    private func commonInit() {
        setupVerticalCardSwiperView()
        setupConstraints()
    }

    private func performUpdates(updateClosure: () -> Void) {
        UIView.performWithoutAnimation {
            self.verticalCardSwiperView.performBatchUpdates({
                updateClosure()
            }, completion: { [weak self] _ in
                self?.verticalCardSwiperView.collectionViewLayout.invalidateLayout()
            })
        }
    }
}

extension VerticalCardSwiper: UICollectionViewDelegate, UICollectionViewDataSource {

    /**
     Reloads all of the data for the VerticalCardSwiperView.
     
     Call this method sparingly when you need to reload all of the items in the VerticalCardSwiper. This causes the VerticalCardSwiperView to discard any currently visible items (including placeholders) and recreate items based on the current state of the data source object. For efficiency, the VerticalCardSwiperView only displays those cells and supplementary views that are visible. If the data shrinks as a result of the reload, the VerticalCardSwiperView adjusts its scrolling offsets accordingly.
     */
    public func reloadData() {
        verticalCardSwiperView.reloadData()
    }

    
    /**
     Scrolls the collection view contents until the specified item is visible.
     If you want to scroll to a specific card from the start, make sure to call this function in `viewDidLayoutSubviews`
     instead of functions like `viewDidLoad` as the underlying collectionView needs to be loaded first for this to work.
     - parameter index: The index of the item to scroll into view.
     - parameter animated: Specify true to animate the scrolling behavior or false to adjust the scroll view’s visible content immediately.
     - Returns: True if scrolling succeeds. False if scrolling failed.
     Scrolling could fail due to the flowlayout not being set up yet or an incorrect index.
     */
    public func scrollToCard(at index: Int, animated: Bool) -> Bool {

        /**
         scrollToItem & scrollRectToVisible were giving issues with reliable scrolling,
         so we're using setContentOffset for the time being.
         See: https://github.com/JoniVR/VerticalCardSwiper/issues/23
         */
        guard index >= 0,
            index < verticalCardSwiperView.numberOfItems(inSection: 0)
            else { return false }
        let y = CGFloat(index) * (self.bounds.size.height + flowLayout.minimumLineSpacing)
        let point = CGPoint(x: verticalCardSwiperView.contentOffset.x, y: y)
        verticalCardSwiperView.setContentOffset(point, animated: animated)
        return true
    }

    /**
     Register a class for use in creating new CardCells.
     Prior to calling the dequeueReusableCell(withReuseIdentifier:for:) method of the collection view,
     you must use this method or the register(_:forCellWithReuseIdentifier:) method
     to tell the collection view how to create a new cell of the given type.
     If a cell of the specified type is not currently in a reuse queue,
     the VerticalCardSwiper uses the provided information to create a new cell object automatically.
     If you previously registered a class or nib file with the same reuse identifier,
     the class you specify in the cellClass parameter replaces the old entry.
     You may specify nil for cellClass if you want to unregister the class from the specified reuse identifier.
     - parameter cellClass: The class of a cell that you want to use in the VerticalCardSwiper
     identifier
     - parameter identifier: The reuse identifier to associate with the specified class. This parameter must not be nil and must not be an empty string.
     */
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        self.verticalCardSwiperView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /**
     Register a nib file for use in creating new collection view cells.
     Prior to calling the dequeueReusableCell(withReuseIdentifier:for:) method of the collection view,
     you must use this method or the register(_:forCellWithReuseIdentifier:) method
     to tell the collection view how to create a new cell of the given type.
     If a cell of the specified type is not currently in a reuse queue,
     the collection view uses the provided information to create a new cell object automatically.
     If you previously registered a class or nib file with the same reuse identifier,
     the object you specify in the nib parameter replaces the old entry.
     You may specify nil for nib if you want to unregister the nib file from the specified reuse identifier.
     - parameter nib: The nib object containing the cell object. The nib file must contain only one top-level object and that object must be of the type UICollectionViewCell.
     identifier
     - parameter identifier: The reuse identifier to associate with the specified nib file. This parameter must not be nil and must not be an empty string.
     */
    public func register(nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        self.verticalCardSwiperView.register(nib, forCellWithReuseIdentifier: identifier)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasource?.numberOfCards(verticalCardSwiperView: verticalCardSwiperView) ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let card = datasource?.cardForItemAt(verticalCardSwiperView: verticalCardSwiperView, cardForItemAt: indexPath.row) {
            return card
        }
        return CardCell()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll?(verticalCardSwiperView: self.verticalCardSwiperView)
        
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
     
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.didEndScroll?(verticalCardSwiperView: verticalCardSwiperView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(verticalCardSwiperView: verticalCardSwiperView)
        
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.didEndScroll?(verticalCardSwiperView: verticalCardSwiperView)
    }
}

extension VerticalCardSwiper: UICollectionViewDelegateFlowLayout {

    fileprivate func setupVerticalCardSwiperView() {
        verticalCardSwiperView = VerticalCardSwiperView(frame: self.frame, collectionViewLayout: flowLayout)
        verticalCardSwiperView.decelerationRate = UIScrollView.DecelerationRate.fast
        verticalCardSwiperView.backgroundColor = UIColor.clear 
        verticalCardSwiperView.contentInsetAdjustmentBehavior = .never
        verticalCardSwiperView.showsVerticalScrollIndicator = false
        verticalCardSwiperView.dataSource = self
        self.addSubview(verticalCardSwiperView)
    }

    fileprivate func setupConstraints() {
        verticalCardSwiperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.verticalCardSwiperView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.verticalCardSwiperView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.verticalCardSwiperView.topAnchor.constraint(equalTo: self.topAnchor),
            self.verticalCardSwiperView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
