import Foundation


@objc public class ReplyTextView : UIView, UITextViewDelegate
{
    // MARK: - Initializers
    public convenience init(width: CGFloat) {
        let theFrame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.init(frame: theFrame)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    // MARK: - Public Properties
    public weak var delegate: UITextViewDelegate?
    
    public var proxyAccessoryAlpha: CGFloat {
        get {
            return proxyTextView.alpha
        }
        set {
            proxyTextView.alpha = newValue
        }
    }

    public var onReply: ((String) -> ())?
    
    public var placeholder: String! {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    public var replyText: String! {
        didSet {
            replyButton.setTitle(replyText, forState: .Normal)
        }
    }
    
    
    // MARK: - Public Helpers
    public func alignAtBottomOfSuperview() {
        if let theSuperview = superview {
            frame.origin.y = CGRectGetMaxY(theSuperview.bounds) - bounds.height
        }
    }
    
    public func setupProxyAccessoryView() {
        proxyTextView                   = ReplyTextView(width: bounds.width)
        textView.inputAccessoryView     = proxyTextView
        proxyTextView.placeholder       = placeholder
        proxyTextView.replyText         = replyText
        proxyTextView.delegate          = self
    }
    
    
    // MARK: - UITextViewDelegate Methods
    public func textViewShouldBeginEditing(textView: UITextView!) -> Bool {
        return delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    public func textViewDidBeginEditing(textView: UITextView!) {
        // If we have a Proxy Accessory View, forward the event!
        if proxyTextView != nil {
            textView.inputAccessoryView.becomeFirstResponder()
        } else {
            delegate?.textViewDidBeginEditing?(textView)
        }
    }
    
    public func textViewShouldEndEditing(textView: UITextView!) -> Bool {
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidEndEditing(textView: UITextView!) {
        delegate?.textViewDidEndEditing?(textView)
    }
    
    public func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        return delegate?.textView?(textView, shouldChangeTextInRange: range, replacementText: text) ?? true
    }

    public func textViewDidChange(textView: UITextView!) {
        refreshControls()
        resizeIfNeeded()
        scrollToCaretInTextView()
        
        delegate?.textViewDidChange?(textView)
    }
    
    public func textView(textView: UITextView!, shouldInteractWithURL URL: NSURL!, inRange characterRange: NSRange) -> Bool {
        return delegate?.textView?(textView, shouldInteractWithURL: URL, inRange: characterRange) ?? true
    }
    
    
    // MARK: - View Methods
    public override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        endEditing(true)
        return super.resignFirstResponder()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame.size.width  = self.bounds.width
    }
    
    
    // MARK: - Private Helpers
    private func resizeIfNeeded() {
        
        // Load the padding from the constraints themselves
        let topPadding      = textView.constraintForAttribute(.Top)     ?? textViewDefaultPadding
        let bottomPadding   = textView.constraintForAttribute(.Bottom)  ?? textViewDefaultPadding
        
        // Calculate the new height
        let textHeight      = floor(textView.contentSize.height + topPadding + bottomPadding)

        var newHeight       = min(max(textHeight, textViewMinHeight), textViewMaxHeight)
        let oldHeight       = frame.size.height

        if newHeight == oldHeight {
            return
        }

        frame.size.height   = newHeight
        frame.origin.y      += oldHeight - newHeight
    }
    
    private func scrollToCaretInTextView() {
        textView.layoutIfNeeded()
        
        var caretRect           = textView.caretRectForPosition(textView.selectedTextRange.start)
        caretRect               = CGRectIntegral(caretRect)
        
        textView.scrollRectToVisible(caretRect, animated: false)
    }
    
    private func setupView() {
        self.frame.size.height          = textViewMinHeight
        
        // Load the nib + add its container view
        bundle = NSBundle.mainBundle().loadNibNamed("ReplyTextView", owner: self, options: nil)
        addSubview(containerView)
        
        // We want this view to stick at the bottom
        contentMode                     = .BottomLeft
        autoresizingMask                = .FlexibleWidth | .FlexibleTopMargin
        containerView.autoresizingMask  = .FlexibleWidth | .FlexibleHeight
        
        // Setup the TextView
        textView.delegate               = self
        textView.scrollsToTop           = false
        textView.contentInset           = UIEdgeInsetsZero
        textView.textContainerInset     = UIEdgeInsetsZero
        textView.font                   = WPStyleGuide.Comments.Fonts.replyText
        textView.textColor              = WPStyleGuide.Comments.Colors.replyText
        textView.textContainer.lineFragmentPadding  = 0
        
        // Placeholder
        placeholderLabel.font           = WPStyleGuide.Comments.Fonts.replyText
        placeholderLabel.textColor      = WPStyleGuide.Comments.Colors.replySeparator
        
        // Reply
        replyButton.enabled             = false
        replyButton.titleLabel.font     = WPStyleGuide.Comments.Fonts.replyButton
        replyButton.setTitleColor(WPStyleGuide.Comments.Colors.replyDisabled, forState: .Disabled)
        replyButton.setTitleColor(WPStyleGuide.Comments.Colors.replyEnabled,  forState: .Normal)
        
        // Background
        layoutView.backgroundColor      = WPStyleGuide.Comments.Colors.replyBackground
    }
    
    private func refreshControls() {
        // [Show | Hide] placeholder + reply button, as needed
        let whitespaceCharSet       = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let shouldEnableReply       = textView.text.stringByTrimmingCharactersInSet(whitespaceCharSet).isEmpty == false
        let shouldHidePlaceholder   = !textView.text.isEmpty
        
        placeholderLabel.hidden     = shouldHidePlaceholder
        replyButton.enabled         = shouldEnableReply
    }

    @IBAction private func btnReplyPressed() {
        if let handler = onReply {
            handler(textView.text)
        }
    }
    
    
    // MARK: - Constants
    private let textViewDefaultPadding:     CGFloat         = 12
    private let textViewMaxHeight:          CGFloat         = 82   // Fits 3 lines onscreen
    private let textViewMinHeight:          CGFloat         = 44
    
    // MARK: - Private Properties
    private var bundle:                     NSArray?
    private var proxyTextView:              ReplyTextView!
    
    // MARK: - IBOutlets
    @IBOutlet private var textView:          UITextView!
    @IBOutlet private var placeholderLabel: UILabel!
    @IBOutlet private var replyButton:      UIButton!
    @IBOutlet private var layoutView:       UIView!
    @IBOutlet private var containerView:    UIView!
}
