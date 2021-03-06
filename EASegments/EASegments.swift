//
//  EASegments.swift
//  EASegments
//
//  Created by Elias Abel on 9/3/17.
//  Copyright © 2017 Meniny Lab. All rights reserved.
//

import UIKit

// MARK: - EASegmentsRoundedLayer

open class EASegmentsRoundedLayer: CALayer {
    override open var bounds: CGRect {
        didSet { cornerRadius = bounds.height / 2.0 }
    }
}

public protocol EASegmentsDelegate: class {
    func segments(_ segments: EASegments, didSelectAt index: Int)
}

// MARK: - EASegments

@IBDesignable
open class EASegments: UIControl {
    
    // MARK: - Public vars
    
    open var titles: [String] {
        set {
            (titleLabels + selectedTitleLabels).forEach { $0.removeFromSuperview() }
            titleLabels = newValue.map { title in
                let label = UILabel()
                label.text = title
                label.textColor = titleColor
                label.font = titleFont
                label.textAlignment = .center
                label.lineBreakMode = .byTruncatingTail
                titleLabelsContentView.addSubview(label)
                return label
            }
            selectedTitleLabels = newValue.map { title in
                let label = UILabel()
                label.text = title
                label.textColor = selectedTitleColor
                label.font = titleFont
                label.textAlignment = .center
                label.lineBreakMode = .byTruncatingTail
                selectedTitleLabelsContentView.addSubview(label)
                return label
            }
        }
        get { return titleLabels.map { $0.text! } }
    }
    
    open weak var delegate: EASegmentsDelegate?
    
    open fileprivate(set) var selectedIndex: Int = 0 {
        didSet {
            self.delegate?.segments(self, didSelectAt: self.selectedIndex)
        }
    }
    
    open var selectedTitle: String? {
        guard selectedIndex >= 0 && selectedIndex < titles.count else {
            return nil
        }
        return titles[selectedIndex]
    }
    
    open var selectedBackgroundInset: CGFloat = 2.0 {
        didSet { setNeedsLayout() }
    }
    
    @IBInspectable
    open var selectedBackgroundColor: UIColor! {
        set { selectedBackgroundView.backgroundColor = newValue }
        get { return selectedBackgroundView.backgroundColor }
    }
    
    @IBInspectable
    open var titleColor: UIColor! {
        didSet { titleLabels.forEach { $0.textColor = titleColor } }
    }
    
    @IBInspectable
    open var selectedTitleColor: UIColor! {
        didSet { selectedTitleLabels.forEach { $0.textColor = selectedTitleColor } }
    }
    
    open var titleFont: UIFont! {
        didSet { (titleLabels + selectedTitleLabels).forEach { $0.font = titleFont } }
    }
    
    @IBInspectable
    open var titleFontFamily: String = "HelveticaNeue"
    
    @IBInspectable
    open var titleFontSize: CGFloat = 18
    
    open var animationDuration: TimeInterval = 0.3
    open var animationSpringDamping: CGFloat = 0.75
    open var animationInitialSpringVelocity: CGFloat = 0
    
    // MARK: - Private vars
    
    open fileprivate(set) var titleLabelsContentView = UIView.init(frame: .zero)
    open fileprivate(set) var titleLabels = [UILabel]()
    
    open fileprivate(set) var selectedTitleLabelsContentView = UIView.init(frame: .zero)
    open fileprivate(set) var selectedTitleLabels = [UILabel]()
    
    open fileprivate(set) var selectedBackgroundView = UIView.init(frame: .zero)
    
    open fileprivate(set) var titleMaskView: UIView = UIView.init(frame: .zero)
    
    open fileprivate(set) var tapGesture: UITapGestureRecognizer!
    open fileprivate(set) var panGesture: UIPanGestureRecognizer!
    
    open fileprivate(set) var initialSelectedBackgroundViewFrame: CGRect?
    
    // MARK: - Constructors
    
    public convenience init(titles: String...) {
        self.init(titles: titles)
    }
    
    public init(titles: [String]) {
        super.init(frame: CGRect.zero)
        self.titles = titles
        finishInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInit()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        finishInit()
        backgroundColor = .black // don't set background color in finishInit(), otherwise IB settings which are applied in init?(coder:) are overwritten
    }
    
    fileprivate func finishInit() {
        // Setup views
        addSubview(titleLabelsContentView)
        
        object_setClass(selectedBackgroundView.layer, EASegmentsRoundedLayer.self)
        addSubview(selectedBackgroundView)
        
        addSubview(selectedTitleLabelsContentView)
        
        object_setClass(titleMaskView.layer, EASegmentsRoundedLayer.self)
        titleMaskView.backgroundColor = .black
        selectedTitleLabelsContentView.layer.mask = titleMaskView.layer
        
//        if #available(iOS 9.0, *) {
//            titleMaskView.leftAnchor.constraint(equalTo: selectedBackgroundView.leftAnchor)
//            titleMaskView.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor)
//            titleMaskView.widthAnchor.constraint(equalTo: selectedBackgroundView.widthAnchor)
//            titleMaskView.heightAnchor.constraint(equalTo: selectedBackgroundView.heightAnchor)
//        }
        
        // Setup defaul colors
        if backgroundColor == nil {
            backgroundColor = .black
        }
        
        selectedBackgroundColor = .white
        titleColor = .white
        selectedTitleColor = .black
      
        // Gestures
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        selectedBackgroundView.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.titleFont = UIFont(name: self.titleFontFamily, size: self.titleFontSize)
    }
    
    // MARK: - Destructor
    
    deinit {
        selectedBackgroundView.removeObserver(self, forKeyPath: "frame")
    }
    
    // MARK: - Observer
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            titleMaskView.frame = selectedBackgroundView.frame
        }
    }
    
    // MARK: -
    
    override open class var layerClass : AnyClass {
        return EASegmentsRoundedLayer.self
    }
    
    @objc func tapped(_ gesture: UITapGestureRecognizer!) {
        let location = gesture.location(in: self)
        let index = Int(location.x / (bounds.width / CGFloat(titleLabels.count)))
        setSelectedIndex(index, animated: true)
    }
    
    @objc func pan(_ gesture: UIPanGestureRecognizer!) {
        if gesture.state == .began {
            initialSelectedBackgroundViewFrame = selectedBackgroundView.frame
        } else if gesture.state == .changed {
            var frame = initialSelectedBackgroundViewFrame!
            frame.origin.x += gesture.translation(in: self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - selectedBackgroundInset - frame.width), selectedBackgroundInset)
            selectedBackgroundView.frame = frame
        } else if gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled {
            let index = max(0, min(titleLabels.count - 1, Int(selectedBackgroundView.center.x / (bounds.width / CGFloat(titleLabels.count)))))
            setSelectedIndex(index, animated: true)
        }
    }
    
    open func setSelectedIndex(_ selectedIndex: Int, animated: Bool) {
        guard 0..<titleLabels.count ~= selectedIndex else { return }
        
        // Reset switch on half pan gestures
        var catchHalfSwitch = false
        if self.selectedIndex == selectedIndex {
            catchHalfSwitch = true
        }
        
        self.selectedIndex = selectedIndex
        if animated {
            if (!catchHalfSwitch) {
                self.sendActions(for: .valueChanged)
            }
            UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationSpringDamping, initialSpringVelocity: animationInitialSpringVelocity, options: [UIViewAnimationOptions.beginFromCurrentState, UIViewAnimationOptions.curveEaseOut], animations: { () -> Void in
                self.layoutSubviews()
                }, completion: nil)
        } else {
            layoutSubviews()
            sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Layout
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let selectedBackgroundWidth = bounds.width / CGFloat(titleLabels.count) - selectedBackgroundInset * 2.0
        selectedBackgroundView.frame = CGRect(x: selectedBackgroundInset + CGFloat(selectedIndex) * (selectedBackgroundWidth + selectedBackgroundInset * 2.0), y: selectedBackgroundInset, width: selectedBackgroundWidth, height: bounds.height - selectedBackgroundInset * 2.0)
        
        (titleLabelsContentView.frame, selectedTitleLabelsContentView.frame) = (bounds, bounds)
        
        let titleLabelMaxWidth = selectedBackgroundWidth
        let titleLabelMaxHeight = bounds.height - selectedBackgroundInset * 2.0
        
        zip(titleLabels, selectedTitleLabels).forEach { label, selectedLabel in
            let index = titleLabels.index(of: label)!
            
            var size = label.sizeThatFits(CGSize(width: titleLabelMaxWidth, height: titleLabelMaxHeight))
            size.width = min(size.width, titleLabelMaxWidth)
          
            let x = floor((bounds.width / CGFloat(titleLabels.count)) * CGFloat(index) + (bounds.width / CGFloat(titleLabels.count) - size.width) / 2.0)
            let y = floor((bounds.height - size.height) / 2.0)
            let origin = CGPoint(x: x, y: y)
            
            let frame = CGRect(origin: origin, size: size)
            label.frame = frame
            selectedLabel.frame = frame
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension EASegments: UIGestureRecognizerDelegate {
    
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            return selectedBackgroundView.frame.contains(gestureRecognizer.location(in: self))
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension EASegments {
    
    public struct Appearance: Equatable {
        public var backgroundColor: UIColor
        public var selectedBackgroundColor: UIColor
        
        public var titleColor: UIColor
        public var selectedTitleColor: UIColor
        
        public var font: UIFont
        
        public init(backgroundColor: UIColor,
                    selected selectedBackgroundColor: UIColor,
                    titleColor: UIColor,
                    selected selectedTitleColor: UIColor,
                    font: UIFont) {
            self.backgroundColor = backgroundColor
            self.selectedBackgroundColor = selectedBackgroundColor
            self.titleColor = titleColor
            self.selectedTitleColor = selectedTitleColor
            self.font = font
        }
        
        private static let defaultFont: UIFont = UIFont.systemFont(ofSize: 16)
        private static let defaultBackground: UIColor = #colorLiteral(red: 0.92, green: 0.38, blue: 0.25, alpha: 1.00)
        private static let defaultForeground: UIColor = UIColor.white
        
        public static var `default`: Appearance = {
            return Appearance.init(backgroundColor: Appearance.defaultBackground,
                                   selected: Appearance.defaultForeground,
                                   titleColor: Appearance.defaultForeground,
                                   selected: Appearance.defaultBackground,
                                   font: Appearance.defaultFont)
        }()
    }
    
    public convenience init(titles: [String],
                            delegate: EASegmentsDelegate?,
                            appearance: Appearance = .default) {
        self.init(titles: titles)
        self.delegate = delegate
        self.backgroundColor = appearance.backgroundColor
        self.selectedBackgroundColor = appearance.selectedBackgroundColor
        self.titleColor = appearance.titleColor
        self.selectedTitleColor = appearance.selectedTitleColor
        self.titleFont = appearance.font
    }
}
