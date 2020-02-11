import Foundation
import UIKit
import Display
//import LegacyUI
import TelegramPresentationData
import SwiftSignalKit
import AccountContext

final class TopChatsController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    
    private let context: AccountContext
    
    var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    var dismiss: (() -> Void)?
    
    var tableView: UITableView = UITableView()
    let animals = ["Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 ", "Nicegram 🇷🇺", "Nicegram 🇬🇧", "Nicegram 🇨🇳 🇹🇼", "Nicegram 🇮🇹", "Nicegram 🇮🇷 🇪🇸 🇹🇷 "]
    let cellReuseIdentifier = "TopChatsCell"

    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(nibName: nil, bundle: nil)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        

        self.view.addSubview(self.tableView)
        self.tableView.frame = self.view.bounds
        self.tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
        self.tableView.separatorColor = self.presentationData.theme.chatList.itemSeparatorColor

    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return animals.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! UITableViewCell

        cell.textLabel?.text = animals[indexPath.row]
        cell.textLabel?.textColor = self.presentationData.theme.chatList.titleColor
        cell.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
        let view = UIView()
        view.backgroundColor = self.presentationData.theme.chatList.itemSelectedBackgroundColor
        cell.selectedBackgroundView = view

        return cell
    }
    
    private func updateThemeAndStrings() {
        //self.title = self.presentationData.strings.Settings_AppLanguage
        //self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        if self.isViewLoaded {
            self.tableView.backgroundColor = self.presentationData.theme.chatList.pinnedItemBackgroundColor
            self.tableView.separatorColor = self.presentationData.theme.chatList.itemSeparatorColor
            self.tableView.reloadData()
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        self.context.sharedContext.applicationBindings.openUrl("https://t.me/nicegramchat")
//        self.context.sharedContext.openExternalUrl(context: self.context, urlContext: .generic, url: "https://t.me/nicegramchat", forceExternal: true, presentationData: self.presentationData, navigationController: nil, dismissInput: {})
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func cancelPressed() {
        self.dismiss?()
    }
    
}

//public func getTopChatsController(/*context: AccountContext? = nil,*/ theme: PresentationTheme? = nil, strings: PresentationStrings? = nil, initialLayout: ContainerViewLayout? = nil) -> ViewController {
//    let nativeController = TopChatsController()
//    var finalLayout: ContainerViewLayout? = nil
//
//    if let strongInitialLayout = initialLayout {
//        finalLayout = strongInitialLayout
//    } else {
////        let statusBarHost = MonkeyApplicationStatusBarHost()
////        let (window, hostView) = nativeWindowHostView()
////        let window1 = Window1(hostView: hostView, statusBarHost: statusBarHost)
////        finalLayout = ContainerViewLayout(size: nativeController.view.bounds.size, metrics: LayoutMetrics(), deviceMetrics: window1.deviceMetrics, intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, inputHeightIsInteractivellyChanging: false, inVoiceOver: false)
//    }
//    nativeController.edgesForExtendedLayout = []
//
//    let viewController = convertController(controller: nativeController, theme: theme, strings: strings, initialLayout: finalLayout)
//    viewController.tabBarItem.image = UIImage(bundleImageName: "Chat List/Tabs/IconChats")
////    viewController.setNavigationBarHidden(true, animated: false)
////    viewController.navigationBar.transform = CGAffineTransform(translationX: -1000.0, y: 0.0)
//
//    return viewController
//}


final class TopChatsControllerNode: ASDisplayNode {
    var dismiss: (() -> Void)?
    
    override init() {
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = UIColor.white
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
//        var tabBarHeight: CGFloat
//        var options: ContainerViewLayoutInsetOptions = []
//        if layout.metrics.widthClass == .regular {
//            options.insert(.input)
//        }
//        let bottomInset: CGFloat = layout.insets(options: options).bottom
//        if !layout.safeInsets.left.isZero {
//            tabBarHeight = 34.0 + bottomInset
//        } else {
//            tabBarHeight = 49.0 + bottomInset
//        }
//
//        let tabBarFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - tabBarHeight), size: CGSize(width: layout.size.width, height: tabBarHeight))
//
//        print("FRAME", tabBarFrame)
//
//        self.bounds = CGRect(x: 0.0, y: 0.0, width: layout.size.width, height: layout.size.height)
//        self.position =  CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0)
    }
    
//    func animateIn() {
//        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
//    }
//
//    func animateOut() {
//        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, completion: { [weak self] _ in
//            if let strongSelf = self {
//                strongSelf.dismiss?()
//            }
//        })
//    }
}


public class TopChatsViewController: ViewController {
    private var controllerNode: TopChatsControllerNode {
        return self.displayNode as! TopChatsControllerNode
    }
    
    private let innerNavigationController: UINavigationController
    private let innerController: TopChatsController
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    public init(context: AccountContext) {
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        self.innerController = TopChatsController(context: context)
        self.innerNavigationController = UINavigationController(rootViewController: self.innerController)
        
        super.init(navigationBarPresentationData: nil)
        
        let title = "Top Chats"
        
        self.tabBarItem.image = UIImage(bundleImageName: "Chat/Input/Media/TrendingIcon")
        self.tabBarItem.title = title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.innerNavigationController.navigationBar.barTintColor = self.presentationData.theme.rootController.navigationBar.backgroundColor
        self.innerNavigationController.navigationBar.tintColor = self.presentationData.theme.rootController.navigationBar.accentTextColor
        self.innerNavigationController.navigationBar.shadowImage = generateImage(CGSize(width: 1.0, height: 1.0), rotatedContext: { size, context in
            context.clear(CGRect(origin: CGPoint(), size: size))
            context.setFillColor(self.presentationData.theme.rootController.navigationBar.separatorColor.cgColor)
            context.fill(CGRect(origin: CGPoint(), size: CGSize(width: 1.0, height: UIScreenPixel)))
        })
        
        self.innerNavigationController.navigationBar.isTranslucent = false
        self.innerNavigationController.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: Font.semibold(17.0), NSAttributedString.Key.foregroundColor: self.presentationData.theme.rootController.navigationBar.primaryTextColor]
        self.navigationItem.title = title
        
        self.innerController.dismiss = { [weak self] in
            self?.cancelPressed()
        }
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                
                strongSelf.presentationData = presentationData
                
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.updateThemeAndStrings()
                }
            }
        })
        
    }
    
    required init(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        print("UPDATING COLORS")
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TopChatsControllerNode()
        self.displayNodeDidLoad()
        
        self.innerNavigationController.willMove(toParent: self)
        self.addChild(self.innerNavigationController)
        self.displayNode.view.addSubview(self.innerNavigationController.view)
        self.innerNavigationController.didMove(toParent: self)
        
        self.controllerNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.innerNavigationController.viewWillAppear(false)
        self.innerNavigationController.viewDidAppear(false)
        
        //self.controllerNode.animateIn()
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        // If we need to go higher than Tabbar
        var tabBarHeight: CGFloat
        var options: ContainerViewLayoutInsetOptions = []
        if layout.metrics.widthClass == .regular {
            options.insert(.input)
        }
        let bottomInset: CGFloat = layout.insets(options: options).bottom
        if !layout.safeInsets.left.isZero {
            tabBarHeight = 34.0 + bottomInset
        } else {
            tabBarHeight = 49.0 + bottomInset
        }

        let tabBarFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - tabBarHeight), size: CGSize(width: layout.size.width, height: tabBarHeight))
        
        var finalLayout = layout.size
        finalLayout.height = finalLayout.height - (tabBarFrame.height / 2.0)
        self.innerNavigationController.view.frame = CGRect(origin: CGPoint(), size: finalLayout)
        
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }
    
    private func cancelPressed() {
        //self.controllerNode.animateOut()
    }
    
}