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

import UIKit

/// Custom `UICollectionViewFlowLayout` that provides the flowlayout information like paging and `CardCell` movements.
internal class VerticalCardSwiperFlowLayout: UICollectionViewFlowLayout {

    public var widthOffset: CGFloat = 35
    public var heightOffset: CGFloat = 35
    private var contentWidth: CGFloat!
    private var contentHeight: CGFloat!
    private var yOffset: CGFloat = 0
    private var maxAlpha: CGFloat = 1
    private var minAlpha: CGFloat = 0

    private var cache: [UICollectionViewLayoutAttributes] = []
    var numberOfItems: Int {
        guard let _collectionView = collectionView, _collectionView.numberOfSections > 0, let item = collectionView?.numberOfItems(inSection: 0) else {
            return 0
        }
        return item
    }

    private var itemWidth: CGFloat {
        return self.collectionViewWidth
    }
    private var itemHeight: CGFloat {
        return self.collectionViewHeight
    }
    private var collectionViewHeight: CGFloat {
        return (collectionView?.bounds.height) ?? 0.0
    }
    private var collectionViewWidth: CGFloat {
        return (collectionView?.bounds.width) ?? 0.0
    }
    private var collectionViewYOffset: CGFloat {
        return self.collectionView?.contentOffset.y ?? 0.0
    }
    private var collectionViewXOffset: CGFloat {
        return self.collectionView?.contentOffset.x ?? 0.0
    }
    private var currentItemIndex: Int {
        return max(0, Int(self.collectionViewYOffset / self.collectionViewHeight))
    }
    private var dragOffset: CGFloat {
        return self.collectionViewHeight
    }
    var nextItemBecomeCurrentPercentage: CGFloat {
        return (self.collectionViewYOffset / self.collectionViewHeight) - CGFloat(currentItemIndex)
    }
    override func prepare() {
        super.prepare()
        self.cache.removeAll(keepingCapacity: true)
        self.yOffset = 0
        self.setAttributes()
    }
    /// Customize the attribute
    private func setAttributes() {
        if self.numberOfItems == 0 {
            return
        }
        var collectionViewCenterYOffset: CGFloat {
            return collectionView?.center.y ?? 0
        }
        var collectionViewCenterXOffset: CGFloat {
            return collectionView?.center.x ?? 0
        }
        for item in 0..<self.numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attribute.zIndex = -indexPath.item

            if (indexPath.item == self.currentItemIndex + 1) && (indexPath.item < self.numberOfItems) {
                attribute.alpha = self.minAlpha + max((self.maxAlpha - self.minAlpha) * self.nextItemBecomeCurrentPercentage, 0)
                let width = self.itemWidth - self.widthOffset + (self.widthOffset * self.nextItemBecomeCurrentPercentage)
                let height = self.itemHeight - self.heightOffset + (self.heightOffset * self.nextItemBecomeCurrentPercentage)

                let deltaWidth = width / self.itemWidth
                let deltaHeight = height / self.itemHeight

                attribute.frame = CGRect.init(x: 0, y: self.yOffset, width: self.itemWidth, height: self.itemHeight)
                attribute.transform = CGAffineTransform(scaleX: deltaWidth, y: deltaHeight)

                attribute.center.y = collectionViewCenterYOffset + self.collectionViewYOffset
                attribute.center.x = collectionViewCenterXOffset + self.collectionViewXOffset
                self.yOffset += self.collectionViewHeight

            } else {
                attribute.frame = CGRect.init(x: 0, y: self.yOffset, width: self.itemWidth, height: self.itemHeight)
                attribute.center.y = collectionViewCenterYOffset + yOffset
                attribute.center.x = collectionViewCenterXOffset
                yOffset += collectionViewHeight
            }
            cache.append(attribute)
        }
    }

    /// Return the size of ContentView
    override var collectionViewContentSize: CGSize {
        contentWidth = self.collectionViewWidth
        contentHeight = (self.collectionViewHeight * CGFloat(self.numberOfItems))
        return CGSize.init(width: self.contentWidth, height: contentHeight)
    }

    /// Return Attributes whose frame lies in the Visible Rect
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var layoutAttributes: [UICollectionViewLayoutAttributes] = []
        self.cache.forEach { (attribute) in
            if attribute.frame.intersects(rect) {
                layoutAttributes.append(attribute)
            }
        }
        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    /// Set ContentOffset
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let itemIndex = round(proposedContentOffset.y / (self.dragOffset))
        let yOffset = itemIndex * self.collectionViewHeight
        return CGPoint(x: 0, y: yOffset)
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return UICollectionViewLayoutAttributes(forCellWith: indexPath)
    }

}
