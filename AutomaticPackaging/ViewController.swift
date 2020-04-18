//
//  ViewController.swift
//  AutomaticPackaging
//
//  Created by 马洪亮 on 2020/4/16.
//

import Cocoa

let kSelectedFilePath = "kSelectedFilePath"
let kSelectedDirectoryPath = "kSelectedDirectoryPath"
let kProvisioniongFilePath = "kProvisioniongFilePath"
let kFirToken = "kFirToken"
let kUserKey = "kUserKey"
let kPGYPassword = "kPGYPassword"
let kApiKey = "kApiKey"
let kAppId = "kAppId"
let kAppIdPwd = "kAppIdPwd"

class ViewController: NSViewController,NSTextStorageDelegate {
    @IBOutlet weak var appid: NSTextField!
    @IBOutlet weak var appid_pwd: NSTextField!
    @IBOutlet weak var automatic_packaging: NSButton!
    @IBOutlet weak var showInfoTextView: NSTextView!
    @IBOutlet weak var mobileprovision_btn: NSButton!
    @IBOutlet weak var mobileprovision_field: NSTextField!
    @IBOutlet weak var pgy_btn: NSButton!
    @IBOutlet weak var fir_btn: NSButton!
    @IBOutlet weak var app_store_btn: NSButton!
    @IBOutlet weak var model_type: NSSegmentedControl!
    @IBOutlet weak var password: NSTextField!
    @IBOutlet weak var UserKey: NSTextField!
    @IBOutlet weak var ApiKey: NSTextField!
    @IBOutlet weak var fir_token: NSTextField!
    @IBOutlet weak var projectPath: NSTextField!
    var selectTag = 1
    var model_tag = 0
    var isLoading = false
    var outputPipe = Pipe()
    var task:Process?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getUiData()
    }
    
    ///获取UI数据
    fileprivate func getUiData() {
        self.projectPath.stringValue = getUserDefaultsValue(key: kSelectedFilePath)
        self.mobileprovision_field.stringValue = getUserDefaultsValue(key: kProvisioniongFilePath)
        self.fir_token.stringValue = getUserDefaultsValue(key: kFirToken)
        self.ApiKey.stringValue = getUserDefaultsValue(key: kApiKey)
        self.UserKey.stringValue = getUserDefaultsValue(key: kUserKey)
        self.password.stringValue = getUserDefaultsValue(key: kPGYPassword)
        self.appid.stringValue = getUserDefaultsValue(key: kAppId)
        self.appid_pwd.stringValue = getUserDefaultsValue(key: kAppIdPwd)
    }
    
    /// 选择打包类型
    /// - Parameter sender:
    @IBAction func segmentd(_ sender: NSSegmentedControl) {
        let tag = sender.selectedSegment
        self.selectTag = tag
        switch tag {
        case 0:
            self.app_store_btn.isEnabled = true
            self.app_store_btn.state = NSControl.StateValue(rawValue: 1)
        default:
            self.app_store_btn.isEnabled = false
            self.app_store_btn.state = NSControl.StateValue(rawValue: 0)
        }
    }
    
    /// 选择打包模式
    /// - Parameter sender: button
    @IBAction func model_segment(_ sender: NSSegmentedControl) {
        let tag = sender.selectedSegment
        self.model_tag = tag
    }
    
    /// 点击选择文件
    /// - Parameter sender: button
    @IBAction func upload(_ sender: NSButton) {
        openFile(sender)
    }
    
    /// 打开文件夹
    /// - Parameters:
    ///   - sender: button
    fileprivate func openFile(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories =  false
        //根据不同时间打开不同的后缀文件
        switch sender.tag {
        case 1:
            openPanel.allowedFileTypes = ["xcworkspace","xcodeproj"]
        case 2:
            openPanel.allowedFileTypes = ["mobileprovision"]
        case 3:
            openPanel.allowedFileTypes = ["ipa"]
        case 4:
            openPanel.allowedFileTypes = ["ipa"]
        case 5:
            openPanel.allowedFileTypes = ["ipa"]
        default:
            break
        }
        //弹出面板框
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result == NSApplication.ModalResponse.OK {
                let fileURL = openPanel.url!.path
                switch sender.tag {
                case 1:
                    self.projectPath.stringValue = fileURL
                    //保存项目所在根目录
                    serUserDefaultsValue(key: kSelectedDirectoryPath, value: (openPanel.directoryURL?.path)!)
                    //保存项目路径用于展示
                    serUserDefaultsValue(key: kSelectedFilePath, value:fileURL)
                case 2:
                    //保存描述文件路径
                    self.mobileprovision_field.stringValue = fileURL
                    serUserDefaultsValue(key: kProvisioniongFilePath, value:fileURL)
                case 3:
                    //上传到fir
                    self.autoPackaging(1,path: fileURL)
                case 4:
                    //上传到蒲公英
                    self.autoPackaging(2,path: fileURL)
                case 5:
                    //上传到App Store
                    self.autoPackaging(3,path: fileURL)
                default:
                    break
                }
                UserDefaults.standard.synchronize()
            }
            sender.state = NSControl.StateValue.off
        }
    }
    
    /// 自动打包
    /// - Parameter sender:
    @IBAction func packaging(_ sender: NSButton) {
        self.automatic_packaging.isEnabled = false
        self.automatic_packaging.title = "正在打包"
        autoPackaging(0,path: "")
    }
    
    
    /// 打包
    /// - Parameters:
    ///   - type: 手动打包方式
    ///   - path: 手动打包选择的ipa包的路径
    fileprivate func autoPackaging(_ type:Int,path:String) {
        guard  let executePath = UserDefaults.standard.value(forKey: kSelectedDirectoryPath) as? String else {
            return
        }
        let fir_tokenStr = self.fir_token?.stringValue ?? ""
        let ApiKeyStr = self.ApiKey?.stringValue ?? ""
        let UserKeyStr = self.UserKey?.stringValue ?? ""
        let passwordStr = self.password?.stringValue ?? ""
        let is_seleted_app_store = self.app_store_btn.state.rawValue
        let is_seleted_fir = self.fir_btn.state.rawValue
        let is_seleted_pgy = self.pgy_btn.state.rawValue
        let mobileprovision_field_str = self.mobileprovision_field?.stringValue ?? ""
        let appid_str = self.appid?.stringValue ?? ""
        let appid_pwd_str = self.appid_pwd?.stringValue ?? ""
        
        serUserDefaultsValue(key: kFirToken, value: fir_tokenStr)
        serUserDefaultsValue(key: kApiKey, value: ApiKeyStr)
        serUserDefaultsValue(key: kUserKey, value: UserKeyStr)
        serUserDefaultsValue(key: kPGYPassword, value: passwordStr)
        serUserDefaultsValue(key: kAppId, value: appid_str)
        serUserDefaultsValue(key: kAppIdPwd, value: appid_pwd_str)
        let data = [
            executePath,//项目本地路径
            String(self.selectTag),//打包类型
            "",//
            fir_tokenStr,//fir token
            UserKeyStr,//蒲公英的user key
            ApiKeyStr,//蒲公英的api key
            passwordStr,//蒲公英的安装密码
            String(self.model_tag),//打包模式
            String(is_seleted_app_store),//是否选中App Store
            String(is_seleted_fir),//是否选中fir
            String(is_seleted_pgy),//是否选中蒲公英
            String(type),//操作类型
            path,//f直接选择h上传IPA路径
            mobileprovision_field_str,
            appid_str,
            appid_pwd_str
        ]
        
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
            // 获取脚本地址
            guard let path = Bundle.main.path(forResource:"script", ofType: "sh") else {
                return
            }
            // 初始化任务
            let buildTask = Process()
            buildTask.launchPath = path
            // 传入参数
            buildTask.arguments = data
            self.captureStandardOutputAndRouteToTextView(buildTask)
            // 任务完成回调
            buildTask.terminationHandler = { task in
                
                DispatchQueue.main.async(execute: {
                    self.automatic_packaging.isEnabled = true
                    self.automatic_packaging.title = "自动打包"
                    self.showInfoTextView.string = self.showInfoTextView.string + "\n" + "任务结束"
                    //滚动到可视位置
                    let range = NSRange(location:self.showInfoTextView.string.count,length:0)
                    self.showInfoTextView.scrollRangeToVisible(range)
                })
            }
            // 开始执行任务
            buildTask.launch()
            // 等任务结束释放内存
            buildTask.waitUntilExit()
        }
    }
    
    
    /// 帮助按钮
    /// - Parameter sender: button
    @IBAction func helpBtn(_ sender: NSButton) {
        switch sender.tag {
        case 100:
            NSWorkspace.shared.open(NSURL(string: "https://github.com/FIRHQ/fir-cli/tree/master/doc")! as URL)
        case 200:
            NSWorkspace.shared.open(NSURL(string: "https://www.pgyer.com/doc/api#uploadApp")! as URL)
            
        default:
            break
        }
    }
    
    /// 截取控制台输出展示到界面UI上
    /// - Parameter task: 任务进程
    fileprivate func captureStandardOutputAndRouteToTextView(_ task:Process) {
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        //在后台线程等待数据和通知
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        //接受到通知消息
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            //获取管道数据 转为字符串
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            if outputString != ""{
                //在主线程处理UI
                DispatchQueue.main.async(execute: {
                    let previousOutput = self.showInfoTextView.string
                    let nextOutput = previousOutput + "\n" + outputString
                    self.showInfoTextView.string = nextOutput
                    //滚动到可视位置
                    let range = NSRange(location:nextOutput.count,length:0)
                    self.showInfoTextView.scrollRangeToVisible(range)
                })
            }
            //继续等待新数据和通知
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    //
}

