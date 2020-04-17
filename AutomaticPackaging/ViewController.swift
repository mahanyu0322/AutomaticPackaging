//
//  ViewController.swift
//  AutomaticPackaging
//
//  Created by 马洪亮 on 2020/4/16.
//

import Cocoa

let kSelectedFilePath = "userSelectedPath"
let ProvisioniongFilePath = "provisioniongFilePath"
let kTeamID = "kTeamID"
let KFir_token = "fir_token"
let KUserKey = "KUserKey"
let KPassword = "KPassword"
let KApiKey = "KApiKey"
class ViewController: NSViewController,NSTextStorageDelegate {

    @IBOutlet weak var password: NSTextField!
    @IBOutlet weak var UserKey: NSTextField!
    @IBOutlet weak var ApiKey: NSTextField!
    @IBOutlet weak var fir_token: NSTextField!
    @IBOutlet weak var teamID: NSTextField!
    @IBOutlet weak var projectPath: NSTextField!
    @IBOutlet weak var teamIDLab: NSTextField!
    var selectTag = 1
    var isLoading = false
    var outputPipe = Pipe()
    var task:Process?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.projectPath.stringValue = UserDefaults.standard.value(forKey: kSelectedFilePath) as? String ?? ""
        self.teamID.stringValue = UserDefaults.standard.value(forKey: kTeamID) as? String ?? ""
        self.fir_token.stringValue = UserDefaults.standard.value(forKey: KFir_token) as? String ?? ""
        self.ApiKey.stringValue = UserDefaults.standard.value(forKey: KApiKey) as? String ?? ""
        self.UserKey.stringValue = UserDefaults.standard.value(forKey: KUserKey) as? String ?? ""
        self.password.stringValue = UserDefaults.standard.value(forKey: KPassword) as? String ?? ""
    }
    
    
    /// 打开文件夹
    /// - Parameters:
    ///   - sender: button
    ///   - type: 点击按钮类型
    fileprivate func openFile(_ sender: NSButton,type:Int) {
        // 1. 创建打开文档面板对象
        let openPanel = NSOpenPanel()
        // 2. 设置确认按钮文字
        openPanel.prompt = "Select"
        // 3. 设置禁止选择文件
        openPanel.canChooseFiles = false
        // 4. 设置可以选择目录
        openPanel.canChooseDirectories =  true
        // 5. 弹出面板框
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            // 6. 选择确认按钮
            if result == NSApplication.ModalResponse.OK {
                self.projectPath.stringValue = (openPanel.directoryURL?.path)!
            UserDefaults.standard.setValue(openPanel.url?.path, forKey: kSelectedFilePath)
                UserDefaults.standard.synchronize()
            }
            // 9. 恢复按钮状态
            sender.state = NSControl.StateValue.off
        }
    }
    
    /// 点击选择根目录
    /// - Parameter sender: button
    @IBAction func upload(_ sender: NSButton) {
        openFile(sender,type: 1)
    }
    
    
    /// 选择打包类型
    /// - Parameter sender:
    @IBAction func segmentd(_ sender: NSSegmentedControl) {
        let tag = sender.selectedSegment
        self.selectTag = tag
        if tag == 0 {
            self.teamID.isHidden = false
            self.teamIDLab.isHidden = false
        }else{
            self.teamID.isHidden = true
            self.teamIDLab.isHidden = true
        }
    }
    
    
    /// 一键打包
    /// - Parameter sender:
    @IBAction func packaging(_ sender: NSButton) {
        let teamIDStr = self.teamID.stringValue
        let fir_tokenStr = self.fir_token.stringValue
        let ApiKeyStr = self.ApiKey.stringValue
        let UserKeyStr = self.UserKey.stringValue
        let passwordStr = self.password.stringValue
        UserDefaults.standard.setValue(teamIDStr, forKey: kTeamID)
        UserDefaults.standard.setValue(fir_tokenStr, forKey: KFir_token)
        UserDefaults.standard.setValue(ApiKeyStr, forKey: KApiKey)
        UserDefaults.standard.setValue(UserKeyStr, forKey: KUserKey)
        UserDefaults.standard.setValue(passwordStr, forKey: KPassword)

        guard  let executePath = UserDefaults.standard.value(forKey: kSelectedFilePath) as? String else {
            return
        }
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        taskQueue.async {
             // 获取脚本地址
             guard let path = Bundle.main.path(forResource: "script", ofType: "sh") else {
                 return
             }
            // 初始化任务
            let buildTask = Process()
            buildTask.launchPath = path
            // 传入参数
            buildTask.arguments = [executePath,String(self.selectTag),teamIDStr,fir_tokenStr,UserKeyStr,ApiKeyStr,passwordStr]
            // 任务完成回调
            buildTask.terminationHandler = { task in
                DispatchQueue.main.async(execute: {
                    print("任务结束")
                })
            }
            // 开始执行任务
            buildTask.launch()
            // 等任务结束释放内存
            buildTask.waitUntilExit()
        }
    }
}

