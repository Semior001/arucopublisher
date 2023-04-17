//
//  FrameHandler.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 17.04.2023.
//

import SwiftUI
import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    // guarded
    @Published var frame: CGImage?
    @Published var fps: Int = 0
    @Published var processedWithinSeconds: Double = 0
    private var lastFrameTimestamp: Double = 0

    @AppStorage("targetServerAddress")
    private var targetServerAddress = ""
    @AppStorage("iso")
    private var iso = ""
    @AppStorage("exposure")
    private var exposure = ""

    private var sender: UDPSender?
    private let lock = NSLock()

    override init() {
        super.init()
        checkPermissions()
        setupCaptureSession()
        sessionQueue.async { [unowned self] in
            captureSession.startRunning()
        }
    }

    func toggleFlash(value: Bool) {
        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
            return
        }
        guard device.hasTorch else {
            return
        }
        guard device.isTorchModeSupported(.on) else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = value ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            permissionGranted = granted
        }
    }

    func setupCaptureSession() {
        let videoOutput = AVCaptureVideoDataOutput()

        guard permissionGranted else {
            return
        }
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else {
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        guard captureSession.canAddInput(videoDeviceInput) else {
            return
        }
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)

        videoOutput.connection(with: .video)?.isCameraIntrinsicMatrixDeliveryEnabled = true
        videoOutput.connection(with: .video)?.videoOrientation = .landscapeRight

        guard videoDevice.isExposureModeSupported(.custom) else {
            return
        }

        do {
            let iso = Float(iso) ?? 100
            let exposure = Float(exposure) ?? 0

            try videoDevice.lockForConfiguration()
            videoDevice.setExposureModeCustom(duration: CMTimeMake(value: 1, timescale: 1000), iso: iso, completionHandler: nil)
            videoDevice.setExposureTargetBias(exposure, completionHandler: nil)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not set exposure")
        }
    }

    func stop() {
        sessionQueue.sync {}
        captureSession.stopRunning()
    }

    func startBroadcast() {
        lock.lock()
        defer { lock.unlock() }
        sender = UDPSender(hostport: targetServerAddress)
    }

    func stopBroadcast() {
        lock.lock()
        defer { lock.unlock() }
        sender = nil
    }

    func captureOutput(
            _ output: AVCaptureOutput,
            didOutput buffer: CMSampleBuffer,
            from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }

        let cameraStats = getCameraStats(
                buffer: buffer,
                from: (captureSession.inputs.first as! AVCaptureDeviceInput).device
        )

        var markers: [ArucoMarker] = []

        let pr = measureSeconds {
            markers = OpenCVWrapper.detectAndLocalize(
                    imageBuffer,
                    withIntrinsics: cameraStats.intrinsics,
                    markerSize: cameraStats.markerSize
            ) as! [ArucoMarker]
        }

        if markers.count > 0 {
            NSLog("[DEBUG] found \(markers.count) markers")
        }

        guard let cgImage = drawMarkers(sampleBuffer: buffer, markers: markers) else {
            return
        }

        DispatchQueue.main.async { [unowned self] in
            frame = cgImage

            let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
            let fpsFloat = 1 / (currentTimestamp - lastFrameTimestamp)
            lastFrameTimestamp = currentTimestamp
            fps = Int(fpsFloat.rounded())
            processedWithinSeconds = pr

            if let sender = sender {
                if markers.count == 0 {
                    return
                }
                let arucos = markers.map { marker in
                    ArucoPacket(
                            id: Int(marker.id),
                            position: FloatTriple(
                                    x: Float(marker.position.x),
                                    y: Float(marker.position.y),
                                    z: Float(marker.position.z)
                            ),
                            orientation: FloatTriple(
                                    x: Float(marker.orientation.x),
                                    y: Float(marker.orientation.y),
                                    z: Float(marker.orientation.z)
                            )
                    )
                }

                lock.lock()
                defer { lock.unlock() }

                sender.send(packet: Packet(arucos: arucos, timeElapsed: processedWithinSeconds, ts: currentTimestamp))
            }
        }
    }

    private func drawMarkers(sampleBuffer: CMSampleBuffer, markers: [ArucoMarker]) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let uiImage = UIImage(cgImage: cgImage)
        UIGraphicsBeginImageContext(uiImage.size)
        let contextRef = UIGraphicsGetCurrentContext()
        uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))

        contextRef?.setLineWidth(2.0)
        contextRef?.setStrokeColor(UIColor.red.cgColor)

        for marker in markers {
            contextRef?.beginPath()
            contextRef?.move(to: marker.corners.first)
            contextRef?.addLine(to: marker.corners.second)
            contextRef?.addLine(to: marker.corners.third)
            contextRef?.addLine(to: marker.corners.fourth)
            contextRef?.closePath()
            contextRef?.strokePath()
        }

        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return drawnImage?.cgImage
    }

    private func getCameraStats(
            buffer: CMSampleBuffer,
            from: AVCaptureDevice
    ) -> (intrinsics: [NSNumber], distortionCoefficients: [NSNumber], markerSize: Float64) {
        let markerSize = 0.133
        var intrinsics = [NSNumber](repeating: 0, count: 9)
        let distortionCoefficients = [NSNumber](repeating: 0, count: 5)

        if let camData = CMGetAttachment(
                buffer,
                key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                attachmentModeOut: nil
        ) as? Data {
            let matrix: matrix_float3x3 = camData.withUnsafeBytes {
                $0.pointee
            }
            for i in 0..<3 {
                for j in 0..<3 {
                    intrinsics[i * 3 + j] = NSNumber(value: matrix[i][j])
                }
            }
        }

        return (
                intrinsics,
                distortionCoefficients,
                markerSize
        )
    }
}

func measureSeconds(_ block: () -> Void) -> Double {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let end = CFAbsoluteTimeGetCurrent()
    return end - start
}

