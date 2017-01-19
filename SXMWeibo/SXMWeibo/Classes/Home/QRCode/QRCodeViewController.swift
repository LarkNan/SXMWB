//
//  QRCodeViewController.swift
//  SXMWeibo
//
//  Created by 申铭 on 17/1/18.
//  Copyright © 2017年 shenming. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeViewController: UIViewController {
    // 二维码结果文本
    @IBOutlet weak var customLabel: UILabel!
    @IBOutlet weak var customTabbar: UITabBar!
    // 容器视图的高度约束
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    // 冲击波视图
    @IBOutlet weak var scanLineView: UIImageView!
    // 冲击波顶部约束
    @IBOutlet weak var scanLineConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        customTabbar.selectedItem = customTabbar.items?.first
        
        // 监听底部工具条的点击
        customTabbar.delegate = self
        
        // 扫描二维码
        scanQRCode()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        startAnimation()
    }
    
    // MARK: - 内部方法
    private func scanQRCode() {
        // 判断输入能否添加到回话中
        if !session.canAddInput(input) {
            return
        }
        // 判断输出是否添加到回话中
        if !session.canAddOutput(output) {
            return
        }
        // 添加输入输出
        session.addInput(input)
        session.addOutput(output)
        // 设置输出能够解析的数据类型
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        // 监听输出解析到的数据
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        // 添加预览图层
        view.layer.insertSublayer(previewLayer, atIndex: 0)
        previewLayer.frame = view.bounds
        // 添加容器图层给描边用
        view.layer.addSublayer(containerLayer)
        containerLayer.frame = view.bounds
        // 开始扫描
        session.startRunning()
    }
    
    // 开启冲击波动画
    private func startAnimation() {
        scanLineConstraint.constant = -containerHeightConstraint.constant
        view.layoutIfNeeded()
        
        // 执行扫描动画
        UIView.animateWithDuration(2.0) { () -> Void in
            UIView.setAnimationRepeatCount(MAXFLOAT)
            self.scanLineConstraint.constant = self.containerHeightConstraint.constant
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func photoBtnClick(sender: AnyObject) {
    }

    @IBAction func closeBtnClick(sender: AnyObject) {
        dismissViewControllerAnimated(true , completion: nil)
    }
    
    // MARK: - lazy
    
    // 输入对象
    private lazy var input: AVCaptureDeviceInput? = {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        return try? AVCaptureDeviceInput(device: device)
    }()
    
    // 会话
    private lazy var session: AVCaptureSession = AVCaptureSession()
    
    // 输出对象
    private lazy var output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    
    // 预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    // 保存描边的图层
    private lazy var containerLayer: CALayer = CALayer()
}

extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        SXMLog(metadataObjects.last?.stringValue)
        // 显示结果
        customLabel.text = metadataObjects.last?.stringValue
        
        clearLayers()
        
        guard let metadata = metadataObjects.last as? AVMetadataObject else {
            return
        }
        
        // 描边的数据
        let objc = previewLayer.transformedMetadataObjectForMetadataObject(metadata)
        // 对二维码进行描边
        drawLines(objc as! AVMetadataMachineReadableCodeObject)
    }
    
    private func drawLines(objc: AVMetadataMachineReadableCodeObject) {
        
        // 安全校验
        guard let array = objc.corners else {
            return
        }
        
        // 创建图层
        let layer = CAShapeLayer()
        layer.lineWidth = 5
        layer.strokeColor = UIColor.greenColor().CGColor
        layer.fillColor = UIColor.clearColor().CGColor
        
        // 绘制矩形
        let path = UIBezierPath()
        var point = CGPointZero
        var index = 0
        CGPointMakeWithDictionaryRepresentation((array[index++] as! CFDictionary), &point)
        
        // 将起点移动到某个点
        path.moveToPoint(point)
        
        while index < array.count {
            CGPointMakeWithDictionaryRepresentation((array[index++] as! CFDictionary), &point)
            path.addLineToPoint(point)
        }
        path.closePath()
        
        layer.path = path.CGPath
        
        // 将图层添加到界面
        containerLayer.addSublayer(layer)
    }
    
    // 清除描边
    private func clearLayers() {
        guard let subLayers = containerLayer.sublayers else {
            return
        }
        
        for layer in subLayers {
            layer.removeFromSuperlayer()
        }
    }
}

extension QRCodeViewController: UITabBarDelegate {
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        SXMLog(item.tag)
        
        containerHeightConstraint.constant = item.tag == 1 ? 150 : 300
        view.layoutIfNeeded()
        
        // 移除动画
        scanLineView.layer.removeAllAnimations()
        
        startAnimation()
    }
}
