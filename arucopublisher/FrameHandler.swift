//
//  FrameHandler.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 17.04.2023.
//

import AVFoundation
import CoreImage

class FrameHandler: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var frame: CGImage?
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let context = CIContext()

    override init() {
        super.init()
        checkPermissions()
        sessionQueue.async { [unowned self] in
            setupCaptureSession()
            captureSession.startRunning()
        }
    }

    func checkPermissions() {
        // video permissions
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

        guard permissionGranted else { return }
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)

        // turn on camera intrinsics matrix delivery
        videoOutput.connection(with: .video)?.isCameraIntrinsicMatrixDeliveryEnabled = true

        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput buffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }

        let cameraStats = getCameraStats(
            buffer: buffer,
            from: (captureSession.inputs.first as! AVCaptureDeviceInput).device
        )

        let markers = OpenCVWrapper.detectAndLocalize(
            imageBuffer,
            withIntrinsics: cameraStats.intrinsics,
            markerSize: cameraStats.markerSize
        )


        guard let cgImage = drawMarkers(sampleBuffer: buffer, markers: markers as! [ArucoMarker]) else { return }

        DispatchQueue.main.async { [unowned self] in
            frame = cgImage
        }
    }

    private func drawMarkers(sampleBuffer: CMSampleBuffer, markers: [ArucoMarker]) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        return cgImage
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
                key:kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                attachmentModeOut:nil
        ) as? Data {
            let matrix: matrix_float3x3 = camData.withUnsafeBytes { $0.pointee }
            for i in 0..<3 {
                for j in 0..<3 {
                    intrinsics[i*3+j] = NSNumber(value: matrix[i][j])
                }
            }
        }

        NSLog("[DEBUG] intrinsics: \(intrinsics)")

        return (
                intrinsics,
                distortionCoefficients,
                markerSize
        )
    }
}

