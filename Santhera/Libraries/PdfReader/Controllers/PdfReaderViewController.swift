//
//  PdfReaderViewController.swift
//  zentiva
//
//  Created by james on 12/04/2018.
//  Copyright © 2018 james. All rights reserved.
//

import UIKit
import PDFKit
import MessageUI
import UIKit.UIGestureRecognizerSubclass

class PdfReaderViewController: UIViewController, UIPopoverPresentationControllerDelegate, PDFViewDelegate, ActionMenuViewControllerDelegate, SearchViewControllerDelegate, ThumbnailGridViewControllerDelegate, OutlineViewControllerDelegate, BookmarkViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    var pdfDocument: PDFDocument?
    var isShareable = true
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailViewContainer: UIView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet private weak var pdfThumbnailViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelContainer: UIView!
    @IBOutlet weak var pageNumberLabel: UILabel!
    @IBOutlet weak var pageNumberLabelContainer: UIView!
    
    let tableOfContentsToggleSegmentedControl = UISegmentedControl(items: [#imageLiteral(resourceName: "Grid"), #imageLiteral(resourceName: "List"), #imageLiteral(resourceName: "Bookmark-N")])
    @IBOutlet weak var thumbnailGridViewConainer: UIView!
    @IBOutlet weak var outlineViewConainer: UIView!
    @IBOutlet weak var bookmarkViewConainer: UIView!
    
    var bookmarkButton: UIBarButtonItem!
    
    var searchNavigationController: UINavigationController?
    
    let barHideOnTapGestureRecognizer = UITapGestureRecognizer()
    let pdfViewGestureRecognizer = PDFViewGestureRecognizer()

    //MARK: - UIPopoverPresentationControllerDelegate
     public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        print("popoverPresentationControllerShouldDismissPopover")
        return true
    }
     public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController){
        print("popoverPresentationControllerDidDismissPopover")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
       // pdfDocument = PDFDocument.init(url: url!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged(_:)), name: .PDFViewPageChanged, object: nil)
        
        barHideOnTapGestureRecognizer.addTarget(self, action: #selector(gestureRecognizedToggleVisibility(_:)))
        view.addGestureRecognizer(barHideOnTapGestureRecognizer)
        
        tableOfContentsToggleSegmentedControl.selectedSegmentIndex = 0
        tableOfContentsToggleSegmentedControl.addTarget(self, action: #selector(toggleTableOfContentsView(_:)), for: .valueChanged)
        
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        //pdfView.displaysAsBook = true
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: [UIPageViewControllerOptionInterPageSpacingKey: 20])
        pdfView.addGestureRecognizer(pdfViewGestureRecognizer)
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        //pdfView.maxScaleFactor = 4.0
        //pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        //pdfView.zoomIn(self)
        
        pdfThumbnailView.layoutMode = .horizontal
        pdfThumbnailView.pdfView = pdfView
        
        titleLabel.text = pdfDocument?.documentAttributes?["Title"] as? String
        titleLabelContainer.layer.cornerRadius = 4
        pageNumberLabelContainer.layer.cornerRadius = 4
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        resume()
    }
    
   
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        adjustThumbnailViewHeight()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.adjustThumbnailViewHeight()
        }, completion: nil)
    }
    
    private func adjustThumbnailViewHeight() {
        self.pdfThumbnailViewHeightConstraint.constant = 44 + self.view.safeAreaInsets.bottom
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ThumbnailGridViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? OutlineViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? BookmarkViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    //MARK: - Share and print
    
    func actionMenuViewControllerShareDocument(_ actionMenuViewController: ActionMenuViewController) {
        
    }
    
    func sharebyEmail(){
       
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            
           return
        }
       
       let  mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        if let lastPathComponent = pdfDocument?.documentURL?.lastPathComponent,
            let documentAttributes = pdfDocument?.documentAttributes,
            let attachmentData = pdfDocument?.dataRepresentation() {
            if let title = documentAttributes["Title"] as? String {
                mailComposeViewController.setSubject(title)
            }
            mailComposeViewController.addAttachmentData(attachmentData, mimeType: "application/pdf", fileName: lastPathComponent)
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
        
    }
    func actionMenuViewControllerPrintDocument(_ actionMenuViewController: ActionMenuViewController) {
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printingItem = pdfDocument?.dataRepresentation()
        printInteractionController.present(animated: true, completionHandler: nil)
    }
    //MARK:  mailComposeControllerDelagate
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?){
        controller.dismiss(animated: true, completion: nil)
        
    }
  
    func searchViewController(_ searchViewController: PdfSearchViewController, didSelectSearchResult selection: PDFSelection) {
        selection.color = .yellow
        pdfView.currentSelection = selection
        pdfView.go(to: selection)
        showBars()
    }
    
    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage) {
        resume()
        pdfView.go(to: page)
    }
    
    func outlineViewController(_ outlineViewController: OutlineViewController, didSelectOutlineAt destination: PDFDestination) {
        resume()
        pdfView.go(to: destination)
    }
    
    func bookmarkViewController(_ bookmarkViewController: BookmarkViewController, didSelectPage page: PDFPage) {
        resume()
        pdfView.go(to: page)
    }
    
    private func resume() {
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Chevron"), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "List"), style: .plain, target: self, action: #selector(showTableOfContents(_:)))
       
        navigationItem.leftBarButtonItems = [backButton, tableOfContentsButton]
        
        //let brightnessButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Brightness"), style: .plain, target: self, action: #selector(showAppearanceMenu(_:)))
        let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Search"), style: .plain, target: self, action: #selector(showSearchView(_:)))
         let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showActionMenu(_:)))
        bookmarkButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Bookmark-N"), style: .plain, target: self, action: #selector(addOrRemoveBookmark(_:)))
        navigationItem.rightBarButtonItems = [bookmarkButton, searchButton]
        if isShareable {
         navigationItem.rightBarButtonItems?.append(actionButton)
        }
        
        pdfThumbnailViewContainer.alpha = 1
        
        pdfView.isHidden = false
        titleLabelContainer.alpha = 1
        pageNumberLabelContainer.alpha = 1
        thumbnailGridViewConainer.isHidden = true
        outlineViewConainer.isHidden = true
        
        barHideOnTapGestureRecognizer.isEnabled = true
        
        updateBookmarkStatus()
        updatePageNumberLabel()
    }
    
    private func showTableOfContents() {
       // view.exchangeSubview(at: 0, withSubviewAt: 1)
       // view.exchangeSubview(at: 0, withSubviewAt: 2)
        thumbnailGridViewConainer.isHidden = true
        pdfView.isHidden = true
        outlineViewConainer.isHidden = false
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Chevron"), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsToggleBarButton = UIBarButtonItem(customView: tableOfContentsToggleSegmentedControl)
        let resumeBarButton = UIBarButtonItem(title: NSLocalizedString("Resume", comment: ""), style: .plain, target: self, action: #selector(resume(_:)))
        navigationItem.leftBarButtonItems = [backButton, tableOfContentsToggleBarButton]
        navigationItem.rightBarButtonItems = [resumeBarButton]
        
        pdfThumbnailViewContainer.alpha = 0
        
        toggleTableOfContentsView(tableOfContentsToggleSegmentedControl)
        
        barHideOnTapGestureRecognizer.isEnabled = false
    }
    
    @objc func resume(_ sender: UIBarButtonItem) {
        resume()
    }
    
    @objc func back(_ sender: UIBarButtonItem) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.popViewController(animated: true)
    }
    
    @objc func showTableOfContents(_ sender: UIBarButtonItem) {
        showTableOfContents()
    }
    
    @objc func showActionMenu(_ sender: UIBarButtonItem) {
        self.sharebyEmail()
       /* let storyBoard : UIStoryboard = UIStoryboard(name: "PdfReader", bundle:nil)
        if let viewController = storyBoard.instantiateViewController(withIdentifier: String(describing: ActionMenuViewController.self)) as? ActionMenuViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 88)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            viewController.delegate = self
            present(viewController, animated: true, completion: nil)
        }*/
    }
    
    @objc func showAppearanceMenu(_ sender: UIBarButtonItem) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "PdfReader", bundle:nil)
        if let viewController = storyBoard.instantiateViewController(withIdentifier: String(describing: AppearanceViewController.self)) as? AppearanceViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 44)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }
    //MARK: - showSearchView
    @objc func showSearchView(_ sender: UIBarButtonItem) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "PdfReader", bundle:nil)
        if let searchNavigationController = self.searchNavigationController {
            searchNavigationController.modalPresentationStyle = .popover
            searchNavigationController.popoverPresentationController?.barButtonItem  = sender
            present(searchNavigationController, animated: true, completion: nil)
        } else if let navigationControllerSearch = storyBoard.instantiateViewController(withIdentifier:"PdfSearchNC") as? UINavigationController,
            let searchViewController = navigationControllerSearch.topViewController as? PdfSearchViewController {
            searchViewController.pdfDocument = pdfDocument
            searchViewController.delegate = self
            navigationControllerSearch.modalPresentationStyle = .popover
            navigationControllerSearch.popoverPresentationController?.barButtonItem  = sender
            navigationControllerSearch.popoverPresentationController?.permittedArrowDirections = .any
            present(navigationControllerSearch, animated: true, completion: nil)
            navigationControllerSearch.popoverPresentationController?.delegate = self
           searchNavigationController = navigationControllerSearch
            
        }
    }
    
    @objc func addOrRemoveBookmark(_ sender: UIBarButtonItem) {
        if let documentURL = pdfDocument?.documentURL?.absoluteString {
            var bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int] ?? [Int]()
            if let currentPage = pdfView.currentPage,
                let pageIndex = pdfDocument?.index(for: currentPage) {
                if let index = bookmarks.index(of: pageIndex) {
                    bookmarks.remove(at: index)
                    UserDefaults.standard.set(bookmarks, forKey: documentURL)
                    bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-N")
                    UserDefaults.standard.synchronize()
                } else {
                    UserDefaults.standard.set((bookmarks + [pageIndex]).sorted(), forKey: documentURL)
                    bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-P")
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    @objc func toggleTableOfContentsView(_ sender: UISegmentedControl) {
        pdfView.isHidden = true
        titleLabelContainer.alpha = 0
        pageNumberLabelContainer.alpha = 0
        
        if tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 0 {
            thumbnailGridViewConainer.isHidden = false
            outlineViewConainer.isHidden = true
            bookmarkViewConainer.isHidden = true
        } else if tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 1 {
            thumbnailGridViewConainer.isHidden = true
            outlineViewConainer.isHidden = false
            bookmarkViewConainer.isHidden = true
        } else {
            thumbnailGridViewConainer.isHidden = true
            outlineViewConainer.isHidden = true
            bookmarkViewConainer.isHidden = false
        }
    }
    
    @objc func pdfViewPageChanged(_ notification: Notification) {
        if pdfViewGestureRecognizer.isTracking {
            hideBars()
        }
        updateBookmarkStatus()
        updatePageNumberLabel()
    }
    
    @objc func gestureRecognizedToggleVisibility(_ gestureRecognizer: UITapGestureRecognizer) {
        if let navigationController = navigationController {
            if navigationController.navigationBar.alpha > 0 {
                hideBars()
            } else {
                showBars()
            }
        }
    }
    
    private func updateBookmarkStatus() {
        if let documentURL = pdfDocument?.documentURL?.absoluteString,
            let bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int],
            let currentPage = pdfView.currentPage,
            let index = pdfDocument?.index(for: currentPage) {
            if bookmarkButton != nil {
                bookmarkButton.image = bookmarks.contains(index) ? #imageLiteral(resourceName: "Bookmark-P") : #imageLiteral(resourceName: "Bookmark-N")
            }
        }
    }
    
    private func updatePageNumberLabel() {
        if let currentPage = pdfView.currentPage, let index = pdfDocument?.index(for: currentPage), let pageCount = pdfDocument?.pageCount {
            pageNumberLabel.text = String(format: "%d/%d", index + 1, pageCount)
        } else {
            pageNumberLabel.text = nil
        }
    }
    
    private func showBars() {
        if let navigationController = navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                navigationController.setNavigationBarHidden(false, animated: true)
                //navigationController.navigationBar.isHidden = false
                navigationController.navigationBar.alpha = 1
                self.pdfThumbnailViewContainer.alpha = 1
                self.titleLabelContainer.alpha = 1
                self.pageNumberLabelContainer.alpha = 1
            }
        }
    }
    
    private func hideBars() {
        if let navigationController = navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                navigationController.setNavigationBarHidden(true, animated: true)
                // navigationController.navigationBar.isHidden = true
                navigationController.navigationBar.alpha = 0
                self.pdfThumbnailViewContainer.alpha = 0
                self.titleLabelContainer.alpha = 0
                self.pageNumberLabelContainer.alpha = 0
            }
        }
    }
}

class PDFViewGestureRecognizer: UIGestureRecognizer {
    var isTracking = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }
}

