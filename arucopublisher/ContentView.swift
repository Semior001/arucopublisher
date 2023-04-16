//
//  ContentView.swift
//  arucopublisher
//
//  Created by Yelshat Duskaliyev on 27.03.2023.
//

import SwiftUI
import AVFoundation

struct ArucoMarkerPreview: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let arucoMarkerViewController = ArucoMarkerViewController()
        return arucoMarkerViewController.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }

    class Coordinator: NSObject {
        var parent: ArucoMarkerPreview

        init(_ parent: ArucoMarkerPreview) {
            self.parent = parent
        }
    }

}

struct ContentView: View {
    @State private var isCameraAuthorized = false

    var body: some View {
        VStack {
            if isCameraAuthorized {
                ArucoMarkerPreview()
                        .edgesIgnoringSafeArea(.all)
            } else {
                Text("Camera access required")
            }
        }.onAppear { checkCameraAuthorization()}
    }

    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isCameraAuthorized = granted
                }
            }
        default:
            break
        }
    }

}

class ArucoMarkerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var intrinsics: [NSNumber]!
    private var distortionCoefficients: [NSNumber]!
    private let markerSize: Float64 = 0.133

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        let videoInput: AVCaptureDeviceInput

        // set intrinsics and distortion coefficients
        let cameraIntrinsics = getCameraIntrinsics(from: videoCaptureDevice)
        intrinsics = cameraIntrinsics.intrinsics
        distortionCoefficients = cameraIntrinsics.distortionCoefficients

        NSLog("Camera intrinsics: \(cameraIntrinsics)")

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if !captureSession.canAddInput(videoInput) {
            return
        }

        captureSession.addInput(videoInput)
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            return
        }

        captureSession.addOutput(videoOutput)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    func getCameraIntrinsics(from captureDevice: AVCaptureDevice) -> (intrinsics: [NSNumber], distortionCoefficients: [NSNumber]) {
        let intrinsics = captureDevice.activeFormat.videoSupportedFrameRateRanges.first!.minFrameRate
        let distortionCoefficients = captureDevice.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate
        return (
                [
                    NSNumber(value: intrinsics),
                    NSNumber(value: intrinsics),
                    NSNumber(value: intrinsics)
                ],
                [
                    NSNumber(value: distortionCoefficients),
                    NSNumber(value: distortionCoefficients),
                    NSNumber(value: distortionCoefficients)
                ]
        )
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        NSLog("captureOutput")

        connection.videoOrientation = .portrait

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        NSLog("requesting markers")

        let markers = OpenCVWrapper.detectAndLocalize(imageBuffer,
                withIntrinsics: intrinsics,
                distortionCoefficients: distortionCoefficients,
                markerSize: markerSize)

        NSLog("no. of markers: \((markers as! [ArucoMarker]).count)")

        // Process detected Aruco markers and draw them on the preview screen
        DispatchQueue.main.async {
            self.drawArucoMarkers(markers: markers as! [ArucoMarker])
        }
    }

    private func drawArucoMarkers(markers: [ArucoMarker]) {
        view.subviews.forEach {
            if $0.tag == 100 {
                $0.removeFromSuperview()
            }
        }

        for marker in markers {
            let points = [marker.corners.first, marker.corners.second, marker.corners.third, marker.corners.fourth]
            let minX = points.map {
                        $0.x
                    }
                    .min()!
            let minY = points.map {
                        $0.y
                    }
                    .min()!
            let maxX = points.map {
                        $0.x
                    }
                    .max()!
            let maxY = points.map {
                        $0.y
                    }
                    .max()!

            let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            let markerView = UIView(frame: rect)
            markerView.layer.borderColor = UIColor.red.cgColor
            markerView.layer.borderWidth = 2
            markerView.tag = 100
            view.addSubview(markerView)
        }
    }
}
